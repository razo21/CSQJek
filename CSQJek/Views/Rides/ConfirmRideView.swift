import SwiftUI
import ContentsquareSDK

struct ConfirmRideView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var marketConfig: MarketConfig
    let destination: Location
    let pickupAddress: String

    @State private var selectedRideIndex = 0
    // MARK: – Payment state
    @State private var selectedPayment: RidePaymentMethod = .visa
    @State private var showPaymentPicker = false

    // MARK: – Booking / error state
    @State private var showConfirmation = false
    @State private var isBooking = false
    @State private var paymentErrorMessage: String? = nil

    // MARK: – Promo
    @State private var promoCode = ""
    @State private var showPromo = false
    @State private var promoRage = RageTapDetector()   // rapid invalid-Apply taps
    @State private var promoFailures = 0

    private var rideOptions: [RideOption] { marketConfig.content.rideOptions }
    var selectedRide: RideOption { rideOptions[selectedRideIndex] }

    var body: some View {
        let s = marketConfig.strings
        ZStack {
            // Route map background
            RouteMapView(destination: destination)
                .ignoresSafeArea()

            VStack {
                // Nav bar
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.csqTextPrimary)
                            .frame(width: 40, height: 40)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 2)
                    }
                    Spacer()
                    VStack(spacing: 1) {
                        Text(s.rideChooseTitle)
                            .font(AppFont.display(15))
                            .foregroundColor(.csqTextPrimary)
                        Text(s.rideRouteInfo)
                            .font(.system(size: 11))
                            .foregroundColor(.csqTextSecondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.full))
                    .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
                    Spacer()
                    Color.clear.frame(width: 40, height: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                Spacer()
            }

            // Bottom sheet
            VStack(spacing: 0) {
                Spacer()
                VStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.csqBorder)
                        .frame(width: 40, height: 4)
                        .padding(.top, 10)
                        .padding(.bottom, 12)

                    // Route summary
                    HStack(spacing: 10) {
                        VStack(spacing: 4) {
                            Circle().fill(Color.csqSuccess).frame(width: 8, height: 8)
                            Rectangle().fill(Color.csqBorder).frame(width: 1, height: 16)
                            Image(systemName: "mappin.fill").font(.system(size: 10)).foregroundColor(.csqPrimary)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text(pickupAddress)
                                .font(.system(size: 12))
                                .foregroundColor(.csqTextSecondary)
                                .lineLimit(1)
                            Text(destination.address)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.csqTextPrimary)
                                .lineLimit(1)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("18.4 km")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.csqTextPrimary)
                            Text("~28 min")
                                .font(.system(size: 11))
                                .foregroundColor(.csqTextSecondary)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 14)

                    Divider()

                    // Ride options
                    VStack(spacing: 8) {
                        ForEach(Array(rideOptions.enumerated()), id: \.offset) { index, ride in
                            RideOptionCard(
                                ride: ride,
                                isSelected: index == selectedRideIndex,
                                action: {
                                    withAnimation(.spring(response: 0.3)) { selectedRideIndex = index }
                                    CSQ.trackEvent("ride_option_selected", properties: [
                                        "ride_type": ride.name,
                                        "price":     ride.price
                                    ])
                                }
                            )
                            .accessibilityIdentifier("confirm_ride_option_\(ride.name.lowercased().replacingOccurrences(of: " ", with: "_"))")
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    Divider()

                    // Payment error banner (slides in above the payment row)
                    if let errMsg = paymentErrorMessage {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                            Text(errMsg)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer()
                            Button {
                                withAnimation(.spring(response: 0.3)) { paymentErrorMessage = nil }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(hex: "#DC2626"))
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .accessibilityIdentifier("confirm_payment_error_banner")
                        .accessibilityLabel("Payment error: \(errMsg)")
                    }

                    // Payment + Promo
                    VStack(spacing: 0) {
                        Button {
                            paymentErrorMessage = nil
                            showPaymentPicker = true
                            CSQ.trackEvent("payment_method_picker_opened", properties: [
                                "current_method": selectedPayment.trackingLabel
                            ])
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: selectedPayment.icon)
                                    .font(.system(size: 14))
                                    .foregroundColor(selectedPayment.iconColor)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(selectedPayment.displayName)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.csqTextPrimary)
                                    if let sub = selectedPayment.subtitle {
                                        Text(sub)
                                            .font(.system(size: 11))
                                            .foregroundColor(.csqTextSecondary)
                                    }
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(.csqTextTertiary)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                        }

                        Divider()

                        Button {
                            withAnimation { showPromo.toggle() }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "tag.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.csqSuccess)
                                Text(promoCode.isEmpty ? s.rideAddPromo : promoCode)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(promoCode.isEmpty ? .csqTextSecondary : .csqSuccess)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(.csqTextTertiary)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                        }
                    }

                    Divider()

                    // Confirm button
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(s.rideTotalLabel)
                                .font(.system(size: 12))
                                .foregroundColor(.csqTextSecondary)
                            Text(marketConfig.market.formatPrice(selectedRide.price))
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(.csqTextPrimary)
                        }
                        Button {
                            isBooking = true
                            paymentErrorMessage = nil

                            // American Express is not accepted — fire error after a realistic processing delay
                            if selectedPayment == .amex {
                                CSQ.trackEvent("payment_error", properties: [
                                    "card_type":    "American Express",
                                    "error_code":   "CARD_TYPE_NOT_SUPPORTED",
                                    "ride_type":    selectedRide.name,
                                    "price":        selectedRide.price
                                ])
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                    isBooking = false
                                    withAnimation(.spring(response: 0.4)) {
                                        paymentErrorMessage = "Payment declined."
                                    }
                                }
                            } else {
                                CSQ.trackEvent("ride_booked", properties: [
                                    "ride_type":      selectedRide.name,
                                    "price":          selectedRide.price,
                                    "pickup":         pickupAddress,
                                    "dropoff":        destination.name,
                                    "eta_minutes":    selectedRide.eta,
                                    "payment_method": selectedPayment.trackingLabel
                                ])
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    isBooking = false
                                    showConfirmation = true
                                }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                if isBooking {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .tint(.white)
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "car.fill")
                                        .font(.system(size: 14))
                                }
                                Text(isBooking ? s.rideFindingDriver : "\(s.rideBookButton) \(selectedRide.name)")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(
                                LinearGradient(colors: [.csqPrimary, .csqPrimaryDark], startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.full))
                            .shadow(color: Color.csqPrimary.opacity(0.35), radius: 8, x: 0, y: 4)
                        }
                        .accessibilityIdentifier("confirm_book_button")
                        .disabled(isBooking)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .padding(.bottom, 10)
                }
                .background(Color.csqSurface)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(color: Color.black.opacity(0.12), radius: 20, x: 0, y: -4)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            LiveAgentButton(screen: "Ride - Confirm")
        }
        .navigationBarHidden(true)
        .onAppear {
            CSQ.trackScreenview("Ride - Confirm")
            // Set default payment to the first method for this market
            selectedPayment = marketConfig.content.paymentMethods.first ?? .visa
        }
        .sheet(isPresented: $showConfirmation) {
            RideBookedSheet(ride: selectedRide, destination: destination)
                .environmentObject(marketConfig)
        }
        .sheet(isPresented: $showPaymentPicker) {
            PaymentPickerSheet(
                selected: $selectedPayment,
                options: marketConfig.content.paymentMethods
            )
            .environmentObject(marketConfig)
            .presentationDetents([.height(380)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showPromo) {
            PromoCodeSheet(isPresented: $showPromo, promoCode: $promoCode, onSubmit: { code in
                // ── Silent failure ───────────────────────────────────────────
                // No error is shown to the user. The sheet closes and the field
                // resets. The only record of what happened lives in CS.
                CSQ.trackEvent("promo_code_invalid", properties: [
                    "promo_code":      code,
                    "ride_type":       selectedRide.name,
                    "price":           selectedRide.price,
                    "error_code":      "PROMO_NOT_FOUND",
                    "visible_to_user": false   // ← the key demo prop
                ])
                // Sheet stays open — user sees no feedback and taps Apply again.
                // Repeated taps on the same element = rage tap signal. Emit an
                // explicit, deterministic rage event once the hammering crosses
                // the threshold (the SDK does not fire rage clicks client-side).
                promoFailures += 1
                if let count = promoRage.registerTap() {
                    FrustrationSignal.promoRage(
                        service: "CSQRide", screen: "Ride - Promo Code Entry",
                        tapCount: count, failedAttempts: promoFailures,
                        codeLength: code.count, market: marketConfig.market)
                }
            })
            .environmentObject(marketConfig)
            .presentationDetents([.height(280)])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Ride Option Card
struct RideOptionCard: View {
    @EnvironmentObject var marketConfig: MarketConfig
    let ride: RideOption
    let isSelected: Bool
    let action: () -> Void

    // Use per-ride priceColor if set; fall back to selection-driven colour
    private var priceColor: Color {
        ride.priceColor ?? (isSelected ? ride.color : .csqTextPrimary)
    }

    var body: some View {
        let s = marketConfig.strings
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 12) {
                    // Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isSelected ? ride.color.opacity(0.15) : Color.csqBackground)
                            .frame(width: 44, height: 44)
                        Image(systemName: ride.iconName)
                            .font(.system(size: 18))
                            .foregroundColor(isSelected ? ride.color : .csqTextSecondary)
                    }

                    // Info
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(ride.name)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.csqTextPrimary)
                            // Badge — driven by ride data, not name checks
                            if let badge = ride.badge {
                                Text(badge)
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(ride.badgeColor)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                        }
                        // Capacity / ETA meta — horse uses dedicated saddle string
                        Text(ride.isHorse
                             ? s.rideOptionHorseMeta(eta: ride.eta)
                             : s.rideOptionMeta(eta: ride.eta, capacity: ride.capacity))
                            .font(.system(size: 11))
                            .foregroundColor(.csqTextSecondary)
                    }

                    Spacer()

                    // Price — gag options always show their dramatic colour
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(marketConfig.market.formatPrice(ride.price))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(priceColor)
                        Text(s.rideEstFare)
                            .font(.system(size: 10))
                            .foregroundColor(.csqTextTertiary)
                    }
                }

                // Fine-print disclaimer — the punchline for gag options
                if let note = ride.disclaimer {
                    Text(note)
                        .font(.system(size: 9, weight: .regular, design: .monospaced))
                        .foregroundColor(.csqTextTertiary)
                        .lineLimit(2)
                        .padding(.top, 6)
                        .padding(.leading, 56) // aligns under the name, clears icon
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .fill(isSelected ? ride.color.opacity(0.05) : Color.csqSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.md)
                            .stroke(isSelected ? ride.color : Color.csqBorder, lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Route Map
// All three Canvas passes merged into one + drawingGroup().
// Route curve and pin overlays kept separate so they stay vector-sharp.
struct RouteMapView: View {
    let destination: Location

    var body: some View {
        ZStack {
            Color(hex: "#E8EDF2")

            // Roads + blocks in a single rasterised pass
            Canvas { context, size in
                let roadShading = GraphicsContext.Shading.color(Color.white)
                for y in stride(from: 0.0, to: size.height, by: 65) {
                    var p = Path(); p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: size.width, y: y))
                    context.stroke(p, with: roadShading, lineWidth: 7)
                }
                for x in stride(from: 0.0, to: size.width, by: 85) {
                    var p = Path(); p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: size.height))
                    context.stroke(p, with: roadShading, lineWidth: 7)
                }
                let blockShadings: [GraphicsContext.Shading] = [
                    .color(Color(hex: "#D4DCE8")), .color(Color(hex: "#CBD5E0")), .color(Color(hex: "#C8D3E0"))
                ]
                for row in 0..<7 {
                    for col in 0..<5 {
                        let rect = CGRect(x: CGFloat(col)*85+12, y: CGFloat(row)*65+10, width: 62, height: 44)
                        context.fill(Path(roundedRect: rect, cornerRadius: 5), with: blockShadings[(row+col) % 3])
                    }
                }
            }
            .drawingGroup()

            // Route curve — separate Canvas so it is not rasterised at low res
            Canvas { context, size in
                var path = Path()
                path.move(to: CGPoint(x: size.width * 0.3, y: size.height * 0.7))
                path.addCurve(
                    to: CGPoint(x: size.width * 0.75, y: size.height * 0.25),
                    control1: CGPoint(x: size.width * 0.3, y: size.height * 0.4),
                    control2: CGPoint(x: size.width * 0.6, y: size.height * 0.25)
                )
                context.stroke(path, with: .color(Color.csqPrimary.opacity(0.85)),
                               style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
            }

            // Start pin (pickup)
            Image(systemName: "person.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(.csqSuccess)
                .offset(x: -UIScreen.main.bounds.width * 0.2, y: UIScreen.main.bounds.height * 0.15)

            // End pin (destination)
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(Color.csqPrimary)
                        .frame(width: 32, height: 32)
                        .shadow(color: Color.csqPrimary.opacity(0.35), radius: 5, x: 0, y: 2)
                    Image(systemName: "mappin.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
                Triangle()
                    .fill(Color.csqPrimary)
                    .frame(width: 10, height: 6)
                    .offset(y: -1)
            }
            .offset(x: UIScreen.main.bounds.width * 0.23, y: -UIScreen.main.bounds.height * 0.1)
        }
    }
}

