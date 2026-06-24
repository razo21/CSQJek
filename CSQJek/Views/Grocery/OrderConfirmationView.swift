import SwiftUI

struct OrderConfirmationView: View {
    @EnvironmentObject var cartStore: CartStore
    @EnvironmentObject var marketConfig: MarketConfig
    @Binding var rootIsPresented: Bool
    @State private var checkmarkScale: CGFloat = 0
    @State private var checkmarkOpacity: Double = 0
    @State private var contentOpacity: Double = 0
    @State private var progressValue: Double = 0
    @State private var currentStep = 0
    @State private var showRiderTracking = false

    let orderNumber = "CSQ-\(Int.random(in: 10000...99999))"
    let eta = "45 min"

    private var steps: [(icon: String, title: String, color: Color)] {[
        (icon: "checkmark.seal.fill", title: marketConfig.strings.orderStepConfirmed, color: Color.csqSuccess),
        (icon: "bag.fill", title: marketConfig.strings.orderStepPacked, color: Color.csqWarning),
        (icon: "bicycle", title: marketConfig.strings.orderStepOutForDelivery, color: Color.csqRideBlue),
        (icon: "house.fill", title: marketConfig.strings.orderStepDelivered, color: Color.csqMartGreen)
    ]}

    var body: some View {
        ZStack {
            Color.csqBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    // Success animation
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.csqSuccess.opacity(0.12))
                                .frame(width: 130, height: 130)
                            Circle()
                                .fill(Color.csqSuccess.opacity(0.2))
                                .frame(width: 100, height: 100)
                            Circle()
                                .fill(Color.csqSuccess)
                                .frame(width: 74, height: 74)
                                .shadow(color: Color.csqSuccess.opacity(0.4), radius: 16, x: 0, y: 6)
                            Image(systemName: "checkmark")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                                .scaleEffect(checkmarkScale)
                                .opacity(checkmarkOpacity)
                        }
                        .padding(.top, 32)

