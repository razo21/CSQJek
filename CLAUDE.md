# CSQJek — CLAUDE.md

## What This Project Is

CSQJek is a **fictitious iOS demo app** built for Contentsquare sales demonstrations. It is a Gojek/Grab-inspired Singapore "super app" with a coral/salmon color scheme matching Contentsquare's brand palette. It is not a production app — it is a polished, simulator-runnable demo that showcases realistic user flows that Contentsquare's analytics platform (session replay, heatmaps, journey analysis, funnels) would instrument.

**This is not an MVP. It is a demo.** Every screen, element, and interaction exists to generate rich, labelable analytics data for the CS platform. Visual polish and crash-free simulator execution matter more than architectural sophistication.

**The #1 design constraint:** Every UI element in this app must be identifiable, trackable, and labelable by the Contentsquare SDK without custom instrumentation workarounds.

---

## Build Phasing — Read This First

The app is being built in deliberate phases. Do not implement features outside the current phase.

| Phase | Scope | Brand Name | Status |
|-------|-------|------------|--------|
| **1 — Ride Sharing** | Home, Destination, Pickup, Confirm, Driver Found | CSQRide | ✅ Complete |
| **2 — Grocery** | Browse, Product Detail, Cart, Checkout, Confirmation | CSQMart | 🔒 Locked |
| **3 — Food Delivery** | Restaurant browse, order, live tracking | CSQFood | ✅ Active |
| **4 — Telco (Mobile)** | eSIM, plans, devices, top-up, roaming | CSQMobile | ✅ Active |

Locked phases exist in the UI as "Coming Soon" stubs. Do not wire up live flows until a phase is explicitly started.

**Phases 3 and 4 are now live.** `FoodHomeView`, `RestaurantDetailView`, `FoodOrderView`, `TelcoHomeView`, and `TelcoPlanDetailView` are all wired into the main tab bar and Home screen respectively. `FoodCartStore` is scoped to the Food tab only (`@StateObject` in `FoodHomeView`, passed down via `@ObservedObject`).

---

## How to Build & Run

**Requirements:** Mac with Xcode 15+, iOS 17 simulator

```bash
# Open in Xcode
open CSQJek.xcodeproj

# Select target: CSQJek
# Select simulator: iPhone 15 Pro (or any iPhone 17+)
# Hit Run (⌘R)
```

**One external dependency: the Contentsquare SDK.** It is integrated via SPM (`apple-sdk` 1.6.2, pinned in `Package.resolved`, which also resolves its transitive Heap/bridge/protobuf/crash-reporter deps) — see the SDK section below. All app *content* is still local sample data; the SDK is the only package.

If Xcode shows "No account" warnings for signing: Signing & Capabilities → Automatically manage signing → select personal team. The app runs on simulator without a paid developer account.

---

## ⚠️ CONTENTSQUARE SDK — INTEGRATION RULES (READ BEFORE EVERY CHANGE)

This section governs how every screen, element, and event in this app must be built. The entire purpose of CSQJek is to generate high-quality, easily-labelable analytics data in the Contentsquare platform. These are not optional guidelines — they are hard requirements for every new file, view, or component added to the project.

### What the CS SDK Is

The Contentsquare iOS SDK (`ContentSquare/apple-sdk`) is a unified package combining two modules:

- **Product Analytics** (powered by Heap) — autocaptures user interactions (taps, gestures, screen views), custom events, user identity, and event properties. This is the primary analytics module for this demo.
- **Experience Analytics** — session replay, heatmaps, zone-based analytics. Secondary module used for visual demos.

Both modules are installed from the same SPM package and initialized together.

---

### SDK Installation (already integrated)

**Package:** Added via Swift Package Manager in Xcode:
```
https://github.com/ContentSquare/apple-sdk
```

Pinned to `apple-sdk` 1.6.2 (see `Package.resolved`). The package resolves its own transitive
dependencies (the Heap autocapture/core SDKs, the interim bridge, crash reporter, protobuf) —
do not add those repos manually.

**Required linker flag** — add to Build Settings → Linking - General → Other Linker Flags:
```
-ObjC
```

**Module:** the app imports the unified module everywhere:
```swift
import ContentsquareSDK
```

**Initialization** — in `CSQJekApp.swift`, inside the `@main` App struct `init()` (this is the
actual code in the project):
```swift
import ContentsquareSDK

// In App init:
CSQ.configureProductAnalytics(
    environmentID: "4140621035",
    additionalOptions: [.enableUIKitAutocapture: true]
)
// Explicit opt-in (required for demo — SDK is opted-out by default):
CSQ.optIn()
CSQ.start()
```

Do NOT initialize in a View — it must be in the App entry point. Everything is driven through the
unified `CSQ` facade (`configureProductAnalytics` / `optIn` / `start`). Do NOT call
`Heap.shared.startRecording()` directly — Heap is a transitive dependency powering Product
Analytics under the hood, not an API this app calls.

---

### Screen Tracking — Rules

Every top-level view (tab root, full-screen cover, sheet) **must** call `CSQ.trackScreenview()` in its `.onAppear()`. This fires a screen-view event that is the foundation of all funnel, journey, and session replay analysis.

```swift
// Pattern for every main view:
var body: some View {
    VStack { ... }
        .onAppear {
            CSQ.trackScreenview("Home")
        }
}
```

**Screen naming rules (enforced):**
- Keep total distinct screen names **under 100** across the entire app
- Use `PascalCase` or `Title Case` — no underscores in screen names
- Names must be stable — never use dynamic values (user IDs, timestamps) in screen names. The one allowed exception in the codebase is `AddWithdrawView`, which switches between two fixed enum values (`"Cash - Add Funds"` / `"Cash - Withdraw"`) — bounded and stable, so acceptable.
- Names must match what a Contentsquare analyst would recognise in the dashboard

This table reflects the actual `CSQ.trackScreenview(...)` calls in the code as of the current build.

