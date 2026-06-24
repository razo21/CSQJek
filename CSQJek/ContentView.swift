import SwiftUI
import ContentsquareSDK

// MARK: - Root Tab View

struct ContentView: View {
    @EnvironmentObject var marketConfig: MarketConfig
    @State private var selectedTab: Int = 0

    var body: some View {
        let s = marketConfig.strings
        TabView(selection: $selectedTab) {

            // Tab 0 — Home
            HomeView(selectedTab: $selectedTab)
                .tabItem {
                    Label(s.tabHome, systemImage: selectedTab == 0 ? "house.fill" : "house")
                }
                .tag(0)
                .accessibilityIdentifier("tab_home")

            // Tab 1 — Rides
            RidesView()
                .tabItem {
                    Label(s.tabRides, systemImage: selectedTab == 1 ? "car.fill" : "car")
                }
                .tag(1)
                .accessibilityIdentifier("tab_rides")

            // Tab 2 — CSQMobile
            TelcoHomeView(isPresented: .constant(false))
                .tabItem {
                    Label(s.tabMobile, systemImage: selectedTab == 2 ? "simcard.fill" : "simcard")
                }
                .tag(2)
                .accessibilityIdentifier("tab_mobile")

            // Tab 3 — Food Delivery
            FoodHomeView()
                .tabItem {
                    Label(s.tabFood, systemImage: selectedTab == 3 ? "takeoutbag.and.cup.and.straw.fill" : "takeoutbag.and.cup.and.straw")
                }
                .tag(3)
                .accessibilityIdentifier("tab_food")

            // Tab 4 — Profile
            ProfileView()
                .tabItem {
                    Label(s.tabProfile, systemImage: selectedTab == 4 ? "person.fill" : "person")
                }
                .tag(4)
                .accessibilityIdentifier("tab_profile")
        }
        .accentColor(.csqPrimary)
        .onChange(of: selectedTab) { _, newTab in
            let names = [s.tabHome, s.tabRides, s.tabMobile, s.tabFood, s.tabProfile]
            let name  = newTab < names.count ? names[newTab] : "Unknown"
            CSQ.trackEvent("tab_switched", properties: [
                "tab_name":   name,
                "tab_index":  newTab,
                "market":     marketConfig.market.trackingLabel
            ])
        }
    }
}

// MARK: - Rides Tab

struct RidesView: View {
    @EnvironmentObject var marketConfig: MarketConfig

    var body: some View {
        let s       = marketConfig.strings
        let history = marketConfig.content.rideHistory

        NavigationView {
            ZStack {
                Color.csqBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {

                        ActiveRideBanner()
                            .padding(.horizontal, 16)
                            .padding(.top, 8)

                        VStack(alignment: .leading, spacing: 12) {
                            Text(s.rideRecentTitle)
                                .font(AppFont.display(17))
                                .foregroundColor(.csqTextPrimary)
                                .padding(.horizontal, 16)

                            VStack(spacing: 0) {
                                ForEach(history) { ride in
                                    RideHistoryRow(ride: ride)
                                    if ride.id != history.last?.id {
                                        Divider().padding(.leading, 56)
                                    }
                                }
                            }
                            .background(Color.csqSurface)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
                            .padding(.horizontal, 16)
                        }

                        // Promo banner
                        HStack(spacing: 14) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(s.ridePromoHeadline)
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                Text(s.ridePromoSub)
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.85))
                                Text(s.ridePromoClaim)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.white.opacity(0.2))
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                    .padding(.top, 2)
                            }
                            Spacer()
                            Image(systemName: "car.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.white.opacity(0.2))
                        }
                        .padding(16)
                        .background(
                            LinearGradient(colors: [.csqRideBlue, Color(hex: "#3A6AE8")], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle(s.rideTabTitle)
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                CSQ.trackScreenview("Rides")
            }
        }
    }
}

// MARK: - Active Ride Banner
struct ActiveRideBanner: View {
    @EnvironmentObject var marketConfig: MarketConfig

    var body: some View {
        let s = marketConfig.strings
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.csqSuccess.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: "car.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.csqSuccess)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(s.rideActiveBannerTitle)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.csqTextPrimary)
                Text(s.rideActiveBannerSub)
                    .font(.system(size: 12))
                    .foregroundColor(.csqTextSecondary)
            }
            Spacer()
            Circle()
                .fill(Color.csqSuccess)
                .frame(width: 8, height: 8)
        }
        .padding(14)
        .background(Color.csqSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg)
                .stroke(Color.csqSuccess.opacity(0.3), lineWidth: 1.5)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
    }
}

