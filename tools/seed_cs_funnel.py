#!/usr/bin/env python3
"""
seed_cs_funnel.py — Synthetic data generator for the CSQMobile
"bill-payment → FAQ deflection → call centre" frustration funnel.

WHAT THIS DOES
--------------
Contentsquare Product Analytics is Heap-powered, and Heap ingests events
server-side via a track API keyed by your environment id (the same id the app
reports to: 4140621035). This script fabricates many believable user sessions
that walk the frustration funnel — most fail to pay their bill, get deflected
through FAQ/support content, and only a few reach the "Call Us" page — and
POSTs them so you can build a funnel / user-journey in the CS dashboard.

The events, property keys and values mirror exactly what the real app emits
(see CLAUDE.md event tables), so synthetic users are indistinguishable from
real ones in funnels and segments — except they carry `synthetic: true` and
`cohort: "<name>"` so you can isolate or delete them later.

IMPORTANT CAVEATS
-----------------
1. Server-side events populate PRODUCT ANALYTICS only (events → funnels,
   journeys, paths). They do NOT create SESSION REPLAYS — replays exist only
   for real app sessions.
2. The ingestion endpoint for a Contentsquare-provisioned Heap project may
   differ from the classic public Heap host. This script defaults to the
   documented Heap server-side API (https://heapanalytics.com/api/track).
   CONFIRM the correct host/auth for your tenant with your CS contact before
   `--send`. Override with --endpoint / --user-props-endpoint.
3. DRY-RUN IS THE DEFAULT. Nothing is sent until you pass --send. Dry-run still
   prints the exact funnel the run would produce.

USAGE
-----
  # See what it would generate (no network):
  python3 tools/seed_cs_funnel.py --users 800 --days 14

  # Actually send (after confirming the endpoint):
  python3 tools/seed_cs_funnel.py --users 800 --days 14 --send

  # Reproducible run + a named cohort you can filter on later:
  python3 tools/seed_cs_funnel.py --users 500 --seed 42 --cohort jun_demo --send
"""

import argparse
import concurrent.futures
import json
import random
import sys
import time
import urllib.error
import urllib.request
import uuid
from datetime import datetime, timedelta, timezone

# ──────────────────────────────────────────────────────────────────────────────
# Configuration defaults
# ──────────────────────────────────────────────────────────────────────────────
DEFAULT_APP_ID = "4140621035"                              # CSQJek PA environment id
DEFAULT_TRACK_ENDPOINT = "https://heapanalytics.com/api/track"
DEFAULT_USER_PROPS_ENDPOINT = "https://heapanalytics.com/api/add_user_properties"

# Market mix + display metadata. Amounts are sent in Singapore-scale numbers for
# EVERY market (the app's documented currency-scale convention); only the app's
# view layer multiplies Tokyo by 100. Do not "fix" this here.
MARKETS = [
    ("Singapore", 0.50),
    ("Tokyo",     0.30),
    ("Sydney",    0.20),
]
DEVICES = ["iPhone 15 Pro", "iPhone 15", "iPhone 14 Pro", "iPhone 16 Pro",
           "iPhone 13", "iPhone SE (3rd gen)"]
IOS_VERSIONS = ["17.5.1", "17.6", "18.0", "18.1", "17.4.1"]
PAY_METHODS = [("card", 0.7), ("wallet", 0.3)]
ARTICLES = ["payment_declined", "pay_your_bill", "update_payment_method",
            "autopay_setup", "understanding_charges", "refunds_overpayments"]
CALL_LINES = ["general", "billing", "premium"]
ERROR_CODE = "CSQ-4012"