| View File | Screen Name | Status |
|-----------|-------------|--------|
| `SplashView.swift` | `"Splash"` | ✅ live |
| `MarketPickerView.swift` | `"Market Picker"` | ✅ live |
| `HomeView.swift` | `"Home"` | ✅ live |
| `ContentView.swift` (Rides tab root) | `"Rides"` | ✅ live |
| `ContentView.swift` (Profile tab) | `"Profile"` | ✅ live |
| `DestinationView.swift` | `"Ride - Destination"` | ✅ live |
| `PickupLocationView.swift` | `"Ride - Pickup"` | ✅ live |
| `ConfirmRideView.swift` | `"Ride - Confirm"` | ✅ live |
| `RideBookedSheet` (in ConfirmRideView) | `"Ride - Driver Found"` | ✅ live |
| `ConfirmRideView.swift` (payment picker) | `"Ride - Payment Picker"` | ✅ live |
| `ConfirmRideView.swift` (promo entry) | `"Ride - Promo Code Entry"` | ✅ live |
| `FoodHomeView.swift` | `"Food - Home"` | ✅ live |
| `RestaurantDetailView.swift` | `"Food - Restaurant Menu"` | ✅ live |
| `FoodOrderView.swift` (checkout) | `"Food - Checkout"` | ✅ live |
| `OrderConfirmedView` (in FoodOrderView) | `"Food - Order Confirmed"` | ✅ live |
| `FoodDeliveryComingSoonView.swift` | `"Food - Coming Soon"` | legacy stub |
| `TelcoHomeView.swift` | `"Telco - Home"` | ✅ live |
| `TelcoPlanDetailView.swift` | `"Telco - Plan Detail"` | ✅ live |
| `TelcoHomeView.swift` (top-up sheet) | `"Telco - Top Up"` | ✅ live |
| `TelcoHomeView.swift` (roaming sheet) | `"Telco - Roaming"` | ✅ live |
| `TelcoHomeView.swift` (data add-on sheet) | `"Telco - Data Add-On"` | ✅ live |
| `TelcoHomeView.swift` (DeviceDetailView) | `"Telco - Device Detail"` | ✅ live |
| `TelcoHomeView.swift` (DeviceFinancingView) | `"Telco - Device Financing"` | ✅ live |
| `TelcoPlanDetailView.swift` (PlanSignupView) | `"Telco - Plan Signup"` | ✅ live |
| `TelcoPlanDetailView.swift` (TelcoCheckoutView) | `"Telco - Checkout"` | ✅ live (shared device + plan) |
| `TelcoPlanDetailView.swift` (TelcoCreditCheckView) | `"Telco - Credit Check"` | ✅ live (funnel drop-off step) |
| `TelcoPlanDetailView.swift` (TelcoOrderConfirmedView) | `"Telco - Order Confirmed"` | ✅ live (shared device + plan) |
| `TelcoComingSoonView.swift` | `"Telco - Coming Soon"` | legacy stub |
| `TelcoBillsView.swift` | `"Telco - Bills"` | ✅ live (bill review + download) |
| `TelcoBillsView.swift` (BillDetail) | `"Telco - Bill Detail"` | ✅ live (itemized + PDF download) |
| `TelcoBillsView.swift` (Payment) | `"Telco - Bill Payment"` | ✅ live (payment **fails** — funnel break) |
| `TelcoBillsView.swift` (HelpCenter) | `"Telco - Help Center"` | ✅ live (deflection hub) |
| `TelcoBillsView.swift` (SupportArticle) | `"Telco - Support Article"` | ✅ live (deflection loop) |
| `TelcoBillsView.swift` (ContactSupport) | `"Telco - Contact Support"` | ✅ live (buried contact options) |
| `TelcoBillsView.swift` (SupportBot) | `"Telco - Support Bot"` | ✅ live (chatbot loop trap) |
| `TelcoBillsView.swift` (LiveChat) | `"Telco - Live Chat"` | ✅ live (human agent — the payoff) |
| `TelcoBillsView.swift` (CallUs) | `"Telco - Call Us"` | ✅ live (buried phone numbers) |
| `CSQCashHomeView.swift` | `"Cash - Home"` | ✅ live |
| `CSQCashHomeView.swift` (all transactions) | `"Cash - All Transactions"` | ✅ live |
| `SendMoneyView.swift` | `"Cash - Send Money"` | ✅ live |
| `QRScannerView.swift` | `"Cash - QR Scanner"` | ✅ live |
| `AddWithdrawView.swift` | `"Cash - Add Funds"` / `"Cash - Withdraw"` | ✅ live (mode-dependent) |
| `CSQAirHomeView.swift` | `"Air - Home"` | ✅ live |
| `FlightResultsView.swift` | `"Air - Results"` | ✅ live |
| `FlightDetailView.swift` | `"Air - Flight Detail"` | ✅ live |
| `BookingConfirmationView.swift` | `"Air - Booking Confirmation"` | ✅ live |
| `MeatCategoryView.swift` | `"Grocery - Meat"` | ✅ live |
| `RiderTrackingView.swift` | `"Grocery - Rider Tracking"` | ✅ live |
| `GroceryComingSoonView.swift` | `"Grocery - Coming Soon"` | ✅ live |
| `LiveAgentButton.swift` (chat sheet) | `"Live Agent - Chat"` | ✅ live |
| `GroceryHomeView.swift` | `"Grocery - Home"` | ⚠️ file exists, NOT instrumented (Phase 2 locked) |
| `ProductDetailView.swift` | `"Grocery - Product Detail"` | ⚠️ file exists, NOT instrumented (Phase 2 locked) |
| `CartView.swift` | `"Grocery - Cart"` | ⚠️ file exists, NOT instrumented (Phase 2 locked) |
| `CheckoutView.swift` | `"Grocery - Checkout"` | ⚠️ file exists, NOT instrumented (Phase 2 locked) |
| `OrderConfirmationView.swift` | `"Grocery - Order Confirmed"` | ⚠️ file exists, NOT instrumented (Phase 2 locked) |

**Rule:** When adding any new screen, add its name to this table before writing any other code.

---

### Autocapture — What the SDK Captures Automatically

Once initialized, the CS SDK autocaptures the following **with no additional code**:

| Interaction | Captured automatically |
|-------------|------------------------|
| Button taps | ✅ Yes |
| NavigationLink taps | ✅ Yes |
| Tab switches | ✅ Yes |
| Toggle changes | ✅ Yes |
| Slider moves | ✅ Yes |
| Scroll depth | ✅ Yes |
| Pinch / zoom gestures | ✅ Yes |
| View controller changes (UIKit) | ✅ Yes |
| App foreground / background | ✅ Yes |
| App version changes | ✅ Yes |
| SwiftUI interactions (v0.9.0+) | ✅ Yes — requires `.accessibilityIdentifier()` for reliable targeting |

**What is NOT autocaptured and requires manual tracking:**
- Custom business events (e.g., "ride booked", "promo tapped")
- User identity
- Screen views in SwiftUI (must call `CSQ.trackScreenview()` in `.onAppear()`)
- Event properties / metadata

---

### `accessibilityIdentifier` — The Most Important Rule

**The CS SDK uses `accessibilityIdentifier` as the primary key to identify, target, and label UI elements.** Without it, elements appear as anonymous addresses in the dashboard and cannot be reliably named or filtered.

**Every interactive element must have `.accessibilityIdentifier()`. No exceptions.**

This includes: `Button`, `NavigationLink`, `Toggle`, `Slider`, `TextField`, `Picker`, `TabItem`, any `View` with a `.onTapGesture`, and any container that is itself a tap target.

```swift
// ✅ Correct — identifiable by CS
Button("Book Ride") { bookRide() }
    .accessibilityIdentifier("confirm_book_button")
    .accessibilityLabel("Book your CSQRide")

// ❌ Wrong — CS cannot reliably label this
Button("Book Ride") { bookRide() }
```

**Naming convention:** `[screen]_[element_type]_[descriptor]`

| Part | Examples |
|------|---------|
| `screen` | `home`, `confirm`, `booked`, `destination`, `pickup`, `profile`, `telco` |
| `element_type` | `btn` (button), `tile` (service tile), `card` (promo/content card), `row` (list row), `tab` (tab bar item), `input` (text field), `toggle`, `map` |
| `descriptor` | Short snake_case description of what it does |

