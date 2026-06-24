import SwiftUI
import ContentsquareSDK

struct TelcoHomeView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var marketConfig: MarketConfig
    var showCloseButton: Bool = false
    @State private var selectedPlanType: PlanType = .postpaid
    @State private var showTopUp      = false
    @State private var showRoaming    = false
    @State private var showDataAddOn  = false

    // Purchase funnel state — scoped to the CSQMobile subtree only.
    @StateObject private var purchase = TelcoPurchaseStore()

    private enum TelcoAccessID {
        static let backButton       = "telco_btn_back"
        static let currentPlanCard  = "telco_card_current_plan"
        static let topUpChip        = "telco_chip_topup"
        static let dataAddOnChip    = "telco_chip_dataaddon"
        static let roamChip         = "telco_chip_roam"
        static func planTab(_ type: PlanType) -> String { "telco_tab_\(type.rawValue)" }
        static func planCard(_ name: String) -> String  { "telco_plan_card_\(name.lowercased())" }
        static func deviceCard(_ model: String) -> String {
            "telco_device_\(model.lowercased().replacingOccurrences(of: " ", with: "_"))"
        }
        static func addonRow(_ name: String) -> String {
            "telco_addon_\(name.lowercased().replacingOccurrences(of: " ", with: "_"))"
        }
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                Color.csqBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    headerView.frame(height: 220).clipped()

                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 20) {
                            dataUsageDialCard
                            billingSummaryCard
                            planTypeTabBar
                            planCardsSection
                            devicesSection
                            addOnsSection
                            Spacer().frame(height: 24)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showTopUp)     { TopUpSheet().environmentObject(marketConfig) }
            .sheet(isPresented: $showRoaming)   { RoamingSheet().environmentObject(marketConfig) }
            .sheet(isPresented: $showDataAddOn) { DataAddOnSheet().environmentObject(marketConfig) }
            .onAppear { CSQ.trackScreenview("Telco - Home") }
        }
        .environmentObject(purchase)
    }

    // MARK: - Header

    private var headerView: some View {
        ZStack(alignment: .bottom) {
            // Background — Singapore header image when available, gradient fallback
            Group {
                if UIImage(named: "TelcoHeaderSG") != nil {
                    Image("TelcoHeaderSG")
                        .resizable()
                        .scaledToFill()
                } else {
                    LinearGradient(
                        colors: [Color.csqPrimary, Color.csqPrimaryDark],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            }
            // Pin the background to a DEFINITE height. Using `maxHeight: .infinity`
            // here inflates the ZStack's ideal size, which makes the call-site
            // `.frame(height:)` (centre-aligned) push the bottom-anchored headline
            // + chips below the frame, where the scroll card then covers them.
            .frame(maxWidth: .infinity)
            .frame(height: 220)
            .clipped()

            // Scrim so text stays legible over any image
            LinearGradient(
                colors: [Color.black.opacity(0), Color.black.opacity(0.22)],
                startPoint: .top, endPoint: .bottom
            )

            VStack(spacing: 0) {
                // Nav row
                HStack {
                    if showCloseButton {
                        Button(action: { isPresented = false }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())
                        }
                        .accessibilityIdentifier(TelcoAccessID.backButton)
                    }
                    Spacer()
                    Text(marketConfig.market == .tokyo ? "CSQモバイル" : "CSQMobile")
                        .font(AppFont.display(18))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Spacer()
                    if showCloseButton { Color.clear.frame(width: 32, height: 32) }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                Spacer()

                // Headline + chips
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(marketConfig.strings.telcoHeroTitle)
                            .font(AppFont.display(26))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text(marketConfig.strings.telcoHeroSubtitle)
                            .font(AppFont.body(13))
                            .foregroundColor(.white.opacity(0.8))
                    }

                    HStack(spacing: 10) {
                        TelcoQuickChip(icon: "arrow.up.circle.fill",              label: marketConfig.strings.telcoTopUpChip)
                            .accessibilityIdentifier(TelcoAccessID.topUpChip)
                            .onTapGesture { showTopUp = true }

                        TelcoQuickChip(icon: "antenna.radiowaves.left.and.right", label: marketConfig.strings.telcoDataAddOnChip)
                            .accessibilityIdentifier(TelcoAccessID.dataAddOnChip)
                            .onTapGesture { showDataAddOn = true }

                        TelcoQuickChip(icon: "airplane",                          label: marketConfig.strings.telcoRoamChip)
                            .accessibilityIdentifier(TelcoAccessID.roamChip)
                            .onTapGesture { showRoaming = true }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
    }

    // MARK: - Data Usage Dial Card

    private var dataUsageDialCard: some View {
        VStack(spacing: 0) {
            // Top label row
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(marketConfig.strings.telcoCurrentPlan)
                        .font(AppFont.display(15))
                        .fontWeight(.bold)
                        .foregroundColor(.csqTextPrimary)
                    Text(marketConfig.strings.telcoRenewsIn)
                        .font(AppFont.body(11))
                        .foregroundColor(.csqTextSecondary)
                }
                Spacer()
                Text("5G")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.csqPrimary)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            // Dial
            DataUsageDial(used: 17, total: 20)
                .padding(.vertical, 8)

            // Bottom stat row
            HStack(spacing: 0) {
                statPill(value: "3 GB", label: marketConfig.strings.telcoRemainingLabel, color: .csqPrimary)
                Divider().frame(height: 36)
                statPill(value: "17 GB", label: marketConfig.strings.telcoUsedLabel, color: .csqTextSecondary)
                Divider().frame(height: 36)
                statPill(value: "20 GB", label: marketConfig.strings.telcoTotalLabel, color: .csqTextSecondary)
            }
            .padding(.bottom, 20)
        }
        .background(Color.csqSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 3)
        .accessibilityIdentifier(TelcoAccessID.currentPlanCard)
    }

    // MARK: - Billing Summary Card (entry to the Bills & Support journey)

    private var billingSummaryCard: some View {
        let m = marketConfig.market
        let jp = m == .tokyo
        let bill = TelcoBill.currentBill(for: m)
        return NavigationLink(destination: TelcoBillsView()) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .fill(bill.status.color.opacity(0.12)).frame(width: 48, height: 48)
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 20)).foregroundColor(bill.status.color)
                }
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(jp ? "今月のご請求" : "Current bill")
                            .font(AppFont.body(13)).fontWeight(.semibold).foregroundColor(.csqTextPrimary)
                        Text(bill.status.label(for: m))
                            .font(.system(size: 9, weight: .bold)).foregroundColor(.white)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(bill.status.color).clipShape(Capsule())
                    }
                    Text((jp ? "支払期限 " : "Due ") + bill.dueDate)
                        .font(AppFont.body(11)).foregroundColor(.csqTextSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(telcoMoney(bill.amount, m))
                        .font(AppFont.display(18)).fontWeight(.black).foregroundColor(.csqTextPrimary)
                    Text(jp ? "確認して支払う" : "View & pay")
                        .font(AppFont.body(11)).fontWeight(.semibold).foregroundColor(.csqTelcoTeal)
                }
                Image(systemName: "chevron.right").font(.caption2).foregroundColor(.csqBorder)
            }
            .padding(16)
            .background(Color.csqSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
            .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("telco_card_billing_summary")
        .accessibilityLabel(jp ? "請求とお支払いを開く" : "Open bills and payments")
    }

    private func statPill(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(AppFont.display(15))
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(AppFont.body(10))
                .foregroundColor(.csqTextTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Plan Tabs

    private var planTypeTabBar: some View {
        HStack(spacing: 0) {
            ForEach(PlanType.allCases, id: \.self) { type in
                VStack(spacing: 6) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) { selectedPlanType = type }
                    }) {
                        Text(type.displayName(for: marketConfig.market))
                            .font(AppFont.body(14))
                            .fontWeight(.semibold)
                            .foregroundColor(selectedPlanType == type ? .csqPrimary : .csqTextTertiary)
                    }
                    .frame(maxWidth: .infinity)

                    RoundedRectangle(cornerRadius: 1)
                        .fill(selectedPlanType == type ? Color.csqPrimary : Color.clear)
                        .frame(height: 2)
                }
                .accessibilityIdentifier(TelcoAccessID.planTab(type))
            }
        }
        .frame(height: 44)
        .background(Color.csqSurface)
        .cornerRadius(AppRadius.md)
    }

    // MARK: - Plan Cards

    private var planCardsSection: some View {
        let filtered = TelcoPlan.plans(for: marketConfig.market).filter { $0.type == selectedPlanType }
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(filtered) { plan in
                    PlanCard(plan: plan)
                        .accessibilityIdentifier(TelcoAccessID.planCard(plan.name))
                        .onAppear {
                            CSQ.trackEvent("telco_plan_viewed", properties: [
                                "plan_name": plan.name, "price": plan.monthlyPrice
                            ])
                        }
                }
            }
        }
    }

    // MARK: - Devices

    private var devicesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(marketConfig.strings.telcoLatestDevices)
                    .font(AppFont.display(16))
                    .fontWeight(.bold)
                    .foregroundColor(.csqTextPrimary)
                Spacer()
                Text(marketConfig.strings.martSeeAll)
                    .font(AppFont.body(13))
                    .foregroundColor(.csqPrimary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(TelcoDevice.devices(for: marketConfig.market)) { device in
                        NavigationLink(destination: DeviceDetailView(device: device)) {
                            DeviceCard(device: device)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier(TelcoAccessID.deviceCard(device.model))
                    }
                }
            }
        }
    }

    // MARK: - Add-ons

    private var addOnsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(marketConfig.strings.telcoRoamingAddons)
                .font(AppFont.display(16))
                .fontWeight(.bold)
                .foregroundColor(.csqTextPrimary)

            VStack(spacing: 10) {
                ForEach(TelcoAddOn.addOns(for: marketConfig.market)) { addon in
                    AddOnRow(addon: addon)
                        .accessibilityIdentifier(TelcoAccessID.addonRow(addon.name))
                        .onTapGesture {
                            CSQ.trackEvent("telco_addon_tapped", properties: ["addon_name": addon.name])
                        }
                }
            }
        }
    }
}

