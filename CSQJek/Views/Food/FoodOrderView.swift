import SwiftUI
import ContentsquareSDK

// MARK: - CS Accessibility IDs
private enum OrderAccessID {
    static let backButton          = "food_order_btn_back"
    static let cartList            = "food_order_cart_list"
    static func cartItemRow(_ name: String) -> String { "food_order_item_\(name.lowercased().replacingOccurrences(of: " ", with: "_"))" }
    static let addressRow          = "food_order_row_address"
    static let paymentRow          = "food_order_row_payment"
    static let promoRow            = "food_order_row_promo"
    static let placeOrderButton    = "food_order_btn_place_order"
    static let confirmDoneButton   = "food_confirm_btn_done"
    static let confirmTrackButton  = "food_confirm_btn_track"
}

// MARK: - ScrollSnapAnchor  (UIKit bridge — replaces PreferenceKey approach)
// Placed as a .background() on the first item in the scroll content.
// Walks the UIView hierarchy to find its parent UIScrollView, then uses
// KVO on contentOffset so it fires EVERY frame — including during deceleration.
// Calling setContentOffset directly on UIScrollView is the only reliable way
// to kill momentum and snap back; proxy.scrollTo loses the race.
private struct ScrollSnapAnchor: UIViewRepresentable {
    /// Points scrolled down before snap fires. Positive = downward.
    let threshold: CGFloat
    let onScrollStarted: () -> Void   // CS: fires once on first scroll > 20pt
    let onSnapTriggered: () -> Void   // CS: fires each time snap kicks in

    func makeCoordinator() -> Coordinator {
        Coordinator(threshold: threshold,
                    onScrollStarted: onScrollStarted,
                    onSnapTriggered: onSnapTriggered)
    }

    func makeUIView(context: Context) -> AnchorView {
        let v = AnchorView(coordinator: context.coordinator)
        v.backgroundColor = .clear
        v.isUserInteractionEnabled = false
        return v
    }

    func updateUIView(_ uiView: AnchorView, context: Context) {
        context.coordinator.threshold        = threshold
        context.coordinator.onScrollStarted = onScrollStarted
        context.coordinator.onSnapTriggered = onSnapTriggered
    }

    // MARK: Host UIView — finds scroll view when added to window
    class AnchorView: UIView {
        private let coordinator: Coordinator
        init(coordinator: Coordinator) {
            self.coordinator = coordinator
            super.init(frame: .zero)
        }
        required init?(coder: NSCoder) { fatalError() }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard window != nil else { return }
            var v: UIView? = superview
            while let view = v {
                if let sv = view as? UIScrollView {
                    coordinator.attach(to: sv)
                    return
                }
                v = view.superview
            }
        }
    }

    // MARK: Coordinator — owns the KVO observation
    class Coordinator: NSObject {
        var threshold: CGFloat
        var onScrollStarted: () -> Void
        var onSnapTriggered: () -> Void

        private var isSnapping          = false
        private var didFireScrollStart  = false
        private var observation: NSKeyValueObservation?
        private weak var scrollView: UIScrollView?

        init(threshold: CGFloat,
             onScrollStarted: @escaping () -> Void,
             onSnapTriggered: @escaping () -> Void) {
            self.threshold        = threshold
            self.onScrollStarted  = onScrollStarted
            self.onSnapTriggered  = onSnapTriggered
        }

        func attach(to sv: UIScrollView) {
            guard scrollView !== sv else { return }
            observation?.invalidate()
            scrollView = sv

            observation = sv.observe(\.contentOffset, options: [.new]) { [weak self] scrollView, change in
                guard let self, let y = change.newValue?.y else { return }

                // CS: scroll_started fires once on any meaningful downward scroll
                if !self.didFireScrollStart && y > 20 {
                    self.didFireScrollStart = true
                    DispatchQueue.main.async { self.onScrollStarted() }
                }

                // Snap back — guard prevents re-entrancy during the return animation
                guard y > self.threshold, !self.isSnapping else { return }
                self.isSnapping = true
                DispatchQueue.main.async {
                    self.onSnapTriggered()
                    // setContentOffset directly on UIScrollView kills deceleration
                    // immediately. animated:true gives the spring feel.
                    scrollView.setContentOffset(.zero, animated: true)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.isSnapping = false
                    }
                }
            }
        }

        deinit { observation?.invalidate() }
    }
}