# ──────────────────────────────────────────────────────────────────────────────
# The funnel spine. Each step's `p` is the probability of reaching it GIVEN the
# previous spine step was reached. Tuned so the story reads:
#   "Hundreds fail to pay; the support maze deflects most; only a handful reach
#    the call centre." Side-events (retries, rage, deflection loop, bot, abandon)
#   are sprinkled in `build_session` for realism.
# ──────────────────────────────────────────────────────────────────────────────
SPINE = [
    ("telco_bills_viewed",            1.00),
    ("telco_bill_payment_started",    0.78),
    ("telco_bill_payment_failed",     0.95),
    ("telco_bill_payment_help_tapped",0.60),
    ("telco_help_center_viewed",      0.97),
    ("telco_support_article_viewed",  0.74),
    ("telco_contact_options_viewed",  0.52),
    ("telco_call_us_viewed",          0.50),
    ("telco_call_number_tapped",      0.55),
]

# The screen layer. Each synthetic session also emits `screen_viewed` events whose
# `screen_name` matches the real app's CSQ.trackScreenview(...) names (CLAUDE.md),
# so a SCREEN-based journey / path lines up with real sessions. NOTE: these are
# custom events approximating native screenviews — they populate an event-based
# screen journey, not Heap's native pageview object (which only the SDK creates).
SCREEN_FLOW = [
    "Telco - Bills",
    "Telco - Bill Payment",
    "Telco - Help Center",
    "Telco - Support Article",
    "Telco - Contact Support",
    "Telco - Support Bot",
    "Telco - Call Us",
]


def weighted_choice(pairs):
    r = random.random()
    acc = 0.0
    for value, w in pairs:
        acc += w
        if r <= acc:
            return value
    return pairs[-1][0]


def pick_market():
    return weighted_choice(MARKETS)


def business_hour():
    # Weight toward daytime/evening; small overnight tail.
    buckets = ([h for h in range(8, 22)] * 3) + list(range(0, 8)) + list(range(22, 24))
    return random.choice(buckets)


def session_start(now, days):
    day_offset = random.randint(0, max(0, days - 1))
    base = now - timedelta(days=day_offset)
    return base.replace(hour=business_hour(),
                        minute=random.randint(0, 59),
                        second=random.randint(0, 59),
                        microsecond=0)


def iso(ts):
    return ts.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def amount_for(market):
    # Believable spread around the app's overdue bill (S$86.40, SG-scale for all).
    return round(random.choice([86.40, 86.40, 92.10, 78.00, 104.50, 67.20]), 2)