// MARK: - Data Usage Dial

struct DataUsageDial: View {
    let used: Double
    let total: Double
    @EnvironmentObject var marketConfig: MarketConfig

    private var pct: Double { min(used / total, 1.0) }
    private var remaining: Double { max(total - used, 0) }

    // Arc spans 240° centred at bottom — starts at 150° (7-o'clock), ends at 390° (5-o'clock)
    private let startAngle = Angle(degrees: 150)
    private let endAngle   = Angle(degrees: 390)

    var body: some View {
        ZStack {
            // Track
            Circle()
                .trim(from: 0, to: 0.667)   // 240/360
                .stroke(Color.csqBorder, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(startAngle)

            // Fill
            Circle()
                .trim(from: 0, to: 0.667 * pct)
                .stroke(
                    LinearGradient(
                        colors: pct > 0.8
                            ? [Color.csqError, Color(hex: "#FF8C00")]
                            : [Color.csqPrimary, Color.csqPrimaryDark],
                        startPoint: .leading, endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(startAngle)
                .animation(.easeInOut(duration: 0.8), value: pct)

            // Centre label
            VStack(spacing: 2) {
                Text(String(format: "%.0f GB", remaining))
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundColor(.csqTextPrimary)
                Text(marketConfig.strings.telcoDialRemaining)
                    .font(AppFont.body(12))
                    .foregroundColor(.csqTextSecondary)
                Text("\(marketConfig.strings.telcoDialOf) \(String(format: "%.0f", total)) GB")
                    .font(AppFont.body(11))
                    .foregroundColor(.csqTextTertiary)

                // Warning badge when nearly full
                if pct > 0.8 {
                    HStack(spacing: 3) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 9, weight: .semibold))
                        Text(marketConfig.strings.telcoRunningLow)
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(.csqError)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.csqError.opacity(0.1))
                    .clipShape(Capsule())
                        .padding(.top, 4)
                }
            }
        }
        .frame(width: 200, height: 200)
        .padding(.top, 8)
    }
}

