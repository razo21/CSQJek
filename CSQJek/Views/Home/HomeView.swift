import SwiftUI
import ContentsquareSDK

// MARK: - Static service grid data (market-agnostic — names/icons don't change)
// imageName: Xcode asset name for the custom icon PNG.
// icon:      SF Symbol fallback if asset is missing.
private let homeServices: [(name: String, imageName: String, icon: String, color: Color, isActive: Bool)] = [
    ("CSQRide",        "IconRide",        "car.fill",               Color.csqRideBlue,     true),
    ("CSQMart",        "IconMart",        "cart.fill",              Color.csqMartGreen,    true),
    ("CSQFood",        "IconFood",        "fork.knife",             Color.csqFoodOrange,   true),
    ("CSQDragonDance", "IconDragonDance", "figure.dance",           Color(hex: "#DC2626"), false),
    ("CSQOutfits",     "IconOutfits",     "tshirt.fill",            Color(hex: "#9333EA"), false),
    ("CSQAir",         "IconAir",         "airplane",               Color(hex: "#1B3FAB"), true),
    ("CSQCash",        "IconCash",        "dollarsign.circle.fill", Color.csqWarning,      true),
    ("CSQMobile",      "IconMobile",      "simcard.fill",           Color.csqTelcoTeal,    true),
]

// MARK: - CS Accessibility ID Registry
// Format: [screen]_[element_type]_[descriptor]
// All identifiers are autocaptured by the Contentsquare Product Analytics SDK.
// Centralised here so they remain stable across refactors.
private enum HomeAccessID {
    // Header
    static let locationSelector = "home_location_selector"
    static let notificationBell = "home_notification_bell"
    static let userAvatar       = "home_user_avatar"
    static let searchBar        = "home_search_bar"
    // Service grid
    static func serviceTile(_ name: String) -> String {
        "home_tile_\(name.lowercased().replacingOccurrences(of: " ", with: "_"))"
    }
    // Promos
    static let promoScroll      = "home_promo_scroll"
    static func promoCard(_ i: Int) -> String { "home_promo_card_\(i)" }
    // Rewards
    static let rewardsCard      = "home_rewards_card"
    static let rewardsBtnRedeem = "home_rewards_btn_redeem"
    // Eats
    static let eatsScroll       = "home_eats_scroll"
    static func eatsCard(_ i: Int) -> String { "home_eats_card_\(i)" }
    static let eatsBtnSeeAll    = "home_eats_btn_see_all"
    // Deals
    static let dealsScroll      = "home_deals_scroll"
    static func dealCard(_ i: Int) -> String { "home_deals_card_\(i)" }
    static let dealsBtnSeeAll   = "home_deals_btn_see_all"
    // Quick actions
    static let quickBtnBookRide     = "home_quick_btn_book_ride"
    static let quickBtnSchedule     = "home_quick_btn_schedule"
    static let quickBtnSendMoney    = "home_quick_btn_send_money"
    static let quickBtnScanPay      = "home_quick_btn_scan_pay"
    // Recent activity
    static let activityBtnSeeAll    = "home_activity_btn_see_all"
    static func activityRow(_ i: Int) -> String { "home_activity_row_\(i)" }
    // Safety
    static let safetyCard           = "home_safety_card"
    static let safetyBtnSOS         = "home_safety_btn_sos"
    static let safetyBtnShareTrip   = "home_safety_btn_share_trip"
}

// MARK: - HomeView