**Full examples:**

```
home_btn_search          home_tile_csqride        home_card_promo_0
confirm_btn_book         confirm_tile_csqblack     booked_btn_cancel
destination_row_recent   pickup_map_canvas         profile_row_payment
tab_home                 tab_rides                 telco_btn_notify_me
```

**Centralise identifiers in an enum per screen:**
```swift
private enum HomeAccessID {
    static let searchBar        = "home_btn_search"
    static let locationSelector = "home_location_selector"
    static func serviceTile(_ name: String) -> String {
        "home_tile_\(name.lowercased())"
    }
}
```

This pattern already exists in `HomeView.swift` — replicate it in every new view file.

---

### Custom Event Tracking — How and When

Use `CSQ.trackEvent()` for business-critical events that autocapture alone cannot distinguish. These are the events that tell the analytics story during a demo.

```swift
// Syntax
CSQ.trackEvent("event_name", properties: ["key": "value"])

// Property value types: String, Bool, Double, Float, Int, Int64, Int32, Int16, Int8
```

**Core custom events (these are wired in the code; many more exist across Cash / Air / Live Agent / Telco flows):**

| Event Name | Where to fire | Key Properties |
|------------|---------------|----------------|
| `ride_booked` | After "Book" button tap + booking confirmed | `ride_type`, `price`, `pickup`, `dropoff`, `eta_minutes` |
| `ride_option_selected` | Each time user taps a ride option card | `ride_type`, `price` |
| `promo_tapped` | Promo banner tap | `promo_index`, `promo_headline` |
| `service_tile_tapped` | Any service tile tap | `service_name`, `is_active` |
| `ride_cancelled` | Cancel button in Driver Found sheet | `ride_type` |
| `destination_selected` | Location selected in DestinationView | `location_name`, `source` (recent/search) |
| `tab_switched` | Tab bar item tap | `tab_name` |
| `food_restaurant_tapped` | Restaurant tap in FoodHomeView | `restaurant_name`, `cuisine` |
| `food_item_added` | Add-to-cart button in RestaurantDetailView | `item_name`, `price`, `restaurant` |
| `food_order_placed` | Place Order button in FoodOrderView | `restaurant`, `item_count`, `total`, `delivery_fee` |
| `food_track_order_tapped` | Track button in OrderConfirmedView | `restaurant` |
| `telco_plan_viewed` | Plan card becomes visible in TelcoHomeView | `plan_name`, `plan_type`, `price` |
| `telco_addon_tapped` | Add-on row tap in TelcoHomeView | `addon_name` |
| `telco_plan_signup_tapped` | Sign-up CTA in TelcoPlanDetailView | `plan_name`, `plan_type`, `price` |
| `telco_device_viewed` | DeviceDetailView appears | `brand`, `model`, `storage`, `outright_price`, `monthly_price`, `market` |
| `telco_device_variant_selected` | Colour/storage tap in DeviceDetailView | `model`, `color`, `storage`, `market` |
| `telco_device_financing_selected` | Finance-mode tap in DeviceFinancingView | `model`, `finance_mode`, `plan_name`, `term_months`, `monthly_total`, `due_today`, `market` |
| `telco_device_plan_attached` | Plan chip tap in DeviceFinancingView | `plan_name`, `plan_type`, `price`, `market` |
| `telco_plan_signup_started` | PlanSignupView appears | `plan_name`, `plan_type`, `price`, `market` |
| `telco_plan_sim_selected` | SIM type / number choice tap in PlanSignupView | `plan_name`, `sim_type`, `number_choice`, `market` |
| `telco_checkout_started` | TelcoCheckoutView appears | `kind`, `item`, `due_today`, `monthly_total`, `market` |
| `telco_fulfillment_selected` | Fulfillment row tap in TelcoCheckoutView | `kind`, `method`, `market` |
| `telco_payment_method_selected` | Payment row tap in TelcoCheckoutView | `kind`, `method`, `market` |
| `telco_credit_check_started` | "Run credit check" tap in TelcoCreditCheckView | `kind`, `item`, `amount`, `market` |
| `telco_credit_check_result` | Credit check completes (drop-off point) | `kind`, `result` (`approved`/`declined`), `market` |
| `telco_credit_recovery_outright` | "Switch to outright purchase" tap after a decline | `kind`, `item`, `due_today`, `market` |
| `telco_purchase_completed` | "Place order" tap in TelcoCreditCheckView | `kind`, `item`, `plan_name`, `finance_mode`, `term_months`, `due_today`, `monthly_total`, `market` |

**Bills & Support "frustration journey" (CSQMobile — `TelcoBillsView.swift`).** This funnel is deliberately a *deflection maze*: a user wants to pay a bill / reach a human but is repeatedly routed into FAQ content. The events below let CS see content consumed, funnel depth, and the abandonment moment. Every event carries `market`; `depth` = how many layers into the support maze.

| Event Name | Where to fire | Key Properties |
|------------|---------------|----------------|
| `telco_bills_viewed` | Bills screen appears | `current_amount`, `status` |
| `telco_bill_download_tapped` | Download icon on a statement row | `invoice_no` |
| `telco_bill_opened` | Statement row tap | `invoice_no` |
| `telco_bill_detail_viewed` | Bill Detail appears | `invoice_no`, `amount` |
| `telco_bill_pdf_downloaded` | "Download PDF" on Bill Detail | `invoice_no` |
| `telco_bill_payment_started` | First "Pay" tap | `invoice_no`, `amount`, `method`, `attempt` |
| `telco_bill_payment_failed` | Payment resolves (always fails) | `invoice_no`, `amount`, `method`, `attempt`, `error_code` (`CSQ-4012`) |
| `telco_bill_payment_retried` | "Try Again" tap after a failure | `invoice_no`, `amount`, `method`, `attempt` |
| `telco_bill_payment_help_tapped` | "Get help" pivot after failure | `invoice_no`, `attempt` |
| `telco_help_center_viewed` | Help Center appears | `entry_point`, `depth` |
| `telco_help_search_performed` | Search submit (query masked) | `query_length`, `entry_point` |
| `telco_help_category_tapped` | Category tile tap | `category` |
| `telco_help_article_tapped` | Article row tap in Help Center | `article_id`, `category`, `source` |
| `telco_support_article_viewed` | Support Article appears | `article_id`, `category`, `depth`, `source` |
| `telco_support_article_feedback` | "Was this helpful?" yes/no | `article_id`, `helpful` (Bool), `depth` |
| `telco_support_article_related_tapped` | Related-article tap (deflection loop) | `from_article_id`, `to_article_id`, `depth` |
| `telco_support_still_need_help_tapped` | "Still need help?" link | `article_id`, `depth` |
| `telco_contact_options_viewed` | Contact Support appears | `depth` |
| `telco_contact_deflected` | Any non-human channel tap (article/forum/bot) | `channel`, `depth` |
| `telco_support_bot_opened` | Support Bot appears | `depth` |
| `telco_support_bot_message_sent` | User sends bot message | `message_index`, `wants_human` (Bool) |
| `telco_support_bot_escalation_requested` | Bot first offers a human | `attempts_before_escalation` |
| `telco_support_bot_escalated` | "Connect me to a human" tap | — |
| `telco_live_chat_queued` | Live Chat appears (in queue) | `queue_position`, `est_wait_min`, `depth` |
| `telco_live_chat_connected` | Human agent picks up | `agent_name`, `wait_sec`, `depth` |
| `telco_live_chat_message_sent` | User message in live chat | `message_index` |
| `telco_call_us_viewed` | Call Us appears | `depth` |
| `telco_call_number_tapped` | A phone-line row tap | `line` (`general`/`billing`/`premium`), `depth` |
| `telco_support_abandoned` | "I'll deal with this later" — the give-up signal | `last_screen`, `depth` |