// MARK: - FoodOrderView
// Unified cart → checkout → confirmation flow.

struct FoodOrderView: View {
    let restaurant: Restaurant
    @ObservedObject var cartStore: FoodCartStore
    @EnvironmentObject var marketConfig: MarketConfig
    @Environment(\.dismiss) var dismiss

    @State private var promoCode = ""
    @State private var showPromoField = false
    @State private var promoRage = RageTapDetector()   // rapid invalid-Apply taps
    @State private var promoFailures = 0
    @State private var isPlacingOrder = false
    @State private var orderPlaced = false
    @State private var selectedPayment = "Visa •••• 4821"

    // Place Order failure frustration state
    @State private var orderAttempts = 0
    @State private var orderErrorMessage: String? = nil

    // Scroll snap threshold — pt of downward scroll before snap-back fires.
    // 80pt is roughly one thumb-flick; fires well before the order summary
    // enters the viewport so the user never reads the totals.
    private let snapBackThreshold: CGFloat = 80

    private var deliveryFeeValue: Double {
        let isFree = restaurant.deliveryFee == "Free" || restaurant.deliveryFee == "無料"
        if isFree { return 0.0 }
        return marketConfig.market == .tokyo ? 199.0 : 1.99
    }
    private var total: Double { cartStore.subtotal + deliveryFeeValue }

    // 8 recommended items — enough height to push order summary well below the fold.
    // The extra depth is what makes the scroll snap-back actually effective.
    private var recommendedItems: [(name: String, desc: String, price: Double, tag: String)] {
        let singapore: [(name: String, desc: String, price: Double, tag: String)] = [
            ("Kopi O Kosong",        "Local black coffee, unsweetened",              1.80, "Popular"),
            ("Teh Tarik",            "Pulled milk tea — frothy & sweet",             2.20, "Trending"),
            ("Curry Puff",           "Old Chang Kee — flaky pastry, spiced filling", 1.60, "Add-on"),
            ("Mineral Water 500ml",  "Chilled",                                       1.00, ""),
            ("Bandung",              "Rose syrup with evaporated milk",              1.80, "Local fav"),
            ("Milo Dinosaur",        "Extra Milo powder on top — cold",              2.50, "Popular"),
            ("Kaya Butter Toast",    "Goes with anything",                           2.00, "Pair it"),
            ("Soft-boiled Eggs (2)", "Classic kopitiam style, with dark soy",        1.20, "Classic"),
        ]
        let sydney: [(name: String, desc: String, price: Double, tag: String)] = [
            ("Flat White",           "Single-origin, locally roasted",               4.50, "Popular"),
            ("Lamington",            "Sponge, chocolate & coconut",                  5.50, "Trending"),
            ("Garlic Bread",         "Wood-fired with garlic butter",                9.00, "Add-on"),
            ("Sparkling Water 500ml", "Chilled",                                      4.00, ""),
            ("Iced Latte",           "Over ice with locally roasted beans",          5.50, "Local fav"),
            ("Sausage Roll",         "Pork & fennel, flaky pastry",                  7.00, "Popular"),
            ("Almond Croissant",     "Goes with any coffee",                         6.50, "Pair it"),
            ("Anzac Biscuit (2)",    "Oats, golden syrup & coconut",                 4.50, "Classic"),
        ]
        let tokyo: [(name: String, desc: String, price: Double, tag: String)] = [
            ("抹茶ラテ",    "濃厚な抹茶と北海道ミルクのブレンド",      550, "人気"),
            ("おにぎり",    "塩むすび・梅・昆布 各種",                 180, "定番"),
            ("唐揚げ (3個)", "国産鶏の揚げたて — 柚子胡椒添え",       420, "おすすめ"),
            ("ミネラルウォーター", "冷やして提供",                      120, ""),
            ("枝豆",        "塩茹で — ビールのお供に",                 350, "人気"),
            ("たこ焼き (8個)", "大阪風 — ソース・マヨ・花かつお",     480, "人気"),
            ("ポテトサラダ", "ほっくりじゃがいも、マヨネーズ仕立て",  320, "一品"),
            ("味噌汁",      "豆腐と わかめ — ほっとする一杯",         250, "定番"),
        ]
        let byMarket: [Market: [(name: String, desc: String, price: Double, tag: String)]] = [
            .singapore: singapore,
            .sydney:    sydney,
            .tokyo:     tokyo
        ]
        return byMarket[marketConfig.market] ?? singapore
    }

