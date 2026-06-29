import SwiftUI
import ContentsquareSDK

// MARK: - App Entry Point
// CartStore is intentionally NOT injected at the app root in Phase 1.
// It is scoped only to the grocery subtree (Phase 2).
//
// Gating (market picker → splash → app) lives in RootView as plain View @State,
// NOT as App-level @State (SwiftUI does not persist that dependably) and NOT as
// @Published on MarketConfig (whose changes re-evaluate the whole tree and were
// replaying the splash's opacity transition, making it flicker on the home page).

@main
struct CSQJekApp: App {

    init() {
        // MARK: - Contentsquare SDK Initialization
        // Verbose logging so Session Replay startup + the replay link show up
        // in the Xcode console. Lower to .warn or .none for a quiet build.
        CSQ.debug.logLevel = .debug

        CSQ.configureProductAnalytics(
            environmentID: "4140621035",
            additionalOptions: [.enableUIKitAutocapture: true]
        )
        CSQ.optIn()
        CSQ.start()

        // MARK: - Session Replay link logging (DEMO)
        CSQ.metadata.onChange { metadata in
            if let url = metadata.sessionReplayURL {
                print("📹 CSQ Session Replay URL: \(url)")
            }
        }

        // MARK: - Session Replay Masking (DEMO ONLY)
        // The CSQ SDK masks ALL views, text, images, and inputs by default,
        // which makes Session Replay look blacked-out. Every piece of data in
        // this app is fake, so we unmask globally to make replays legible.
        // Do NOT ship this in an app with real user data.
        CSQ.setDefaultMasking(false)
        CSQ.maskTexts(false)
        CSQ.maskImages(false)
        CSQ.maskTextInputs(false)

        // MARK: - Demo User Identity
        CSQ.identify("jeff.lin@demo.com")
        CSQ.addUserProperties([
            "name":            "Jeff Lin",
            "account_type":    "premium",
            "demo_user":       true,
            // Cohort dimensions — let every funnel / journey segment by user type
            // (new vs returning, tenure, order volume, loyalty, acquisition channel).
            "is_new_user":     false,
            "tenure_days":     487,
            "lifetime_orders": 213,
            "loyalty_tier":    "gold",
            "signup_channel":  "referral"
            // "market" is set after the user picks a region in MarketPickerView
        ])
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

// MARK: - Root Coordinator
// Owns MarketConfig and the one-time flow flags. View @State here is stable
// across re-renders, so the splash dismisses once and never flickers back.

struct RootView: View {
    @StateObject private var marketConfig = MarketConfig()
    @State private var hasSelectedMarket = false
    @State private var showSplash        = true

    var body: some View {
        ZStack {
            if hasSelectedMarket {
                // Main app — receives MarketConfig through the environment
                ContentView()
                    .environmentObject(marketConfig)

                if showSplash {
                    // No .transition here: an opacity transition on this branch
                    // was being replayed by parent re-renders and flickering.
                    SplashView(isVisible: $showSplash)
                        .environmentObject(marketConfig)
                        .zIndex(1)
                }
            } else {
                // Pre-splash region picker
                MarketPickerView(marketConfig: marketConfig) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        hasSelectedMarket = true
                    }
                }
                .transition(.opacity)
            }
        }
        .preferredColorScheme(.light)
    }
}
