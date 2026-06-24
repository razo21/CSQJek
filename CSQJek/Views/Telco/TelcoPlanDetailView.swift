import SwiftUI
import ContentsquareSDK

struct TelcoPlanDetailView: View {
    let plan: TelcoPlan
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var marketConfig: MarketConfig

    private enum PlanDetailAccessID {
        static let backButton = "telco_detail_btn_back"
        static let scrollView = "telco_detail_scroll"
        static let whatsIncluded = "telco_detail_whats_included"
        static let compareSection = "telco_detail_compare"
        static let portInCard = "telco_detail_portin"
        static let faqSection = "telco_detail_faq"
        static func signupButton(_ name: String) -> String { "telco_btn_signup_\(name.lowercased())" }
    }

    var body: some View {
        ZStack(alignment: .top) {
            // Background
            Color(hex: "#F8F3EF")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerView
                    .frame(height: 200)

                // Content
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) {
                        // What's Included
                        whatsIncludedCard

                        // Compare Section
                        compareSection

                        // Port-in Offer
                        portInCard

                        // FAQ Section
                        faqSection

                        Spacer()
                            .frame(height: 100)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                }
                .accessibilityIdentifier(PlanDetailAccessID.scrollView)

                Spacer()
            }

            // Sticky CTA Bar
            VStack(spacing: 0) {
                Spacer()

                stickyCtaBar
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            CSQ.trackScreenview("Telco - Plan Detail")
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Back Button
            Button(action: { dismiss() }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text(marketConfig.strings.telcoBackButton)
                }
                .font(AppFont.body(14))
                .foregroundColor(.white)
            }
            .accessibilityIdentifier(PlanDetailAccessID.backButton)
            .padding(.horizontal, 16)
            .padding(.top, 12)