// MARK: - Plan Card

struct PlanCard: View {
    let plan: TelcoPlan
    @EnvironmentObject var marketConfig: MarketConfig

    private var priceString: String {
        let val = marketConfig.market == .tokyo
            ? Int(plan.monthlyPrice) * 100
            : Int(plan.monthlyPrice)
        return marketConfig.market.formatPrice(Double(val)) + marketConfig.strings.telcoPricePerMonth
    }

    var body: some View {
        NavigationLink(destination: TelcoPlanDetailView(plan: plan)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(plan.displayName)
                            .font(AppFont.display(16))
                            .fontWeight(.bold)
                            .foregroundColor(.csqTextPrimary)
                        Text(priceString)
                            .font(AppFont.body(12))
                            .foregroundColor(.csqTextSecondary)
                    }
                    Spacer()
                    if let badge = plan.badge {
                        Text(badge)
                            .font(AppFont.body(9))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.vertical, 3)
                            .padding(.horizontal, 7)
                            .background(plan.isPopular ? Color.csqPrimary : Color.csqSuccess)
                            .cornerRadius(AppRadius.sm)
                    }
                }

                Text(plan.dataAllowance)
                    .font(AppFont.display(24))
                    .fontWeight(.black)
                    .foregroundColor(plan.color)

                Text(plan.contractTerm)
                    .font(AppFont.body(10))
                    .foregroundColor(.csqTextTertiary)

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(plan.features.prefix(3), id: \.self) { feat in
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.csqPrimary)
                            Text(feat)
                                .font(AppFont.body(11))
                                .foregroundColor(.csqTextPrimary)
                                .lineLimit(2)
                        }
                    }
                }

                Spacer()

                Text(marketConfig.strings.telcoSelectPlan)
                    .font(AppFont.body(13))
                    .fontWeight(.semibold)
                    .foregroundColor(.csqPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .overlay(RoundedRectangle(cornerRadius: AppRadius.md).stroke(Color.csqPrimary, lineWidth: 1))
            }
            .padding(14)
            .frame(width: 200)
            .background(Color.csqSurface)
            .cornerRadius(AppRadius.md)
            .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
        }
    }
}

// MARK: - Device Card

struct DeviceCard: View {
    let device: TelcoDevice
    @EnvironmentObject var marketConfig: MarketConfig

    private var priceString: String {
        let val = marketConfig.market == .tokyo
            ? Int(device.monthlyPrice) * 100
            : Int(device.monthlyPrice)
        return marketConfig.strings.telcoFromPrice
            + marketConfig.market.formatPrice(Double(val))
            + marketConfig.strings.telcoPricePerMonth
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Phone photo or gradient fallback
            ZStack(alignment: .topTrailing) {
                Group {
                    if let img = UIImage(named: device.imageName) {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .padding(12)
                    } else {
                        // Fallback: dark gradient + SF symbol until photo lands
                        ZStack {
                            LinearGradient(
                                colors: [Color.csqNavy, Color.csqNavy.opacity(0.7)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                            Image(systemName: device.fallbackIcon)
                                .font(.system(size: 44))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 130)
                .background(Color(hex: "#F5F5F7"))
                .clipped()

                if let badge = device.badge {
                    Text(badge)
                        .font(AppFont.body(9))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.vertical, 3)
                        .padding(.horizontal, 7)
                        .background(Color.csqPrimary.opacity(0.85))
                        .cornerRadius(AppRadius.sm)
                        .padding(8)
                }
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(device.brand)
                    .font(AppFont.body(10))
                    .foregroundColor(.csqTextSecondary)
                Text(device.model)
                    .font(AppFont.body(13))
                    .fontWeight(.bold)
                    .foregroundColor(.csqTextPrimary)
                    .lineLimit(1)
                Text(priceString)
                    .font(AppFont.body(11))
                    .fontWeight(.semibold)
                    .foregroundColor(.csqPrimary)
                Text(device.contractPlan)
                    .font(AppFont.body(9))
                    .foregroundColor(.csqTextTertiary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.csqSurface)
        }
        .frame(width: 160)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .shadow(color: .black.opacity(0.09), radius: 6, x: 0, y: 3)
    }
}

// MARK: - Add-On Row

struct AddOnRow: View {
    let addon: TelcoAddOn
    @EnvironmentObject var marketConfig: MarketConfig

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: addon.icon)
                .font(.system(size: 18))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(addon.color)
                .cornerRadius(AppRadius.md)

            VStack(alignment: .leading, spacing: 2) {
                Text(addon.name)
                    .font(AppFont.body(14))
                    .fontWeight(.semibold)
                    .foregroundColor(.csqTextPrimary)
                Text(addon.description)
                    .font(AppFont.body(11))
                    .foregroundColor(.csqTextSecondary)
                    .lineLimit(2)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(marketConfig.market.formatPrice(addon.price))
                    .font(AppFont.body(13))
                    .fontWeight(.bold)
                    .foregroundColor(.csqTextPrimary)
                Text(addon.period)
                    .font(AppFont.body(9))
                    .foregroundColor(.csqTextTertiary)
            }

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundColor(.csqBorder)
        }
        .padding(14)
        .background(Color.csqSurface)
        .cornerRadius(AppRadius.md)
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 1)
    }
}