// MARK: - Booked Confirmation Sheet
struct RideBookedSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var marketConfig: MarketConfig
    let ride: RideOption
    let destination: Location

    private var driver: Driver { marketConfig.content.driver }

    var body: some View {
        let s = marketConfig.strings
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Handle
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.csqBorder)
                    .frame(width: 40, height: 4)
                    .padding(.top, 12)

                // Status
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(Color.csqSuccess.opacity(0.15))
                            .frame(width: 64, height: 64)
                        Image(systemName: "checkmark")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.csqSuccess)
                    }
                    Text(s.rideDriverFound)
                        .font(AppFont.display(22))
                        .foregroundColor(.csqTextPrimary)
                    Text(s.rideDriverETA(rideName: ride.name, eta: ride.eta))
                        .font(AppFont.body(14))
                        .foregroundColor(.csqTextSecondary)
                }

                // Live map — static, car approaching pickup
                DriverApproachMapView(ride: ride, etaText: s.rideETAChip(eta: ride.eta), liveLabel: s.rideLiveLabel)
                    .frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.lg)
                            .stroke(Color.csqBorder, lineWidth: 1)
                    )
                    .accessibilityIdentifier("booked_live_map")
                    .accessibilityLabel("Live map — driver approaching your pickup")

                // Driver card — initials avatar
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.csqRideBlue, Color(hex: "#3A6AE8")], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 56, height: 56)
                        Text(driver.avatarInitials)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .accessibilityIdentifier("booked_driver_avatar")

                    VStack(alignment: .leading, spacing: 4) {
                        Text(driver.name)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.csqTextPrimary)
                        HStack(spacing: 6) {
                            StarRating(rating: driver.rating, size: 11)
                            Text(String(format: "%.1f · %d trips", driver.rating, driver.trips))
                                .font(.system(size: 12))
                                .foregroundColor(.csqTextSecondary)
                        }
                        Text("\(driver.carColor) \(driver.carModel) · \(driver.plateNumber)")
                            .font(.system(size: 12))
                            .foregroundColor(.csqTextSecondary)
                    }
                    Spacer()
                    VStack(spacing: 8) {
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
                .padding(16)
                .background(Color.csqBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))

                // ETA Bar
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(s.rideArrivingIn)
                            .font(.system(size: 12))
                            .foregroundColor(.csqTextSecondary)
                        Text("\(ride.eta) min")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.csqTextPrimary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(s.rideEstimatedFare)
                            .font(.system(size: 12))
                            .foregroundColor(.csqTextSecondary)
                        Text(marketConfig.market.formatPrice(ride.price))
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.csqPrimary)
                    }
                }
                .padding(16)
                .background(Color.csqPrimaryPastel)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))

                CSQButton(s.rideCancelRide, style: .outline) {
                    CSQ.trackEvent("ride_cancelled", properties: [
                        "ride_type": ride.name
                    ])
                    dismiss()
                }
                .accessibilityIdentifier("booked_btn_cancel_ride")
                .padding(.bottom, 16)
            }
            .padding(.horizontal, 20)
        }
        .background(Color.csqSurface.ignoresSafeArea())
        .onAppear {
            CSQ.trackScreenview("Ride - Driver Found")
        }
    }
}