**Resolution / recovery paths (the positive counterparts — `TelcoBillsView.swift`).** The maze isn't only failure: the bill can actually get paid. `TelcoBillPaymentView` takes an optional `resolvedVia` — when set (`self_service` / `call_center`) the payment SUCCEEDS instead of failing (CSQ-4012). At `Telco - Call Us` the journey forks: call (→ `called_into_call_center`) or back out to the FAQ (→ `telco_call_abandoned`); a "helpful" article offers a "this fixed it → pay" CTA (→ `telco_self_service_resolved`). These reuse existing screen names (no new screens).

| Event Name | Where to fire | Key Properties |
|------------|---------------|----------------|
| `telco_call_abandoned` | "Skip the wait — try the quick guide" tap on Call Us | `depth`, `market` |
| `called_into_call_center` | A phone-line call connects (1.8s after tap) | `line`, `depth`, `market` |
| `telco_self_service_resolved` | "This fixed it — pay my bill" on a helpful article | `invoice_no`, `article_id`, `resolution_path` (`self_service`), `depth`, `market` |
| `telco_bill_payment_completed` | Payment clears (only when `resolvedVia` is set) — the terminal conversion | `invoice_no`, `amount`, `method`, `resolved_via` (`self_service`/`call_center`), `market` |

**Rage / frustration signals (`Views/Shared/RageTapDetector.swift`).** The CS iOS SDK does **not** emit rage clicks client-side — rage is a behavioural signal the platform derives server-side from autocaptured taps + replay. To make it *deterministic* for demos, these explicit events fire when a user hammers a control. `RageTapDetector` is a sliding-window value type (`@State`); `FrustrationSignal` holds the emitters. Fire them in addition to (not instead of) the per-screen events.

| Event Name | Where to fire | Key Properties |
|------------|---------------|----------------|
| `promo_rage_apply` | Coupon "Apply" hammered on an invalid code — shared across CSQRide (`ConfirmRideView`), CSQFood (`FoodOrderView`), CSQMart (`CartView`). Segment by `service`. | `service` (`CSQRide`/`CSQFood`/`CSQMart`), `screen`, `tap_count`, `failed_attempts`, `code_length` (length only — never the code), `market` |
| `telco_payment_rage_retry` | A failing bill payment retried ≥3 times in `TelcoBillsView` | `invoice_no`, `tap_count`, `amount`, `method`, `market` |

When adding events: fire them in the same action closure as the UI interaction. Never fire them in `.onAppear()` unless the event semantically is "screen viewed" (use `trackScreenview` for that instead).

### Event Naming Convention (enforced for all new events)

A single convention so funnels across CSQRide, CSQFood, and CSQMobile (device + plan) line up cleanly in the Contentsquare dashboard. Follow it for every new event.

**Event name shape:** `[section]_[object]_[action]` — all lowercase `snake_case`, no dynamic values.

- `section` — the service prefix: `ride`, `food`, `telco`, `cash`, `air`, `grocery`.
- `object` — the noun the action applies to: `device`, `plan`, `checkout`, `credit_check`, `restaurant`, `item`, `addon`.
- `action` — a past-tense verb from the shared vocabulary below.

**Shared action vocabulary (use these, in this funnel order):**

`viewed` → `selected` → `started` → (`result`) → `completed`

- `viewed` — an item/screen entered (e.g. `telco_device_viewed`).
- `selected` — a choice within a step (`telco_device_variant_selected`, `telco_fulfillment_selected`).
- `started` — a sub-flow began (`telco_checkout_started`, `telco_plan_signup_started`).
- `result` — a gated step resolved; carry a `result` property (`telco_credit_check_result` → `approved`/`declined`).
- `completed` — the terminal conversion. **New funnels must end in `_completed`** (`telco_purchase_completed`). Legacy `food_order_placed` predates this rule — do not rename it, but prefer `_completed` going forward.

**Property key rules:**

- Every event carries `market` (`Singapore` / `Tokyo` / `Sydney`) so funnels segment by market.
- Stable keys, never localized values: identifiers use the English `name` (`plan_name: "ValuePlus"`), never `displayName`.
- Reuse these standard keys across events: `kind` (`device`/`plan`), `item`, `method`, `result`, `finance_mode`, `term_months`, `price`, `due_today`, `monthly_total`.
- Enum-valued properties use stable analytics tokens, never display text:
  `finance_mode` = `outright` | `installment_24mo` · `sim_type` = `esim` | `physical` ·
  `number_choice` = `new_number` | `port_in` · `method` = `card` | `wallet` | `esim` | `delivery` | `pickup` ·
  `result` = `approved` | `declined`.

**⚠️ Currency-scale caveat (known data quirk):** monetary properties (`price`, `due_today`, `monthly_total`) are sent in **Singapore-scale numbers** — the same numeric value for all markets. Tokyo's ×100 yen scaling happens only in the view layer, not in the event. So a Tokyo `price: 28` represents ¥2,800, while a Sydney `price: 28` represents A$28. **Do not sum or compare these raw amounts across markets without first scaling by market.** Segment by `market`, or convert before aggregating.

---

### User Identity — How to Implement

```swift
// When a user "logs in" (demo: hardcoded on app launch)
CSQ.identify("jeff.lin@demo.com")

// Attach properties to the user profile
CSQ.addUserProperties([
    "name":         "Jeff Lin",
    "account_type": "premium",
    "market":       "Singapore",
    "demo_user":    true
])
```

**Rules:**
- Call `CSQ.identify()` once per session, after the splash screen
- `CSQ.addUserProperties()` can be called at any time — properties persist across sessions
- Never use real personal data as identity — use the demo persona (`jeff.lin@demo.com`)
- For the demo, set `"demo_user": true` as a property so demo sessions can be filtered out in the CS dashboard

---

### SwiftUI-Specific Rules (Critical for CS Compatibility)

The CS SDK has known limitations with certain SwiftUI patterns. These rules prevent element identification failures:

**1. Avoid deeply nested LazyVGrid / LazyHStack**
Intricate hierarchies of `LazyStack` or `LazyGrid` cause inconsistent element identification — elements may appear with different addresses on each render, breaking CS labeling.