# ──────────────────────────────────────────────────────────────────────────────
# Build one user's event sequence: list of (event_name, datetime, properties).
# ──────────────────────────────────────────────────────────────────────────────
def build_session(now, days, cohort, index, run_tag):
    market = pick_market()
    method = weighted_choice(PAY_METHODS)
    invoice = "INV-2026-%04d" % random.randint(100, 9999)
    amount = amount_for(market)
    # Deterministic identity keyed by run_tag + index: re-running the same run_tag
    # updates the SAME users (Heap merges by identity) instead of duplicating them.
    identity = "syn-%s-%04d" % (run_tag, index)

    base_props = {
        "market": market,
        "synthetic": True,
        "demo_user": True,
        "cohort": cohort,
    }

    user_props = dict(base_props)
    user_props.update({
        "name": "Synthetic User",
        "device": random.choice(DEVICES),
        "os_version": random.choice(IOS_VERSIONS),
        "account_type": random.choice(["standard", "standard", "premium"]),
    })

    t = session_start(now, days)
    events = []
    depth = 0

    def emit(name, props, dwell=(4, 30)):
        nonlocal t
        t = t + timedelta(seconds=random.randint(*dwell))
        p = dict(base_props)
        p.update(props)
        events.append((name, t, p))

    def emit_screen(screen_name, dwell=(2, 8)):
        # Screenview-style custom event mirroring CSQ.trackScreenview(screen_name).
        emit("screen_viewed", {"screen_name": screen_name, "depth": depth}, dwell=dwell)

    # Walk the spine, dropping off per conditional probability. Inject side-events
    # at the steps where the real app would fire them.
    reached = {}
    for idx, (event, p) in enumerate(SPINE):
        if idx > 0 and random.random() > p:
            break  # user drops out of the funnel here
        reached[event] = True

        if event == "telco_bills_viewed":
            emit_screen("Telco - Bills")
            emit(event, {"current_amount": amount,
                         "status": random.choice(["overdue", "due", "due"])})

        elif event == "telco_bill_payment_started":
            emit_screen("Telco - Bill Payment")
            emit(event, {"invoice_no": invoice, "amount": amount,
                         "method": method, "attempt": 1}, dwell=(6, 25))

        elif event == "telco_bill_payment_failed":
            attempt = 1
            emit(event, {"invoice_no": invoice, "amount": amount, "method": method,
                         "attempt": attempt, "error_code": ERROR_CODE}, dwell=(2, 4))
            # Retry behaviour — repeated failures, sometimes hammered (rage).
            retries = random.choices([0, 1, 2, 3, 4], weights=[35, 28, 18, 11, 8])[0]
            for _ in range(retries):
                attempt += 1
                emit("telco_bill_payment_retried",
                     {"invoice_no": invoice, "amount": amount, "method": method,
                      "attempt": attempt}, dwell=(3, 12))
                emit("telco_bill_payment_failed",
                     {"invoice_no": invoice, "amount": amount, "method": method,
                      "attempt": attempt, "error_code": ERROR_CODE}, dwell=(2, 4))
            if attempt >= 3:
                emit("telco_payment_rage_retry",
                     {"invoice_no": invoice, "tap_count": attempt, "amount": amount,
                      "method": method}, dwell=(1, 3))

        elif event == "telco_bill_payment_help_tapped":
            emit(event, {"invoice_no": invoice, "attempt": random.randint(1, 4)},
                 dwell=(2, 8))

        elif event == "telco_help_center_viewed":
            depth += 1
            emit_screen("Telco - Help Center")
            if random.random() < 0.45:
                emit("telco_help_search_performed",
                     {"query_length": random.randint(6, 24),
                      "entry_point": "payment_failed"}, dwell=(5, 20))
            emit(event, {"entry_point": "payment_failed", "depth": depth},
                 dwell=(3, 15))
            if random.random() < 0.6:
                emit("telco_help_category_tapped", {"category": "billing"},
                     dwell=(2, 10))

        elif event == "telco_support_article_viewed":
            # Tap an article, read it, often find it unhelpful, sometimes loop
            # into related articles (the deflection maze).
            depth += 1
            art = random.choice(ARTICLES)
            emit("telco_help_article_tapped",
                 {"article_id": art, "category": "billing", "source": "help_popular"},
                 dwell=(2, 6))
            emit_screen("Telco - Support Article")
            emit(event, {"article_id": art, "category": "billing", "depth": depth,
                         "source": "help_popular"}, dwell=(20, 110))
            if random.random() < 0.7:
                emit("telco_support_article_feedback",
                     {"article_id": art, "helpful": False, "depth": depth},
                     dwell=(4, 18))
            # Deflection loop: read 0–2 related articles.
            for _ in range(random.choices([0, 1, 2], weights=[45, 35, 20])[0]):
                depth += 1
                nxt = random.choice(ARTICLES)
                emit("telco_support_article_related_tapped",
                     {"from_article_id": art, "to_article_id": nxt, "depth": depth},
                     dwell=(2, 8))
                emit_screen("Telco - Support Article")
                emit("telco_support_article_viewed",
                     {"article_id": nxt, "category": "billing", "depth": depth,
                      "source": "related_%s" % art}, dwell=(15, 90))
                art = nxt
            if random.random() < 0.5:
                emit("telco_support_still_need_help_tapped",
                     {"article_id": art, "depth": depth}, dwell=(3, 10))

        elif event == "telco_contact_options_viewed":
            depth += 1
            emit_screen("Telco - Contact Support")
            emit(event, {"depth": depth}, dwell=(3, 14))
            # More deflection before any human channel.
            if random.random() < 0.5:
                emit("telco_contact_deflected",
                     {"channel": random.choice(["article", "forum"]), "depth": depth},
                     dwell=(4, 20))
            # Some detour into the bot loop.
            if random.random() < 0.4:
                depth += 1
                emit_screen("Telco - Support Bot")
                emit("telco_support_bot_opened", {"depth": depth}, dwell=(4, 12))
                turns = random.randint(1, 3)
                for i in range(turns):
                    emit("telco_support_bot_message_sent",
                         {"message_index": i + 1,
                          "wants_human": i + 1 >= 2}, dwell=(6, 25))
                if turns >= 2:
                    emit("telco_support_bot_escalation_requested",
                         {"attempts_before_escalation": turns}, dwell=(2, 6))

        elif event == "telco_call_us_viewed":
            depth += 1
            emit_screen("Telco - Call Us")
            emit(event, {"depth": depth}, dwell=(4, 16))

        elif event == "telco_call_number_tapped":
            emit(event, {"line": weighted_choice([("general", 0.5),
                                                  ("billing", 0.35),
                                                  ("premium", 0.15)]),
                         "depth": depth}, dwell=(3, 12))

    # Abandonment: some users who got deep but never reached/finished the call
    # page give up ("I'll deal with this later").
    last_step = None
    for ev, _ in SPINE:
        if reached.get(ev):
            last_step = ev
    deep_no_call = reached.get("telco_contact_options_viewed") and not reached.get("telco_call_number_tapped")
    if deep_no_call and random.random() < 0.5:
        screen_map = {
            "telco_contact_options_viewed": "Telco - Contact Support",
            "telco_call_us_viewed": "Telco - Call Us",
        }
        emit("telco_support_abandoned",
             {"last_screen": screen_map.get(last_step, "Telco - Contact Support"),
              "depth": max(depth, 1)}, dwell=(5, 30))

    return identity, user_props, events