// MARK: - Driver Approach Map (static, non-interactive)
// Shows a simplified street grid with a car icon approaching the pickup pin.
// All positions are fixed — no random values, no Timer re-renders.
// ride: drives the car icon, colour, and ETA chip dynamically.
// etaText: localised "4 min away" / "4分後" string from AppStrings.
// liveLabel: localised "LIVE" / "ライブ" badge text from AppStrings.
struct DriverApproachMapView: View {
    let ride: RideOption
    let etaText: String
    let liveLabel: String

    var body: some View {
        ZStack {
            Color(hex: "#E8EDF2")

            // Street grid — single merged Canvas pass, rasterised via drawingGroup
            Canvas { context, size in
                let roadColor = GraphicsContext.Shading.color(Color.white)
                // Horizontal streets
                for y in stride(from: 0.0, to: size.height, by: 40) {
                    var p = Path()
                    p.move(to: CGPoint(x: 0, y: y))
                    p.addLine(to: CGPoint(x: size.width, y: y))
                    context.stroke(p, with: roadColor, lineWidth: 6)
                }
                // Vertical streets
                for x in stride(from: 0.0, to: size.width, by: 55) {
                    var p = Path()
                    p.move(to: CGPoint(x: x, y: 0))
                    p.addLine(to: CGPoint(x: x, y: size.height))
                    context.stroke(p, with: roadColor, lineWidth: 6)
                }
                // City blocks
                let blockShades: [GraphicsContext.Shading] = [
                    .color(Color(hex: "#D4DCE8")),
                    .color(Color(hex: "#CBD5E0")),
                    .color(Color(hex: "#C8D3E0"))
                ]
                for row in 0..<5 {
                    for col in 0..<7 {
                        let rect = CGRect(x: CGFloat(col)*55+8, y: CGFloat(row)*40+7, width: 38, height: 26)
                        context.fill(Path(roundedRect: rect, cornerRadius: 4), with: blockShades[(row+col) % 3])
                    }
                }
            }
            .drawingGroup()

            // Pickup pin — fixed position center-left
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(Color.csqSuccess)
                        .frame(width: 26, height: 26)
                        .shadow(color: Color.csqSuccess.opacity(0.4), radius: 4, x: 0, y: 2)
                    Image(systemName: "person.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                }
                Triangle()
                    .fill(Color.csqSuccess)
                    .frame(width: 8, height: 5)
                    .offset(y: -1)
            }
            .offset(x: -30, y: 10)

            // Car icon — colour and icon driven by the selected ride type
            ZStack {
                Circle()
                    .fill(ride.color)
                    .frame(width: 32, height: 32)
                    .shadow(color: ride.color.opacity(0.4), radius: 6, x: 0, y: 3)
                Image(systemName: ride.iconName)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
            }
            .offset(x: 60, y: -28)

            // Dashed route from car to pickup — colour matches ride type
            Canvas { context, size in
                var path = Path()
                let carX = size.width / 2 + 60
                let carY = size.height / 2 - 28
                let pinX = size.width / 2 - 30
                let pinY = size.height / 2 + 10
                path.move(to: CGPoint(x: carX, y: carY))
                path.addCurve(
                    to: CGPoint(x: pinX, y: pinY),
                    control1: CGPoint(x: carX - 20, y: carY + 20),
                    control2: CGPoint(x: pinX + 20, y: pinY - 20)
                )
                context.stroke(path, with: .color(ride.color.opacity(0.7)),
                               style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [6, 4]))
            }

            // LIVE badge — localised ("LIVE" / "ライブ")
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.csqSuccess)
                    .frame(width: 6, height: 6)
                Text(liveLabel)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.csqSuccess)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.92))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(10)

            // ETA chip — localised string from parent
            Text(etaText)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.csqTextPrimary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.92))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(10)
        }
    }
}