```swift
// ✅ Preferred — single-layer lazy grid
LazyVGrid(columns: cols, spacing: 12) {
    ForEach(items) { item in
        ItemView(item: item)
            .accessibilityIdentifier("home_tile_\(item.name)")
    }
}

// ❌ Avoid — nested lazy containers break CS element IDs
LazyVGrid(...) {
    LazyHStack(...) {   // <-- nested lazy = unreliable IDs
        ItemView(...)
    }
}
```

The current `LazyVGrid` in `HomeView.swift` (service grid) is single-layer and acceptable. Do not add nesting.

**2. Call `trackScreenview` in `.onAppear()`, not in `init()`**
```swift
// ✅ Correct
.onAppear { CSQ.trackScreenview("Home") }

// ❌ Wrong — fires before view is fully rendered
init() { CSQ.trackScreenview("Home") }
```

**3. Do not rely on view hierarchy position for CS targeting**
Always use `.accessibilityIdentifier()`. Position-based identifiers (e.g., "3rd button in VStack") are fragile in SwiftUI and will break across OS versions.

**4. Rotation is not supported for LazyStack / LazyGrid elements**
The app is portrait-only (`UIInterfaceOrientationPortrait` in build settings) — this is already correct.

**5. ScrollView + LazyStack offset**
If a `ScrollView` containing a `LazyStack` starts at a non-zero offset, element IDs become inconsistent. Always start scroll position at zero (no `scrollPosition` offset on launch).

---

### Sensitive Data — Masking Rules

The CS SDK captures text content from UI elements to use as event labels. For demo purposes this is desirable. However, follow these rules:

**Do not mask in this demo** (everything is fake data — masking would reduce demo value):
- Pricing, ETA, driver names — all fake, fine to capture

**The actual masking modifier used in this app is `.csqMaskContents(_:)`** — see `DestinationView.swift` (the search field is wrapped with `.csqMaskContents(true)`).

```swift
// Mask a specific view's captured contents (e.g., a text field with user input)
TextField("Search...", text: $query)
    .csqMaskContents(true)   // CS SDK SwiftUI modifier — actual API
```

**Rule:** Any `TextField` or `SecureField` added to this app must have `.csqMaskContents(true)` applied. Do not capture user-typed input.

---

### New Screen / Feature Checklist

**Run through this checklist every time a new view, screen, or interactive element is added:**

- [ ] Screen has a `CSQ.trackScreenview("Screen Name")` call in `.onAppear()`
- [ ] Screen name is added to the Screen Tracking table above
- [ ] Screen name is under 50 characters, uses Title Case, contains no dynamic values
- [ ] Every `Button` has `.accessibilityIdentifier()` and `.accessibilityLabel()`
- [ ] Every `NavigationLink` has `.accessibilityIdentifier()`
- [ ] Every `TabItem` has `.accessibilityIdentifier()`
- [ ] Every tappable card / tile has `.accessibilityIdentifier()` on the outermost tap target
- [ ] Identifiers follow `[screen]_[type]_[descriptor]` convention
- [ ] Identifiers are centralised in a private `enum [Screen]AccessID` at top of the file
- [ ] No `LazyVGrid` / `LazyHStack` are nested inside other lazy containers
- [ ] Any new `TextField` / `SecureField` has `.csqMaskContents(true)` applied
- [ ] Any new business event (booking, purchase, key CTA) has a `CSQ.trackEvent()` call planned
- [ ] New events are added to the Custom Events table in this file

---

### Identifier Reference — All Current Elements

| Screen | Identifier | Element Type |
|--------|------------|--------------|
| **Splash** | `splash_tap_to_proceed_overlay` | Tap area |
| **Home** | `home_search_bar` | Search button |
| **Home** | `home_location_selector` | Location chevron |
| **Home** | `home_notification_bell` | Bell button |
| **Home** | `home_user_avatar` | Avatar button |
| **Home** | `home_promo_carousel` | Carousel container |
| **Home** | `home_promo_card_0/1/2` | Promo cards |
| **Home** | `home_service_tile_csqride` | Service tile |
| **Home** | `home_service_tile_csqmart` | Service tile |
| **Home** | `home_service_tile_csqfood` | Service tile |
| **Home** | `home_service_tile_csqexpress` | Service tile |
| **Home** | `home_service_tile_csqhealth` | Service tile |
| **Home** | `home_service_tile_csqclean` | Service tile |
| **Home** | `home_service_tile_csqcash` | Service tile |
| **Home** | `home_service_tile_csqmobile` | Service tile |
| **Confirm Ride** | `confirm_ride_option_csqride` | Ride option card |
| **Confirm Ride** | `confirm_ride_option_csqxpress` | Ride option card |
| **Confirm Ride** | `confirm_ride_option_csqblack` | Ride option card |
| **Confirm Ride** | `confirm_ride_option_csq_tank` | Ride option card |
| **Confirm Ride** | `confirm_ride_option_csq_horse` | Ride option card |
| **Confirm Ride** | `confirm_book_button` | Primary CTA |
| **Driver Found** | `booked_live_map` | Canvas map |
| **Driver Found** | `booked_btn_cancel_ride` | Cancel button |
| **Telco Sheet (legacy)** | `telco_coming_soon_illustration` | Visual |
| **Telco Sheet (legacy)** | `telco_coming_soon_title` | Text |
| **Telco Sheet (legacy)** | `telco_btn_notify_me` | CTA button |
| **Telco Home** | `telco_plan_type_tab_[postpaid/prepaid/simOnly]` | Plan type tab |
| **Telco Home** | `telco_plan_card_[plan_name]` | Plan card |
| **Telco Home** | `telco_device_card_[device_name]` | Device card |
| **Telco Home** | `telco_addon_row_[addon_name]` | Add-on row |
| **Telco Plan Detail** | `telco_detail_whats_included` | Features card |
| **Telco Plan Detail** | `telco_detail_portin` | Port-in offer card |
| **Telco Plan Detail** | `telco_detail_faq` | FAQ section |
| **Telco Plan Detail** | `telco_btn_signup_[plan_name]` | Sign-up CTA |
| **Food Home** | `food_search_bar` | Search input |
| **Food Home** | `food_chip_[category]` | Category filter chip |
| **Food Home** | `food_featured_[index]` | Featured card |
| **Food Home** | `food_restaurant_row_[name]` | Restaurant list row |
| **Restaurant Detail** | `restaurant_back_button` | Back nav |
| **Restaurant Detail** | `restaurant_view_cart_button` | Cart CTA bar |
| **Restaurant Detail** | `restaurant_category_tab_[index]` | Menu section tab |
| **Restaurant Detail** | `restaurant_item_[uuid]` | Menu item row |
| **Restaurant Detail** | `restaurant_add_[uuid]` | Add-to-cart button |
| **Food Checkout** | `food_order_cart_list` | Cart items list |
| **Food Checkout** | `food_order_row_address` | Delivery address row |
| **Food Checkout** | `food_order_row_payment` | Payment method row |
| **Food Checkout** | `food_order_row_promo` | Promo code row |
| **Food Checkout** | `food_order_btn_place_order` | Place Order button |
| **Food Confirmed** | `food_confirm_btn_track` | Track My Order button |
| **Food Confirmed** | `food_confirm_btn_done` | Back to CSQFood button |
| **Tabs** | `tab_home` | Tab item |
| **Tabs** | `tab_rides` | Tab item |
| **Tabs** | `tab_grocery` | Tab item |
| **Tabs** | `tab_food` | Tab item |
| **Tabs** | `tab_profile` | Tab item |

