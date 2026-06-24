import SwiftUI

struct CartView: View {
    @EnvironmentObject var cartStore: CartStore
    @EnvironmentObject var marketConfig: MarketConfig
    @Environment(\.dismiss) var dismiss
    @Binding var rootIsPresented: Bool
    @State private var navigateToCheckout = false
    @State private var promoCode = ""
    @State private var promoApplied = false
    @State private var promoError = false
    @State private var promoRage = RageTapDetector()   // rapid invalid-Apply taps
    @State private var promoFailures = 0

    // Only this exact code works — everything else triggers an error and rage clicks
    private let validPromoCode = "WEEKEND10"

    var body: some View {
        ZStack {
            Color.csqBackground.ignoresSafeArea()

            if cartStore.items.isEmpty {
                EmptyCartView()
            } else {
                VStack(spacing: 0) {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            // Delivery banner
                            HStack(spacing: 10) {
                                Image(systemName: "shippingbox.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.csqMartGreen)
                                Text(LocalizedStringKey(marketConfig.strings.cartExpressDelivery))
                                    .font(.system(size: 13))
                                    .foregroundColor(.csqTextSecondary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11))
                                    .foregroundColor(.csqTextTertiary)
                            }
                            .padding(12)
                            .background(Color.csqMartGreen.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.md)
                                    .stroke(Color.csqMartGreen.opacity(0.2), lineWidth: 1)
                            )
                            .padding(.horizontal, 16)
                            .padding(.top, 8)

                            // Items
                            VStack(spacing: 0) {
                                ForEach(cartStore.items) { item in
                                    CartItemRow(item: item)
                                    if item.id != cartStore.items.last?.id {
                                        Divider().padding(.leading, 78)
                                    }
                                }
                            }
                            .background(Color.csqSurface)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
                            .padding(.horizontal, 16)

                            // Promo code
                            VStack(spacing: 0) {
                                HStack(spacing: 10) {
                                    Image(systemName: "tag.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(promoApplied ? .csqSuccess : .csqMartGreen)
                                    TextField(marketConfig.strings.cartEnterPromo, text: $promoCode)
                                        .font(.system(size: 14))
                                        .foregroundColor(.csqTextPrimary)
                                        .onChange(of: promoCode) { _, _ in
                                            if promoError { withAnimation { promoError = false } }
                                        }
                                    Button {
                                        guard !promoCode.isEmpty else { return }
                                        if promoCode.uppercased() == validPromoCode {
                                            withAnimation {
                                                promoApplied = true
                                                promoError   = false
                                            }
                                            promoRage.reset()
                                        } else {
                                            withAnimation { promoError = true }
                                            promoFailures += 1
                                            if let count = promoRage.registerTap() {
                                                FrustrationSignal.promoRage(
                                                    service: "CSQMart", screen: "Grocery - Cart",
                                                    tapCount: count, failedAttempts: promoFailures,
                                                    codeLength: promoCode.count, market: marketConfig.market)
                                            }
                                        }
                                    } label: {
                                        Text(marketConfig.strings.cartApply)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(promoApplied ? .csqSuccess : promoError ? .csqError : .csqMartGreen)
                                    }
                                    .accessibilityIdentifier("cart_apply_promo_button")
                                    if promoApplied {
                                        Text("✓")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.csqSuccess)
                                    }
                                }
                                .padding(14)

                                if promoError {
                                    Divider().padding(.horizontal, 14)
                                    HStack(spacing: 6) {
                                        Image(systemName: "exclamationmark.circle.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(.csqError)
                                        Text(marketConfig.strings.cartInvalidPromo)
                                            .font(.system(size: 12))
                                            .foregroundColor(.csqError)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.bottom, 12)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }
                            .background(Color.csqSurface)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
                            .padding(.horizontal, 16)

                            // Order summary
                            VStack(spacing: 0) {
                                HStack {
                                    Text(marketConfig.strings.cartOrderSummary)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.csqTextPrimary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 14)
                                .padding(.bottom, 10)

                                Divider().padding(.horizontal, 16)

                                VStack(spacing: 12) {
                                    SummaryRow(label: marketConfig.strings.cartSubtotal(cartStore.totalItems), value: cartStore.subtotal, marketConfig: marketConfig)
                                    SummaryRow(label: marketConfig.strings.cartDeliveryFee, value: cartStore.deliveryFee, marketConfig: marketConfig)
                                    SummaryRow(label: marketConfig.strings.cartServiceFee, value: cartStore.serviceFee, marketConfig: marketConfig)
                                    if promoApplied {
                                        SummaryRow(label: marketConfig.strings.cartPromoDiscount, value: -2.00, highlight: true, marketConfig: marketConfig)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)

                                Divider().padding(.horizontal, 16)

                                HStack {
                                    Text(marketConfig.strings.cartTotal)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.csqTextPrimary)
                                    Spacer()
                                    Text(marketConfig.market.formatPrice(promoApplied ? cartStore.total - 2 : cartStore.total))
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                        .foregroundColor(.csqTextPrimary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                            }
                            .background(Color.csqSurface)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
                            .padding(.horizontal, 16)

                            Color.clear.frame(height: 90)
                        }
                    }

                    // Bottom checkout button
                    VStack(spacing: 0) {
                        Divider()
                        NavigationLink(destination: CheckoutView(rootIsPresented: $rootIsPresented).environmentObject(marketConfig), isActive: $navigateToCheckout) {
                            EmptyView()
                        }
                        Button { navigateToCheckout = true } label: {
                            HStack {
                                Text(marketConfig.strings.cartProceedCheckout)
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                Spacer()
                                Text(marketConfig.market.formatPrice(promoApplied ? cartStore.total - 2 : cartStore.total))
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(colors: [.csqMartGreen, .csqMartGreenDark], startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.full))
                            .shadow(color: Color.csqMartGreen.opacity(0.35), radius: 8, x: 0, y: 4)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .padding(.bottom, 8)
                    }
                    .background(Color.csqSurface)
                }
            }
        }
        .navigationTitle("\(marketConfig.strings.cartNavTitle) (\(cartStore.totalItems))")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !cartStore.items.isEmpty {
                    Button(marketConfig.strings.cartClearButton) {
                        withAnimation { cartStore.clear() }
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.csqError)
                }
            }
        }
    }
}

