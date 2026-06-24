#!/usr/bin/env python3
"""
seed_callcenter_return.py — "Call centre → 2-day return → successful payment"
cohort for the CSQMobile bill-pay demo.

Distinct from seed_cs_funnel.py (realistic drop-off). Here users complete the
deflection maze, reach the Call Us page, trigger `called_into_call_center`, then
RETURN ~2 days later and pay successfully (`telco_bill_payment_completed`).

Two populations, same cohort:
  • 8 named Contentsquare "people" (first.last@contentsquare.com) — the inspectable
    HERO journeys (all reach the call centre + return).
  • A BACKING AUDIENCE of N anonymised users with diverse random names, weighted
    across device types (iOS/Android × old/new) and tenure segments
    (5+ / 1-5 / under-1 year), with light, believable drop-off — so the
    acquisition-by-device chart and tenure segments look full.

Device / OS / tenure ride along as PEOPLE properties AND on every event, so
acquisition + segmentation charts work on user- or event-properties.

Usage:
  python3 tools/seed_callcenter_return.py                       # heroes, dry-run
  python3 tools/seed_callcenter_return.py --send                # heroes only
  python3 tools/seed_callcenter_return.py --backing 500 --no-heroes --send
  #   ^ send 500 backing users WITHOUT re-sending the heroes (avoids dup events)
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

ERROR_CODE = "CSQ-4012"
ARTICLES = ["payment_declined", "pay_your_bill", "update_payment_method", "autopay_setup"]

# ── Device buckets: (platform, [os_versions], os_category, [models]) ───────────
DEVICE_BUCKETS = {
    "iOS_new":     ("iOS",     ["18.1", "18.0", "17.6"], "new",
                    ["iPhone 15 Pro", "iPhone 16", "iPhone 15", "iPhone 14 Pro"]),
    "iOS_old":     ("iOS",     ["15.7", "14.8", "16.2"], "old",
                    ["iPhone 8", "iPhone X", "iPhone 11", "iPhone SE"]),
    "Android_new": ("Android", ["14", "13"], "new",
                    ["Samsung Galaxy S24", "Google Pixel 8", "Samsung Galaxy S23", "OnePlus 12"]),
    "Android_old": ("Android", ["11", "10", "12"], "old",
                    ["Samsung Galaxy S9", "Google Pixel 3", "Samsung Galaxy A10", "Huawei P20"]),
}
BUCKET_WEIGHTS = [("iOS_new", 0.35), ("iOS_old", 0.18), ("Android_new", 0.30), ("Android_old", 0.17)]
TENURE_WEIGHTS = [("5+ years", 0.30), ("1-5 years", 0.45), ("under 1 year", 0.25)]
MARKET_WEIGHTS = [("Singapore", 0.50), ("Tokyo", 0.30), ("Sydney", 0.20)]

FIRST_NAMES = ["David", "Jack", "Miguel", "Vicky", "Jane", "Wei", "Priya", "Carlos", "Aisha",
               "Sofia", "Liam", "Noah", "Mei", "Hiroshi", "Sanjay", "Olga", "Ahmed", "Chen",
               "Yuki", "Rahul", "Emma", "Olivia", "Ethan", "Diego", "Fatima", "Ingrid", "Kenji",
               "Ananya", "Lucas", "Mia", "Omar", "Nadia", "Tariq", "Elena", "Marco", "Grace",
               "Hassan", "Jin", "Kavya", "Leila", "Tomas", "Ravi", "Sun", "Yara", "Zoe", "Bjorn",
               "Camila", "Dmitri", "Esther", "Felix"]
LAST_NAMES = ["Chang", "Smith", "Gutierrez", "Lee", "Woods", "Patel", "Nguyen", "Kim", "Tanaka",
              "Garcia", "Johnson", "Wang", "Singh", "Muller", "Rossi", "Okafor", "Ali", "Cohen",
              "Andersson", "Sato", "Reyes", "Brown", "Davis", "Martinez", "Kumar", "Chen",
              "Yamamoto", "Hernandez", "Khan", "Lopez", "Walsh", "Petrov", "Suzuki", "Nakamura",
              "Mehta", "Park", "Choi", "Dubois", "Ferrari", "Costa", "Adeyemi", "Haddad",
              "Schmidt", "Ivanov", "Tan", "Lim", "Wong", "Sharma", "Bauer", "Fernandez"]

# ── The 8 named hero people ───────────────────────────────────────────────────
# name, platform, os, os_cat, device, tenure_segment, tenure_years, market, day0_days_ago, failed_attempts
HERO_RAW = [
    ("Atsushi Okimoto",    "iOS",     "18.1", "new", "iPhone 15 Pro",      "5+ years",     7, "Tokyo",     11, 2),
    ("Jaewon Jang",        "Android", "14",   "new", "Samsung Galaxy S24", "1-5 years",    3, "Singapore",  9, 3),
    ("Abhi Nair",          "Android", "11",   "old", "Samsung Galaxy S9",  "under 1 year", 0, "Singapore", 12, 1),
    ("Florian Korbella",   "iOS",     "15.7", "old", "iPhone 8",           "5+ years",     6, "Sydney",     7, 2),
    ("Lynn Lertsumikul",   "Android", "13",   "new", "Google Pixel 8",     "1-5 years",    2, "Singapore", 10, 1),
    ("Sebastian Barillot", "iOS",     "17.6", "new", "iPhone 16",          "under 1 year", 0, "Sydney",     6, 4),
    ("Andrew Elturk",      "iOS",     "14.8", "old", "iPhone X",           "1-5 years",    4, "Sydney",     8, 2),
    ("Romain Lebon",       "Android", "10",   "old", "Google Pixel 3",     "5+ years",     8, "Tokyo",      5, 3),
]


def email_for(name, used):
    base = name.lower().replace(" ", ".")
    email = base + "@contentsquare.com"
    n = 2
    while email in used:
        email = "%s%d@contentsquare.com" % (base, n)
        n += 1
    used.add(email)
    return email


def iso(ts):
    return ts.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def weighted(pairs):
    r = random.random()
    acc = 0.0
    for v, w in pairs:
        acc += w
        if r <= acc:
            return v
    return pairs[-1][0]


def hero_specs(used):
    specs = []
    for (name, plat, osv, oscat, dev, ten, yrs, mkt, dago, fails) in HERO_RAW:
        specs.append(dict(name=name, email=email_for(name, used), platform=plat, os_version=osv,
                          os_category=oscat, device_model=dev, tenure_segment=ten, tenure_years=yrs,
                          market=mkt, day0_days_ago=dago, failed_attempts=fails,
                          reaches_call=True, returns_pays=True))
    return specs


def backing_specs(n, used):
    specs = []
    for _ in range(n):
        first = random.choice(FIRST_NAMES)
        last = random.choice(LAST_NAMES)
        name = "%s %s" % (first, last)
        bucket = weighted(BUCKET_WEIGHTS)
        plat, osvs, oscat, models = DEVICE_BUCKETS[bucket]
        ten = weighted(TENURE_WEIGHTS)
        yrs = {"5+ years": random.randint(5, 12),
               "1-5 years": random.randint(1, 4),
               "under 1 year": 0}[ten]
        # This cohort is "people who call the centre": most reach it, ~2/3 return.
        reaches = random.random() < 0.90
        returns = reaches and (random.random() < 0.65)
        specs.append(dict(name=name, email=email_for(name, used), platform=plat,
                          os_version=random.choice(osvs), os_category=oscat,
                          device_model=random.choice(models), tenure_segment=ten,
                          tenure_years=yrs, market=weighted(MARKET_WEIGHTS),
                          day0_days_ago=random.randint(3, 14),
                          failed_attempts=random.choices([1, 2, 3, 4], weights=[30, 35, 20, 15])[0],
                          reaches_call=reaches, returns_pays=returns))
    return specs


def build_journey(spec, now, cohort):
    s = spec
    amount = {"Tokyo": 86.40, "Sydney": 92.10, "Singapore": 86.40}.get(s["market"], 86.40)
    invoice = "INV-2026-%04d" % random.randint(1000, 9999)
    method = random.choice(["card", "card", "wallet"])

    base = {
        "market": s["market"],
        "platform": s["platform"],
        "initial_device_type": s["platform"],
        "device_model": s["device_model"],
        "os_version": s["os_version"],
        "os_category": s["os_category"],
        "tenure_segment": s["tenure_segment"],
        "synthetic": True,
        "demo_user": True,
        "cohort": cohort,
    }
    user_props = dict(base)
    user_props.update({"name": s["name"], "email": s["email"], "tenure_years": s["tenure_years"]})

    events = []
    t = [(now - timedelta(days=s["day0_days_ago"])).replace(
        hour=random.randint(8, 21), minute=random.randint(0, 59), second=random.randint(0, 59),
        microsecond=0)]

    def step(secs):
        t[0] = t[0] + timedelta(seconds=secs)
        return t[0]

    def emit(secs, name_, props):
        p = dict(base); p.update(props)
        events.append((name_, step(secs), p))

    def screen(secs, sname, depth):
        emit(secs, "screen_viewed", {"screen_name": sname, "depth": depth})

    # ── Day 0 ────────────────────────────────────────────────────────────────
    screen(2, "Telco - Bills", 0)
    emit(3, "telco_bills_viewed", {"current_amount": amount, "status": "overdue"})
    screen(9, "Telco - Bill Payment", 0)
    attempt = 1
    emit(8, "telco_bill_payment_started",
         {"invoice_no": invoice, "amount": amount, "method": method, "attempt": attempt})
    emit(2, "telco_bill_payment_failed",
         {"invoice_no": invoice, "amount": amount, "method": method, "attempt": attempt, "error_code": ERROR_CODE})
    for _ in range(s["failed_attempts"] - 1):
        attempt += 1
        emit(7, "telco_bill_payment_retried",
             {"invoice_no": invoice, "amount": amount, "method": method, "attempt": attempt})
        emit(2, "telco_bill_payment_failed",
             {"invoice_no": invoice, "amount": amount, "method": method, "attempt": attempt, "error_code": ERROR_CODE})
    if attempt >= 3:
        emit(2, "telco_payment_rage_retry",
             {"invoice_no": invoice, "tap_count": attempt, "amount": amount, "method": method})

    # Maze. Callers go all the way (stage 6 + called); non-callers drop at 1..5.
    maxstage = 6 if s["reaches_call"] else random.randint(1, 5)
    art = random.choice(ARTICLES)
    line = random.choice(["general", "billing", "premium"])
    if maxstage >= 1:
        emit(5, "telco_bill_payment_help_tapped", {"invoice_no": invoice, "attempt": attempt})
    if maxstage >= 2:
        screen(4, "Telco - Help Center", 1)
        emit(3, "telco_help_center_viewed", {"entry_point": "payment_failed", "depth": 1})
    if maxstage >= 3:
        emit(3, "telco_help_article_tapped", {"article_id": art, "category": "billing", "source": "help_popular"})
        screen(2, "Telco - Support Article", 2)
        emit(40, "telco_support_article_viewed",
             {"article_id": art, "category": "billing", "depth": 2, "source": "help_popular"})
        emit(8, "telco_support_article_feedback", {"article_id": art, "helpful": False, "depth": 2})
    if maxstage >= 4:
        screen(6, "Telco - Contact Support", 3)
        emit(4, "telco_contact_options_viewed", {"depth": 3})
    if maxstage >= 5:
        screen(8, "Telco - Call Us", 4)
        emit(5, "telco_call_us_viewed", {"depth": 4})
    if maxstage >= 6:
        emit(4, "telco_call_number_tapped", {"line": line, "depth": 4})
        emit(3, "called_into_call_center",
             {"invoice_no": invoice, "amount": amount, "line": line,
              "wait_minutes": random.choice([12, 18, 24, 31, 47]), "resolved": True})

    # ── Day +2 return: successful payment ────────────────────────────────────
    if s["reaches_call"] and s["returns_pays"]:
        t[0] = t[0] + timedelta(days=2, hours=random.randint(2, 9))
        screen(2, "Telco - Bills", 0)
        emit(3, "telco_bills_viewed", {"current_amount": amount, "status": "overdue"})
        screen(7, "Telco - Bill Payment", 0)
        emit(6, "telco_bill_payment_started",
             {"invoice_no": invoice, "amount": amount, "method": method, "attempt": 1, "return_visit": True})
        emit(3, "telco_bill_payment_completed",
             {"invoice_no": invoice, "amount": amount, "method": method,
              "resolved_via": "call_center", "days_since_call": 2})

    return s["email"], user_props, events


# ── Heap networking ───────────────────────────────────────────────────────────
def post_json(url, payload, timeout=15, retries=3):
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(url, data=data, method="POST",
                                 headers={"Content-Type": "application/json", "Accept": "application/json"})
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


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--app-id", default=DEFAULT_APP_ID)
    ap.add_argument("--endpoint", default=DEFAULT_TRACK_ENDPOINT)
    ap.add_argument("--user-props-endpoint", default=DEFAULT_USER_PROPS_ENDPOINT)
    ap.add_argument("--cohort", default="callcenter_return_demo")
    ap.add_argument("--backing", type=int, default=0, help="number of backing-audience users")
    ap.add_argument("--no-heroes", action="store_true", help="skip the 8 named hero users (avoid re-sending)")
    ap.add_argument("--seed", type=int, default=None)
    ap.add_argument("--max-workers", type=int, default=8)
    ap.add_argument("--send", action="store_true", help="POST to Heap (default: dry-run)")
    args = ap.parse_args()
    if args.seed is not None:
        random.seed(args.seed)

    now = datetime.now(timezone.utc)
    used_emails = set()
    specs = []
    if not args.no_heroes:
        specs += hero_specs(used_emails)
    specs += backing_specs(args.backing, used_emails)
    journeys = [build_journey(s, now, args.cohort) for s in specs]

    # ── Summary: acquisition + tenure + funnel ──
    total_events = sum(len(ev) for _, _, ev in journeys)
    by_plat, by_bucket, by_tenure = {}, {}, {}
    called = returned = bills = 0
    for spec, (_id, _u, ev) in zip(specs, journeys):
        by_plat[spec["platform"]] = by_plat.get(spec["platform"], 0) + 1
        bkey = "%s/%s" % (spec["platform"], spec["os_category"])
        by_bucket[bkey] = by_bucket.get(bkey, 0) + 1
        by_tenure[spec["tenure_segment"]] = by_tenure.get(spec["tenure_segment"], 0) + 1
        names = set(n for n, _, _ in ev)
        bills += 1 if "telco_bills_viewed" in names else 0
        called += 1 if "called_into_call_center" in names else 0
        returned += 1 if "telco_bill_payment_completed" in names else 0

    print("\n" + "=" * 64)
    print("  Call-centre return cohort   cohort=%s" % args.cohort)
    print("  sending %d users · %d events  (heroes=%s, backing=%d)"
          % (len(specs), total_events, "no" if args.no_heroes else "yes", args.backing))
    print("=" * 64)
    print("  ACQUISITION — by initial device type:")
    for k in sorted(by_plat): print("    %-10s %4d" % (k, by_plat[k]))
    print("  ACQUISITION — by device bucket (platform/os_category):")
    for k in sorted(by_bucket): print("    %-14s %4d" % (k, by_bucket[k]))
    print("  SEGMENTS — by tenure:")
    for k in ("5+ years", "1-5 years", "under 1 year"):
        print("    %-14s %4d" % (k, by_tenure.get(k, 0)))
    print("  FUNNEL — bills_viewed=%d  called_into_call_center=%d  bill_payment_completed=%d"
          % (bills, called, returned))
    print("=" * 64 + "\n")

    if not args.send:
        print("DRY-RUN — nothing sent. Re-run with --send.")
        return

    flat = []
    for identity, uprops, events in journeys:
        flat.append(("u", identity, uprops))
        for nm, ts, props in events:
            flat.append(("e", identity, nm, ts, props))

    def work(item):
        if item[0] == "u":
            _, identity, uprops = item
            return post_json(args.user_props_endpoint,
                             {"app_id": args.app_id, "identity": identity, "properties": uprops})
        _, identity, nm, ts, props = item
        return post_json(args.endpoint,
                         {"app_id": args.app_id, "identity": identity, "event": nm,
                          "timestamp": iso(ts), "properties": props})

    print("SENDING %d requests ...\n" % len(flat))
    ok = fail = 0
    every = max(1, len(flat) // 15)
    with concurrent.futures.ThreadPoolExecutor(max_workers=args.max_workers) as ex:
        for i, (status, body) in enumerate(ex.map(work, flat), 1):
            good = status is not None and 200 <= status < 300
            ok += 1 if good else 0
            fail += 0 if good else 1
            if not good and fail <= 5:
                print("  ! error status=%s body=%s" % (status, (body or "")[:140]))
            if i % every == 0:
                print("  ... %d/%d (ok=%d fail=%d)" % (i, len(flat), ok, fail))
    print("\nDone. %d requests: ok=%d fail=%d" % (len(flat), ok, fail))
    print("Filter the dashboard on  cohort = '%s'." % args.cohort)


if __name__ == "__main__":
    main()