---

## Architecture

### Directory Structure

```
CSQJek/
├── CSQJekApp.swift          # App entry point, splash gate, CS SDK init
├── ContentView.swift        # Root tab bar (5 tabs: Home, Rides, Grocery, Food, Profile)
├── Theme/
│   └── AppTheme.swift       # ALL colors, spacing, radius, typography, reusable components
├── Models/
│   ├── RideModels.swift     # RideOption, Location, Driver + sample data
│   ├── GroceryModels.swift  # Grocery models (Phase 2 — locked)
│   ├── FoodModels.swift     # Restaurant, MenuItem, FoodCartStore (Phase 3 — active)
│   └── TelcoModels.swift    # TelcoPlan, TelcoDevice, TelcoAddOn (Phase 4 — active)
└── Views/
    ├── Home/
    │   └── HomeView.swift
    ├── SplashView.swift
    ├── Rides/
    │   ├── DestinationView.swift
    │   ├── PickupLocationView.swift
    │   └── ConfirmRideView.swift
    ├── Grocery/
    │   ├── GroceryComingSoonView.swift   # Phase 2 placeholder
    │   ├── GroceryHomeView.swift         # Phase 2 (locked)
    │   ├── ProductDetailView.swift       # Phase 2 (locked)
    │   ├── CartView.swift                # Phase 2 (locked)
    │   ├── CheckoutView.swift            # Phase 2 (locked)
    │   └── OrderConfirmationView.swift   # Phase 2 (locked)
    ├── Food/
    │   ├── FoodHomeView.swift            # Phase 3 — restaurant browse + cart bar
    │   ├── RestaurantDetailView.swift    # Phase 3 — menu + add-to-cart
    │   ├── FoodOrderView.swift           # Phase 3 — checkout + order confirmed
    │   └── FoodDeliveryComingSoonView.swift  # Legacy stub (unused)
    └── Telco/
        ├── TelcoHomeView.swift           # Phase 4 — plan browse, devices, add-ons
        ├── TelcoPlanDetailView.swift     # Phase 4 — plan detail + sign-up CTA
        └── TelcoComingSoonView.swift     # Legacy stub (unused)
```

### State Management

- **`FoodCartStore`** (Phase 3) is a `@StateObject` in `FoodHomeView` and passed as `@ObservedObject` to `RestaurantDetailView` and `FoodOrderView`. It is **not** injected at app root — scoped to the Food tab only to avoid spurious re-renders on other tabs.
- **`CartStore`** (Phase 2 Grocery) exists but is dormant — do not wire it up until Phase 2 begins.
- All other state is **local `@State`** within each view.
- Do not add new `ObservableObject` classes or reach for Combine, Redux patterns, or ViewModels unless explicitly asked. This is a demo, not an enterprise app.

### Navigation Architecture

The ride flow uses a specific pattern — **do not change this without good reason:**

```
ContentView (TabView)
  └── HomeView
        └── DestinationView        [fullScreenCover — dismisses back to Home]
              └── PickupLocationView  [NavigationLink push]
                    └── ConfirmRideView  [NavigationLink push]
                          └── RideBookedSheet  [.sheet modal]
```

- `DestinationView` is presented via `fullScreenCover` from `HomeView` — this gives it the Gojek-style full-screen map feel.
- The remaining ride steps use `NavigationLink` push within that full-screen context.
- `RideBookedSheet` is a `.sheet` (partial modal) — it intentionally does not cover the map.

---

## Design System Rules

**All styling must come from `AppTheme.swift`. Never hardcode colors, spacing, or corner radii.**

---

### Contentsquare Official Brand Colors (2024 Guidelines)

These tokens come directly from the official Contentsquare 2024 Presentation Template.
**These take priority over all other color decisions.** When in doubt, use these.

| Token | Hex | Official Usage |
|-------|-----|----------------|
| `.csElectricBlue` | `#3640E8` | **PRIMARY brand color** — hero slide backgrounds, key brand moments, dominant accent |
| `.csDeepNavy` | `#1C1263` | Dark navy/indigo — headlines on light BGs, dark hero slides, text on cream |
| `.csAmber` | `#FBAE40` | Brand amber/gold — secondary accent, rewards, highlights |
| `.csCoral` | `#F26B43` | Brand coral/orange — warm accent, CTAs, section markers |
| `.csCream` | `#FFEEB0` | Brand cream/yellow — light slide backgrounds, soft card fills |
| `.csLavender` | `#CDCFF9` | Light blue/periwinkle tint — soft backgrounds, inactive states |
| `.csLightPeach` | `#FEEDE7` | Light peach tint — soft warm backgrounds |
| `.csOffWhite` | `#FFFDF5` | App screen background (nearest to CS cream in mobile context) |

**Typography (official CS brand):**
- **Gilroy** — Primary typeface (bold, modern geometric sans-serif). Embed as a custom font if possible.
- **Poppins** — Official Google Workspace fallback. Available as a free Google Font.
- **SF Pro (system font)** — iOS fallback when neither Gilroy nor Poppins is embedded. Acceptable for simulator demos.
- Minimum font size: **11pt** for body content per CS accessibility guidelines.

**CS Design Language Rules (from brand guide):**
- ✅ Bold, solid color blocks — no gradients
- ✅ High contrast — always check AA rating between text and background
- ✅ CS logo / icon can be used as a watermark pattern on colored backgrounds
- ✅ Clean, open, geometric — Gilroy's personality should carry through layout choices
- ❌ No off-brand colors — stay within the palette above
- ❌ No decorative gradients on brand color backgrounds
- ❌ No mixing brand colors randomly — Electric Blue dominates, others support

---

### App-Specific Service Colors

These extend the CS brand palette with colors specific to CSQJek's services.
They are intentionally distinct so services are visually identifiable at a glance.

| Token | Hex | Usage |
|-------|-----|-------|
| `.csqPrimary` | `#FF6652` | Legacy primary — being phased toward CS brand tokens |
| `.csqSurface` | `#FFFFFF` | Cards, sheets, inputs |
| `.csqBorder` | `#E8E0DA` | Dividers, outlines |
| `.csqTextPrimary` | `#1C1C2E` | Headlines, labels |
| `.csqTextSecondary` | `#6B7280` | Supporting text |
| `.csqTextTertiary` | `#9CA3AF` | Placeholder, hint text |
| `.csqSuccess` | `#10B981` | Pickup pin, confirmed states |
| `.csqWarning` | `#F59E0B` | Amber badges, CSQ Tank pricing |
| `.csqError` | `#EF4444` | Error states, cancelled status |
| `.csqRideBlue` | `#4F7FFF` | CSQRide tile |
| `.csqGroceryGreen` | `#2AC09A` | CSQMart tile |
| `.csqFoodOrange` | `#FF8C42` | CSQFood tile |
| `.csqExpressPurple` | `#9B6DFF` | CSQExpress branding |
| `.csqTelcoTeal` | `#0EA5E9` | CSQMobile tile |