// MARK: - Payment Method Model
// Covers both Singapore (PayNow, cards) and Tokyo (PayPay, Suica, cards).
// Amex is intentionally included to trigger the demo error flow.
enum RidePaymentMethod: Equatable {
    case payNow
    case payPay
    case suica
    case visa
    case mastercard
    case amex

    var displayName: String {
        switch self {
        case .payNow:     return "PayNow"
        case .payPay:     return "PayPay"
        case .suica:      return "Suica / IC カード"
        case .visa:       return "Visa •••• 4821"
        case .mastercard: return "Mastercard •••• 5523"
        case .amex:       return "American Express •••• 3785"
        }
    }

    // Short label shown in the picker header and in CS events
    var trackingLabel: String {
        switch self {
        case .payNow:     return "PayNow"
        case .payPay:     return "PayPay"
        case .suica:      return "Suica"
        case .visa:       return "Visa"
        case .mastercard: return "Mastercard"
        case .amex:       return "American Express"
        }
    }

    var subtitle: String? {
        switch self {
        case .payNow:     return "Instant transfer via Singapore PayNow"
        case .payPay:     return "スキャンして支払い — 日本最大のQRコード決済"
        case .suica:      return "Suica / IC カード残高でお支払い"
        case .visa:       return nil
        case .mastercard: return nil
        case .amex:       return nil
        }
    }