    var body: some View {
        ZStack {
            Color.csqBackground.ignoresSafeArea()

            if orderPlaced {
                OrderConfirmedView(restaurant: restaurant, total: total, onDone: { dismiss() })
                    .environmentObject(marketConfig)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
            } else {
                checkoutContent
            }
        }
        .navigationBarHidden(true)
        .onAppear { CSQ.trackScreenview("Food - Checkout") }
    }

    // MARK: - Checkout Content
    private var checkoutContent: some View {
        VStack(spacing: 0) {
            // Header
            ZStack(alignment: .leading) {
                LinearGradient(
                    colors: [Color(hex: "#FF8C42"), Color(hex: "#E05A00")],
                    startPoint: .leading, endPoint: .trailing
                )
                .frame(height: 88)
                .ignoresSafeArea(edges: .top)

                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 38, height: 38)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                    .accessibilityIdentifier(OrderAccessID.backButton)
                    .padding(.leading, 16)

                    Spacer()

                    VStack(spacing: 2) {
                        Text(marketConfig.strings.foodYourOrder)
                            .font(AppFont.display(17))
                            .foregroundColor(.white)
                        Text(restaurant.name)
                            .font(AppFont.body(12))
                            .foregroundColor(.white.opacity(0.8))
                    }

                    Spacer()
                    Color.clear.frame(width: 38, height: 38).padding(.trailing, 16)
                }
                .padding(.top, 8)
            }

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {

                    // ── UIKit snap anchor ────────────────────────────────────
                    // ScrollSnapAnchor (UIViewRepresentable) lives here so it's
                    // inside the UIScrollView's content view. It climbs the
                    // UIView hierarchy, attaches KVO to the UIScrollView, and
                    // calls setContentOffset directly — killing deceleration
                    // immediately, something proxy.scrollTo cannot do.
                    Color.clear
                        .frame(height: 1)
                        .background(
                            ScrollSnapAnchor(
                                threshold: snapBackThreshold,
                                onScrollStarted: {
                                    CSQ.trackEvent("page_scroll_started", properties: [
                                        "screen":           "Food - Checkout",
                                        "restaurant":       restaurant.name,
                                        "scroll_direction": "down"
                                    ])
                                },
                                onSnapTriggered: {
                                    // NOTE: page_scroll_to_bottom intentionally NEVER fires.
                                    // The absence of that event is the CS demo payload.
                                    CSQ.trackEvent("checkout_scroll_blocked", properties: [
                                        "restaurant": restaurant.name,
                                        "threshold":  Int(snapBackThreshold)
                                    ])
                                }
                            )
                        )

                    // Cart items
                    cartItemsSection

                    // Recommended Items — pushes order summary below the fold
                    recommendedItemsSection

                    // Delivery address
                    SectionCard(title: marketConfig.strings.foodDeliveryAddress, icon: "mappin.circle.fill", iconColor: .csqPrimary) {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(marketConfig.strings.checkoutHome)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.csqTextPrimary)
                                Text(marketConfig.strings.foodHomeAddress)
                                    .font(.system(size: 12))
                                    .foregroundColor(.csqTextSecondary)
                            }
                            Spacer()
                            Text(marketConfig.strings.foodChange)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.csqPrimary)
                        }
                        .padding(.top, 4)
                    }
                    .accessibilityIdentifier(OrderAccessID.addressRow)

                    // Payment
                    SectionCard(title: marketConfig.strings.foodPayment, icon: "creditcard.fill", iconColor: .csqRideBlue) {
                        HStack(spacing: 10) {
                            Image(systemName: "creditcard.fill")
                                .foregroundColor(.csqRideBlue)
                                .font(.system(size: 14))
                            Text(selectedPayment)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.csqTextPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(.csqTextTertiary)
                        }
                        .padding(.top, 4)
                    }
                    .accessibilityIdentifier(OrderAccessID.paymentRow)

                    // Promo code
                    SectionCard(title: marketConfig.strings.foodPromoCode, icon: "tag.fill", iconColor: .csqSuccess) {
                        Button {
                            withAnimation { showPromoField.toggle() }
                        } label: {
                            HStack {
                                Text(promoCode.isEmpty ? marketConfig.strings.foodAddPromoCode : promoCode)
                                    .font(.system(size: 14))
                                    .foregroundColor(promoCode.isEmpty ? .csqTextTertiary : .csqSuccess)
                                Spacer()
                                Image(systemName: showPromoField ? "chevron.up" : "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(.csqTextTertiary)
                            }
                            .padding(.top, 4)
                        }
                        .buttonStyle(.plain)

                        if showPromoField {
                            HStack(spacing: 8) {
                                TextField(marketConfig.strings.foodEnterCode, text: $promoCode)
                                    .font(.system(size: 14))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(Color.csqBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
                                Button(marketConfig.strings.foodApply) {
                                    guard !promoCode.isEmpty else { return }
                                    // Demo: only WEEKEND10 is valid — every other code
                                    // silently fails, prompting the user to tap Apply again.
                                    if promoCode.uppercased() != "WEEKEND10" {
                                        promoFailures += 1
                                        if let count = promoRage.registerTap() {
                                            FrustrationSignal.promoRage(
                                                service: "CSQFood", screen: "Food - Checkout",
                                                tapCount: count, failedAttempts: promoFailures,
                                                codeLength: promoCode.count, market: marketConfig.market)
                                        }
                                    }
                                }
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(Color.csqSuccess)
                                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
                                    .accessibilityIdentifier("food_apply_promo_button")
                            }
                            .padding(.top, 8)
                        }
                    }
                    .accessibilityIdentifier(OrderAccessID.promoRow)

                    // Order summary
                    orderSummarySection

                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 120)
            } // ScrollView

            // Bottom CTA
            VStack(spacing: 0) {
                // ── Error banner ─────────────────────────────────────────────
                // Slides in from bottom when order fails. Deliberately vague.
                // CS captures repeated food_order_placed events as retry signal.
                if let errorMsg = orderErrorMessage {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 15))
                        Text(errorMsg)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)
                    .background(Color(hex: "#DC2626"))
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Divider()

                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(marketConfig.strings.foodTotal)
                            .font(.system(size: 12))
                            .foregroundColor(.csqTextSecondary)
                        Text(marketConfig.market.formatPrice(total))
                            .font(AppFont.display(22))
                            .foregroundColor(.csqTextPrimary)
                    }

                    Button {
                        orderAttempts += 1
                        isPlacingOrder = true
                        withAnimation { orderErrorMessage = nil }

                        // CS event fires on EVERY attempt — the repeated events
                        // and escalating attempt_number tell the story in PA.
                        CSQ.trackEvent("food_order_placed", properties: [
                            "restaurant":    restaurant.name,
                            "item_count":    cartStore.itemCount,
                            "total":         String(format: "%.2f", total),
                            "delivery_fee":  String(format: "%.2f", deliveryFeeValue),
                            "attempt_number": orderAttempts
                        ])

                        // Attempts 1 & 2 fail after a long wait. 3rd succeeds.
                        let delay = Double.random(in: 4.2...5.1)
                        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                            isPlacingOrder = false
                            if orderAttempts < 3 {
                                // Silent backend failure — vague message, no detail
                                CSQ.trackEvent("food_order_failed", properties: [
                                    "restaurant":    restaurant.name,
                                    "attempt_number": orderAttempts,
                                    "error_code":    "CHECKOUT_TIMEOUT",
                                    "visible_to_user": true
                                ])
                                withAnimation(.spring()) {
                                    orderErrorMessage = marketConfig.strings.foodSomethingWentWrong
                                }
                            } else {
                                // Finally succeeds — user had to try 3 times
                                orderErrorMessage = nil
                                withAnimation(.spring()) { orderPlaced = true }
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if isPlacingOrder {
                                ProgressView().progressViewStyle(.circular).tint(.white).scaleEffect(0.8)
                            } else {
                                Image(systemName: "bag.fill").font(.system(size: 14))
                            }
                            Text(isPlacingOrder ? marketConfig.strings.foodPlacingOrder : marketConfig.strings.foodPlaceOrder)
                                .font(AppFont.display(15))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(colors: [Color(hex: "#FF8C42"), Color(hex: "#E05A00")],
                                           startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.full))
                        .shadow(color: Color(hex: "#FF8C42").opacity(0.35), radius: 8, x: 0, y: 4)
                    }
                    .disabled(isPlacingOrder || cartStore.itemCount == 0)
                    .accessibilityIdentifier(OrderAccessID.placeOrderButton)
                    .accessibilityLabel("\(marketConfig.strings.foodPlaceOrder) — \(marketConfig.market.formatPrice(total))")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.csqSurface)
            }
        }
    }

    // MARK: - Cart Items Section
    private var cartItemsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(marketConfig.strings.foodOrderSummary)
                .font(AppFont.display(17))
                .foregroundColor(.csqTextPrimary)

            VStack(spacing: 0) {
                ForEach(cartStore.items) { cartItem in
                    HStack(spacing: 12) {
                        // Quantity badge
                        Text("\(cartItem.quantity)×")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Color(hex: "#FF8C42"))
                            .clipShape(RoundedRectangle(cornerRadius: 6))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(cartItem.menuItem.name)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.csqTextPrimary)
                            if !cartItem.menuItem.description.isEmpty {
                                Text(cartItem.menuItem.description)
                                    .font(.system(size: 11))
                                    .foregroundColor(.csqTextTertiary)
                                    .lineLimit(1)
                            }
                        }

                        Spacer()

                        Text(marketConfig.market.formatPrice(cartItem.menuItem.price * Double(cartItem.quantity)))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.csqTextPrimary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .accessibilityIdentifier(OrderAccessID.cartItemRow(cartItem.menuItem.idKey))

                    if cartStore.items.last?.id != cartItem.id {
                        Divider().padding(.leading, 56)
                    }
                }
            }
            .background(Color.csqSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
            .accessibilityIdentifier(OrderAccessID.cartList)
        }
    }

    // MARK: - Recommended Items
    // Placed between cart and address sections to push order summary below the fold.
    // Users must scroll down to see the total — triggering the snap-back frustration loop.
    private var recommendedItemsSection: some View {
        SectionCard(title: marketConfig.strings.foodYouMightLike, icon: "sparkles", iconColor: Color(hex: "#F59E0B")) {
            VStack(spacing: 0) {
                ForEach(Array(recommendedItems.enumerated()), id: \.offset) { idx, item in
                    HStack(spacing: 12) {
                        // Colour swatch thumbnail
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                [Color(hex: "#C8860A"), Color(hex: "#DB2777"),
                                 Color(hex: "#B45309"), Color.csqPrimary][idx % 4]
                            )
                            .frame(width: 48, height: 48)
                            .overlay(
                                Image(systemName: ["cup.and.saucer.fill","cup.and.saucer.fill","fork.knife","drop.fill"][idx % 4])
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                            )

                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Text(item.name)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.csqTextPrimary)
                                if !item.tag.isEmpty {
                                    Text(item.tag)
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 5).padding(.vertical, 2)
                                        .background(Color(hex: "#FF8C42"))
                                        .clipShape(Capsule())
                                }
                            }
                            Text(item.desc)
                                .font(.system(size: 11))
                                .foregroundColor(.csqTextSecondary)
                                .lineLimit(1)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text(marketConfig.market.formatPrice(item.price))
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.csqTextPrimary)
                            Button {
                                CSQ.trackEvent("recommended_item_added", properties: [
                                    "item":       item.name,
                                    "price":      String(format: "%.2f", item.price),
                                    "restaurant": restaurant.name
                                ])
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(Color(hex: "#FF8C42"))
                            }
                        }
                    }
                    .padding(.vertical, 10)

                    if idx < recommendedItems.count - 1 {
                        Divider().padding(.leading, 60)
                    }
                }
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Order Summary Totals
    private var orderSummarySection: some View {
        VStack(spacing: 0) {
            FoodSummaryRow(label: marketConfig.strings.foodSubtotal, value: marketConfig.market.formatPrice(cartStore.subtotal))
            Divider().padding(.horizontal, 16)
            FoodSummaryRow(label: marketConfig.strings.foodDeliveryFee, value: deliveryFeeValue == 0 ? marketConfig.strings.foodFree : marketConfig.market.formatPrice(deliveryFeeValue),
                       valueColor: deliveryFeeValue == 0 ? .csqSuccess : .csqTextPrimary)
            Divider().padding(.horizontal, 16)
            FoodSummaryRow(label: marketConfig.strings.foodPlatformFee, value: marketConfig.market.formatPrice(0.30))
            Divider().padding(.horizontal, 16)
            HStack {
                Text(marketConfig.strings.foodTotal)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.csqTextPrimary)
                Spacer()
                Text(marketConfig.market.formatPrice(total + 0.30))
                    .font(AppFont.display(17))
                    .foregroundColor(Color(hex: "#FF8C42"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .background(Color.csqSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
    }
}

// MARK: - Order Confirmed View
struct OrderConfirmedView: View {
    let restaurant: Restaurant
    let total: Double
    let onDone: () -> Void
    @EnvironmentObject var marketConfig: MarketConfig

    @State private var trackingStep = 0

    private var steps: [String] { [
        marketConfig.strings.foodStepReceived,
        marketConfig.strings.foodStepPreparing,
        marketConfig.strings.foodStepOnTheWay,
        marketConfig.strings.foodStepDelivered
    ]}
    private let stepIcons = ["checkmark.circle.fill", "flame.fill", "bicycle", "house.fill"]

    var body: some View {
        VStack(spacing: 0) {
            Color(hex: "#FF8C42")
                .frame(height: 4)

            // Top nav — visible immediately so user is never trapped
            HStack {
                Button(action: onDone) {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.csqTextSecondary)
                        .frame(width: 36, height: 36)
                        .background(Color.csqBackground)
                        .clipShape(Circle())
                }
                .accessibilityIdentifier(OrderAccessID.confirmDoneButton)
                Spacer()
                Text(marketConfig.strings.foodOrderConfirmed)
                    .font(AppFont.display(15))
                    .foregroundColor(.csqTextPrimary)
                Spacer()
                Color.clear.frame(width: 36, height: 36)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.csqSurface)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {

                    // Success hero
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.csqSuccess.opacity(0.12))
                                .frame(width: 90, height: 90)
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.csqSuccess)
                        }
                        .padding(.top, 32)

                        Text(marketConfig.strings.foodOrderConfirmedTitle)
                            .font(AppFont.display(24))
                            .foregroundColor(.csqTextPrimary)

                        Text(marketConfig.strings.foodOrderFromRestaurant(restaurant.name))
                            .font(AppFont.body(14))
                            .foregroundColor(.csqTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .accessibilityIdentifier("food_confirm_hero")

                    // ETA card
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(marketConfig.strings.foodEstimatedArrival)
                                .font(.system(size: 12))
                                .foregroundColor(.csqTextSecondary)
                            Text(marketConfig.market == .tokyo
                                ? (restaurant.deliveryTime.components(separatedBy: "〜").last.map { "約\($0)" } ?? "約35分")
                                : (restaurant.deliveryTime.components(separatedBy: "–").last.map { "~\($0)" } ?? "~35 min"))
                                .font(AppFont.display(28))
                                .foregroundColor(.csqTextPrimary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(marketConfig.strings.foodOrderTotal)
                                .font(.system(size: 12))
                                .foregroundColor(.csqTextSecondary)
                            Text(marketConfig.market.formatPrice(total))
                                .font(AppFont.display(22))
                                .foregroundColor(Color(hex: "#FF8C42"))
                        }
                    }
                    .padding(16)
                    .background(Color(hex: "#FFF7F0"))
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                    .overlay(RoundedRectangle(cornerRadius: AppRadius.lg).stroke(Color(hex: "#FF8C42").opacity(0.2), lineWidth: 1))

                    // Tracking steps
                    VStack(alignment: .leading, spacing: 0) {
                        Text(marketConfig.strings.foodLiveTracking)
                            .font(AppFont.display(15))
                            .foregroundColor(.csqTextPrimary)
                            .padding(.bottom, 16)

                        ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(index <= trackingStep ? Color(hex: "#FF8C42") : Color.csqBackground)
                                        .frame(width: 36, height: 36)
                                    Image(systemName: stepIcons[index])
                                        .font(.system(size: 15))
                                        .foregroundColor(index <= trackingStep ? .white : .csqTextTertiary)
                                }
                                .accessibilityIdentifier("food_confirm_step_\(index)")

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(step)
                                        .font(.system(size: 14, weight: index <= trackingStep ? .semibold : .regular))
                                        .foregroundColor(index <= trackingStep ? .csqTextPrimary : .csqTextTertiary)
                                    if index == trackingStep {
                                        Text(index == 0 ? marketConfig.strings.foodStepReceived : index == 1 ? marketConfig.strings.foodStepPreparing : marketConfig.strings.foodStepOnTheWay)
                                            .font(.system(size: 11))
                                            .foregroundColor(Color(hex: "#FF8C42"))
                                    }
                                }
                                Spacer()
                                if index < trackingStep {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.csqSuccess)
                                }
                            }
                            if index < steps.count - 1 {
                                Rectangle()
                                    .fill(index < trackingStep ? Color(hex: "#FF8C42").opacity(0.4) : Color.csqBorder)
                                    .frame(width: 2, height: 24)
                                    .padding(.leading, 17)
                            }
                        }
                    }
                    .padding(16)
                    .background(Color.csqSurface)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)

                    // Delivery note
                    HStack(spacing: 10) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(Color(hex: "#FF8C42"))
                        Text(marketConfig.strings.foodDeliveryNote)
                            .font(.system(size: 12))
                            .foregroundColor(.csqTextSecondary)
                    }
                    .padding(12)
                    .background(Color(hex: "#FFF7F0"))
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))

                    // CTAs
                    VStack(spacing: 10) {
                        Button {
                            CSQ.trackEvent("food_track_order_tapped", properties: ["restaurant": restaurant.name])
                        } label: {
                            Label(marketConfig.strings.foodTrackMyOrder, systemImage: "location.fill")
                                .font(AppFont.display(15))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(colors: [Color(hex: "#FF8C42"), Color(hex: "#E05A00")],
                                                   startPoint: .leading, endPoint: .trailing)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: AppRadius.full))
                        }
                        .accessibilityIdentifier(OrderAccessID.confirmTrackButton)

                        Button(action: onDone) {
                            Text(marketConfig.strings.foodBackToFood)
                                .font(AppFont.display(15))
                                .foregroundColor(Color(hex: "#FF8C42"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color(hex: "#FFF7F0"))
                                .clipShape(RoundedRectangle(cornerRadius: AppRadius.full))
                        }
                        .accessibilityIdentifier(OrderAccessID.confirmDoneButton)
                    }
                    .padding(.bottom, 40)
                }
                .padding(.horizontal, 20)
            }
        }
        .background(Color.csqBackground.ignoresSafeArea())
        .onAppear {
            CSQ.trackScreenview("Food - Order Confirmed")
            // Simulate order progressing through step 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.spring()) { trackingStep = 1 }
            }
        }
    }
}

// MARK: - Helper sub-views

private struct SectionCard<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    let content: Content

    init(title: String, icon: String, iconColor: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.csqTextSecondary)
                    .textCase(.uppercase)
                    .tracking(0.3)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 4)

            content
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
        }
        .background(Color.csqSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
    }
}

private struct FoodSummaryRow: View {
    let label: String
    let value: String
    var valueColor: Color = .csqTextPrimary

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.csqTextSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(valueColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