// MARK: - Quick Chip

private struct TelcoQuickChip: View {
    let icon: String
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
        }
        .foregroundColor(.csqPrimary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.92))
        .clipShape(Capsule())
    }
}

// MARK: - Top-Up Sheet

struct TopUpSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var marketConfig: MarketConfig
    @State private var selectedAmount: Int = 10
    @State private var confirmed = false
    let amounts = [5, 10, 15, 20, 30, 50]

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Balance card
                VStack(spacing: 6) {
                    Text(marketConfig.strings.telcoTopUpCurrentBal)
                        .font(AppFont.body(13))
                        .foregroundColor(.csqTextSecondary)
                    Text(marketConfig.market.formatPrice(4.20))
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundColor(.csqTextPrimary)
                    Text(marketConfig.market == .tokyo ? "バリューカード10 — 4月28日まで有効" : "ValueCard 10 — expires 28 Apr")
                        .font(AppFont.body(11))
                        .foregroundColor(.csqTextTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(
                    LinearGradient(colors: [Color.csqPrimary.opacity(0.08), Color.csqPrimary.opacity(0.02)],
                                   startPoint: .top, endPoint: .bottom)
                )
                .cornerRadius(AppRadius.lg)
                .padding(.horizontal, 16)

                // Amount picker
                VStack(alignment: .leading, spacing: 12) {
                    Text(marketConfig.strings.telcoTopUpSelectAmt)
                        .font(AppFont.body(14))
                        .fontWeight(.semibold)
                        .foregroundColor(.csqTextPrimary)
                        .padding(.horizontal, 16)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                        ForEach(amounts, id: \.self) { amt in
                            Button(action: { selectedAmount = amt }) {
                                Text(marketConfig.market.formatPrice(Double(amt)))
                                    .font(AppFont.body(15))
                                    .fontWeight(.bold)
                                    .foregroundColor(selectedAmount == amt ? .white : .csqTextPrimary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(selectedAmount == amt ? Color.csqPrimary : Color.csqSurface)
                                    .cornerRadius(AppRadius.md)
                                    .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }

                // Payment method
                HStack(spacing: 14) {
                    Image(systemName: "creditcard.fill")
                        .foregroundColor(.csqPrimary)
                    Text("Visa •••• 4242")
                        .font(AppFont.body(14))
                        .foregroundColor(.csqTextPrimary)
                    Spacer()
                    Text(marketConfig.market == .tokyo ? "変更" : "Change")
                        .font(AppFont.body(13))
                        .foregroundColor(.csqPrimary)
                }
                .padding(16)
                .background(Color.csqSurface)
                .cornerRadius(AppRadius.md)
                .padding(.horizontal, 16)

                Spacer()

                // CTA
                Button(action: {
                    withAnimation { confirmed = true }
                    CSQ.trackEvent("telco_topup_confirmed", properties: ["amount": selectedAmount])
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { dismiss() }
                }) {
                    HStack(spacing: 8) {
                        if confirmed {
                            Image(systemName: "checkmark.circle.fill")
                            Text(marketConfig.strings.telcoTopUpToppedUp)
                        } else {
                            Text(marketConfig.strings.telcoTopUpButton(String(selectedAmount)))
                        }
                    }
                    .font(AppFont.body(16))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(confirmed ? Color.csqSuccess : Color.csqPrimary)
                    .cornerRadius(AppRadius.full)
                    .animation(.easeInOut(duration: 0.3), value: confirmed)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .padding(.top, 8)
            .background(Color.csqBackground.ignoresSafeArea())
            .navigationTitle(marketConfig.strings.telcoTopUpTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(marketConfig.strings.telcoTopUpDone) { dismiss() }
                        .foregroundColor(.csqPrimary)
                }
            }
        }
        .onAppear { CSQ.trackScreenview("Telco - Top Up") }
    }
}

// MARK: - Roaming Sheet

struct RoamingSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var marketConfig: MarketConfig
    @State private var selectedDestination = "ASEAN"

    // Tokyo/Sydney get their own catalogues; any unhandled market (incl. future
    // cases) falls back to the Singapore destinations via `default`.
    var destinations: [(String, String, String, String)] {
        switch marketConfig.market {
        case .tokyo:
            return [
                ("アジア全域", "airplane.circle.fill", "韓国・台湾・タイ等 10カ国以上", "¥1,100/日"),
                ("ASEAN", "globe.asia.australia.fill", "TH, ID, PH, VN, MY 等", "¥1,320/日"),
                ("香港・マカオ", "building.2.fill", "データ無制限", "¥1,650/日"),
                ("ヨーロッパ", "globe.europe.africa.fill", "42カ国対応", "¥2,750/日"),
                ("米国・カナダ", "globe.americas.fill", "通話・データ無制限", "¥2,500/日"),
                ("オーストラリア・NZ", "globe.asia.australia.fill", "データ無制限", "¥2,200/日"),
            ]
        case .sydney:
            return [
                ("New Zealand", "airplane.circle.fill", "Unlimited data across NZ", "A$8/day"),
                ("Asia", "globe.asia.australia.fill", "ID, TH, JP, KR + 10 more", "A$10/day"),
                ("Pacific Islands", "globe.asia.australia.fill", "Fiji, Samoa, Vanuatu + more", "A$12/day"),
                ("UK & Europe", "globe.europe.africa.fill", "42 countries", "A$20/day"),
                ("USA & Canada", "globe.americas.fill", "Unlimited calls & data", "A$18/day"),
            ]
        default:
            return [
                ("ASEAN", "airplane.circle.fill", "MY, TH, ID, PH, VN + 5 more", "S$8/日"),
                ("Hong Kong & Macau", "building.2.fill", "Unlimited data", "S$12/日"),
                ("Japan & Korea", "mountain.2.fill", "Unlimited data", "S$15/日"),
                ("Europe", "globe.europe.africa.fill", "42 countries", "S$20/日"),
                ("USA & Canada", "globe.americas.fill", "Unlimited calls & data", "S$18/日"),
                ("Australia & NZ", "globe.asia.australia.fill", "Unlimited data", "S$15/日"),
            ]
        }
    }

    // Markdown (**bold**) is preserved — rendered via `Text(.init(roamingTipText))`.
    // Unhandled markets (incl. future cases) fall back to the Singapore tip.
    var roamingTipText: String {
        switch marketConfig.market {
        case .tokyo:
            return "今週末は韓国へ？ **近隣アジア周遊パック** なら7日間¥500で、1日パスよりお得です。"
        case .sydney:
            return "Heading across the Tasman this weekend? The **Asia Roaming Pass** at A$5 for 7 days is better value than a daily pass."
        default:
            return "Heading to JB this weekend? The **JB Roam Pack** at S$5 for 7 days is better value than a daily pass."
        }
    }

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Current roaming status
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(Color.csqSuccess.opacity(0.12)).frame(width: 44, height: 44)
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .foregroundColor(.csqSuccess)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(marketConfig.strings.telcoRoamingOff)
                                .font(AppFont.body(14)).fontWeight(.semibold).foregroundColor(.csqTextPrimary)
                            Text(marketConfig.strings.telcoRoamingTip)
                                .font(AppFont.body(11)).foregroundColor(.csqTextSecondary)
                        }
                        Spacer()
                    }
                    .padding(16)
                    .background(Color.csqSurface)
                    .cornerRadius(AppRadius.md)
                    .padding([.horizontal, .top], 16)

                    // Destinations
                    VStack(alignment: .leading, spacing: 10) {
                        Text(marketConfig.strings.telcoDayPassesTitle)
                            .font(AppFont.display(15)).fontWeight(.bold).foregroundColor(.csqTextPrimary)
                            .padding(.horizontal, 16).padding(.top, 20)

                        ForEach(destinations, id: \.0) { dest in
                            HStack(spacing: 14) {
                                Image(systemName: dest.1)
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Color.csqPrimary)
                                    .cornerRadius(AppRadius.md)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(dest.0)
                                        .font(AppFont.body(14)).fontWeight(.semibold).foregroundColor(.csqTextPrimary)
                                    Text(dest.2)
                                        .font(AppFont.body(11)).foregroundColor(.csqTextSecondary)
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(dest.3)
                                        .font(AppFont.body(13)).fontWeight(.bold).foregroundColor(.csqTextPrimary)
                                    Text(marketConfig.strings.telcoAddButton)
                                        .font(AppFont.body(11)).fontWeight(.semibold).foregroundColor(.csqPrimary)
                                }
                            }
                            .padding(14)
                            .background(Color.csqSurface)
                            .cornerRadius(AppRadius.md)
                            .shadow(color: .black.opacity(0.04), radius: 3, x: 0, y: 1)
                            .padding(.horizontal, 16)
                            .onTapGesture {
                                CSQ.trackEvent("telco_roaming_selected", properties: ["destination": dest.0])
                            }
                        }
                    }

                    // JB tip
                    HStack(spacing: 12) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.csqWarning)
                        Text(.init(roamingTipText))
                            .font(AppFont.body(12))
                            .foregroundColor(.csqTextPrimary)
                    }
                    .padding(14)
                    .background(Color.csqWarning.opacity(0.08))
                    .cornerRadius(AppRadius.md)
                    .padding(16)
                }
            }
            .background(Color.csqBackground.ignoresSafeArea())
            .navigationTitle(marketConfig.strings.telcoRoamingTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(marketConfig.strings.telcoDone) { dismiss() }.foregroundColor(.csqPrimary)
                }
            }
        }
        .onAppear { CSQ.trackScreenview("Telco - Roaming") }
    }
}

