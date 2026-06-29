#!/usr/bin/env python3
"""
CSQJek — synthetic data generator: CSQMobile device-purchase + credit-check fork.

Companion to seed_cs_funnel.py / seed_callcenter_return.py. Generates the telco
DEVICE-PURCHASE journey as synthetic Product-Analytics data, ending in the
credit-check FORK:

    device_viewed → variant_selected → financing_selected → plan_attached →
    checkout_started → fulfillment_selected → payment_method_selected →
    credit_check_started → credit_check_result
        ├─ approved  → purchase_completed
        └─ declined  → credit_recovery_outright → purchase_completed  (recovery)
                       └─ or abandon

The point of THIS generator: credit-check **approval rate varies by cohort**.
Each synthetic user carries the same cohort properties the live app now sends
(account_type, loyalty_tier, is_new_user, tenure_days, lifetime_orders,
signup_channel), and approval probability is computed from them — so a PM can
split the credit-check funnel by `account_type` or `loyalty_tier` and see
genuinely different approval rates. That is the "behaviour varies by cohort"
story, generated as historical data WITHOUT making the live demo non-deterministic.

Event names + property keys/tokens match CLAUDE.md's telco device tables exactly,
so synthetic users are indistinguishable from real ones in funnels/segments —
except they carry `synthetic: true` and `cohort: "<name>"` for isolation/cleanup.

Endpoints + payload shape are identical to seed_cs_funnel.py (Heap server-side
/api/track + /api/add_user_properties). Defaults to a DRY-RUN; pass --send to POST.

  # Dry-run (prints funnel tally + approval-by-cohort + sample sessions):
  python3 tools/seed_device_credit.py --users 60 --seed 7

  # Send a reproducible, named cohort to the dashboard:
  python3 tools/seed_device_credit.py --users 600 --seed 42 --cohort device_credit_demo --send
"""

import argparse
import concurrent.futures
import json
import random
import time
import urllib.error
import urllib.request
from datetime import datetime, timedelta, timezone

DEFAULT_APP_ID = "4140621035"
DEFAULT_TRACK_ENDPOINT = "https://heapanalytics.com/api/track"
DEFAULT_USER_PROPS_ENDPOINT = "https://heapanalytics.com/api/add_user_properties"

# ── Market mix (amounts are Singapore-scale for EVERY market — the app's
# documented currency-scale convention; only the app view layer ×100s Tokyo). ──
MARKETS = [("Singapore", 0.50), ("Tokyo", 0.30), ("Sydney", 0.20)]

# Device catalogue: (brand, model, storage, outright_price, monthly_price_24mo).
# Prices are Singapore-scale to match the app's RideOption/TelcoPlan convention.
DEVICES = [
    ("Apple",   "iPhone 16 Pro",   "256GB", 1899, 79),
    ("Apple",   "iPhone 16",       "128GB", 1299, 54),
    ("Samsung", "Galaxy S26",      "256GB", 1699, 71),
    ("Samsung", "Galaxy Z Fold6",  "512GB", 2799, 117),
    ("Google",  "Pixel 9 Pro",     "128GB", 1499, 62),
]
COLORS = {
    "Apple":   ["Natural Titanium", "Black Titanium", "Desert Titanium"],
    "Samsung": ["Phantom Black", "Cream", "Mint"],
    "Google":  ["Obsidian", "Porcelain", "Hazel"],
}
PLANS = [  # (name, plan_type, monthly_price)  — name is the STABLE analytics token
    ("ValuePlus",   "postpaid", 28),
    ("MaxData",     "postpaid", 48),
    ("LiteConnect", "postpaid", 18),
]
FINANCE = [("installment_24mo", 0.62), ("outright", 0.38)]
FULFILLMENT = [("delivery", 0.68), ("pickup", 0.32)]
PAY_METHODS = [("card", 0.70), ("wallet", 0.30)]