# ──────────────────────────────────────────────────────────────────────────────
# Networking (Heap server-side API)
# ──────────────────────────────────────────────────────────────────────────────
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
            # Retry on rate-limit / transient server errors; fail fast otherwise.
            if e.code in (429, 500, 502, 503, 504) and attempt < retries:
                time.sleep(backoff)
                backoff *= 2
                continue
            return e.code, e.read(400).decode("utf-8", "replace")
        except Exception as e:  # noqa
            if attempt < retries:
                time.sleep(backoff)
                backoff *= 2
                continue
            return None, str(e)


def send_user_properties(endpoint, app_id, identity, props):
    return post_json(endpoint, {"app_id": app_id, "identity": identity,
                                "properties": stringify(props)})


def send_event(endpoint, app_id, identity, name, ts, props):
    return post_json(endpoint, {"app_id": app_id, "identity": identity,
                                "event": name, "timestamp": iso(ts),
                                "properties": stringify(props)})


def stringify(props):
    # Heap property values are scalars; keep numbers/bools but stringify nothing
    # lossy. (Heap accepts str/number/bool.) Booleans pass through as-is.
    out = {}
    for k, v in props.items():
        out[k] = v
    return out


# ──────────────────────────────────────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────────────────────────────────────
def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--users", type=int, default=800, help="number of synthetic users (default 800)")
    ap.add_argument("--days", type=int, default=14, help="spread sessions over the last N days (default 14)")
    ap.add_argument("--app-id", default=DEFAULT_APP_ID, help="Heap/CS environment id")
    ap.add_argument("--endpoint", default=DEFAULT_TRACK_ENDPOINT, help="track API endpoint")
    ap.add_argument("--user-props-endpoint", default=DEFAULT_USER_PROPS_ENDPOINT,
                    help="add_user_properties endpoint")
    ap.add_argument("--cohort", default="bill_payment_frustration",
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
    sessions = [build_session(now, args.days, args.cohort, i, run_tag)
                for i in range(args.users)]

    # Funnel tally (spine steps only).
    spine_names = [e for e, _ in SPINE]
    counts = {e: 0 for e in spine_names}
    total_events = 0
    for _identity, _uprops, events in sessions:
        seen = set(name for name, _, _ in events)
        total_events += len(events)
        for e in spine_names:
            if e in seen:
                counts[e] += 1

    start = counts[spine_names[0]] or 1
    print("\n" + "=" * 64)
    print("  CSQMobile bill-payment frustration funnel — generated cohort")
    print("  users=%d  events=%d  days=%d  cohort=%s" %
          (args.users, total_events, args.days, args.cohort))
    print("=" * 64)
    print("  %-34s %7s %7s %7s" % ("funnel step (event)", "users", "%start", "%prev"))
    print("  " + "-" * 60)
    prev = start
    for e in spine_names:
        c = counts[e]
        pct_start = 100.0 * c / start
        pct_prev = 100.0 * c / prev if prev else 0.0
        print("  %-34s %7d %6.1f%% %6.1f%%" % (e, c, pct_start, pct_prev))
        prev = c if c else prev
    print("  " + "-" * 60)
    print("  → %d of %d users (%.1f%%) reach the Call Us page; %d tap a number.\n"
          % (counts['telco_call_us_viewed'], start,
             100.0 * counts['telco_call_us_viewed'] / start,
             counts['telco_call_number_tapped']))

    # Screen-view layer tally (users who entered each screen at least once).
    screen_users = {s: 0 for s in SCREEN_FLOW}
    screen_total = 0
    for _identity, _uprops, events in sessions:
        seen_screens = set()
        for name, _ts, props in events:
            if name == "screen_viewed":
                screen_total += 1
                seen_screens.add(props.get("screen_name"))
        for s in seen_screens:
            if s in screen_users:
                screen_users[s] += 1
    print("  screen layer (screen_viewed → screen_name)   %d total screenviews" % screen_total)
    print("  " + "-" * 60)
    for s in SCREEN_FLOW:
        c = screen_users[s]
        print("  %-40s %7d  %5.1f%%" % (s, c, 100.0 * c / start))
    print("  " + "-" * 60 + "\n")

    if not args.send:
        print("DRY-RUN — nothing sent. Sample sessions:\n")
        for identity, uprops, events in sessions[:max(0, args.sample)]:
            print("  user %s  [%s]" % (identity, uprops["market"]))
            for name, ts, props in events:
                slim = {k: v for k, v in props.items()
                        if k not in ("synthetic", "demo_user", "cohort", "market")}
                print("    %s  %-34s %s" % (iso(ts), name, json.dumps(slim)))
            print()
        print("Re-run with --send to POST to %s (app_id=%s)." % (args.endpoint, args.app_id))
        print("⚠  Confirm that endpoint is correct for YOUR Contentsquare tenant first.")
        return

    # ── Send ──────────────────────────────────────────────────────────────────
    print("SENDING to %s  (app_id=%s) ...\n" % (args.endpoint, args.app_id))
    flat = []  # (kind, *args)
    for identity, uprops, events in sessions:
        flat.append(("u", identity, uprops))
        for name, ts, props in events:
            flat.append(("e", identity, name, ts, props))

    sent = {"ok": 0, "fail": 0}
    lock_print_every = max(1, len(flat) // 20)

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
            if i % lock_print_every == 0:
                print("  ... %d/%d  (ok=%d fail=%d)" % (i, len(flat), sent["ok"], sent["fail"]))

    print("\nDone. %d requests: ok=%d fail=%d" % (len(flat), sent["ok"], sent["fail"]))
    if sent["fail"]:
        print("If everything failed, the endpoint/app_id is likely wrong for this tenant.")
        print("Confirm the ingestion host with your CS contact and pass --endpoint/--user-props-endpoint.")
    print("In the dashboard, filter on  synthetic = true  (or cohort = '%s')  to isolate this data." % args.cohort)


if __name__ == "__main__":
    main()