            // Plan Info
            VStack(alignment: .leading, spacing: 8) {
                Text(plan.displayName)
                    .font(AppFont.display(22))
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                HStack(spacing: 8) {
                    Text(plan.type.displayName(for: marketConfig.market))
                        .font(AppFont.body(12))
                        .fontWeight(.semibold)
                        .foregroundColor(plan.color)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 10)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(AppRadius.sm)

                    Spacer()
                }
            }
            .padding(.horizontal, 16)

            // Price Display
            HStack(alignment: .top, spacing: 4) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(marketConfig.strings.cashCurrencyPrefix)
                            .font(AppFont.body(24))
                            .fontWeight(.bold)

                        Text("\(marketConfig.market == .tokyo ? Int(plan.monthlyPrice) * 100 : Int(plan.monthlyPrice))")
                            .font(AppFont.display(48))
                            .fontWeight(.bold)
                    }

                    Text(marketConfig.strings.telcoPricePerMonth)
                        .font(AppFont.body(14))
                        .foregroundColor(.white.opacity(0.9))
                }

                Spacer()
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)

            // Data Allowance
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(marketConfig.strings.telcoDataAllowance)
                        .font(AppFont.body(12))
                        .foregroundColor(.white.opacity(0.8))

                    Text(plan.dataAllowance)
                        .font(AppFont.display(20))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }

                Spacer()

                VStack(alignment: .center, spacing: 4) {
                    Text(plan.contractTerm)
                        .font(AppFont.body(11))
                        .foregroundColor(plan.color)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 10)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(AppRadius.sm)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)

            Spacer()
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    plan.color,
                    plan.color.opacity(0.7)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    // MARK: - What's Included Card

    private var whatsIncludedCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(marketConfig.strings.telcoEverythingInPlan)
                .font(AppFont.display(16))
                .fontWeight(.bold)
                .foregroundColor(Color(hex: "#1C1C2E"))

            VStack(alignment: .leading, spacing: 12) {
                ForEach(plan.features, id: \.self) { feature in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "#0EA5E9"))
                            .frame(width: 24)
                            .padding(.top, 2)

                        Text(feature)
                            .font(AppFont.body(14))
                            .foregroundColor(Color(hex: "#1C1C2E"))
                            .lineLimit(3)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(hex: "#FFFFFF"))
        .cornerRadius(AppRadius.md)
        .accessibilityIdentifier(PlanDetailAccessID.whatsIncluded)
    }

    // MARK: - Compare Section

    private var compareSection: some View {
        let otherPlans = TelcoPlan.plans(for: marketConfig.market).filter { $0.type == plan.type && $0.id != plan.id }

        return VStack(alignment: .leading, spacing: 12) {
            Text(marketConfig.strings.telcoCompareOtherPlans)
                .font(AppFont.display(16))
                .fontWeight(.bold)
                .foregroundColor(Color(hex: "#1C1C2E"))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(otherPlans) { otherPlan in
                        NavigationLink(destination: TelcoPlanDetailView(plan: otherPlan)) {
                            ComparisonCard(plan: otherPlan)
                        }
                    }
                }
            }
        }
        .accessibilityIdentifier(PlanDetailAccessID.compareSection)
    }

    // MARK: - Port-in Card

    private var portInCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(marketConfig.strings.telcoPortInTitle)
                .font(AppFont.display(16))
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text(marketConfig.strings.telcoPortInBody)
                .font(AppFont.body(13))
                .foregroundColor(.white.opacity(0.9))

            Button(action: {}) {
                HStack(spacing: 4) {
                    Text(marketConfig.strings.telcoPortInNow)
                        .font(AppFont.body(14))
                        .fontWeight(.semibold)

                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "#0EA5E9"),
                    Color(hex: "#0369A1")
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(AppRadius.md)
        .accessibilityIdentifier(PlanDetailAccessID.portInCard)
    }

    // MARK: - FAQ Section

    private var faqSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(marketConfig.strings.telcoFAQTitle)
                .font(AppFont.display(16))
                .fontWeight(.bold)
                .foregroundColor(Color(hex: "#1C1C2E"))

            VStack(spacing: 8) {
                FAQItem(
                    question: marketConfig.strings.telcoFAQ1Q,
                    answer: marketConfig.strings.telcoFAQ1A
                )

                FAQItem(
                    question: marketConfig.strings.telcoFAQ2Q,
                    answer: marketConfig.strings.telcoFAQ2A
                )

                FAQItem(
                    question: marketConfig.strings.telcoFAQ3Q,
                    answer: marketConfig.strings.telcoFAQ3A
                )

                FAQItem(
                    question: marketConfig.strings.telcoFAQ4Q,
                    answer: marketConfig.strings.telcoFAQ4A
                )
            }
        }
        .accessibilityIdentifier(PlanDetailAccessID.faqSection)
    }

    // MARK: - Sticky CTA Bar

    private var stickyCtaBar: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(marketConfig.market.formatPrice(
                        marketConfig.market == .tokyo
                            ? Double(Int(plan.monthlyPrice) * 100)
                            : plan.monthlyPrice
                    ))
                        .font(AppFont.display(20))
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "#1C1C2E"))

                    Text(marketConfig.strings.telcoPerMonth)
                        .font(AppFont.body(12))
                        .foregroundColor(Color(hex: "#6B7280"))
                }

                Spacer()

                NavigationLink(destination: PlanSignupView(plan: plan)) {
                    Text(marketConfig.strings.telcoSignUpFor(plan.displayName))
                        .font(AppFont.body(15)).fontWeight(.bold).foregroundColor(.white)
                        .padding(.vertical, 14).padding(.horizontal, 20)
                        .background(Color.csqTelcoTeal)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                }
                .simultaneousGesture(TapGesture().onEnded {
                    CSQ.trackEvent("telco_plan_signup_tapped", properties: [
                        "plan_name": plan.name,
                        "price":     plan.monthlyPrice
                    ])
                })
                .accessibilityIdentifier(PlanDetailAccessID.signupButton(plan.name))
            }
            .padding(16)
            .background(Color(hex: "#FFFFFF"))
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: -2)
        }
    }
}

// MARK: - Comparison Card Component

