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

        // MARK: - Demo User Identity (varied per session)
        // Pick a random persona each launch so Contentsquare sees a VARIETY of
        // users. This lets the cohort segments (account_type, loyalty_tier,
        // is_new_user, signup_channel) populate multiple buckets across funnels
        // and journeys instead of a single one. Every persona is fake and carries
        // demo_user:true so demo traffic stays filterable. ("market" is added
        // after the user picks a region in MarketPickerView.)
        let persona = CSQJekApp.demoPersonas.randomElement() ?? CSQJekApp.demoPersonas[0]
        CSQ.identify(persona.email)
        CSQ.addUserProperties([
            "name":            persona.name,
            "account_type":    persona.accountType,
            "demo_user":       true,
            "is_new_user":     persona.isNewUser,
            "tenure_days":     persona.tenureDays,
            "lifetime_orders": persona.lifetimeOrders,
            "loyalty_tier":    persona.loyaltyTier,
            "signup_channel":  persona.signupChannel
        ])
    }

    // MARK: - Demo Persona Roster
    // A spread of fake users so CS segmentation shows multiple buckets instead of
    // one. A persona is chosen at random each launch (see init). All are fictitious
    // and tagged demo_user:true. Market is chosen separately in MarketPickerView,
    // so any persona can run in any market.
    private struct DemoPersona {
        let email: String
        let name: String
        let accountType: String      // "premium" | "standard"
        let isNewUser: Bool
        let tenureDays: Int
        let lifetimeOrders: Int
        let loyaltyTier: String      // "platinum" | "gold" | "silver" | "bronze" | "none"
        let signupChannel: String    // "referral" | "organic" | "paid_ad" | "partner"
    }

    private static let demoPersonas: [DemoPersona] = [
        DemoPersona(email: "jeff.lin@demo.com",     name: "Jeff Lin",     accountType: "premium",  isNewUser: false, tenureDays: 487, lifetimeOrders: 213, loyaltyTier: "gold",     signupChannel: "referral"),
        DemoPersona(email: "mei.tan@demo.com",      name: "Mei Tan",      accountType: "standard", isNewUser: false, tenureDays: 192, lifetimeOrders: 64,  loyaltyTier: "silver",   signupChannel: "organic"),
        DemoPersona(email: "arjun.rao@demo.com",    name: "Arjun Rao",    accountType: "standard", isNewUser: true,  tenureDays: 3,   lifetimeOrders: 1,   loyaltyTier: "bronze",   signupChannel: "paid_ad"),
        DemoPersona(email: "sofia.cruz@demo.com",   name: "Sofia Cruz",   accountType: "premium",  isNewUser: false, tenureDays: 921, lifetimeOrders: 540, loyaltyTier: "platinum", signupChannel: "referral"),
        DemoPersona(email: "ken.watanabe@demo.com", name: "Ken Watanabe", accountType: "standard", isNewUser: true,  tenureDays: 0,   lifetimeOrders: 0,   loyaltyTier: "none",     signupChannel: "organic"),
        DemoPersona(email: "luca.bianchi@demo.com", name: "Luca Bianchi", accountType: "premium",  isNewUser: false, tenureDays: 365, lifetimeOrders: 158, loyaltyTier: "gold",     signupChannel: "partner")
    ]

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
