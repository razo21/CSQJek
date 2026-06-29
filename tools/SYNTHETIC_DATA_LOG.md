# CSQJek — Synthetic Data Generation Log

Running log of every synthetic-data push to the Contentsquare / Heap **Product
Analytics** environment for the CSQJek demo. Update this file on every new run.

| | |
|---|---|
| **PA environment id (app_id)** | `4140621035` |
| **Ingestion endpoint** | `https://heapanalytics.com/api/track` (+ `/api/add_user_properties`) — confirmed working |
| **Generators** | `tools/seed_cs_funnel.py`, `tools/seed_callcenter_return.py`, `tools/seed_device_credit.py` |
| **Isolate / clean up** | filter `synthetic = true`, or by `cohort` |

> ⚠️ **DATA IS TIME-RELATIVE — REGENERATE PERIODICALLY.**
> Event timestamps are generated relative to *when the script runs* (spread over
> the last N days). The dates below were generated **June 2026**, so they age
> out — expect to **regenerate roughly yearly** (the next regen is due ~mid-2027,
> or whenever the dashboards show only stale dates). To regenerate, re-run the
> script(s) with `--send`. See **How to regenerate** at the bottom.

---

## Runs

### 1. Smoke test — `smoke_test_jun23`
- **Date:** 2026-06-23 · **Script:** `seed_cs_funnel.py`
- **Cmd:** `--users 3 --seed 99 --cohort smoke_test_jun23 --send`
- **Result:** 3 users · 28 events · 31 requests · ok=31 fail=0
- **Purpose:** verify the Heap endpoint accepts data. Event-only (predates the screen layer).
- **Status:** disposable — can be deleted.

### 2. Realistic funnel v1 — `bill_payment_frustration`  ⟶ SUPERSEDED
- **Date:** 2026-06-23 · **Script:** `seed_cs_funnel.py`
- **Cmd:** `--users 800 --days 14 --cohort bill_payment_frustration --max-workers 8 --send`
- **Result:** 800 users · 6,341 events · 7,141 requests · ok=7,141 fail=0
- **Content:** bill-pay → FAQ-deflection → call-centre funnel, **custom events only (no `screen_viewed`)**.
- **Status:** **redundant — superseded by v2.** Recommend deleting so it doesn't double-count under `synthetic = true`.

### 3. Realistic funnel v2 (+ screen layer) — `bill_payment_frustration_v2`  ⟶ PRIMARY
- **Date:** 2026-06-23 · **Script:** `seed_cs_funnel.py`
- **Cmd:** `--users 800 --days 14 --seed 42 --cohort bill_payment_frustration_v2 --max-workers 8 --send`
- **Result:** 800 users · 9,293 events · 10,093 requests · ok=10,093 fail=0
- **Content:** full funnel custom events **+ `screen_viewed` screen layer** (`Telco - Bills → … → Telco - Call Us`). Realistic drop-off: ~71 reach Call Us, ~39 tap a number.
- **Funnel:** `telco_bills_viewed → telco_bill_payment_started → telco_bill_payment_failed → telco_bill_payment_help_tapped → telco_help_center_viewed → telco_support_article_viewed → telco_contact_options_viewed → telco_call_us_viewed → telco_call_number_tapped`
- **Segments to demo:** `telco_payment_rage_retry`, `telco_support_article_feedback (helpful=false)`, `telco_support_abandoned`.
- **Status:** **active / primary realistic-funnel cohort.**

### 4. v2 boost — `bill_payment_frustration_v2` (run-tag `..._boost`)  ⟶ INCOMPLETE
- **Date:** 2026-06-24 · **Script:** `seed_cs_funnel.py`
- **Cmd:** `--users 2500 --days 14 --seed 142 --cohort bill_payment_frustration_v2 --run-tag bill_payment_frustration_v2_boost --max-workers 8 --send`
- **Result:** **KILLED mid-run** — only a partial, unknown number of events landed. Intended to thicken the call-tail (~+220 `telco_call_us_viewed`).
- **Status:** incomplete. If a heavier tail is wanted, re-run (ideally delete the partial first, or use a fresh run-tag).