    var icon: String {
        switch self {
        case .payNow:     return "qrcode"
        case .payPay:     return "qrcode"
        case .suica:      return "creditcard.fill"
        case .visa:       return "creditcard.fill"
        case .mastercard: return "creditcard.fill"
        case .amex:       return "creditcard.fill"
        }
    }

    var iconColor: Color {
        switch self {
        case .payNow:     return Color(hex: "#9B1C1C")   // PayNow red
        case .payPay:     return Color(hex: "#D70020")   // PayPay red
        case .suica:      return Color(hex: "#2E7D32")   // Suica green
        case .visa:       return Color(hex: "#1A1F71")   // Visa navy
        case .mastercard: return Color(hex: "#EB001B")   // MC red
        case .amex:       return Color(hex: "#007BC1")   // Amex blue
        }
    }

    // Visual accent chip shown in the picker row
    var brandChip: (label: String, bg: Color, fg: Color) {
        switch self {
        case .payNow:     return ("PayNow",  Color(hex: "#9B1C1C"), .white)
        case .payPay:     return ("PayPay",  Color(hex: "#D70020"), .white)
        case .suica:      return ("Suica",   Color(hex: "#2E7D32"), .white)
        case .visa:       return ("VISA",    Color(hex: "#1A1F71"), .white)
        case .mastercard: return ("MC",      Color(hex: "#EB001B"), .white)
        case .amex:       return ("AMEX",    Color(hex: "#007BC1"), .white)
        }
    }
}

