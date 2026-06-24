import SwiftUI

struct CheckoutView: View {
    @EnvironmentObject var cartStore: CartStore
    @EnvironmentObject var marketConfig: MarketConfig
    @Binding var rootIsPresented: Bool
    @State private var selectedSlotIndex = 0
    @State private var selectedPaymentIndex = 0
    @State private var showOrderConfirmation = false
    @State private var isPlacingOrder = false
    @State private var deliveryNote = ""
    @State private var leaveAtDoor = true

    let slots = DeliverySlot.available
    let payments = PaymentMethod.available

    var selectedSlot: DeliverySlot { slots[selectedSlotIndex] }
    var selectedPayment: PaymentMethod { payments[selectedPaymentIndex] }

    var body: some View {
        ZStack {
            Color.csqBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Delivery address card
                    CheckoutSection(title: marketConfig.strings.checkoutDeliveryAddress, icon: "mappin.circle.fill", iconColor: .csqMartGreen) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 10) {
                                ZStack {
                                    Circle()
                                        .fill(Color.csqMartGreen.opacity(0.1))
                                        .frame(width: 38, height: 38)
                                    Image(systemName: "house.fill")
                                        .font(.system(size: 15))
                                        .foregroundColor(.csqMartGreen)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(marketConfig.strings.checkoutHome)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.csqTextPrimary)
                                    Text(marketConfig.strings.checkoutHomeAddress)
                                        .font(.system(size: 12))
                                        .foregroundColor(.csqTextSecondary)
                                }
                                Spacer()
                                Button(marketConfig.strings.checkoutChange) {}
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.csqMartGreen)
                            }

                            Divider()

                            // Delivery instructions
                            VStack(alignment: .leading, spacing: 8) {
                                Toggle(isOn: $leaveAtDoor) {
                                    Text(marketConfig.strings.checkoutLeaveAtDoor)
                                        .font(.system(size: 13))
                                        .foregroundColor(.csqTextSecondary)
                                }
                                .tint(.csqMartGreen)

                                TextField(marketConfig.strings.checkoutAddInstructions, text: $deliveryNote)
                                    .font(.system(size: 13))
                                    .padding(10)
                                    .background(Color.csqBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }

                    // Delivery slot
                    CheckoutSection(title: marketConfig.strings.checkoutDeliverySlot, icon: "clock.fill", iconColor: .csqRideBlue) {
                        VStack(spacing: 8) {
                            ForEach(Array(slots.enumerated()), id: \.offset) { index, slot in
                                Button { withAnimation { selectedSlotIndex = index } } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(slot.label)
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.csqTextPrimary)
                                            Text(slot.time)
                                                .font(.system(size: 12))
                                                .foregroundColor(.csqTextSecondary)
                                        }
                                        Spacer()
                                        Text(slot.fee == 0 ? marketConfig.strings.foodFree : marketConfig.market.formatPrice(slot.fee))
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(slot.fee == 0 ? .csqSuccess : .csqTextPrimary)

                                        ZStack {
                                            Circle()
                                                .stroke(selectedSlotIndex == index ? Color.csqMartGreen : Color.csqBorder, lineWidth: 2)
                                                .frame(width: 20, height: 20)
                                            if selectedSlotIndex == index {
                                                Circle()
                                                    .fill(Color.csqMartGreen)
                                                    .frame(width: 10, height: 10)
                                            }
                                        }
                                    }
                                    .padding(12)
                                    .background(selectedSlotIndex == index ? Color.csqMartGreenPastel : Color.csqBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppRadius.md)
                                            .stroke(selectedSlotIndex == index ? Color.csqMartGreen : Color.clear, lineWidth: 1.5)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Payment method
                    CheckoutSection(title: marketConfig.strings.checkoutPayment, icon: "creditcard.fill", iconColor: .csqExpressPurple) {
                        VStack(spacing: 8) {
                            ForEach(Array(payments.enumerated()), id: \.offset) { index, method in
                                Button { withAnimation { selectedPaymentIndex = index } } label: {
                                    HStack(spacing: 12) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(method.color.opacity(0.1))
                                                .frame(width: 38, height: 38)
                                            Image(systemName: method.iconName)
                                                .font(.system(size: 15))
                                                .foregroundColor(method.color)
                                        }
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(method.name)
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundColor(.csqTextPrimary)
                                            Text(method.detail)
                                                .font(.system(size: 11))
                                                .foregroundColor(.csqTextSecondary)
                                        }
                                        Spacer()
                                        ZStack {
                                            Circle()
                                                .stroke(selectedPaymentIndex == index ? Color.csqMartGreen : Color.csqBorder, lineWidth: 2)
                                                .frame(width: 20, height: 20)
                                            if selectedPaymentIndex == index {
                                                Circle()
                                                    .fill(Color.csqMartGreen)
                                                    .frame(width: 10, height: 10)
                                            }
                                        }
                                    }
                                    .padding(12)
                                    .background(selectedPaymentIndex == index ? Color.csqMartGreenPastel : Color.csqBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppRadius.md)
                                            .stroke(selectedPaymentIndex == index ? Color.csqMartGreen : Color.clear, lineWidth: 1.5)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Order summary
                    CheckoutSection(title: marketConfig.strings.cartOrderSummary, icon: "list.bullet", iconColor: .csqMartGreen) {
                        VStack(spacing: 10) {
                            SummaryRow(label: marketConfig.strings.cartSubtotal(cartStore.totalItems), value: cartStore.subtotal, marketConfig: marketConfig)
                            SummaryRow(label: marketConfig.strings.cartDeliveryFee, value: selectedSlot.fee, marketConfig: marketConfig)
                            SummaryRow(label: marketConfig.strings.cartServiceFee, value: cartStore.serviceFee, marketConfig: marketConfig)
                            Divider()
                            HStack {
                                Text(marketConfig.strings.cartTotal)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.csqTextPrimary)
                                Spacer()
                                Text(marketConfig.market.formatPrice(cartStore.subtotal + selectedSlot.fee + cartStore.serviceFee))
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(.csqTextPrimary)
                            }
                        }
                    }

                    Color.clear.frame(height: 90)
                }
                .padding(.top, 8)
            }

            // Bottom place order button
            VStack {
                Spacer()
                VStack(spacing: 0) {
                    Divider()
                    NavigationLink(
                        destination: OrderConfirmationView(rootIsPresented: $rootIsPresented)
                            .navigationBarBackButtonHidden(true)
                            .environmentObject(marketConfig),
                        isActive: $showOrderConfirmation
                    ) { EmptyView() }

                    Button {
                        isPlacingOrder = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                            isPlacingOrder = false
                            showOrderConfirmation = true
                        }
                    } label: {
                        HStack(spacing: 10) {
                            if isPlacingOrder {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                                    .scaleEffect(0.85)
                                Text(marketConfig.strings.checkoutPlacingOrder)
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 14))
                                Text("\(marketConfig.strings.checkoutPlaceOrder)\(marketConfig.market.formatPrice(cartStore.subtotal + selectedSlot.fee + cartStore.serviceFee))")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(colors: [.csqMartGreen, .csqMartGreenDark], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.full))
                        .shadow(color: Color.csqMartGreen.opacity(0.35), radius: 8, x: 0, y: 4)
                    }
                    .disabled(isPlacingOrder)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .padding(.bottom, 8)
                }
                .background(Color.csqSurface)
            }
        }
        .navigationTitle(marketConfig.strings.checkoutTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Section Container
struct CheckoutSection<Content: View>: View {
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
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.csqTextPrimary)
            }
            content
        }
        .padding(16)
        .background(Color.csqSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
        .padding(.horizontal, 16)
    }
}
