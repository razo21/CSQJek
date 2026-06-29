#!/usr/bin/env python3
"""
CSQJek — synthetic data generator: consumer funnels (CSQRide + CSQFood), by cohort.

Companion to seed_cs_funnel.py / seed_callcenter_return.py / seed_device_credit.py.
Generates either the RIDE-booking funnel or the FOOD-ordering funnel as synthetic
Product-Analytics data, with conversion that VARIES BY COHORT (same idea as the
device-credit generator):

  --funnel ride
    service_tile_tapped(CSQRide) → destination_selected → ride_option_selected
      → ride_booked  [book-through varies by cohort]
          ├─ promo sub-branch: promo_tapped → promo_code_invalid → promo_rage_apply
          └─ cancel branch:    ride_cancelled  [cancel rate varies by cohort]

  --funnel food
    food_restaurant_tapped → food_item_added×N → food_order_placed(attempt 1)
      → [fails → food_order_failed → retry?]  [retry/abandon varies by cohort]
      → food_order_placed(succeeds) → food_track_order_tapped

Each synthetic user carries the live app's cohort props (account_type, loyalty_tier,
is_new_user, tenure_days, lifetime_orders, signup_channel); the key conversion step
is computed from them, so splitting the funnel by account_type / loyalty_tier shows
genuinely different completion rates. Behaviour-varies-by-cohort as historical data,
with the live demo untouched.

Event names + property keys match CLAUDE.md exactly. Users carry `synthetic: true`
and `cohort: "<name>"` for isolation/cleanup. Same Heap server-side API + dry-run /
--send safety as the other seeds. Defaults to DRY-RUN; pass --send to POST.

  python3 tools/seed_consumer_funnels.py --funnel ride --users 80 --seed 7
  python3 tools/seed_consumer_funnels.py --funnel food --users 600 --seed 42 \
    --cohort food_funnel_demo --max-workers 8 --send
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

MARKETS = [("Singapore", 0.50), ("Tokyo", 0.30), ("Sydney", 0.20)]

# Amounts are Singapore-scale for EVERY market (app currency-scale convention).
RIDE_TYPES = [  # (ride_type, price, eta_minutes, weight)
    ("CSQRide",   8.50,  4, 0.55),
    ("CSQXpress", 11.00, 2, 0.22),
    ("CSQBlack",  18.75, 7, 0.15),
    ("CSQ Tank",  249.99, 12, 0.03),
    ("CSQ Horse", 4.20,  20, 0.05),
]
RIDE_PLACES = ["Home", "Work", "Airport", "Mall", "Hotel", "Gym", "Station"]

RESTAURANTS = [  # (restaurant_name, cuisine)
    ("Ya Kun Kaya Toast", "kaya_toast"), ("The Coconut Club", "nasi_lemak"),
    ("Tim Ho Wan", "dim_sum"), ("一風堂", "ramen"), ("すし三崎丸", "sushi"),
    ("Jumbo Seafood", "seafood"), ("Din Tai Fung", "dumplings"),
    ("Guzman y Gomez", "mexican"), ("Three Blue Ducks", "brunch"),
]
FOOD_ITEMS = ["Signature Set", "Combo A", "House Special", "Chef's Pick",
              "Side Order", "Drink", "Dessert"]
DELIVERY_FEES = [0.00, 0.00, 1.99, 2.99, 3.50]

ACCOUNT_TYPES = [("standard", 0.60), ("premium", 0.40)]
LOYALTY_TIERS = [("none", 0.15), ("bronze", 0.20), ("silver", 0.25),
                 ("gold", 0.25), ("platinum", 0.15)]
SIGNUP_CHANNELS = [("organic", 0.34), ("referral", 0.28),
                   ("paid_ad", 0.24), ("partner", 0.14)]
ERROR_CODE = "CHECKOUT_TIMEOUT"


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


def make_profile():
    account_type = weighted_choice(ACCOUNT_TYPES)
    loyalty = weighted_choice(LOYALTY_TIERS)
    is_new = random.random() < 0.30
    if is_new:
        tenure_days, lifetime_orders = random.randint(0, 30), random.randint(0, 3)
    else:
        tenure_days, lifetime_orders = random.randint(60, 1500), random.randint(4, 600)
    return {"account_type": account_type, "loyalty_tier": loyalty, "is_new_user": is_new,
            "tenure_days": tenure_days, "lifetime_orders": lifetime_orders,
            "signup_channel": weighted_choice(SIGNUP_CHANNELS)}


def tenure_boost(profile, cap=0.18):
    return clamp(profile["tenure_days"] / 1500.0, 0.0, 1.0) * cap


def engagement(profile):
    """Small per-step retention nudge from the cohort — compounds through the
    funnel so engaged cohorts (premium / loyal / tenured) progress further at
    every step, giving a CLEAR completion gradient to segment on."""
    e = 0.0
    e += 0.06 if profile["account_type"] == "premium" else -0.02
    e += -0.07 if profile["is_new_user"] else 0.02
    e += {"platinum": 0.05, "gold": 0.03, "silver": 0.0,
          "bronze": -0.03, "none": -0.06}[profile["loyalty_tier"]]
    return e


# ── RIDE conversion (cohort-driven) ───────────────────────────────────────────
def ride_book_p(profile):
    p = 0.72
    p += 0.16 if profile["account_type"] == "premium" else 0.0
    p += -0.22 if profile["is_new_user"] else 0.0
    p += {"platinum": 0.14, "gold": 0.08, "silver": 0.0,
          "bronze": -0.06, "none": -0.14}[profile["loyalty_tier"]]
    p += tenure_boost(profile, cap=0.15)
    return clamp(p, 0.15, 0.97)


def ride_cancel_p(profile):
    p = 0.10
    p += 0.10 if profile["is_new_user"] else 0.0
    p += -0.04 if profile["account_type"] == "premium" else 0.0
    return clamp(p, 0.02, 0.40)


def promo_p(profile):
    p = 0.25
    p += 0.12 if profile["is_new_user"] else 0.0
    p += 0.08 if profile["loyalty_tier"] in ("bronze", "none") else 0.0
    p += -0.05 if profile["account_type"] == "premium" else 0.0
    return clamp(p, 0.05, 0.6)


# ── FOOD conversion (cohort-driven) ───────────────────────────────────────────
def food_retry_p(profile):
    """After a failed checkout, probability the user retries (vs abandons)."""
    p = 0.60
    p += 0.15 if profile["account_type"] == "premium" else 0.0
    p += -0.18 if profile["is_new_user"] else 0.0
    p += {"platinum": 0.10, "gold": 0.06, "silver": 0.0,
          "bronze": -0.06, "none": -0.12}[profile["loyalty_tier"]]
    return clamp(p, 0.10, 0.95)


# ──────────────────────────────────────────────────────────────────────────────
def _emitter(base_props, t0):
    events = []
    state = {"t": t0}

    def emit(name, props, dwell=(4, 30)):
        state["t"] = state["t"] + timedelta(seconds=random.randint(*dwell))
        p = dict(base_props)
        p.update(props)
        events.append((name, state["t"], p))

    def emit_screen(screen_name, dwell=(2, 8)):
        emit("screen_viewed", {"screen_name": screen_name}, dwell=dwell)

    return events, emit, emit_screen


def build_ride_session(now, days, cohort, index, run_tag):
    market = pick_market()
    profile = make_profile()
    eng = engagement(profile)
    place = random.choice(RIDE_PLACES)
    ride_type = weighted_choice([(r[0], r[3]) for r in RIDE_TYPES])
    price = next(r[1] for r in RIDE_TYPES if r[0] == ride_type)
    eta = next(r[2] for r in RIDE_TYPES if r[0] == ride_type)

    identity = "syn-%s-%04d" % (run_tag, index)
    base_props = {"market": market, "synthetic": True, "demo_user": True, "cohort": cohort}
    user_props = dict(base_props); user_props.update({"name": "Synthetic User"}); user_props.update(profile)

    events, emit, emit_screen = _emitter(base_props, session_start(now, days))
    booked = cancelled = False

    emit_screen("Rides")
    emit("service_tile_tapped", {"service_name": "CSQRide", "is_active": True})

    if random.random() < clamp(0.86 + eng, 0.40, 0.98):
        emit_screen("Ride - Destination")
        emit("destination_selected",
             {"location_name": place, "source": random.choice(["recent", "search"])})

        if random.random() < 0.92:
            emit_screen("Ride - Pickup")

            if random.random() < clamp(0.88 + eng, 0.40, 0.98):
                emit_screen("Ride - Confirm")
                emit("ride_option_selected", {"ride_type": ride_type, "price": price})

                # Promo sub-branch (price-sensitive cohorts engage more).
                if random.random() < promo_p(profile):
                    emit("promo_tapped", {"promo_index": random.randint(0, 2),
                                          "promo_headline": "Save on your ride"})
                    if random.random() < 0.5:
                        emit("promo_code_invalid", {"code_length": random.randint(4, 10)})
                        taps = random.choices([1, 2, 3, 4, 5], weights=[20, 25, 25, 18, 12])[0]
                        if taps >= 3:
                            emit("promo_rage_apply",
                                 {"service": "CSQRide", "screen": "Ride - Confirm",
                                  "tap_count": taps, "failed_attempts": taps,
                                  "code_length": random.randint(4, 10)})

                if random.random() < ride_book_p(profile):
                    emit_screen("Ride - Driver Found")
                    emit("ride_booked", {"ride_type": ride_type, "price": price,
                                         "pickup": place, "dropoff": random.choice(RIDE_PLACES),
                                         "eta_minutes": eta})
                    booked = True
                    if random.random() < ride_cancel_p(profile):
                        emit("ride_cancelled", {"ride_type": ride_type})
                        cancelled = True

    meta = {"profile": profile, "booked": booked, "cancelled": cancelled,
            "completed": booked and not cancelled}
    return identity, user_props, events, meta


def build_food_session(now, days, cohort, index, run_tag):
    market = pick_market()
    profile = make_profile()
    eng = engagement(profile)
    restaurant, cuisine = random.choice(RESTAURANTS)
    n_items = random.choices([1, 2, 3], weights=[45, 35, 20])[0]
    delivery_fee = random.choice(DELIVERY_FEES)

    identity = "syn-%s-%04d" % (run_tag, index)
    base_props = {"market": market, "synthetic": True, "demo_user": True, "cohort": cohort}
    user_props = dict(base_props); user_props.update({"name": "Synthetic User"}); user_props.update(profile)

    events, emit, emit_screen = _emitter(base_props, session_start(now, days))
    placed = succeeded = False

    emit_screen("Food - Home")
    emit("food_restaurant_tapped", {"restaurant_name": restaurant, "cuisine": cuisine})

    emit_screen("Food - Restaurant Menu")
    total = 0.0
    for _ in range(n_items):
        item = random.choice(FOOD_ITEMS)
        price = round(random.uniform(3.5, 24.0), 2)
        total = round(total + price, 2)
        emit("food_item_added", {"item_name": item, "price": price, "restaurant": restaurant})

    if random.random() < clamp(0.78 + eng, 0.45, 0.95):
        emit_screen("Food - Checkout")
        placed = True
        attempt = 1
        while attempt <= 3:
            emit("food_order_placed",
                 {"restaurant": restaurant, "item_count": n_items,
                  "total": round(total + delivery_fee, 2), "delivery_fee": delivery_fee,
                  "attempt_number": attempt}, dwell=(6, 22))
            # Attempts 1 & 2 may fail (mirrors the app's scripted friction).
            if attempt < 3 and random.random() < 0.45:
                emit("food_order_failed",
                     {"restaurant": restaurant, "attempt_number": attempt,
                      "error_code": ERROR_CODE, "visible_to_user": True}, dwell=(2, 5))
                if random.random() < food_retry_p(profile):
                    attempt += 1
                    continue
                break  # abandon after a failure
            succeeded = True
            break

        if succeeded:
            emit_screen("Food - Order Confirmed")
            if random.random() < 0.55:
                emit("food_track_order_tapped", {"restaurant": restaurant})

    meta = {"profile": profile, "placed": placed, "completed": succeeded}
    return identity, user_props, events, meta


FUNNELS = {
    "ride": {"build": build_ride_session,
             "spine": ["service_tile_tapped", "destination_selected",
                       "ride_option_selected", "ride_booked"],
             "title": "CSQRide booking funnel"},
    "food": {"build": build_food_session,
             "spine": ["food_restaurant_tapped", "food_item_added",
                       "food_order_placed", "food_track_order_tapped"],
             "title": "CSQFood ordering funnel"},
}


# ── Sending (identical shape to the other seeds) ──────────────────────────────
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
    ap.add_argument("--funnel", choices=sorted(FUNNELS), required=True, help="which funnel to generate")
    ap.add_argument("--users", type=int, default=600, help="number of synthetic users (default 600)")
    ap.add_argument("--days", type=int, default=14, help="spread sessions over the last N days (default 14)")
    ap.add_argument("--app-id", default=DEFAULT_APP_ID, help="Heap/CS environment id")
    ap.add_argument("--endpoint", default=DEFAULT_TRACK_ENDPOINT, help="track API endpoint")
    ap.add_argument("--user-props-endpoint", default=DEFAULT_USER_PROPS_ENDPOINT,
                    help="add_user_properties endpoint")
    ap.add_argument("--cohort", default=None, help="cohort tag (default: <funnel>_funnel_demo)")
    ap.add_argument("--run-tag", default=None, help="identity namespace (default: cohort)")
    ap.add_argument("--seed", type=int, default=None, help="RNG seed for reproducible runs")
    ap.add_argument("--send", action="store_true", help="ACTUALLY POST to the endpoint (default: dry-run)")
    ap.add_argument("--max-workers", type=int, default=6, help="concurrent POSTs when sending (default 6)")
    ap.add_argument("--sample", type=int, default=2, help="dry-run: print N sample sessions")
    args = ap.parse_args()

    if args.seed is not None:
        random.seed(args.seed)

    cfg = FUNNELS[args.funnel]
    cohort = args.cohort or ("%s_funnel_demo" % args.funnel)
    run_tag = args.run_tag or cohort
    now = datetime.now(timezone.utc)
    sessions = [cfg["build"](now, args.days, cohort, i, run_tag) for i in range(args.users)]

    spine = cfg["spine"]
    counts = {e: 0 for e in spine}
    total_events = 0
    for _id, _up, events, _m in sessions:
        seen = set(n for n, _, _ in events)
        total_events += len(events)
        for e in spine:
            if e in seen:
                counts[e] += 1
    start = counts[spine[0]] or 1

    print("\n" + "=" * 66)
    print("  %s — generated cohort" % cfg["title"])
    print("  users=%d  events=%d  days=%d  cohort=%s" % (args.users, total_events, args.days, cohort))
    print("=" * 66)
    print("  %-34s %7s %7s %7s" % ("funnel step (event)", "users", "%start", "%prev"))
    print("  " + "-" * 60)
    prev = start
    for e in spine:
        c = counts[e]
        print("  %-34s %7d %6.1f%% %6.1f%%" % (e, c, pct(c, start), pct(c, prev)))
        prev = c if c else prev
    print("  " + "-" * 60)

    completed = sum(1 for _i, _u, _e, m in sessions if m["completed"])
    print("  completed journeys: %d / %d  (%.1f%%)" % (completed, args.users, pct(completed, args.users)))

    # Completion rate by cohort — the segmentation payoff.
    for dim, order in (("account_type", ["premium", "standard"]),
                       ("loyalty_tier", ["platinum", "gold", "silver", "bronze", "none"])):
        by = {}
        for _i, _u, _e, m in sessions:
            k = m["profile"][dim]
            by.setdefault(k, [0, 0])
            by[k][0] += 1 if m["completed"] else 0
            by[k][1] += 1
        print("  completion rate by %s:" % dim)
        for k in order:
            if k in by:
                c, n = by[k]
                print("    %-10s %3d/%-3d  (%.1f%%)" % (k, c, n, pct(c, n)))
    print("  " + "-" * 60 + "\n")

    if not args.send:
        print("DRY-RUN — nothing sent. Sample sessions:\n")
        for identity, uprops, events, _m in sessions[:max(0, args.sample)]:
            print("  user %s  [%s, %s/%s]" % (identity, uprops["market"],
                                              uprops["account_type"], uprops["loyalty_tier"]))
            for name, ts, props in events:
                slim = {k: v for k, v in props.items()
                        if k not in ("synthetic", "demo_user", "cohort", "market")}
                print("    %s  %-30s %s" % (iso(ts), name, json.dumps(slim, ensure_ascii=False)))
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
    print("In the dashboard, filter on  synthetic = true  (or cohort = '%s')  to isolate." % cohort)


if __name__ == "__main__":
    main()