### 5. Call-centre → 2-day return — `callcenter_return_demo`  ⟶ ACTIVE
- **Date:** 2026-06-24 · **Script:** `seed_callcenter_return.py`
- **Cmd:** `--send`
- **Result:** 8 users · 207 events · 215 requests · ok=215 fail=0
- **Content:** 8 named `first.last@contentsquare.com` "people" who **all** reach the Call Us page → **`called_into_call_center`**, then **return after 2 days** and pay → **`telco_bill_payment_completed`**.
- **New events introduced:** `called_into_call_center`, `telco_bill_payment_completed`.
- **People properties (for charts):** `initial_device_type` (iOS/Android), `os_category` (old/new), `device_model`, `os_version`, `tenure_segment` (`5+ years` / `1-5 years` / `under 1 year`), `tenure_years`, `name`, `email`, `market`.
- **Device spread:** iOS new ×2 (Atsushi, Sebastian), iOS old ×2 (Florian, Andrew), Android new ×2 (Jaewon, Lynn), Android old ×2 (Abhi, Romain). Tenure 3/3/2.
- **Funnel note:** to include the return payment step, set the funnel **conversion window ≥ 3 days** (the success event is +2 days).
- **Status:** **active.** The 8 named heroes are the inspectable journeys sitting on top of the backing audience (run #6).

### 6. Call-centre return — backing audience — `callcenter_return_demo`  ⟶ ACTIVE
- **Date:** 2026-06-24 · **Script:** `seed_callcenter_return.py`
- **Cmd:** `--backing 500 --no-heroes --seed 2026 --max-workers 8 --send`
- **Result:** 500 users · 11,533 events · 12,033 requests · ok=12,033 fail=0
- **Content:** 500 anonymised users (diverse random names @contentsquare.com), same call-centre → 2-day-return flow as the heroes, with light drop-off (~90% reach the call centre, ~68% of those return and pay). `--no-heroes` so the 8 named users were **not** re-sent (avoids duplicate events).
- **Distributions:** device — iOS 273 / Android 227 (buckets: iOS new 181 / old 92, Android new 142 / old 85); tenure — 5+ 135 / 1-5 244 / <1 121.
- **For:** acquisition-by-device chart + tenure segmentation. Combined with the 8 heroes ≈ **508 users** in the cohort.
- **Status:** **active.**

### 7. Call-centre return — self-service branch (B) — `callcenter_return_demo`  ⟶ ACTIVE
- **Date:** 2026-06-24 · **Script:** `seed_callcenter_return.py`
- **Cmd:** `--self-service 200 --no-heroes --seed 7 --max-workers 8 --send`
- **Result:** 200 users · 5,321 events · 5,521 requests · ok=5,521 fail=0
- **Content:** branch-B users who reach `telco_call_number_tapped`, then **back out of calling** → re-read the FAQ (`telco_support_article_viewed`, `source=returned_from_call_us`) → self-resolve → pay **same session**. `--no-heroes`; identities reserved against the deployed 8 heroes + 500 backing (seed 2026) ⇒ **0 collisions**.
- **New events:** `telco_call_abandoned`, `telco_self_service_resolved`. Payment carries `resolved_via: "self_service"` (vs `call_center` for path A); `days_since_call: 0`.
- **Fork:** at `telco_call_number_tapped` the cohort splits ~458 call (path A) vs 200 self-serve (path B). Analyze via a journey from `telco_call_number_tapped`, or split a funnel by the `resolved_via` property.
- **Status:** **active.**

### 8. Device-purchase + credit-check fork — `device_credit_demo`  ⟶ READY (not yet sent)
- **Date:** generated 2026-06-29 · **Script:** `seed_device_credit.py` (new)
- **Cmd (suggested):** `--users 600 --days 14 --seed 42 --cohort device_credit_demo --max-workers 8 --send`
- **Status:** **dry-run verified, NOT yet sent.** Claude does not push to the live tenant — run the `--send` command above yourself when ready.
- **Content:** the CSQMobile device-purchase funnel ending in the credit-check **FORK** — `telco_device_viewed → variant → financing → plan_attached → checkout_started → fulfillment → payment_method → telco_credit_check_started → telco_credit_check_result → {approved → telco_purchase_completed | declined → telco_credit_recovery_outright → telco_purchase_completed | abandon}`. Plus a `screen_viewed` layer (`Telco - Device Detail → Device Financing → Checkout → Credit Check → Order Confirmed`).
- **The point — approval varies by cohort.** Each user carries the live app's cohort props (`account_type`, `loyalty_tier`, `is_new_user`, `tenure_days`, `lifetime_orders`, `signup_channel`); approval probability is computed from them. Dry-run (400 users, seed 42) showed **premium 63% vs standard 43%** approval; **platinum 73% vs none 25%**. Split the `telco_credit_check_result` funnel by `account_type` / `loyalty_tier` to demo it.
- **Funnel note:** to see the recovery arm, include `telco_credit_recovery_outright` between `telco_credit_check_result` and `telco_purchase_completed`, or split `telco_purchase_completed` by `finance_mode` (`outright` = recovered after a decline).
- **New events:** none beyond the documented telco device tables (CLAUDE.md) — fully aligned, so it merges with real device-purchase sessions.

---

## How to regenerate (after the dates age out)

1. **Re-run the generators** with `--send` (timestamps auto-refresh to the new run date):
   ```bash
   python3 tools/seed_cs_funnel.py --users 800 --days 14 --seed 42 \
     --cohort bill_payment_frustration_v2 --max-workers 8 --send
   python3 tools/seed_callcenter_return.py --send
   python3 tools/seed_device_credit.py --users 600 --days 14 --seed 42 \
     --cohort device_credit_demo --max-workers 8 --send
   ```
2. **Mind duplicate identities.** Both scripts use *deterministic* identities
   (`seed_cs_funnel.py` = `syn-<run_tag>-<index>`; `seed_callcenter_return.py` =
   the 8 emails). Re-running the **same** cohort/run-tag re-sends the **same
   users**, which **appends duplicate events** (Heap doesn't dedupe). For a clean
   refresh either: (a) delete the old cohort first, or (b) use a new `--cohort` /
   `--run-tag` (e.g. bump to `_v3` / `_2027`).
3. **Dry-run first** (no `--send`) to eyeball the funnel/journeys before pushing.
4. **Update this log** with the new run (date, cohort, counts).

## Gotchas / facts to remember
- Server-side events populate **Product Analytics only** — they do **not** create session replays (those need real app sessions).
- New low-volume / first-seen **event names take minutes–hours to surface** in Heap's UI; high-volume events appear first.
- The `--endpoint` defaults to the public Heap host. If a future tenant ingests elsewhere, override `--endpoint` / `--user-props-endpoint`.
- Monetary amounts are **Singapore-scale for all markets** (Tokyo ×100 only in the app view layer) — don't sum across markets without scaling.