struct HomeView: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var marketConfig: MarketConfig
    // One full-screen flow at a time. Stacking multiple `.fullScreenCover` modifiers
    // on a single view conflicts in SwiftUI (a flow could open then immediately bounce
    // back to Home). Driven by a single item-based cover instead.
    enum HomeFlow: String, Identifiable { case ride, telco, mart, air, cash; var id: String { rawValue } }
    @State private var activeFlow: HomeFlow?
    @StateObject private var cartStore = CartStore()
    @State private var promoIndex      = 0

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        return marketConfig.strings.homeGreeting(name: marketConfig.strings.homeUserDisplayName, hour: hour)
    }

    // Maps a child view's `isPresented` Bool back onto the single activeFlow item.
    private func flowBinding(_ flow: HomeFlow) -> Binding<Bool> {
        Binding(get: { activeFlow == flow }, set: { if !$0 { activeFlow = nil } })
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                headerSection
                    .padding(.bottom, 20)

                VStack(spacing: 24) {

                    serviceGrid
                        .padding(.horizontal, 16)

                    promoCarousel

                    if marketConfig.market == .singapore {
                        krakakaoPartnerSection
                            .padding(.horizontal, 16)
                    }

                    rewardsSection
                        .padding(.horizontal, 16)

                    nearbyEatsSection

                    dealsSection

                    quickActionsSection
                        .padding(.horizontal, 16)

                    recentActivitySection
                        .padding(.horizontal, 16)

                    safetySection
                        .padding(.horizontal, 16)
                        .padding(.bottom, 36)
                }
            }
        }
        .background(Color.csOffWhite.ignoresSafeArea())
        .onAppear {
            CSQ.trackScreenview("Home")
        }
        .overlay(alignment: .bottomTrailing) {
            LiveAgentButton(screen: "Home")
        }
        .fullScreenCover(item: $activeFlow) { flow in
            switch flow {
            case .ride:
                DestinationView()
                    .environmentObject(marketConfig)
            case .telco:
                TelcoHomeView(isPresented: flowBinding(.telco), showCloseButton: true)
                    .environmentObject(marketConfig)
            case .mart:
                GroceryHomeView(isPresented: flowBinding(.mart))
                    .environmentObject(cartStore)
                    .environmentObject(marketConfig)
            case .air:
                CSQAirHomeView(isPresented: flowBinding(.air))
                    .environmentObject(marketConfig)
            case .cash:
                CSQCashHomeView(isPresented: flowBinding(.cash))
                    .environmentObject(marketConfig)
            }
        }
    }

    // MARK: - Header
    var headerSection: some View {
        let s = marketConfig.strings
        return ZStack(alignment: .bottom) {
            GeometryReader { geo in
                Group {
                    // Per-market header art with a graceful fallback: a market shows
                    // "HeaderBackground<Flag>" if that asset exists, else the generic
                    // Singapore header. A new market needs zero edits here — just add
                    // its asset (or let it fall back). Tokyo keeps its dedicated asset.
                    switch marketConfig.market {
                    case .tokyo:
                        Image("HeaderBackgroundTokyo")
                            .resizable()
                            .scaledToFill()
                    default:
                        Image(UIImage(named: "HeaderBackground\(marketConfig.market.profile.flagCode)") != nil
                              ? "HeaderBackground\(marketConfig.market.profile.flagCode)"
                              : "HeaderBackground")
                            .resizable()
                            .scaledToFill()
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
                .allowsHitTesting(false)
            }
            .frame(height: 240)
            .ignoresSafeArea(edges: .top)

            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.9))
                            Text(s.homeLocationLabel)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.95))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 1)
                        .accessibilityIdentifier(HomeAccessID.locationSelector)

                        Text(greeting)
                            .font(.system(size: 21, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.55), radius: 5, x: 0, y: 2)
                            .accessibilityIdentifier("home_greeting_text")

                        HStack(spacing: 5) {
                            Image(systemName: "sun.max.fill")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(Color(hex: "#FFD580"))
                            Text(s.homeWeather)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.32))
                        .clipShape(Capsule())
                    }
                    Spacer()
                    HStack(spacing: 12) {
                        Button {} label: {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 1)
                                Circle()
                                    .fill(Color.csqWarning)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 2, y: -2)
                            }
                        }
                        .accessibilityIdentifier(HomeAccessID.notificationBell)

                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.38))
                                .frame(width: 38, height: 38)
                            Text(marketConfig.strings.homeUserAvatarInitials)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .accessibilityIdentifier(HomeAccessID.userAvatar)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 22)
                .padding(.bottom, 16)

                Button { activeFlow = .ride } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.csqTextTertiary)
                        Text(s.homeSearchPlaceholder)
                            .font(.system(size: 15))
                            .foregroundColor(.csqTextTertiary)
                        Spacer()
                        Image(systemName: "mic.fill")
                            .foregroundColor(.csqPrimary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 13)
                    .background(Color.csqSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                }
                .accessibilityIdentifier(HomeAccessID.searchBar)
                .padding(.horizontal, 16)
                .padding(.bottom, -20)
            }
        }
        .padding(.bottom, 20)
    }

    // MARK: - Service Grid
    var serviceGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.csBrandRed)
                    .frame(width: 3, height: 18)
                    .clipShape(Capsule())
                Text("  \(marketConfig.strings.homeSectionServices)")
                    .font(AppFont.display(17))
                    .foregroundColor(.csDeepNavy)
            }

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4),
                spacing: 16
            ) {
                ForEach(homeServices, id: \.name) { service in
                    ServiceTile(
                        name: service.name,
                        imageName: service.imageName,
                        icon: service.icon,
                        color: service.color,
                        isActive: service.isActive,
                        action: {
                            CSQ.trackEvent("service_tile_tapped", properties: [
                                "service_name": service.name,
                                "is_active":    service.isActive
                            ])
                            switch service.name {
                            case "CSQRide":   activeFlow = .ride
                            case "CSQFood":   selectedTab = 3
                            case "CSQMobile": selectedTab = 2
                            case "CSQMart":   activeFlow = .mart
                            case "CSQAir":    activeFlow = .air
                            case "CSQCash":   activeFlow = .cash
                            default: break
                            }
                        }
                    )
                    .accessibilityIdentifier(HomeAccessID.serviceTile(service.name))
                    .accessibilityLabel("\(service.name)\(service.isActive ? "" : " — coming soon")")
                }
            }
        }
        .padding(16)
        .background(Color.csqSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg)
                .stroke(Color.csDeepNavy.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Color.csDeepNavy.opacity(0.08), radius: 12, x: 0, y: 4)
    }

    // MARK: - Promo Carousel
    var promoCarousel: some View {
        let promos = marketConfig.content.promos
        return VStack(spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(promos.enumerated()), id: \.offset) { index, promo in
                        PromoBanner(
                            headline:  promo.headline,
                            subtext:   promo.sub,
                            color:     promo.color,
                            icon:      promo.icon,
                            imageName: promo.imageName,
                            logoName:  promo.logoName,
                            claimLabel: marketConfig.strings.homePromoClaimOffer
                        )
                        .containerRelativeFrame(.horizontal, count: 1, spacing: 32)
                        .accessibilityIdentifier(HomeAccessID.promoCard(index))
                        .accessibilityLabel("Promo \(index + 1): \(promo.headline)")
                        .onTapGesture {
                            CSQ.trackEvent("promo_tapped", properties: [
                                "promo_index":    index,
                                "promo_headline": promo.headline,
                                "market":         marketConfig.market.trackingLabel
                            ])
                        }
                    }
                }
                .scrollTargetLayout()
            }
            .contentMargins(.horizontal, 16, for: .scrollContent)
            .scrollTargetBehavior(.viewAligned)
            .frame(height: 118)
            .accessibilityIdentifier(HomeAccessID.promoScroll)

            HStack(spacing: 6) {
                ForEach(0..<promos.count, id: \.self) { _ in
                    Capsule()
                        .fill(Color.csqBorder)
                        .frame(width: 6, height: 6)
                }
            }
        }
    }

    // MARK: - Krakakoa Featured Partner
    var krakakaoPartnerSection: some View {
        KrakakoaPartnerBanner()
            .accessibilityIdentifier("home_krakakoa_partner_banner")
            .accessibilityLabel("Featured partner: Krakakoa — 35% off for Mastercard holders")
            .onTapGesture {
                CSQ.trackEvent("partner_banner_tapped", properties: [
                    "partner":     "Krakakoa",
                    "offer":       "35_percent_off",
                    "payment_req": "Mastercard"
                ])
            }
    }

    // MARK: - CSQRewards
    var rewardsSection: some View {
        Button {} label: {
            HStack(spacing: 16) {
                // Points ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.25), lineWidth: 4)
                        .frame(width: 56, height: 56)
                    Circle()
                        .trim(from: 0, to: 0.78)
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 56, height: 56)
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 0) {
                        Text("2,840")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text(marketConfig.strings.homeRewardsPtsLabel)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(marketConfig.strings.homeRewardsName)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text(marketConfig.strings.homeRewardsTierGold)
                            .font(.system(size: 9, weight: .heavy))
                            .foregroundColor(Color.csAmber)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    Text(marketConfig.strings.homeRewardsProgress)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.85))

                    // Progress bar
                    GeometryReader { g in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white.opacity(0.25))
                                .frame(height: 5)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white)
                                .frame(width: g.size.width * 0.78, height: 5)
                        }
                    }
                    .frame(height: 5)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(16)
            .background(
                // CS Electric Blue (#3640E8) → CS Deep Navy (#1C1263) — official brand gradient
                LinearGradient(
                    colors: [Color.csElectricBlue, Color.csDeepNavy],
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
            .shadow(color: Color.csElectricBlue.opacity(0.35), radius: 12, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(HomeAccessID.rewardsCard)
        .accessibilityLabel("CSQRewards — Gold tier, 2840 points, 160 points to next reward")
    }

    // MARK: - Nearby Eats (CSQFood teaser)
    var nearbyEatsSection: some View {
        let s    = marketConfig.strings
        let eats = marketConfig.content.nearbyRestaurants
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.csBrandRed)
                            .frame(width: 3, height: 18)
                            .clipShape(Capsule())
                        Text("  \(s.homeSectionFavourites)")
                            .font(AppFont.display(17))
                            .foregroundColor(.csDeepNavy)
                    }
                    Text(s.homeFavouritesSubtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.csqTextSecondary)
                        .padding(.leading, 11)
                }
                Spacer()
                Button(s.homeSectionSeeAll) { selectedTab = 3 }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.csBrandRed)
                    .accessibilityIdentifier(HomeAccessID.eatsBtnSeeAll)
            }
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(eats.enumerated()), id: \.offset) { index, eat in
                        Button(action: { selectedTab = 3 }) {
                            EatsCard(eat: eat, freeLabel: s.homeEatsDeliveryFree)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier(HomeAccessID.eatsCard(index))
                        .accessibilityLabel("\(eat.name) — \(eat.cuisine), rated \(eat.rating), \(eat.deliveryTime) delivery")
                    }
                }
                .padding(.horizontal, 16)
            }
            .accessibilityIdentifier(HomeAccessID.eatsScroll)
        }
    }

    // MARK: - Deals
    var dealsSection: some View {
        let s     = marketConfig.strings
        let deals = marketConfig.content.deals
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.csBrandRed)
                        .frame(width: 3, height: 18)
                        .clipShape(Capsule())
                    Text("  \(s.homeSectionDeals)")
                        .font(AppFont.display(17))
                        .foregroundColor(.csDeepNavy)
                }
                Spacer()
                Button(s.homeSectionSeeAll) {}
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.csBrandRed)
                    .accessibilityIdentifier(HomeAccessID.dealsBtnSeeAll)
            }
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(deals.enumerated()), id: \.offset) { index, deal in
                        DealCard(deal: deal)
                            .accessibilityIdentifier(HomeAccessID.dealCard(index))
                            .accessibilityLabel("\(deal.title) — \(deal.merchant), expires \(deal.expiry)")
                    }
                }
                .padding(.horizontal, 16)
            }
            .accessibilityIdentifier(HomeAccessID.dealsScroll)
        }
    }

    // MARK: - Quick Actions
    var quickActionsSection: some View {
        let s = marketConfig.strings
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.csBrandRed)
                    .frame(width: 3, height: 18)
                    .clipShape(Capsule())
                Text("  \(s.homeSectionQuickActions)")
                    .font(AppFont.display(17))
                    .foregroundColor(.csDeepNavy)
            }

            let cols = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
            LazyVGrid(columns: cols, spacing: 12) {
                QuickActionCard(title: s.homeQuickBookRide,    subtitle: s.homeQuickBookRideSub,  icon: "car.fill",                   color: .csqRideBlue,     action: { activeFlow = .ride })
                    .accessibilityIdentifier(HomeAccessID.quickBtnBookRide)

                QuickActionCard(title: s.homeQuickSchedule,   subtitle: s.homeQuickScheduleSub,  icon: "calendar",                   color: .csqExpressPurple,action: { activeFlow = .ride })
                    .accessibilityIdentifier(HomeAccessID.quickBtnSchedule)

                QuickActionCard(title: s.homeQuickSendMoney,  subtitle: s.homeQuickSendMoneySub, icon: "arrow.up.right.circle.fill", color: .csqWarning,      action: {})
                    .accessibilityIdentifier(HomeAccessID.quickBtnSendMoney)

                QuickActionCard(title: s.homeQuickScanPay,    subtitle: s.homeQuickScanPaySub,   icon: "qrcode.viewfinder",          color: .csqGroceryGreen, action: {})
                    .accessibilityIdentifier(HomeAccessID.quickBtnScanPay)
            }
        }
    }

    // MARK: - Recent Activity
    var recentActivitySection: some View {
        let s        = marketConfig.strings
        let activity = marketConfig.content.recentActivity
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.csBrandRed)
                        .frame(width: 3, height: 18)
                        .clipShape(Capsule())
                    Text("  \(s.homeSectionRecentActivity)")
                        .font(AppFont.display(17))
                        .foregroundColor(.csDeepNavy)
                }
                Spacer()
                Button(s.homeSectionSeeAll) {}
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.csBrandRed)
                    .accessibilityIdentifier(HomeAccessID.activityBtnSeeAll)
            }

            VStack(spacing: 0) {
                ForEach(Array(activity.enumerated()), id: \.offset) { index, item in
                    RecentActivityRow(
                        icon: item.icon, iconColor: item.iconColor,
                        title: item.title, subtitle: item.subtitle, status: item.status,
                        isError: item.isError
                    )
                    .accessibilityIdentifier(HomeAccessID.activityRow(index))

                    if index < activity.count - 1 {
                        Divider().padding(.leading, 56)
                    }
                }
            }
            .background(Color.csqSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
        }
    }

    // MARK: - Safety
    var safetySection: some View {
        let s = marketConfig.strings
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.csBrandRed)
                    .frame(width: 3, height: 18)
                    .clipShape(Capsule())
                Text("  \(s.homeSectionSafety)")
                    .font(AppFont.display(17))
                    .foregroundColor(.csDeepNavy)
            }

            HStack(spacing: 12) {
                Button {} label: {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle().fill(Color.red.opacity(0.12)).frame(width: 40, height: 40)
                            Image(systemName: "sos.circle.fill").font(.system(size: 22)).foregroundColor(.red)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(s.homeSafetySOSTitle).font(.system(size: 13, weight: .bold)).foregroundColor(.csqTextPrimary)
                            Text(s.homeSafetySOSSub).font(.system(size: 11)).foregroundColor(.csqTextSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundColor(.csqTextTertiary)
                    }
                    .padding(14)
                    .background(Color.csqSurface)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                    .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(HomeAccessID.safetyBtnSOS)

                Button {} label: {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle().fill(Color.csqRideBlue.opacity(0.12)).frame(width: 40, height: 40)
                            Image(systemName: "person.wave.2.fill").font(.system(size: 18)).foregroundColor(.csqRideBlue)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(s.homeSafetyShareTitle).font(.system(size: 13, weight: .bold)).foregroundColor(.csqTextPrimary)
                            Text(s.homeSafetyShareSub).font(.system(size: 11)).foregroundColor(.csqTextSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundColor(.csqTextTertiary)
                    }
                    .padding(14)
                    .background(Color.csqSurface)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                    .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(HomeAccessID.safetyBtnShareTrip)
            }
        }
        .accessibilityIdentifier(HomeAccessID.safetyCard)
    }
}