// MARK: - Payment Picker Sheet
struct PaymentPickerSheet: View {
    @Binding var selected: RidePaymentMethod
    let options: [RidePaymentMethod]
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var marketConfig: MarketConfig

    var body: some View {
        let s = marketConfig.strings
        VStack(spacing: 0) {
            // Handle
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.csqBorder)
                .frame(width: 40, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 16)

            // Title
            HStack {
                Text(s.ridePaymentMethodTitle)
                    .font(AppFont.display(17))
                    .foregroundColor(.csqTextPrimary)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.csqTextTertiary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)

            // Options
            VStack(spacing: 8) {
                ForEach(options, id: \.trackingLabel) { method in
                    PaymentOptionRow(
                        method: method,
                        isSelected: selected == method,
                        action: {
                            CSQ.trackEvent("payment_method_selected", properties: [
                                "method": method.trackingLabel
                            ])
                            selected = method
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { dismiss() }
                        }
                    )
                }
            }
            .padding(.horizontal, 16)

            Spacer()
        }
        .background(Color.csqSurface.ignoresSafeArea())
        .onAppear {
            CSQ.trackScreenview("Ride - Payment Picker")
        }
    }
}

// MARK: - Payment Option Row
struct PaymentOptionRow: View {
    let method: RidePaymentMethod
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Brand chip
                Text(method.brandChip.label)
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(method.brandChip.fg)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 5)
                    .background(method.brandChip.bg)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .frame(width: 52)

                // Details
                VStack(alignment: .leading, spacing: 2) {
                    Text(method.displayName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.csqTextPrimary)
                    if let sub = method.subtitle {
                        Text(sub)
                            .font(.system(size: 11))
                            .foregroundColor(.csqTextSecondary)
                    }
                }

                Spacer()

                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.csqPrimary : Color.csqBorder, lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(Color.csqPrimary)
                            .frame(width: 12, height: 12)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .fill(isSelected ? Color.csqPrimaryPastel : Color.csqBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.md)
                            .stroke(isSelected ? Color.csqPrimary : Color.csqBorder,
                                    lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("payment_option_\(method.trackingLabel.lowercased().replacingOccurrences(of: " ", with: "_"))")
        .accessibilityLabel("\(method.displayName)\(isSelected ? ", selected" : "")")
    }
}