// MARK: - Data Add-On Sheet

struct DataAddOnSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var marketConfig: MarketConfig
    // Keyed by `gb` (stable across renders) — `packs` is computed, so random UUIDs
    // would regenerate every render and break selection tracking.
    @State private var addedPacks: Set<Int> = []

    // Tokyo has yen-priced packs; every other market (incl. future cases) falls
    // back to the Singapore packs via `default`. Sydney shares the SG pricing.
    var packs: [(gb: Int, price: Int, label: String, note: String)] {
        switch marketConfig.market {
        case .tokyo:
            return [
                (1,  300,  "1 GB",  "即時 — 有効期限なし"),
                (3,  600,  "3 GB",  "即時 — 有効期限なし"),
                (5,  800,  "5 GB",  "即時 — 繰り越し可"),
                (10, 1200, "10 GB", "お得 — 繰り越し可"),
                (20, 2000, "20 GB", "ヘビーユーザー向け"),
            ]
        default:
            return [
                (1,  3,  "1 GB",  "Instant — no expiry"),
                (3,  6,  "3 GB",  "Instant — no expiry"),
                (5,  8,  "5 GB",  "Instant — rolls over"),
                (10, 12, "10 GB", "Best value — rolls over"),
                (20, 20, "20 GB", "Power user pack"),
            ]
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Current data status mini-dial
                HStack(spacing: 16) {
                    DataUsageDial(used: 17, total: 20)
                        .frame(width: 100, height: 100)
                        .scaleEffect(0.5)
                        .frame(width: 50, height: 50)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(marketConfig.market == .tokyo ? "残り3 GB" : "3 GB left")
                            .font(AppFont.display(18)).fontWeight(.black).foregroundColor(.csqTextPrimary)
                        Text(marketConfig.market == .tokyo ? "20 GB中 · 12日後に更新" : "of 20 GB · renews in 12 days")
                            .font(AppFont.body(12)).foregroundColor(.csqTextSecondary)
                        Text(marketConfig.market == .tokyo ? "残りわずか — 今すぐデータを追加" : "Running low — add data now")
                            .font(AppFont.body(11)).fontWeight(.semibold).foregroundColor(.csqError)
                    }
                    Spacer()
                }
                .padding(16)
                .background(Color.csqSurface)
                .padding(16)

                Text(marketConfig.strings.telcoChooseDataPack)
                    .font(AppFont.display(15)).fontWeight(.bold).foregroundColor(.csqTextPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach(packs, id: \.gb) { pack in
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: AppRadius.md)
                                        .fill(Color.csqPrimary.opacity(0.1))
                                        .frame(width: 50, height: 50)
                                    Text("\(pack.gb)")
                                        .font(.system(size: 18, weight: .black, design: .rounded))
                                        .foregroundColor(.csqPrimary)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(marketConfig.market == .tokyo ? "\(pack.label) データ" : "\(pack.label) Data")
                                        .font(AppFont.body(14)).fontWeight(.semibold).foregroundColor(.csqTextPrimary)
                                    Text(pack.note)
                                        .font(AppFont.body(11)).foregroundColor(.csqTextSecondary)
                                }

                                Spacer()

                                Button(action: {
                                    withAnimation { addedPacks.insert(pack.gb) }
                                    CSQ.trackEvent("telco_data_addon_added", properties: ["gb": pack.gb, "price": pack.price])
                                }) {
                                    HStack(spacing: 4) {
                                        if addedPacks.contains(pack.gb) {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 11, weight: .bold))
                                        }
                                        Text(addedPacks.contains(pack.gb) ? marketConfig.strings.telcoDataAddedButton : marketConfig.strings.telcoDataPrice(String(pack.price)))
                                            .font(AppFont.body(13)).fontWeight(.bold)
                                    }
                                    .foregroundColor(addedPacks.contains(pack.gb) ? .csqSuccess : .white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(addedPacks.contains(pack.gb) ? Color.csqSuccess.opacity(0.12) : Color.csqPrimary)
                                    .cornerRadius(AppRadius.full)
                                }
                            }
                            .padding(14)
                            .background(Color.csqSurface)
                            .cornerRadius(AppRadius.md)
                            .shadow(color: .black.opacity(0.04), radius: 3, x: 0, y: 1)
                        }
                    }
                    .padding(16)
                }

                if !addedPacks.isEmpty {
                    Button(action: { dismiss() }) {
                        Text(marketConfig.strings.telcoConfirmAddOns(addedPacks.count))
                            .font(AppFont.body(16)).fontWeight(.bold).foregroundColor(.white)
                            .frame(maxWidth: .infinity).frame(height: 52)
                            .background(Color.csqPrimary)
                            .cornerRadius(AppRadius.full)
                    }
                    .padding(.horizontal, 16).padding(.bottom, 32)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .background(Color.csqBackground.ignoresSafeArea())
            .navigationTitle(marketConfig.strings.telcoDataAddOnTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(marketConfig.strings.telcoDone) { dismiss() }.foregroundColor(.csqPrimary)
                }
            }
        }
        .onAppear { CSQ.trackScreenview("Telco - Data Add-On") }
    }
}