// MARK: - Service Tile
struct ServiceTile: View {
    @EnvironmentObject var marketConfig: MarketConfig
    let name: String
    let imageName: String
    let icon: String
    let color: Color
    var isActive: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    // Solid colour tile — Monzo/Revolut card style
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(isActive ? color : Color(.systemGray4))
                        .frame(width: 56, height: 56)
                        .shadow(
                            color: (isActive ? color : Color.black).opacity(isActive ? 0.28 : 0.06),
                            radius: 6, x: 0, y: 3
                        )

                    // SF Symbol — white on solid bg, high contrast
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(isActive ? .white : Color(.systemGray2))
                        .frame(width: 56, height: 56)

                    // "SOON" / "近日" badge — CS coral pill, top-trailing
                    if !isActive {
                        Text(marketConfig.strings.homeServicesSoonBadge)
                            .font(.system(size: 7, weight: .black))
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.csBrandRed)
                            .clipShape(Capsule())
                            .offset(x: 6, y: -6)
                    }
                }
                Text(marketConfig.strings.homeServiceDisplayName(name))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(isActive ? .csqTextPrimary : .csqTextTertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .buttonStyle(.plain)
        .disabled(!isActive)
    }
}

// MARK: - Krakakoa Partner Banner
// Full-width featured partner card — lives outside the promo carousel,
// sits between promoCarousel and rewardsSection for maximum visibility.
struct KrakakoaPartnerBanner: View {