// RideHistoryItem is now defined in RideModels.swift and populated via MarketContent.

struct RideHistoryRow: View {
    let ride: RideHistoryItem

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.csqRideBlue.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: ride.iconName)
                    .font(.system(size: 16))
                    .foregroundColor(.csqRideBlue)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(ride.destination)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.csqTextPrimary)
                    .lineLimit(1)
                Text("\(ride.rideType) · \(ride.date)")
                    .font(.system(size: 12))
                    .foregroundColor(.csqTextSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(ride.fare)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.csqTextPrimary)
                Text(ride.status)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(ride.statusColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(ride.statusColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Profile View
struct ProfileView: View {
    @EnvironmentObject var marketConfig: MarketConfig

    var body: some View {
        let s = marketConfig.strings
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {

                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.csqPrimary, .csqPrimaryDark], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 100, height: 100)
                        Text(marketConfig.strings.homeUserAvatarInitials)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .shadow(color: Color.csqPrimary.opacity(0.35), radius: 16, x: 0, y: 6)
                    .padding(.top, 24)
                    .accessibilityIdentifier("profile_user_avatar")
                    .accessibilityLabel("User avatar — \(marketConfig.strings.profileUserName)")

                    VStack(spacing: 4) {
                        Text(marketConfig.strings.profileUserName)
                            .font(AppFont.display(22))
                            .foregroundColor(.csqTextPrimary)
                        Text(marketConfig.strings.profileUserEmail)
                            .font(AppFont.body(14))
                            .foregroundColor(.csqTextSecondary)
                    }

                    HStack(spacing: 0) {
                        StatPill(value: "4.92", label: s.profileRating,     icon: "star.fill")
                        Divider().frame(height: 40)
                        StatPill(value: "148",  label: s.profileRidesCount, icon: "car.fill")
                        Divider().frame(height: 40)
                        StatPill(value: marketConfig.market.formatPrice(1204), label: s.profileSaved, icon: "tag.fill")
                    }
                    .background(Color.csqSurface)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                    .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
                    .padding(.horizontal, 16)

                    ProfileSection(title: s.profileSectionAccount) {
                        ProfileRow(icon: "person.fill",    label: s.profilePersonalInfo,   color: .csqPrimary)
                            .accessibilityIdentifier("profile_row_personal_info")
                        ProfileRow(icon: "creditcard.fill",label: s.profilePaymentMethods, color: .csqRideBlue)
                            .accessibilityIdentifier("profile_row_payment_methods")
                        ProfileRow(icon: "mappin.fill",    label: s.profileSavedAddresses, color: .csqSuccess)
                            .accessibilityIdentifier("profile_row_saved_addresses")
                    }

                    ProfileSection(title: s.profileSectionRidePrefs) {
                        ProfileRow(icon: "car.fill",    label: s.profileDefaultRideType, color: .csqRideBlue)
                            .accessibilityIdentifier("profile_row_default_ride_type")
                        ProfileRow(icon: "music.note",  label: s.profileMusicPrefs,      color: .csqExpressPurple)
                            .accessibilityIdentifier("profile_row_music_preferences")
                        ProfileRow(icon: "star.fill",   label: s.profileMyReviews,       color: .csqWarning)
                            .accessibilityIdentifier("profile_row_my_reviews")
                    }

                    ProfileSection(title: s.profileSectionSupport) {
                        ProfileRow(icon: "bell.fill",                 label: s.profileNotifications,   color: .csqWarning)
                            .accessibilityIdentifier("profile_row_notifications")
                        ProfileRow(icon: "lock.fill",                 label: s.profilePrivacySecurity, color: .csqExpressPurple)
                            .accessibilityIdentifier("profile_row_privacy_security")
                        ProfileRow(icon: "questionmark.circle.fill",  label: s.profileHelpSupport,     color: .csqInfo)
                            .accessibilityIdentifier("profile_row_help_support")
                    }

                    // MARK: - Demo Tools (fake API errors for Contentsquare)
                    ProfileSection(title: "Demo Tools") {
                        Button {
                            DemoErrorSimulator.fireRandom(
                                screen: "Profile",
                                market: marketConfig.market.trackingLabel
                            )
                        } label: {
                            DemoToolRow(icon: "exclamationmark.triangle.fill",
                                        label: "Simulate API Error (random)",
                                        color: .csqError)
                        }
                        .accessibilityIdentifier("profile_btn_simulate_api_error")
                        .accessibilityLabel("Simulate a random API error")

                        Button {
                            DemoErrorSimulator.fire(
                                DemoErrorSimulator.catalogue[1],   // 402 payment failure
                                screen: "Profile",
                                market: marketConfig.market.trackingLabel
                            )
                        } label: {
                            DemoToolRow(icon: "creditcard.fill",
                                        label: "Simulate Payment Failure (402)",
                                        color: .csqWarning)
                        }
                        .accessibilityIdentifier("profile_btn_simulate_payment_error")
                        .accessibilityLabel("Simulate a payment failure API error")
                    }

                    Button {} label: {
                        Text(s.profileSignOut)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.csqError)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.csqError.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                    }
                    .accessibilityIdentifier("profile_btn_sign_out")
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            }
            .background(Color.csqBackground.ignoresSafeArea())
            .navigationTitle(s.profileTitle)
            .navigationBarTitleDisplayMode(.large)
            .onAppear { CSQ.trackScreenview("Profile") }
        }
    }
}