// MARK: - Shared CSQMobile CTA label (used by funnel NavigationLinks)

struct TelcoCTALabel: View {
    let text: String
    var enabled: Bool = true
    var body: some View {
        Text(text)
            .font(AppFont.body(16))
            .fontWeight(.bold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(enabled ? Color.csqTelcoTeal : Color.csqTextTertiary)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }
}

// Small helper: scale to yen for Tokyo, then format with the market currency.
func telcoMoney(_ base: Double, _ market: Market) -> String {
    market.formatPrice(market == .tokyo ? base * 100 : base)
}

// MARK: - Device Detail (funnel step 1)

struct DeviceDetailView: View {
    let device: TelcoDevice
    @EnvironmentObject var marketConfig: MarketConfig
    @EnvironmentObject var purchase: TelcoPurchaseStore

    private func fireVariant() {
        CSQ.trackEvent("telco_device_variant_selected", properties: [
            "model":   device.model,
            "color":   purchase.selectedColor,
            "storage": purchase.selectedStorage?.label ?? "",
            "market":  marketConfig.market.trackingLabel
        ])
    }

    var body: some View {
        let m = marketConfig.market
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {

                // Hero image
                ZStack {
                    if let img = UIImage(named: device.imageName) {
                        Image(uiImage: img).resizable().scaledToFit().padding(24)
                    } else {
                        ZStack {
                            LinearGradient(colors: [Color.csqNavy, Color.csqNavy.opacity(0.7)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                            Image(systemName: device.fallbackIcon)
                                .font(.system(size: 64)).foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
                .frame(maxWidth: .infinity).frame(height: 240)
                .background(Color(hex: "#F5F5F7"))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))

                // Title + price
                VStack(alignment: .leading, spacing: 4) {
                    Text(device.brand).font(AppFont.body(13)).foregroundColor(.csqTextSecondary)
                    Text(device.model).font(AppFont.display(24)).fontWeight(.bold).foregroundColor(.csqTextPrimary)
                    Text(marketConfig.strings.telcoFromPrice
                         + telcoMoney(device.monthlyPrice, m)
                         + marketConfig.strings.telcoPricePerMonth)
                        .font(AppFont.body(15)).fontWeight(.semibold).foregroundColor(.csqTelcoTeal)
                }

                // Colour picker
                VStack(alignment: .leading, spacing: 10) {
                    Text(marketConfig.strings.telcoColorLabel)
                        .font(AppFont.body(13)).fontWeight(.bold).foregroundColor(.csqTextPrimary)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(device.colorOptions, id: \.self) { color in
                                Button {
                                    purchase.selectedColor = color
                                    fireVariant()
                                } label: {
                                    Text(color)
                                        .font(AppFont.body(13))
                                        .fontWeight(.semibold)
                                        .foregroundColor(purchase.selectedColor == color ? .white : .csqTextPrimary)
                                        .padding(.vertical, 8).padding(.horizontal, 14)
                                        .background(purchase.selectedColor == color ? Color.csqTelcoTeal : Color.csqSurface)
                                        .overlay(RoundedRectangle(cornerRadius: AppRadius.full)
                                            .stroke(Color.csqBorder, lineWidth: 1))
                                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.full))
                                }
                                .accessibilityIdentifier("device_detail_color_\(color.lowercased().replacingOccurrences(of: " ", with: "_"))")
                            }
                        }
                    }
                }

                // Storage picker
                VStack(alignment: .leading, spacing: 10) {
                    Text(marketConfig.strings.telcoStorageLabel)
                        .font(AppFont.body(13)).fontWeight(.bold).foregroundColor(.csqTextPrimary)
                    HStack(spacing: 10) {
                        ForEach(device.storageTiers) { tier in
                            Button {
                                purchase.selectedStorage = tier
                                fireVariant()
                            } label: {
                                VStack(spacing: 2) {
                                    Text(tier.label).font(AppFont.body(14)).fontWeight(.bold)
                                    if tier.priceDelta > 0 {
                                        Text("+" + telcoMoney(tier.priceDelta, m))
                                            .font(AppFont.body(10))
                                    }
                                }
                                .foregroundColor(purchase.selectedStorage == tier ? .white : .csqTextPrimary)
                                .frame(maxWidth: .infinity).padding(.vertical, 12)
                                .background(purchase.selectedStorage == tier ? Color.csqTelcoTeal : Color.csqSurface)
                                .overlay(RoundedRectangle(cornerRadius: AppRadius.md)
                                    .stroke(Color.csqBorder, lineWidth: 1))
                                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                            }
                            .accessibilityIdentifier("device_detail_storage_\(tier.label.lowercased().replacingOccurrences(of: " ", with: "_"))")
                        }
                    }
                }

                NavigationLink(destination: DeviceFinancingView()) {
                    TelcoCTALabel(text: marketConfig.strings.telcoContinue)
                }
                .accessibilityIdentifier("device_detail_btn_continue")
                .padding(.top, 8)
            }
            .padding(16)
        }
        .background(Color.csqBackground.ignoresSafeArea())
        .navigationTitle(device.model)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            purchase.startDevice(device)
            CSQ.trackScreenview("Telco - Device Detail")
            CSQ.trackEvent("telco_device_viewed", properties: [
                "brand":         device.brand,
                "model":         device.model,
                "storage":       device.storage,
                "outright_price": device.outrightPrice,
                "monthly_price":  device.monthlyPrice,
                "market":        marketConfig.market.trackingLabel
            ])
        }
    }
}