    private let bgColor = Color(hex: "#1C0800")  // deep chocolate, matches Krakakoa black

    var body: some View {
        ZStack(alignment: .bottomLeading) {

            // Photo background
            if let uiImg = UIImage(named: "PromoKrakakoa") {
                Image(uiImage: uiImg)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .clipped()
            } else {
                // Placeholder until photo is installed
                LinearGradient(
                    colors: [Color(hex: "#3D1200"), bgColor],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .frame(height: 200)
            }

            // Dark vignette — heavier at bottom so text always pops
            LinearGradient(
                stops: [
                    .init(color: .clear,               location: 0.0),
                    .init(color: bgColor.opacity(0.55), location: 0.45),
                    .init(color: bgColor.opacity(0.95), location: 1.0),
                ],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 200)

            // Content
            VStack(alignment: .leading, spacing: 8) {

                // "FEATURED PARTNER" label
                Text("FEATURED PARTNER")
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(.white.opacity(0.55))
                    .tracking(1.8)

                // Krakakoa logo — white pill ensures legibility on any dark background
                if let logoImg = UIImage(named: "KrakakoaLogo") {
                    Image(uiImage: logoImg)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 22)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }

                // Offer headline
                Text("35% off for Mastercard holders")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                // Sub copy
                Text("Premium Indonesian artisan dark chocolate — today only")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.8))

                // CTA row
                HStack(spacing: 10) {
                    // Mastercard badge
                    HStack(spacing: 5) {
                        ZStack {
                            Circle().fill(Color(hex: "#EB001B")).frame(width: 12, height: 12).offset(x: -3)
                            Circle().fill(Color(hex: "#F79E1B").opacity(0.9)).frame(width: 12, height: 12).offset(x: 3)
                        }
                        .frame(width: 22, height: 16)
                        Text("Mastercard exclusive")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                    Text("Shop now →")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(hex: "#F79E1B"))
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .shadow(color: Color(hex: "#1C0800").opacity(0.45), radius: 16, x: 0, y: 6)
    }
}

// MARK: - Promo Banner
struct PromoBanner: View {
    let headline:   String
    let subtext:    String
    let color:      Color
    let icon:       String
    var imageName:  String = ""
    var logoName:   String = ""
    var claimLabel: String = "Claim Offer →"