struct ComparisonCard: View {
    let plan: TelcoPlan
    @EnvironmentObject var marketConfig: MarketConfig

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(plan.displayName)
                .font(AppFont.body(13))
                .fontWeight(.bold)
                .foregroundColor(Color(hex: "#1C1C2E"))

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(marketConfig.market.formatPrice(
                        marketConfig.market == .tokyo
                            ? Double(Int(plan.monthlyPrice) * 100)
                            : plan.monthlyPrice
                    ))
                        .font(AppFont.body(14))
                        .fontWeight(.semibold)
                        .foregroundColor(plan.color)

                    Spacer()

                    Text(marketConfig.strings.telcoPricePerMonth)
                        .font(AppFont.body(11))
                        .foregroundColor(Color(hex: "#6B7280"))
                }

                Text(plan.dataAllowance)
                    .font(AppFont.body(12))
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "#1C1C2E"))

                Text(plan.contractTerm)
                    .font(AppFont.body(10))
                    .foregroundColor(Color(hex: "#9CA3AF"))
            }

            Spacer()

            HStack(spacing: 4) {
                Text(marketConfig.strings.telcoViewDetails)
                    .font(AppFont.body(12))
                    .fontWeight(.semibold)
                    .foregroundColor(plan.color)

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(plan.color)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 180)
        .padding(12)
        .background(Color(hex: "#FFFFFF"))
        .cornerRadius(AppRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(Color(hex: "#E8E0DA"), lineWidth: 1)
        )
    }
}

// MARK: - FAQ Item Component

struct FAQItem: View {
    let question: String
    let answer: String
    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(
            isExpanded: $isExpanded,
            content: {
                Text(answer)
                    .font(AppFont.body(13))
                    .foregroundColor(Color(hex: "#6B7280"))
                    .padding(.top, 12)
            },
            label: {
                HStack {
                    Text(question)
                        .font(AppFont.body(14))
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "#1C1C2E"))

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(Color(hex: "#9CA3AF"))
                }
            }
        )
        .padding(12)
        .background(Color(hex: "#FFFFFF"))
        .cornerRadius(AppRadius.md)
    }
}

#Preview {
    NavigationView {
        TelcoPlanDetailView(plan: TelcoPlan.plans(for: .singapore)[1])
    }
    .environmentObject(MarketConfig())
    .environmentObject(TelcoPurchaseStore())
}

// MARK: - Plan Signup (plan funnel step 1)

struct PlanSignupView: View {
    let plan: TelcoPlan
    @EnvironmentObject var marketConfig: MarketConfig
    @EnvironmentObject var purchase: TelcoPurchaseStore

    private func fireSim() {
        CSQ.trackEvent("telco_plan_sim_selected", properties: [
            "plan_name":     plan.name,
            "sim_type":      purchase.simType.analytics,
            "number_choice": purchase.numberChoice.analytics,
            "market":        marketConfig.market.trackingLabel
        ])
    }