### Typography — use `AppFont`:

```swift
AppFont.display(22, weight: .bold)   // Screen titles — Gilroy Bold equivalent
AppFont.display(17)                   // Section headers
AppFont.body(15)                      // Body copy — min 11pt per CS accessibility rules
AppFont.body(13)                      // Supporting text
```

> **Font embedding note:** To fully comply with CS brand guidelines, embed Gilroy as a custom
> font in the Xcode project (add .ttf files to Assets, register in Info.plist, update `AppFont`
> to use `Font.custom("Gilroy-Bold", size: X)`). Until embedded, SF Pro is acceptable for demos.

### Spacing — use `AppSpacing`:
`AppSpacing.xs` (4) / `.sm` (8) / `.md` (16) / `.lg` (24) / `.xl` (32)

### Corner Radius — use `AppRadius`:
`AppRadius.sm` (8) / `.md` (12) / `.lg` (16) / `.xl` (24) / `.full` (999)

---

## What Is Intentionally Fake

Do not "fix" these — they are deliberate demo choices:

| Element | Reality | Why |
|---------|---------|-----|
| Map | `Canvas`-drawn grid of roads and blocks | No MapKit dependency needed for demo |
| Driver data | Hardcoded `Driver.sampleDriver` | Stable, looks realistic |
| Nearby cars | Fixed offset positions | Deterministic, no animation drift |
| Location | "Singapore CBD" hardcoded | Demo is set in Singapore |
| Pricing | Static values in `RideOption` | No surge pricing logic needed |
| Ride booking | 1.5s delay then shows sheet | Simulates network round-trip |
| GPS | No `CoreLocation` usage | Avoids permission dialogs during demo |

---

## Phase 1 Ride Flow — Screen Inventory

| Screen | File | Entry Point |
|--------|------|-------------|
| Home | `HomeView.swift` | Root tab 0 |
| Destination Search | `DestinationView.swift` | CSQRide tile tap on Home |
| Pickup Location | `PickupLocationView.swift` | Location selected in Destination |
| Confirm Ride | `ConfirmRideView.swift` | "Confirm Pickup Location" button |
| Driver Found | `RideBookedSheet` in `ConfirmRideView.swift` | "Book CSQRide" button |

### The Demo Script (what to tap during a Contentsquare demo)

**Ride flow:**
1. Launch → **Splash screen** auto-advances (or tap anywhere)
2. **Home** — show Singapore header illustration, service grid, promo carousel, recent activity
3. Tap **CSQRide** tile → Destination screen opens full-screen
4. Tap **Capitol Tower** from recents → navigates to Pickup
5. Drag the pickup pin slightly, tap **Confirm Pickup Location**
6. On Confirm screen, switch between ride options — try **CSQ Tank** and **CSQ Horse** gags
7. Tap **Book CSQRide** → 1.5s loading → Driver Found sheet appears
8. Show **Raj S.** driver card, ETA, live map, call/message buttons
9. Dismiss → back to Home

**Food flow (Phase 3):**
10. Tap **CSQFood** tile on Home → opens Food tab (FoodHomeView)
11. Browse **Featured Today**, **Hawker Picks**, **Free Delivery** sections
12. Tap **Ya Kun Kaya Toast** or **The Coconut Club** — explore Singapore hawker menu
13. Add items → floating cart bar appears → tap to go to Checkout
14. **Place Order** → 1.8s loading → Order Confirmed screen with live tracking steps

**Telco flow (Phase 4):**
15. Tap **CSQMobile** tile on Home → opens TelcoHomeView (full-screen cover)
16. Show current plan card (ValuePlus S$28/mo), data usage bar
17. Browse **Postpaid / Prepaid / SIM-Only** plan tabs
18. Tap a plan card → TelcoPlanDetailView — show features, FAQ, port-in offer
19. Tap **Sign Up for [plan]** CTA — fire `telco_plan_signup_tapped` event

---

## SF Symbols Usage

Target: **iOS 17 / SF Symbols 5**. All symbols below are confirmed available:

**Ride screens:** `car.fill`, `bolt.car.fill`, `mappin.fill`, `location.fill`, `person.fill`, `phone.fill`, `message.fill`, `star.fill`, `checkmark`, `chevron.left`, `chevron.right`, `chevron.down`, `xmark`, `house.fill`, `building.2.fill`, `airplane`, `tram.fill`

**Home/UI:** `magnifyingglass`, `bell.fill`, `location.circle.fill`, `tag.fill`, `creditcard.fill`, `simcard.fill`, `antenna.radiowaves.left.and.right`

**Telco (Phase 4):** `simcard.fill`, `iphone`, `doc.text.fill`, `plus.circle.fill`, `globe`, `chart.bar.fill`, `arrow.up.circle.fill`, `person.2.fill`

When adding a new SF Symbol, verify it exists in SF Symbols 5 app before committing.

---

## Known Issues / Watch Out For

- `LE_SWIFT_VERSION` in project.pbxproj is a typo (should be `SWIFT_VERSION`) — Xcode ignores it, do not "fix" it.
- `GENERATE_INFOPLIST_FILE = YES` and a manual `Info.plist` coexist — Xcode handles this fine on 15+.
- The `MapPlaceholder` Canvas drawing uses hardcoded geometry — acceptable for demo.
- `RideBookedSheet` uses `@Environment(\.dismiss)` — do not wrap it in a `NavigationView`.
- **pbxproj edits:** Never patch with Python `str.replace()` — always rewrite the entire file. Duplicate substring patterns will inject syntax into wrong sections and corrupt the project.

---

## Phase 2 — Grocery (CSQMart)

When Phase 2 begins, the following will be activated:
- `GroceryHomeView` replaces `GroceryComingSoonView`
- `ProductDetailView`, `CartView`, `CheckoutView`, `OrderConfirmationView`
- `CartStore` will be fully wired (exists but dormant in Phase 1)
- Grocery tab badge shows cart item count
- All new screens must follow the CS SDK checklist above before merge

---

## Phase 3 — Food Delivery (CSQEats)

When Phase 3 begins:
- `FoodDeliveryComingSoonView` is replaced with a live browse + order flow
- Restaurant catalog (static data), menu browsing, cart, order confirmation
- Live order tracking using Canvas-drawn map (same pattern as ride map)
- Order history in Profile tab
- CS events: `food_order_placed`, `restaurant_viewed`, `menu_item_added`

---

## Phase 4 — Telco (CSQMobile)

**Brand:** CSQMobile | **Color:** `.csqTelcoTeal` (`#0EA5E9`) | **Icon:** `simcard.fill`

### Full Feature Scope