    var body: some View {
        ZStack(alignment: .trailing) {
            // Background: photo + color overlay, or solid gradient fallback
            if !imageName.isEmpty, let uiImg = UIImage(named: imageName) {
                Image(uiImage: uiImg)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                LinearGradient(
                    stops: [
                        .init(color: color.opacity(0.93), location: 0.0),
                        .init(color: color.opacity(0.93), location: 0.42),
                        .init(color: color.opacity(0.28), location: 1.0),
                    ],
                    startPoint: .leading, endPoint: .trailing
                )
            } else {
                LinearGradient(colors: [color, color.opacity(0.75)], startPoint: .leading, endPoint: .trailing)
            }

            // Content
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    // Partner logo — white-on-black assets use .screen blend so black becomes transparent
                    if !logoName.isEmpty, let logoImg = UIImage(named: logoName) {
                        Image(uiImage: logoImg)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 22)
                    }

                    Text(headline)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(subtext)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(1)

                    // CTA — Mastercard promos show a branded MC pill instead of generic
                    if logoName.isEmpty {
                        Text(claimLabel)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    } else {
                        HStack(spacing: 5) {
                            // Mastercard circles badge
                            ZStack {
                                Circle().fill(Color(hex: "#EB001B")).frame(width: 10, height: 10).offset(x: -3)
                                Circle().fill(Color(hex: "#F79E1B")).frame(width: 10, height: 10).offset(x: 3)
                            }
                            .frame(width: 20, height: 14)
                            Text("Mastercard exclusive →")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                }
                Spacer()
                if imageName.isEmpty {
                    Image(systemName: icon)
                        .font(.system(size: 44))
                        .foregroundColor(.white.opacity(0.2))
                }
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
    }
}

// MARK: - Eats Card
struct EatsCard: View {
    let eat:       NearbyRestaurant
    var freeLabel: String = "Free delivery"

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Photo or gradient fallback
            ZStack(alignment: .topTrailing) {
                if !eat.imageName.isEmpty, let uiImg = UIImage(named: eat.imageName) {
                    Image(uiImage: uiImg)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 150, height: 90)
                        .clipped()
                } else {
                    LinearGradient(
                        colors: [eat.color.opacity(0.8), eat.color.opacity(0.5)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                    .frame(width: 150, height: 90)
                    Image(systemName: "fork.knife")
                        .font(.system(size: 32))
                        .foregroundColor(.white.opacity(0.4))
                        .frame(width: 150, height: 90)
                }

                // Tag badge
                Text(eat.tag)
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundColor(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(eat.color)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .padding(8)
            }
            .frame(width: 150, height: 90)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(eat.name)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.csqTextPrimary)
                    .lineLimit(1)
                Text(eat.cuisine)
                    .font(.system(size: 11))
                    .foregroundColor(.csqTextSecondary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    // Rating
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.csqWarning)
                        Text(eat.rating)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.csqTextPrimary)
                    }
                    Text("·")
                        .foregroundColor(.csqTextTertiary)
                        .font(.system(size: 11))
                    Text(eat.deliveryTime)
                        .font(.system(size: 11))
                        .foregroundColor(.csqTextSecondary)
                }