ACCOUNT_TYPES = [("standard", 0.60), ("premium", 0.40)]
LOYALTY_TIERS = [("none", 0.15), ("bronze", 0.20), ("silver", 0.25),
                 ("gold", 0.25), ("platinum", 0.15)]
SIGNUP_CHANNELS = [("organic", 0.34), ("referral", 0.28),
                   ("paid_ad", 0.24), ("partner", 0.14)]

# Screen layer — names match CSQ.trackScreenview(...) in the app (CLAUDE.md).
# device_viewed..purchase walks these screens.
SCREEN_FLOW = [
    "Telco - Device Detail",
    "Telco - Device Financing",
    "Telco - Checkout",
    "Telco - Credit Check",
    "Telco - Order Confirmed",
]

# Device-purchase funnel spine: (event, p_reach_given_prev_reached).
SPINE = [
    ("telco_device_viewed",           1.00),
    ("telco_device_variant_selected", 0.82),
    ("telco_device_financing_selected", 0.70),
    ("telco_device_plan_attached",    0.86),
    ("telco_checkout_started",        0.74),
    ("telco_fulfillment_selected",    0.90),
    ("telco_payment_method_selected", 0.93),
    ("telco_credit_check_started",    0.80),
    ("telco_credit_check_result",     0.97),  # gated step → FORK after this
]


def weighted_choice(pairs):
    r = random.random()
    acc = 0.0
    for value, w in pairs:
        acc += w
        if r <= acc:
            return value
    return pairs[-1][0]


def clamp(x, lo, hi):
    return max(lo, min(hi, x))


def pick_market():
    return weighted_choice(MARKETS)


def business_hour():
    buckets = ([h for h in range(8, 22)] * 3) + list(range(0, 8)) + list(range(22, 24))
    return random.choice(buckets)


def session_start(now, days):
    base = now - timedelta(days=random.randint(0, max(0, days - 1)))
    return base.replace(hour=business_hour(), minute=random.randint(0, 59),
                        second=random.randint(0, 59), microsecond=0)


def iso(ts):
    return ts.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


# ── Cohort profile + the behaviour it drives ──────────────────────────────────
def make_profile():
    account_type = weighted_choice(ACCOUNT_TYPES)
    loyalty = weighted_choice(LOYALTY_TIERS)
    is_new = random.random() < 0.30
    if is_new:
        tenure_days = random.randint(0, 30)
        lifetime_orders = random.randint(0, 3)
    else:
        tenure_days = random.randint(60, 1500)
        lifetime_orders = random.randint(4, 600)
    return {
        "account_type": account_type,
        "loyalty_tier": loyalty,
        "is_new_user": is_new,
        "tenure_days": tenure_days,
        "lifetime_orders": lifetime_orders,
        "signup_channel": weighted_choice(SIGNUP_CHANNELS),
    }


def approval_p(profile):
    """Credit-check approval probability from the cohort — the whole point."""
    p = 0.50
    p += 0.22 if profile["account_type"] == "premium" else 0.0
    p += {"platinum": 0.20, "gold": 0.10, "silver": 0.0,
          "bronze": -0.10, "none": -0.18}[profile["loyalty_tier"]]
    p += -0.22 if profile["is_new_user"] else 0.0
    p += clamp(profile["tenure_days"] / 1500.0, 0.0, 1.0) * 0.18
    return clamp(p, 0.08, 0.96)


def recovery_p(profile):
    """After a decline, probability the user switches to an outright purchase."""
    p = 0.45
    p += 0.20 if profile["account_type"] == "premium" else 0.0
    p += 0.10 if profile["loyalty_tier"] in ("gold", "platinum") else 0.0
    return clamp(p, 0.10, 0.90)