// MARK: - Promo Code Sheet
// Intentional UX dark pattern for demo purposes:
// Any code the user enters is silently rejected.
// The sheet closes, the field resets, and the screen returns to its prior
// state with zero feedback. The failure is only visible in Contentsquare
// via the promo_code_invalid event, demonstrating CS's ability to surface
// errors that are completely invisible at the UI layer.
struct PromoCodeSheet: View {
    @Binding var isPresented: Bool
    @Binding var promoCode: String
    let onSubmit: (String) -> Void
    @EnvironmentObject var marketConfig: MarketConfig

    @State private var inputCode: String = ""
    @State private var isProcessing: Bool = false   // brief flicker — makes button feel alive
    @FocusState private var isFocused: Bool

    var body: some View {
        let s = marketConfig.strings
        VStack(spacing: 0) {
            // Handle
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.csqBorder)
                .frame(width: 40, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 20)

            // Title
            HStack {
                Text(s.rideEnterPromoTitle)
                    .font(AppFont.display(17))
                    .foregroundColor(.csqTextPrimary)
                Spacer()
                Button { isPresented = false } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.csqTextTertiary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)

            // Input field
            HStack(spacing: 10) {
                Image(systemName: "tag.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.csqTextTertiary)
                TextField(s.ridePromoPlaceholder, text: $inputCode)
                    .font(.system(size: 15, weight: .medium))
                    .textInputAutocapitalization(.characters)
                    .disableAutocorrection(true)
                    .focused($isFocused)
                    .submitLabel(.done)
                    .onSubmit { submitCode() }
                if !inputCode.isEmpty {
                    Button { inputCode = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.csqTextTertiary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.csqBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .stroke(isFocused ? Color.csqPrimary : Color.csqBorder, lineWidth: 1.5)
            )
            .padding(.horizontal, 20)

            Spacer()

            // Apply button
            // Never disabled — every tap reaches the CS SDK gesture recognizer.
            // isProcessing gives a 0.4s visual flicker so it feels like it tried,
            // then snaps back to idle with no feedback, prompting the user to tap again.
            Button { submitCode() } label: {
                Group {
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                            .scaleEffect(0.85)
                    } else {
                        Text(inputCode.isEmpty ? s.rideApply : "\(s.rideApply) \"\(inputCode.uppercased())\"")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    Group {
                        if inputCode.isEmpty {
                            Color.csqBorder
                        } else {
                            LinearGradient(colors: [.csqPrimary, .csqPrimaryDark],
                                           startPoint: .leading, endPoint: .trailing)
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.full))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(Color.csqSurface.ignoresSafeArea())
        .onAppear {
            isFocused = true
            CSQ.trackScreenview("Ride - Promo Code Entry")
        }
    }

    private func submitCode() {
        guard !inputCode.isEmpty, !isProcessing else { return }
        let submitted = inputCode.uppercased()

        // Flicker: spinner for 0.4s, then silently back to idle.
        // Sheet stays open. User sees no success or failure — just a brief spin.
        // Each subsequent tap fires onSubmit again → another CS event logged.
        isProcessing = true
        isFocused = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            onSubmit(submitted)
            isProcessing = false
            // Do NOT close the sheet. User is left in limbo, prompting rage taps.
        }
    }
}
