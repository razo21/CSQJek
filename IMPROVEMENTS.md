# CSQJek — Improvements Backlog

A living, prioritized backlog of enhancements that make CSQJek more **robust** and
**realistic** as a Contentsquare sales-demo app. Claude maintains this file; you steer
by priorities. Worked one small batch at a time, each delivered as a CI-checked PR.

**Ground rules** (from `CLAUDE.md` — every item must respect these):
- No new SPM/CocoaPods packages · maps stay `Canvas`-drawn (no MapKit)
- Don't wire up Phase 2 Grocery locked files until Phase 2 is explicitly started
- Use only the `CSQ` facade (never `Heap.shared.*`)
- Every new screen → `CSQ.trackScreenview()` + table entry; every interactive element → `.accessibilityIdentifier()`
- New events follow the `[section]_[object]_[action]` naming convention

> ⚠️ **Verify before you build.** This backlog was seeded from a fast code scan, and
> some candidates turned out not to match the real code (see "Rejected" below). Any
> item marked _(candidate)_ must be re-confirmed against the actual source before
> implementing — don't trust the description alone.

---

## Legend
`[ ]` open · `[x]` shipped · **S/M/L** = rough size · _(candidate)_ = needs code re-verification

---

## Priority 1 — Robustness (crash-safety; demo must never crash)

- [x] **S** — `ConfirmRideView.selectedRide` clamps its index (was an unguarded subscript). — *Batch 1*
- [ ] **S** _(candidate)_ — `MeatCategoryView` subcategory index: confirm `selectedSubcategoryIndex` stays in bounds across `onChange`. `Views/Grocery/MeatCategoryView.swift`
- [ ] **S** _(candidate)_ — `FlightResultsView` → `FlightDetailView`: confirm selected-flight access is guarded. `Views/Air/FlightResultsView.swift`
- [ ] **S** — `FoodHomeView` search: add a "no results" empty state so an unmatched search term doesn't collapse the layout to blank. `Views/Food/FoodHomeView.swift` **M** if it touches several sections.
- [ ] **S** — `CartView` (Phase 2, locked): empty-state render when items are removed to zero — defer until Phase 2.

## Priority 2 — CS-SDK instrumentation gaps (the app's whole purpose)

- [ ] **S** _(candidate)_ — `SendMoneyView` tab switches (contacts → transfer → international) fire no event. Add `cash_send_tab_selected` { tab, market }. `Views/Cash/SendMoneyView.swift`
- [ ] **S** _(candidate)_ — `CSQAirHomeView` popular-destination taps fire no event. Add `air_destination_selected` { destination, market }. `Views/Air/CSQAirHomeView.swift`
- [ ] **S** _(candidate)_ — `TelcoHomeView` data-usage dial card: confirm it's tappable and add `.accessibilityIdentifier()` if missing. `Views/Telco/TelcoHomeView.swift`
- [ ] **S** _(candidate)_ — `RiderTrackingView` has a screenview but no journey events (e.g. `grocery_tracking_status_advanced`). `Views/Grocery/RiderTrackingView.swift`
- [ ] **S** — Phase 2 Grocery screenviews/events (`GroceryHomeView`, `ProductDetailView`, `CartView`, `CheckoutView`, `OrderConfirmationView`) — **deferred until Phase 2 unlocks.**

## Priority 3 — Realism (richer flows = richer analytics)

- [ ] **M** — Food checkout: make the delivery-address row tappable ("change address") to add funnel depth. `Views/Food/FoodOrderView.swift`
- [ ] **M** — Telco device variant selector (colour/storage affecting price). `Views/Telco/TelcoPlanDetailView.swift`
- [ ] **M** — Flight results filtering UI (stops / price / time-of-day). `Views/Air/FlightResultsView.swift`
- [ ] **M** — Cash transaction-detail screen (tap a transaction row → detail). `Views/Cash/CSQCashHomeView.swift`
- [ ] **S** — Thicker hawker menus (more sections/items) for deeper scroll + heatmap data. `Models/FoodModels.swift`
- [ ] **M** — Home "Recommended for you" personalized section. `Views/Home/HomeView.swift`

## Priority 4 — Polish (theme consistency, UX feedback)

- [ ] **S** — Ride booking: add a loading indicator during the 1.5 s book delay. `Views/Rides/ConfirmRideView.swift`
- [ ] **S** — Live Agent chat: localize timestamp format (24-h for Tokyo). `Views/Shared/LiveAgentButton.swift`
- [ ] **M** — Audit hardcoded spacing/padding → `AppSpacing` tokens (~20 sites).
- [ ] **M** — Audit hardcoded `.font(.system(...))` → `AppFont` helpers.

---

## Rejected after verification (do NOT re-add without new evidence)
- ~~LiveAgentButton chat "state leakage" on reopen~~ — `LiveAgentChatSheet` is re-instantiated per `.sheet` presentation, so `@State messages` already resets. Not a bug.
- ~~FoodOrderView quantity-change event~~ — checkout shows quantity read-only; there are no +/− steppers in that view. Adds/removes happen in `RestaurantDetailView` (already fires `food_item_added`).

---

## Batch log
- **Batch 1** — Establish this backlog + harden `ConfirmRideView.selectedRide` against out-of-bounds. (PR: "First improvements: backlog + ride-flow hardening")