    var body: some View {
        let s = marketConfig.strings
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                Text(s.telcoSignupTitle)
                    .font(AppFont.display(20)).fontWeight(.bold).foregroundColor(.csqTextPrimary)

                Text(s.telcoSimTypeTitle)
                    .font(AppFont.body(15)).fontWeight(.bold).foregroundColor(.csqTextPrimary)
                VStack(spacing: 12) {
                    optionCard(selected: purchase.simType == .esim, icon: TelcoSIMType.esim.icon,
                               title: s.telcoESIMLabel, sub: s.telcoESIMSub, id: "plan_signup_sim_esim") {
                        purchase.simType = .esim; purchase.fulfillment = .esim; fireSim()
                    }
                    optionCard(selected: purchase.simType == .physical, icon: TelcoSIMType.physical.icon,
                               title: s.telcoPhysicalSIMLabel, sub: s.telcoPhysicalSIMSub, id: "plan_signup_sim_physical") {
                        purchase.simType = .physical; purchase.fulfillment = .delivery; fireSim()
                    }
                }

                Text(s.telcoNumberTitle)
                    .font(AppFont.body(15)).fontWeight(.bold).foregroundColor(.csqTextPrimary)
                VStack(spacing: 12) {
                    optionCard(selected: purchase.numberChoice == .newNumber, icon: "number",
                               title: s.telcoNewNumberLabel, sub: s.telcoNewNumberSub, id: "plan_signup_number_new") {
                        purchase.numberChoice = .newNumber; fireSim()
                    }
                    optionCard(selected: purchase.numberChoice == .portIn, icon: "arrow.left.arrow.right",
                               title: s.telcoKeepNumberLabel, sub: s.telcoKeepNumberSub, id: "plan_signup_number_portin") {
                        purchase.numberChoice = .portIn; fireSim()
                    }
                }

                NavigationLink(destination: TelcoCheckoutView()) {
                    TelcoCTALabel(text: s.telcoContinueCheckout)
                }
                .accessibilityIdentifier("plan_signup_btn_checkout")
                .padding(.top, 4)
            }
            .padding(16)
        }
        .background(Color.csqBackground.ignoresSafeArea())
        .navigationTitle(plan.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            purchase.startPlan(plan)
            CSQ.trackScreenview("Telco - Plan Signup")
            CSQ.trackEvent("telco_plan_signup_started", properties: [
                "plan_name": plan.name,
                "plan_type": plan.type.rawValue,
                "price":     plan.monthlyPrice,
                "market":    marketConfig.market.trackingLabel
            ])
        }
    }

    @ViewBuilder
    private func optionCard(selected: Bool, icon: String, title: String, sub: String,
                            id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon).font(.system(size: 18))
                    .foregroundColor(selected ? .white : .csqTelcoTeal)
                    .frame(width: 40, height: 40)
                    .background(selected ? Color.csqTelcoTeal : Color.csqTelcoTeal.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(AppFont.body(15)).fontWeight(.semibold).foregroundColor(.csqTextPrimary)
                    Text(sub).font(AppFont.body(12)).foregroundColor(.csqTextSecondary)
                }
                Spacer()
                Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(selected ? .csqTelcoTeal : .csqTextTertiary)
            }
            .padding(14).background(Color.csqSurface)
            .overlay(RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(selected ? Color.csqTelcoTeal : Color.csqBorder, lineWidth: 1.5))
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        }
        .accessibilityIdentifier(id)
    }
}

// MARK: - Shared Checkout (device + plan funnels)

struct TelcoCheckoutView: View {
    @EnvironmentObject var marketConfig: MarketConfig
    @EnvironmentObject var purchase: TelcoPurchaseStore

    @State private var name = ""
    @State private var idNumber = ""
    @State private var email = ""
    @State private var address = ""
    @State private var cardNumber = ""
    @State private var payWallet = false   // false = card, true = wallet

    private var needsAddress: Bool { purchase.fulfillment == .delivery }

    private func fireFulfillment(_ f: TelcoFulfillment) {
        CSQ.trackEvent("telco_fulfillment_selected", properties: [
            "kind": purchase.kind.rawValue, "method": f.analytics,
            "market": marketConfig.market.trackingLabel
        ])
    }
    private func firePayment(_ method: String) {
        CSQ.trackEvent("telco_payment_method_selected", properties: [
            "kind": purchase.kind.rawValue, "method": method,
            "market": marketConfig.market.trackingLabel
        ])
    }