# ── Build one user's event sequence ───────────────────────────────────────────
def build_session(now, days, cohort, index, run_tag):
    market = pick_market()
    profile = make_profile()
    brand, model, storage, outright, monthly = random.choice(DEVICES)
    color = random.choice(COLORS[brand])
    finance_mode = weighted_choice(FINANCE)
    plan_name, plan_type, plan_price = random.choice(PLANS)
    term_months = 24 if finance_mode == "installment_24mo" else 0
    monthly_total = (monthly + plan_price) if finance_mode == "installment_24mo" else plan_price
    due_today = plan_price if finance_mode == "installment_24mo" else (outright + plan_price)

    identity = "syn-%s-%04d" % (run_tag, index)

    base_props = {"market": market, "synthetic": True, "demo_user": True, "cohort": cohort}
    user_props = dict(base_props)
    user_props.update({"name": "Synthetic User"})
    user_props.update(profile)

    t = session_start(now, days)
    events = []

    def emit(name, props, dwell=(4, 30)):
        nonlocal t
        t = t + timedelta(seconds=random.randint(*dwell))
        p = dict(base_props)
        p.update(props)
        events.append((name, t, p))

    def emit_screen(screen_name, dwell=(2, 8)):
        emit("screen_viewed", {"screen_name": screen_name}, dwell=dwell)

    reached = {}
    credit_result = None
    for idx, (event, p) in enumerate(SPINE):
        if idx > 0 and random.random() > p:
            break  # drop out of the funnel here
        reached[event] = True

        if event == "telco_device_viewed":
            emit_screen("Telco - Device Detail")
            emit(event, {"brand": brand, "model": model, "storage": storage,
                         "outright_price": outright, "monthly_price": monthly})

        elif event == "telco_device_variant_selected":
            emit(event, {"model": model, "color": color, "storage": storage}, dwell=(3, 18))

        elif event == "telco_device_financing_selected":
            emit_screen("Telco - Device Financing")
            emit(event, {"model": model, "finance_mode": finance_mode,
                         "plan_name": plan_name, "term_months": term_months,
                         "monthly_total": monthly_total, "due_today": due_today})

        elif event == "telco_device_plan_attached":
            emit(event, {"plan_name": plan_name, "plan_type": plan_type, "price": plan_price})

        elif event == "telco_checkout_started":
            emit_screen("Telco - Checkout")
            emit(event, {"kind": "device", "item": model,
                         "due_today": due_today, "monthly_total": monthly_total})

        elif event == "telco_fulfillment_selected":
            emit(event, {"kind": "device", "method": weighted_choice(FULFILLMENT)})

        elif event == "telco_payment_method_selected":
            emit(event, {"kind": "device", "method": weighted_choice(PAY_METHODS)})

        elif event == "telco_credit_check_started":
            emit_screen("Telco - Credit Check")
            emit(event, {"kind": "device", "item": model, "amount": due_today}, dwell=(5, 20))

        elif event == "telco_credit_check_result":
            approved = random.random() < approval_p(profile)
            credit_result = "approved" if approved else "declined"
            emit(event, {"kind": "device", "result": credit_result}, dwell=(2, 6))

    # ── The fork (only if the user actually reached the result step) ──
    completed = False
    recovered = False
    if credit_result == "approved":
        emit_screen("Telco - Order Confirmed")
        emit("telco_purchase_completed",
             {"kind": "device", "item": model, "plan_name": plan_name,
              "finance_mode": finance_mode, "term_months": term_months,
              "due_today": due_today, "monthly_total": monthly_total}, dwell=(2, 8))
        completed = True
    elif credit_result == "declined":
        if random.random() < recovery_p(profile):
            recovered = True
            emit("telco_credit_recovery_outright",
                 {"kind": "device", "item": model, "due_today": outright + plan_price}, dwell=(4, 20))
            emit_screen("Telco - Order Confirmed")
            emit("telco_purchase_completed",
                 {"kind": "device", "item": model, "plan_name": plan_name,
                  "finance_mode": "outright", "term_months": 0,
                  "due_today": outright + plan_price, "monthly_total": plan_price}, dwell=(2, 8))
            completed = True
        # else: abandon — no further events.

    meta = {"profile": profile, "credit_result": credit_result,
            "completed": completed, "recovered": recovered}
    return identity, user_props, events, meta