| Feature | Description | Demo Value |
|---------|-------------|------------|
| **eSIM Activation** | Instant digital SIM — no physical card needed | Digital-first onboarding journey |
| **New Devices** | Browse & finance latest smartphones | Device purchase funnel — high drop-off demo |
| **Postpaid Plans** | 12 & 24-month contracts. From S$18/mo | Plan comparison, upsell journey |
| **SIM-Only Plans** | Month-to-month. Data-only or voice + data | Subscription conversion flow |
| **Prepaid Top-Up** | Add data credit to prepaid SIM in one tap | Repeat-purchase micro-transaction |
| **Data Add-Ons** | Boost data mid-cycle. Day/week packs | Upsell / cross-sell opportunity |
| **International Roaming** | Day-pass roaming across 100+ countries | Travel intent detection |
| **Plan Upgrade** | View current plan, compare, switch with one tap | Retention + upgrade journey |
| **Usage Monitor** | Real-time data, calls, SMS usage tracking | Daily engagement feature |
| **Bill Payment** | Pay bills, autopay, downloadable invoices | Payments funnel |
| **Family Plan** | Up to 5 lines, shared or individual data | Multi-user acquisition |
| **Device Trade-In** | Instant valuation, apply to new device/plan | Circular commerce story |
| **Number Porting** | Bring existing number, IMDA-compliant | Competitor switcher acquisition |

### Phase 4 CS Events (plan ahead)
`telco_esim_started`, `telco_plan_selected`, `telco_device_viewed`, `telco_topup_completed`, `telco_roaming_pack_added`

---

---

## ⚠️ PRODUCT ANALYTICS (HEAP ENGINE) — HOW IT ACTUALLY WORKS IN THIS APP

Heap is the engine that powers Contentsquare Product Analytics. **This app does NOT call any Heap
API directly.** There are zero `Heap.shared.*` calls in the codebase — everything goes through the
unified `CSQ` facade from `import ContentsquareSDK`. The Heap autocapture/core SDKs appear in
`Package.resolved` only as *transitive* dependencies pulled in by `apple-sdk`; you never import or
call them yourself.

> If you are about to write `Heap.shared.startRecording`, `.heapScreenName`, `.heapRedactText`,
> `Heap.shared.track`, `Heap.shared.identify`, or install the `heap-ios-cs-integration-sdk` bridge
> manually — stop. None of that is how this project is wired. Use the `CSQ` equivalents below.

### Data Model (still worth understanding)

The captured data is organized in a hierarchy that drives funnel, journey, and session-replay
analysis:

```
Account
  └── User (anonymous until identified)
        └── Session
              └── Screenview
                    └── Events (autocaptured or manual)
```

- **Users** start anonymous and merge with a known identity when `CSQ.identify()` is called
- **Sessions** contain one or more **Screenviews** (fired via `CSQ.trackScreenview()`)
- **Screenviews** are the container for **Events** — every event belongs to a screenview
- Past anonymous sessions are retroactively linked to the identified user after `identify()` fires

The more precise the screen names and event properties, the better the demo quality.

---

### The CSQ Facade — the only API this app uses

| Task | Actual API in this app |
|------|------------------------|
| Configure | `CSQ.configureProductAnalytics(environmentID:additionalOptions:)` |
| Opt in / start | `CSQ.optIn()` then `CSQ.start()` |
| Screen views | `CSQ.trackScreenview("Screen Name")` in `.onAppear()` |
| Custom events | `CSQ.trackEvent("event_name", properties: [...])` |
| User identity | `CSQ.identify("jeff.lin@demo.com")` |
| User properties | `CSQ.addUserProperties([...])` |
| Sensitive masking | `.csqMaskContents(true)` SwiftUI modifier |
| Session replay / heatmaps / zones | Handled by the Experience Analytics module — no app code |
| Element labeling | `accessibilityIdentifier` — the shared targeting key |

**Manual event API:**
```swift
CSQ.trackEvent("ride_booked", properties: [
    "ride_type": "CSQRide",
    "price": 8.50,
    "eta_minutes": 4
])
```
Property value types supported: `String`, `Bool`, `Double`, `Float`, `Int`, `Int64`, `Int32`, `Int16`, `Int8`.

**User identity API:**
```swift
CSQ.identify("jeff.lin@demo.com")
CSQ.addUserProperties([
    "name":         "Jeff Lin",
    "account_type": "premium",
    "demo_user":    true
])
```

**Rules:**
- `CSQ.identify()` is called once at app launch in `CSQJekApp.init()` (demo persona, hardcoded)
- `"demo_user": true` must always be set so demo sessions can be filtered out in the CS dashboard
- Never use real personal data as identity
- `"market"` is added via `CSQ.addUserProperties` after the user picks a region in `MarketPickerView`

---

### SwiftUI Autocapture — Rules

Once `CSQ.start()` fires, the SDK autocaptures SwiftUI button taps, toggles, NavigationLink taps,
scrolls, and pinch/zoom. Two things to remember:

1. **SwiftUI events carry no view-hierarchy data** — `accessibilityIdentifier` is the *only* stable
   targeting key. Elements without it appear as anonymous touch targets and cannot be named in the
   dashboard.
2. **Screen names come from `CSQ.trackScreenview()`**, called in `.onAppear()` — not from any
   `.heapScreenName` modifier (that modifier is not used in this project).

---

### Sensitive Data — Masking

All content in this demo is fake, so masking is intentionally minimal. The one masking modifier
used is `.csqMaskContents(true)` (see `DestinationView.swift`). Any `TextField` / `SecureField`
added later must have `.csqMaskContents(true)` applied so user-typed input is not captured.

---

## Rules for Making Changes

1. **Never hardcode a color.** Always use a `.csq*` color token from AppTheme.
2. **Never add a network call.** All data comes from static extensions in Models files.
3. **Never install a package** (no SPM, no CocoaPods) without explicit instruction.
4. **Do not touch locked phase files** without explicit instruction to start that phase.
5. **Preserve the navigation architecture.** The `fullScreenCover` + `NavigationLink` chain is intentional.
6. **Keep maps as Canvas.** Do not swap in MapKit — it would require entitlements and API keys.
7. **Test mental model before coding:** for every change, ask "does this break the demo script above?"
8. **pbxproj:** Always rewrite the entire file. Never use Python string replacement on it.
9. **Every new view needs a `CSQ.trackScreenview()` call** — see the CS SDK checklist above.
10. **Every new interactive element needs `.accessibilityIdentifier()`** — no exceptions. The CS SDK cannot label what it cannot identify.
11. **Run the New Screen / Feature Checklist** before considering any view "done".
12. **Respect the data model hierarchy** (account > user > session > screenview > event) — every screen name and event design decision should map cleanly to this structure.
13. **`addUserProperties()` is stateless** — only the last written value persists. Do not use it to accumulate lists.
14. **Apply `.csqMaskContents(true)`** to any field containing real or user-typed input.
15. **Use the `CSQ` facade only.** Do not call `Heap.shared.*` directly or add the Heap/CS bridge SDK manually — Heap is a transitive dependency, not an app-level API.