    var body: some View {
        let s = marketConfig.strings
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                summaryCard

                VStack(alignment: .leading, spacing: 10) {
                    Text(s.telcoFulfillmentTitle).font(AppFont.body(15)).fontWeight(.bold).foregroundColor(.csqTextPrimary)
                    fulfillmentRow(.esim, label: s.telcoFulfillmentESIM)
                    fulfillmentRow(.delivery, label: s.telcoFulfillmentDelivery)
                    fulfillmentRow(.pickup, label: s.telcoFulfillmentPickup)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text(s.telcoYourDetailsTitle).font(AppFont.body(15)).fontWeight(.bold).foregroundColor(.csqTextPrimary)
                    maskedField(s.telcoFieldName, text: $name, id: "checkout_input_name")
                    maskedField(s.telcoFieldID, text: $idNumber, id: "checkout_input_id")
                    maskedField(s.telcoFieldEmail, text: $email, id: "checkout_input_email")
                    if needsAddress {
                        maskedField(s.telcoFieldAddress, text: $address, id: "checkout_input_address")
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text(s.telcoPaymentTitle).font(AppFont.body(15)).fontWeight(.bold).foregroundColor(.csqTextPrimary)
                    paymentRow(s.telcoPayCard, walletChoice: false, id: "checkout_pay_card")
                    paymentRow(s.telcoPayWallet, walletChoice: true, id: "checkout_pay_wallet")
                    if !payWallet {
                        maskedField(s.telcoFieldCardNumber, text: $cardNumber, id: "checkout_input_card")
                    }
                }

                NavigationLink(destination: TelcoCreditCheckView()) {
                    TelcoCTALabel(text: s.telcoContinueVerify)
                }
                .accessibilityIdentifier("checkout_btn_continue")
                .padding(.top, 4)
            }
            .padding(16)
        }
        .background(Color.csqBackground.ignoresSafeArea())
        .navigationTitle(s.telcoCheckoutTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            CSQ.trackScreenview("Telco - Checkout")
            CSQ.trackEvent("telco_checkout_started", properties: [
                "kind":          purchase.kind.rawValue,
                "item":          purchase.itemKey,
                "due_today":     purchase.dueToday,
                "monthly_total": purchase.monthlyTotal,
                "market":        marketConfig.market.trackingLabel
            ])
        }
    }

    private var summaryCard: some View {
        let m = marketConfig.market
        let s = marketConfig.strings
        return VStack(alignment: .leading, spacing: 8) {
            Text(s.telcoOrderSummary).font(AppFont.body(13)).fontWeight(.bold).foregroundColor(.csqTextSecondary)
            HStack {
                Text(purchase.itemLabel).font(AppFont.body(15)).fontWeight(.semibold).foregroundColor(.csqTextPrimary)
                Spacer()
            }
            if purchase.kind == .device, let storage = purchase.selectedStorage {
                Text("\(purchase.selectedColor) · \(storage.label)")
                    .font(AppFont.body(12)).foregroundColor(.csqTextSecondary)
            }
            Divider()
            HStack {
                Text(s.telcoDueToday).foregroundColor(.csqTextSecondary)
                Spacer()
                Text(telcoMoney(purchase.dueToday, m)).fontWeight(.bold).foregroundColor(.csqTextPrimary)
            }.font(AppFont.body(14))
            HStack {
                Text(s.telcoMonthlyLabel).foregroundColor(.csqTextSecondary)
                Spacer()
                Text(telcoMoney(purchase.monthlyTotal, m) + s.telcoPricePerMonth)
                    .fontWeight(.bold).foregroundColor(.csqTelcoTeal)
            }.font(AppFont.body(14))
        }
        .padding(14).background(Color.csqSurface).clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }

    private func fulfillmentRow(_ f: TelcoFulfillment, label: String) -> some View {
        Button {
            purchase.fulfillment = f
            fireFulfillment(f)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: f.icon)
                    .foregroundColor(purchase.fulfillment == f ? .csqTelcoTeal : .csqTextTertiary).frame(width: 24)
                Text(label).font(AppFont.body(14)).foregroundColor(.csqTextPrimary)
                Spacer()
                Image(systemName: purchase.fulfillment == f ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(purchase.fulfillment == f ? .csqTelcoTeal : .csqTextTertiary)
            }
            .padding(12).background(Color.csqSurface)
            .overlay(RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(purchase.fulfillment == f ? Color.csqTelcoTeal : Color.csqBorder, lineWidth: 1.2))
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        }
        .accessibilityIdentifier("checkout_fulfillment_\(f.analytics)")
    }

    private func paymentRow(_ label: String, walletChoice: Bool, id: String) -> some View {
        let selected = payWallet == walletChoice
        return Button {
            payWallet = walletChoice
            firePayment(walletChoice ? "wallet" : "card")
        } label: {
            HStack(spacing: 12) {
                Image(systemName: walletChoice ? "qrcode" : "creditcard.fill")
                    .foregroundColor(selected ? .csqTelcoTeal : .csqTextTertiary).frame(width: 24)
                Text(label).font(AppFont.body(14)).foregroundColor(.csqTextPrimary)
                Spacer()
                Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(selected ? .csqTelcoTeal : .csqTextTertiary)
            }
            .padding(12).background(Color.csqSurface)
            .overlay(RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(selected ? Color.csqTelcoTeal : Color.csqBorder, lineWidth: 1.2))
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        }
        .accessibilityIdentifier(id)
    }

    private func maskedField(_ placeholder: String, text: Binding<String>, id: String) -> some View {
        TextField(placeholder, text: text)
            .font(AppFont.body(14))
            .padding(12)
            .background(Color.csqSurface)
            .overlay(RoundedRectangle(cornerRadius: AppRadius.md).stroke(Color.csqBorder, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            .csqMaskContents(true)
            .accessibilityIdentifier(id)
    }
}

// MARK: - Credit / ID Check (the funnel's drop-off step)

struct TelcoCreditCheckView: View {
    @EnvironmentObject var marketConfig: MarketConfig
    @EnvironmentObject var purchase: TelcoPurchaseStore

    @State private var consented = false
    @State private var checking = false
    @State private var showConfirmed = false
    @State private var declined = false

    var body: some View {
        let s = marketConfig.strings
        let m = marketConfig.market
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                Image(systemName: "checkmark.shield.fill").font(.system(size: 44)).foregroundColor(.csqTelcoTeal)
                Text(s.telcoCreditTitle).font(AppFont.display(20)).fontWeight(.bold).foregroundColor(.csqTextPrimary)
                Text(s.telcoCreditBody).font(AppFont.body(14)).foregroundColor(.csqTextSecondary)

                Toggle(isOn: $consented) {
                    Text(s.telcoCreditConsent).font(AppFont.body(13)).foregroundColor(.csqTextPrimary)
                }
                .tint(.csqTelcoTeal)
                .accessibilityIdentifier("credit_toggle_consent")

                if purchase.creditApproved {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.csqSuccess)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(s.telcoCreditApproved).font(AppFont.body(15)).fontWeight(.bold).foregroundColor(.csqTextPrimary)
                            Text(s.telcoCreditApprovedSub).font(AppFont.body(12)).foregroundColor(.csqTextSecondary)
                        }
                        Spacer()
                    }
                    .padding(14).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.csqSuccess.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: AppRadius.md))

                    NavigationLink(destination: TelcoOrderConfirmedView(), isActive: $showConfirmed) { EmptyView() }
                        .hidden()

                    Button {
                        CSQ.trackEvent("telco_purchase_completed", properties: [
                            "kind":          purchase.kind.rawValue,
                            "item":          purchase.itemKey,
                            "plan_name":     purchase.attachedPlan?.name ?? purchase.plan?.name ?? "none",
                            "finance_mode":  purchase.kind == .device ? purchase.financeMode.analytics : "n/a",
                            "term_months":   (purchase.kind == .device && purchase.financeMode == .installment24) ? 24 : 0,
                            "due_today":     purchase.dueToday,
                            "monthly_total": purchase.monthlyTotal,
                            "market":        m.trackingLabel
                        ])
                        showConfirmed = true
                    } label: {
                        TelcoCTALabel(text: s.telcoPlaceOrder)
                    }
                    .accessibilityIdentifier("credit_btn_place_order")
                } else if declined {
                    HStack(spacing: 10) {
                        Image(systemName: "xmark.octagon.fill").foregroundColor(.csqError)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(s.telcoCreditDeclined).font(AppFont.body(15)).fontWeight(.bold).foregroundColor(.csqTextPrimary)
                            Text(s.telcoCreditDeclinedSub).font(AppFont.body(12)).foregroundColor(.csqTextSecondary)
                        }
                        Spacer()
                    }
                    .padding(14).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.csqError.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: AppRadius.md))

                    Button {
                        purchase.financeMode = .outright
                        declined = false
                        purchase.creditApproved = true   // outright needs no financing approval
                        CSQ.trackEvent("telco_credit_recovery_outright", properties: [
                            "kind":      purchase.kind.rawValue,
                            "item":      purchase.itemKey,
                            "due_today": purchase.dueToday,
                            "market":    m.trackingLabel
                        ])
                    } label: {
                        TelcoCTALabel(text: s.telcoSwitchOutright)
                    }
                    .accessibilityIdentifier("credit_btn_switch_outright")
                } else {
                    Button {
                        guard consented, !checking else { return }
                        checking = true
                        CSQ.trackEvent("telco_credit_check_started", properties: [
                            "kind":   purchase.kind.rawValue,
                            "item":   purchase.itemKey,
                            "amount": purchase.dueToday,
                            "market": m.trackingLabel
                        ])
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                            checking = false
                            // High-value devices on instalment are declined — a realistic
                            // funnel cliff. Everything else is approved.
                            let declineHighValue = (purchase.kind == .device)
                                && (purchase.financeMode == .installment24)
                                && ((purchase.device?.outrightPrice ?? 0) >= 2000)
                            if declineHighValue {
                                declined = true
                                CSQ.trackEvent("telco_credit_check_result", properties: [
                                    "kind": purchase.kind.rawValue, "result": "declined", "market": m.trackingLabel
                                ])
                            } else {
                                purchase.creditApproved = true
                                CSQ.trackEvent("telco_credit_check_result", properties: [
                                    "kind": purchase.kind.rawValue, "result": "approved", "market": m.trackingLabel
                                ])
                            }
                        }
                    } label: {
                        TelcoCTALabel(text: checking ? s.telcoChecking : s.telcoRunCheck, enabled: consented)
                    }
                    .disabled(!consented || checking)
                    .accessibilityIdentifier("credit_btn_run_check")
                }
            }
            .padding(16)
        }
        .background(Color.csqBackground.ignoresSafeArea())
        .navigationTitle(s.telcoCreditTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { CSQ.trackScreenview("Telco - Credit Check") }
    }
}