// MARK: - Cart Item Row
struct CartItemRow: View {
    @EnvironmentObject var cartStore: CartStore
    @EnvironmentObject var marketConfig: MarketConfig
    let item: CartItem

    var body: some View {
        HStack(spacing: 12) {
            // Product image
            GroceryProductImage(product: item.product, symbolSize: 26)
                .frame(width: 62, height: 62)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.product.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.csqTextPrimary)
                    .lineLimit(2)
                Text(item.product.unit)
                    .font(.system(size: 11))
                    .foregroundColor(.csqTextTertiary)
                Text("\(marketConfig.market.formatPrice(item.product.price)) \(marketConfig.strings.cartEach)")
                    .font(.system(size: 12))
                    .foregroundColor(.csqTextSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 10) {
                Text(marketConfig.market.formatPrice(item.subtotal))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.csqTextPrimary)

                HStack(spacing: 8) {
                    Button { cartStore.remove(item.product) } label: {
                        Image(systemName: item.quantity == 1 ? "trash" : "minus")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(item.quantity == 1 ? .csqError : .csqMartGreen)
                            .frame(width: 26, height: 26)
                            .background(item.quantity == 1 ? Color.csqError.opacity(0.08) : Color.csqMartGreenPastel)
                            .clipShape(Circle())
                    }
                    Text("\(item.quantity)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.csqTextPrimary)
                    Button { cartStore.add(item.product) } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 26, height: 26)
                            .background(Color.csqMartGreen)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Summary Row
struct SummaryRow: View {
    let label: String
    let value: Double
    var highlight: Bool = false
    var marketConfig: MarketConfig? = nil

    private func formattedValue(_ v: Double) -> String {
        guard let mc = marketConfig else {
            return v < 0 ? String(format: "-$%.2f", abs(v)) : String(format: "$%.2f", v)
        }
        return v < 0 ? "-\(mc.market.formatPrice(abs(v)))" : mc.market.formatPrice(v)
    }

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(highlight ? .csqSuccess : .csqTextSecondary)
            Spacer()
            Text(formattedValue(value))
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(highlight ? .csqSuccess : .csqTextPrimary)
        }
    }
}

// MARK: - Empty Cart
struct EmptyCartView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var marketConfig: MarketConfig

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.csqMartGreenPastel)
                    .frame(width: 120, height: 120)
                Image(systemName: "cart")
                    .font(.system(size: 52))
                    .foregroundColor(.csqMartGreen)
            }
            VStack(spacing: 8) {
                Text(marketConfig.strings.cartEmptyTitle)
                    .font(AppFont.display(22))
                    .foregroundColor(.csqTextPrimary)
                Text(marketConfig.strings.cartEmptySubtitle)
                    .font(AppFont.body(15))
                    .foregroundColor(.csqTextSecondary)
                    .multilineTextAlignment(.center)
            }
            Button { dismiss() } label: {
                Text(marketConfig.strings.cartStartShopping)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Color.csqMartGreen)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.full))
                    .shadow(color: Color.csqMartGreen.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            Spacer()
        }
        .padding()
    }
}