                Text(eat.deliveryFee == "Free" || eat.deliveryFee == "無料" ? freeLabel : "\(eat.deliveryFee) delivery")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(eat.deliveryFee == "Free" || eat.deliveryFee == "無料" ? .csqSuccess : .csqTextSecondary)
            }
            .padding(.top, 8)
            .padding(.horizontal, 4)
            .padding(.bottom, 4)
        }
        .frame(width: 150)
        .background(Color.csqSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .shadow(color: Color.black.opacity(0.07), radius: 8, x: 0, y: 3)
    }
}

// MARK: - Deal Card
struct DealCard: View {
    let deal: HomeDeal

    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(deal.color.opacity(0.12))
                    .frame(width: 52, height: 52)
                Image(systemName: deal.icon)
                    .font(.system(size: 22))
                    .foregroundColor(deal.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                // Badge
                Text(deal.badge)
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(deal.color)
                    .clipShape(RoundedRectangle(cornerRadius: 5))

                Text(deal.title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.csqTextPrimary)
                    .lineLimit(1)
                Text(deal.merchant)
                    .font(.system(size: 11))
                    .foregroundColor(.csqTextSecondary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                        .foregroundColor(.csqTextTertiary)
                    Text(deal.expiry)
                        .font(.system(size: 11))
                        .foregroundColor(.csqTextTertiary)
                }
            }
        }
        .padding(14)
        .frame(width: 230, alignment: .leading)
        .background(Color.csqSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .shadow(color: Color.black.opacity(0.07), radius: 8, x: 0, y: 3)
    }
}

// MARK: - Quick Action Card
struct QuickActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(color.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(color)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.csqTextPrimary)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.csqTextSecondary)
                }
                Spacer()
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 68, alignment: .leading)
            .background(Color.csqSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Recent Activity Row
struct RecentActivityRow: View {
    let icon:      String
    let iconColor: Color
    let title:     String
    let subtitle:  String
    let status:    String
    var isError:   Bool = false   // drives status pill colour — avoids localised string comparison

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.csqTextPrimary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.csqTextSecondary)
                    .lineLimit(1)
            }
            Spacer()
            Text(status)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(isError ? .csqError : .csqSuccess)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background((isError ? Color.csqError : Color.csqSuccess).opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