                        VStack(spacing: 6) {
                            Text(marketConfig.strings.orderPlaced)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.csqTextPrimary)
                            Text(marketConfig.strings.orderGroceriesPrepared)
                                .font(AppFont.body(15))
                                .foregroundColor(.csqTextSecondary)
                        }

                        // Order number + ETA
                        HStack(spacing: 20) {
                            VStack(spacing: 4) {
                                Text(marketConfig.strings.orderNumber)
                                    .font(.system(size: 11))
                                    .foregroundColor(.csqTextTertiary)
                                Text(orderNumber)
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundColor(.csqTextPrimary)
                            }
                            Rectangle()
                                .fill(Color.csqBorder)
                                .frame(width: 1, height: 32)
                            VStack(spacing: 4) {
                                Text(marketConfig.strings.orderEstimatedArrival)
                                    .font(.system(size: 11))
                                    .foregroundColor(.csqTextTertiary)
                                Text(eta)
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(.csqMartGreen)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(Color.csqSurface)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
                    }
                    .opacity(contentOpacity)

                    // Progress tracker
                    VStack(alignment: .leading, spacing: 16) {
                        Text(marketConfig.strings.orderProgress)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.csqTextPrimary)

                        VStack(spacing: 0) {
                            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                                HStack(spacing: 16) {
                                    // Icon + line
                                    VStack(spacing: 0) {
                                        ZStack {
                                            Circle()
                                                .fill(index <= currentStep ? step.color : Color.csqBorder)
                                                .frame(width: 38, height: 38)
                                            Image(systemName: step.icon)
                                                .font(.system(size: 15))
                                                .foregroundColor(index <= currentStep ? .white : .csqTextTertiary)
                                        }
                                        if index < steps.count - 1 {
                                            Rectangle()
                                                .fill(index < currentStep ? step.color : Color.csqBorder)
                                                .frame(width: 2, height: 36)
                                        }
                                    }

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(step.title)
                                            .font(.system(size: 14, weight: index <= currentStep ? .semibold : .regular))
                                            .foregroundColor(index <= currentStep ? .csqTextPrimary : .csqTextTertiary)
                                        if index == currentStep {
                                            Text(marketConfig.strings.orderInProgress)
                                                .font(.system(size: 12))
                                                .foregroundColor(step.color)
                                        } else if index < currentStep {
                                            Text(marketConfig.strings.orderCompleted)
                                                .font(.system(size: 12))
                                                .foregroundColor(.csqSuccess)
                                        }
                                    }
                                    Spacer()

                                    if index == currentStep {
                                        ProgressView()
                                            .progressViewStyle(.circular)
                                            .scaleEffect(0.7)
                                            .tint(step.color)
                                    } else if index < currentStep {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.csqSuccess)
                                    }
                                }
                                .padding(.vertical, index < steps.count - 1 ? 0 : 0)
                            }
                        }
                        .padding(16)
                        .background(Color.csqSurface)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
                    }
                    .padding(.horizontal, 16)
                    .opacity(contentOpacity)

                    // Rider info
                    VStack(alignment: .leading, spacing: 14) {
                        Text(marketConfig.strings.orderDeliveryPartner)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.csqTextPrimary)

                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(colors: [.csqMartGreen, Color(hex: "#1A9E82")], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 56, height: 56)
                                Text("RK")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Ravi K.")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.csqTextPrimary)
                                HStack(spacing: 6) {
                                    StarRating(rating: 4.8, size: 11)
                                    Text("4.8 · 1,203 deliveries")
                                        .font(.system(size: 12))
                                        .foregroundColor(.csqTextSecondary)
                                }
                                Text(marketConfig.strings.orderDeliveryInfo)
                                    .font(.system(size: 12))
                                    .foregroundColor(.csqTextSecondary)
                            }
                            Spacer()
                            HStack(spacing: 8) {
                                Button {} label: {
                                    Image(systemName: "phone.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.csqSuccess)
                                        .frame(width: 38, height: 38)
                                        .background(Color.csqSuccess.opacity(0.1))
                                        .clipShape(Circle())
                                }
                                Button {} label: {
                                    Image(systemName: "message.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.csqRideBlue)
                                        .frame(width: 38, height: 38)
                                        .background(Color.csqRideBlue.opacity(0.1))
                                        .clipShape(Circle())
                                }
                            }
                        }
                    }
                    .padding(16)
                    .background(Color.csqSurface)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                    .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
                    .padding(.horizontal, 16)
                    .opacity(contentOpacity)

                    // Rate & share buttons
                    VStack(spacing: 12) {
                        NavigationLink(
                            destination: RiderTrackingView()
                                .environmentObject(marketConfig),
                            isActive: $showRiderTracking
                        ) { EmptyView() }

                        Button { showRiderTracking = true } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "map.fill")
                                    .font(.system(size: 14))
                                Text(marketConfig.strings.orderTrackLiveMap)
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(
                                LinearGradient(colors: [.csqMartGreen, .csqMartGreenDark], startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.full))
                            .shadow(color: Color.csqMartGreen.opacity(0.35), radius: 8, x: 0, y: 4)
                        }
                        .accessibilityIdentifier("order_btn_track_rider")

                        HStack(spacing: 12) {
                            Button {} label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.system(size: 13))
                                    Text(marketConfig.strings.orderReorder)
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .foregroundColor(.csqMartGreen)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .background(Color.csqMartGreenPastel)
                                .clipShape(RoundedRectangle(cornerRadius: AppRadius.full))
                            }
                            Button {} label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 13))
                                    Text(marketConfig.strings.orderShare)
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .foregroundColor(.csqTextSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .background(Color.csqBackground)
                                .clipShape(RoundedRectangle(cornerRadius: AppRadius.full))
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppRadius.full)
                                        .stroke(Color.csqBorder, lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                    .opacity(contentOpacity)
                }
            }
        }
        .overlay(alignment: .topLeading) {
            Button { rootIsPresented = false } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.csqTextPrimary)
                    .frame(width: 36, height: 36)
                    .background(Color.csqSurface)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
            }
            .accessibilityIdentifier("order_btn_close")
            .accessibilityLabel("Close and return to home")
            .padding(.leading, 16)
            .padding(.top, 8)
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.2)) {
                checkmarkScale = 1
                checkmarkOpacity = 1
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
                contentOpacity = 1
            }
        }
    }
}