// MARK: - Device Financing (funnel step 2)

struct DeviceFinancingView: View {
    @EnvironmentObject var marketConfig: MarketConfig
    @EnvironmentObject var purchase: TelcoPurchaseStore

    private func fireFinancing() {
        CSQ.trackEvent("telco_device_financing_selected", properties: [
            "model":         purchase.device?.model ?? "",
            "finance_mode":  purchase.financeMode.analytics,
            "plan_name":     purchase.attachedPlan?.name ?? "none",
            "term_months":   purchase.financeMode == .outright ? 0 : 24,
            "monthly_total": purchase.monthlyTotal,
            "due_today":     purchase.dueToday,
            "market":        marketConfig.market.trackingLabel
        ])
    }

    var body: some View {
        let m = marketConfig.market
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {

                Text(marketConfig.strings.telcoFinancingTitle)
                    .font(AppFont.display(20)).fontWeight(.bold).foregroundColor(.csqTextPrimary)

                // Finance mode options
                VStack(spacing: 12) {
                    financeOption(.installment24,
                                  title: marketConfig.strings.telcoInstallmentLabel,
                                  sub: marketConfig.strings.telcoInstallmentSub)
                    financeOption(.outright,
                                  title: marketConfig.strings.telcoOutrightLabel,
                                  sub: marketConfig.strings.telcoOutrightSub)
                }

                // Attach a plan (optional)
                Text(marketConfig.strings.telcoAttachPlanTitle)
                    .font(AppFont.body(15)).fontWeight(.bold).foregroundColor(.csqTextPrimary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(TelcoPlan.plans(for: m).filter { $0.type == .postpaid }) { plan in
                            Button {
                                purchase.attachedPlan = (purchase.attachedPlan?.id == plan.id) ? nil : plan
                                CSQ.trackEvent("telco_device_plan_attached", properties: [
                                    "plan_name":  plan.name,
                                    "plan_type":  plan.type.rawValue,
                                    "price":      plan.monthlyPrice,
                                    "market":     m.trackingLabel
                                ])
                                fireFinancing()
                            } label: {
                                planChip(plan)
                            }
                            .accessibilityIdentifier("device_financing_plan_\(plan.name.lowercased())")
                        }
                    }
                }

                // Price summary
                priceSummary

                NavigationLink(destination: TelcoCheckoutView()) {
                    TelcoCTALabel(text: marketConfig.strings.telcoContinueCheckout)
                }
                .accessibilityIdentifier("device_financing_btn_checkout")
                .padding(.top, 4)
            }
            .padding(16)
        }
        .background(Color.csqBackground.ignoresSafeArea())
        .navigationTitle(marketConfig.strings.telcoFinancingTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { CSQ.trackScreenview("Telco - Device Financing") }
    }

    private func financeOption(_ mode: TelcoFinanceMode, title: String, sub: String) -> some View {
        Button {
            purchase.financeMode = mode
            fireFinancing()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: purchase.financeMode == mode ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(purchase.financeMode == mode ? .csqTelcoTeal : .csqTextTertiary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(AppFont.body(15)).fontWeight(.semibold).foregroundColor(.csqTextPrimary)
                    Text(sub).font(AppFont.body(12)).foregroundColor(.csqTextSecondary)
                }
                Spacer()
            }
            .padding(14)
            .background(Color.csqSurface)
            .overlay(RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(purchase.financeMode == mode ? Color.csqTelcoTeal : Color.csqBorder, lineWidth: 1.5))
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        }
        .accessibilityIdentifier("device_financing_mode_\(mode.analytics)")
    }

    private func planChip(_ plan: TelcoPlan) -> some View {
        let selected = purchase.attachedPlan?.id == plan.id
        return VStack(alignment: .leading, spacing: 4) {
            Text(plan.displayName).font(AppFont.body(13)).fontWeight(.bold)
                .foregroundColor(selected ? .white : .csqTextPrimary)
            Text(telcoMoney(plan.monthlyPrice, marketConfig.market) + marketConfig.strings.telcoPricePerMonth)
                .font(AppFont.body(11)).foregroundColor(selected ? .white : .csqTelcoTeal)
            Text(plan.dataAllowance).font(AppFont.body(10))
                .foregroundColor(selected ? .white.opacity(0.9) : .csqTextSecondary)
        }
        .frame(width: 130, alignment: .leading)
        .padding(12)
        .background(selected ? Color.csqTelcoTeal : Color.csqSurface)
        .overlay(RoundedRectangle(cornerRadius: AppRadius.md).stroke(Color.csqBorder, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }

    private var priceSummary: some View {
        VStack(spacing: 10) {
            HStack {
                Text(marketConfig.strings.telcoDueToday).foregroundColor(.csqTextSecondary)
                Spacer()
                Text(telcoMoney(purchase.dueToday, marketConfig.market))
                    .fontWeight(.bold).foregroundColor(.csqTextPrimary)
            }
            HStack {
                Text(marketConfig.strings.telcoMonthlyLabel).foregroundColor(.csqTextSecondary)
                Spacer()
                Text(telcoMoney(purchase.monthlyTotal, marketConfig.market) + marketConfig.strings.telcoPricePerMonth)
                    .fontWeight(.bold).foregroundColor(.csqTelcoTeal)
            }
        }
        .font(AppFont.body(14))
        .padding(14)
        .background(Color.csqSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }
}