// MARK: - Demo API Error Simulator
// Demo-only. The app has no real network layer (see CLAUDE.md), so we fabricate
// API failures and report them to Contentsquare:
//   1. Product Analytics — a custom `api_error` event (works on any plan). ACTIVE.
//   2. Experience Analytics Error Analysis (network metric) — currently DISABLED
//      because the API type isn't exported by the pinned SDK 1.6.2 (see fire()).
// Nothing here performs a real network request. Every value is fake.
enum DemoErrorSimulator {

    struct FakeError {
        let endpoint: String
        let method: String
        let status: Int
        let message: String
    }

    static let catalogue: [FakeError] = [
        FakeError(endpoint: "https://api.csqjek.com/v1/rides/book",      method: "POST", status: 500, message: "Internal Server Error"),
        FakeError(endpoint: "https://api.csqjek.com/v1/payments/charge", method: "POST", status: 402, message: "Payment Required"),
        FakeError(endpoint: "https://api.csqjek.com/v1/food/checkout",   method: "POST", status: 503, message: "Service Unavailable"),
        FakeError(endpoint: "https://api.csqjek.com/v1/auth/session",    method: "GET",  status: 401, message: "Unauthorized"),
        FakeError(endpoint: "https://api.csqjek.com/v1/promo/validate",  method: "GET",  status: 404, message: "Not Found")
    ]

    /// Fire a fake API error into both Product Analytics and Experience Analytics.
    static func fire(_ error: FakeError, screen: String, market: String) {
        // 1) Product Analytics custom event.
        CSQ.trackEvent("api_error", properties: [
            "endpoint":    error.endpoint,
            "http_method": error.method,
            "status_code": error.status,
            "message":     error.message,
            "screen":      screen,
            "market":      market,
            "simulated":   true
        ])

        // 2) Experience Analytics — Error Analysis network metric.
        // DISABLED: the `HTTPMetric` API is not exported by ContentsquareSDK
        // 1.6.2 (the pinned version), so it does not compile here. The PA event
        // above is what "registered in PA" needs. To populate the EA Error
        // Analysis dashboard, upgrade the SDK, re-enable a verified network-metric
        // call, and ensure the Experience Monitoring add-on is enabled.
    }

    static func fireRandom(screen: String, market: String) {
        fire(catalogue.randomElement()!, screen: screen, market: market)
    }
}

// MARK: - Profile sub-components
struct StatPill: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundColor(.csqPrimary)
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.csqTextPrimary)
            }
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.csqTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}

struct ProfileSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.csqTextTertiary)
                .tracking(0.5)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                content
            }
            .background(Color.csqSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
        }
        .padding(.horizontal, 16)
    }
}

struct ProfileRow: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(color)
            }
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.csqTextPrimary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.csqTextTertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }
}

// Tappable row for the demo-tools section (no chevron; trailing bolt instead).
struct DemoToolRow: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(color)
            }
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.csqTextPrimary)
            Spacer()
            Image(systemName: "bolt.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .contentShape(Rectangle())
    }
}