# ── Sending (identical shape to seed_cs_funnel.py) ────────────────────────────
def post_json(url, payload, timeout=15, retries=3):
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(url, data=data, method="POST",
                                 headers={"Content-Type": "application/json",
                                          "Accept": "application/json"})
    backoff = 0.5
    for attempt in range(retries + 1):
        try:
            with urllib.request.urlopen(req, timeout=timeout) as resp:
                return resp.status, resp.read(200).decode("utf-8", "replace")
        except urllib.error.HTTPError as e:
            if e.code in (429, 500, 502, 503, 504) and attempt < retries:
                time.sleep(backoff); backoff *= 2; continue
            return e.code, e.read(400).decode("utf-8", "replace")
        except Exception as e:  # noqa
            if attempt < retries:
                time.sleep(backoff); backoff *= 2; continue
            return None, str(e)


def send_user_properties(endpoint, app_id, identity, props):
    return post_json(endpoint, {"app_id": app_id, "identity": identity, "properties": props})


def send_event(endpoint, app_id, identity, name, ts, props):
    return post_json(endpoint, {"app_id": app_id, "identity": identity,
                                "event": name, "timestamp": iso(ts), "properties": props})


def pct(n, d):
    return (100.0 * n / d) if d else 0.0


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--users", type=int, default=600, help="number of synthetic users (default 600)")
    ap.add_argument("--days", type=int, default=14, help="spread sessions over the last N days (default 14)")
    ap.add_argument("--app-id", default=DEFAULT_APP_ID, help="Heap/CS environment id")
    ap.add_argument("--endpoint", default=DEFAULT_TRACK_ENDPOINT, help="track API endpoint")
    ap.add_argument("--user-props-endpoint", default=DEFAULT_USER_PROPS_ENDPOINT,
                    help="add_user_properties endpoint")
    ap.add_argument("--cohort", default="device_credit_demo",
                    help="cohort tag stamped on every event (for filtering/cleanup)")
    ap.add_argument("--run-tag", default=None,
                    help="identity namespace (default: cohort). Same tag => same users on re-run.")
    ap.add_argument("--seed", type=int, default=None, help="RNG seed for reproducible runs")
    ap.add_argument("--send", action="store_true", help="ACTUALLY POST to the endpoint (default: dry-run)")
    ap.add_argument("--max-workers", type=int, default=6, help="concurrent POSTs when sending (default 6)")
    ap.add_argument("--sample", type=int, default=2, help="dry-run: print N sample sessions")
    args = ap.parse_args()

    if args.seed is not None:
        random.seed(args.seed)

    run_tag = args.run_tag or args.cohort
    now = datetime.now(timezone.utc)
    sessions = [build_session(now, args.days, args.cohort, i, run_tag) for i in range(args.users)]

    # ── Funnel tally ──
    spine_names = [e for e, _ in SPINE]
    counts = {e: 0 for e in spine_names}
    total_events = 0
    for _id, _up, events, _m in sessions:
        seen = set(n for n, _, _ in events)
        total_events += len(events)
        for e in spine_names:
            if e in seen:
                counts[e] += 1
    start = counts[spine_names[0]] or 1

    print("\n" + "=" * 66)
    print("  CSQMobile device-purchase + credit-check fork — generated cohort")
    print("  users=%d  events=%d  days=%d  cohort=%s" % (args.users, total_events, args.days, args.cohort))
    print("=" * 66)
    print("  %-36s %7s %7s %7s" % ("funnel step (event)", "users", "%start", "%prev"))
    print("  " + "-" * 62)
    prev = start
    for e in spine_names:
        c = counts[e]
        print("  %-36s %7d %6.1f%% %6.1f%%" % (e, c, pct(c, start), pct(c, prev)))
        prev = c if c else prev
    print("  " + "-" * 62)

    # ── The fork outcome ──
    res = {"approved": 0, "declined": 0, "none": 0}
    completed = recovered = 0
    for _id, _up, _ev, m in sessions:
        res[m["credit_result"] or "none"] += 1
        completed += 1 if m["completed"] else 0
        recovered += 1 if m["recovered"] else 0
    decided = res["approved"] + res["declined"]
    print("  credit-check FORK:")
    print("    reached result : %d   approved %d (%.1f%%) · declined %d (%.1f%%)"
          % (decided, res["approved"], pct(res["approved"], decided),
             res["declined"], pct(res["declined"], decided)))
    print("    purchase_completed %d  (of which recovery-after-decline %d)" % (completed, recovered))
    print("  " + "-" * 62)

    # ── Approval rate BY COHORT — the demo payoff ──
    by = {}
    for _id, _up, _ev, m in sessions:
        if m["credit_result"] in ("approved", "declined"):
            k = m["profile"]["account_type"]
            by.setdefault(k, [0, 0])
            by[k][0] += 1 if m["credit_result"] == "approved" else 0
            by[k][1] += 1
    print("  approval rate by account_type (the segmentation story):")
    for k in sorted(by):
        a, n = by[k]
        print("    %-10s %3d/%-3d approved  (%.1f%%)" % (k, a, n, pct(a, n)))
    byL = {}
    for _id, _up, _ev, m in sessions:
        if m["credit_result"] in ("approved", "declined"):
            k = m["profile"]["loyalty_tier"]
            byL.setdefault(k, [0, 0])
            byL[k][0] += 1 if m["credit_result"] == "approved" else 0
            byL[k][1] += 1
    print("  approval rate by loyalty_tier:")
    for k in ["platinum", "gold", "silver", "bronze", "none"]:
        if k in byL:
            a, n = byL[k]
            print("    %-10s %3d/%-3d approved  (%.1f%%)" % (k, a, n, pct(a, n)))
    print("  " + "-" * 62 + "\n")

    if not args.send:
        print("DRY-RUN — nothing sent. Sample sessions:\n")
        for identity, uprops, events, _m in sessions[:max(0, args.sample)]:
            print("  user %s  [%s, %s/%s]" % (identity, uprops["market"],
                                              uprops["account_type"], uprops["loyalty_tier"]))
            for name, ts, props in events:
                slim = {k: v for k, v in props.items()
                        if k not in ("synthetic", "demo_user", "cohort", "market")}
                print("    %s  %-32s %s" % (iso(ts), name, json.dumps(slim)))
            print()
        print("Re-run with --send to POST to %s (app_id=%s)." % (args.endpoint, args.app_id))
        print("⚠  Confirm that endpoint is correct for YOUR Contentsquare tenant first.")
        return

    print("SENDING to %s  (app_id=%s) ...\n" % (args.endpoint, args.app_id))
    flat = []
    for identity, uprops, events, _m in sessions:
        flat.append(("u", identity, uprops))
        for name, ts, props in events:
            flat.append(("e", identity, name, ts, props))

    sent = {"ok": 0, "fail": 0}
    every = max(1, len(flat) // 20)

    def work(item):
        if item[0] == "u":
            _, identity, uprops = item
            return send_user_properties(args.user_props_endpoint, args.app_id, identity, uprops)
        _, identity, name, ts, props = item
        return send_event(args.endpoint, args.app_id, identity, name, ts, props)

    with concurrent.futures.ThreadPoolExecutor(max_workers=args.max_workers) as ex:
        for i, (status, body) in enumerate(ex.map(work, flat), 1):
            ok = status is not None and 200 <= status < 300
            sent["ok" if ok else "fail"] += 1
            if not ok and sent["fail"] <= 5:
                print("  ! send error: status=%s body=%s" % (status, (body or "")[:160]))
            if i % every == 0:
                print("  ... %d/%d  (ok=%d fail=%d)" % (i, len(flat), sent["ok"], sent["fail"]))

    print("\nDone. %d requests: ok=%d fail=%d" % (len(flat), sent["ok"], sent["fail"]))
    print("In the dashboard, filter on  synthetic = true  (or cohort = '%s')  to isolate." % args.cohort)


if __name__ == "__main__":
    main()