// MARK: - Order Confirmed (shared)

struct TelcoOrderConfirmedView: View {
    @EnvironmentObject var marketConfig: MarketConfig
    @EnvironmentObject var purchase: TelcoPurchaseStore
    @Environment(\.dismiss) private var dismiss

    private let orderNumber = "CSQ-" + String(Int.random(in: 100000...999999))

    var body: some View {
        let s = marketConfig.strings
        let showESIM = purchase.kind == .plan && purchase.simType == .esim
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 18) {
                Image(systemName: "checkmark.circle.fill").font(.system(size: 64)).foregroundColor(.csqSuccess).padding(.top, 24)
                Text(s.telcoOrderConfirmedTitle).font(AppFont.display(22)).fontWeight(.bold).foregroundColor(.csqTextPrimary)
                Text(s.telcoOrderConfirmedSub).font(AppFont.body(14)).foregroundColor(.csqTextSecondary)
                    .multilineTextAlignment(.center)

                VStack(spacing: 4) {
                    Text(s.telcoOrderNumberLabel).font(AppFont.body(12)).foregroundColor(.csqTextSecondary)
                    Text(orderNumber).font(AppFont.body(16)).fontWeight(.bold).foregroundColor(.csqTextPrimary)
                }
                .padding(14).frame(maxWidth: .infinity).background(Color.csqSurface)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))

                if showESIM {
                    VStack(spacing: 10) {
                        Text(s.telcoESIMReady).font(AppFont.body(15)).fontWeight(.bold).foregroundColor(.csqTextPrimary)
                        Image(systemName: "qrcode").font(.system(size: 120)).foregroundColor(.csqTextPrimary)
                        Text(s.telcoScanToActivate).font(AppFont.body(12)).foregroundColor(.csqTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(16).frame(maxWidth: .infinity).background(Color.csqSurface)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                }

                Button { dismiss() } label: {
                    TelcoCTALabel(text: s.telcoBackToMobile)
                }
                .accessibilityIdentifier("order_confirmed_btn_done")
            }
            .padding(16)
        }
        .background(Color.csqBackground.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .onAppear { CSQ.trackScreenview("Telco - Order Confirmed") }
    }
}
