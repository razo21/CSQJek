import SwiftUI
import ContentsquareSDK

// MARK: - Rider Tracking View
// Three-phase flow:
//   .finding  → pulsing search animation (auto-advances after ~2.5s)
//   .found    → rider assigned card animates in (auto-advances after ~1.5s)
//   .enRoute  → simulated map + live ETA countdown

struct RiderTrackingView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var marketConfig: MarketConfig

    @State private var phase: TrackingPhase = .finding
    @State private var riderProgress: CGFloat = 0.0   // 0 → 1 along route
    @State private var etaSeconds: Int = 2700          // 45 min in seconds
    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.6
    @State private var riderCardOffset: CGFloat = 200
    @State private var riderCardOpacity: Double = 0
    @State private var mapOpacity: Double = 0

    private let riderName  = "Ravi K."
    private let riderInit  = "RK"
    private let riderRating = 4.8
    private let riderBike  = "Bicycle · SG-BX-4821"
    private let riderETA   = "~ 45 min"

    let mainTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    enum TrackingPhase { case finding, found, enRoute }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.csqBackground.ignoresSafeArea()

            switch phase {
            case .finding:
                findingView
            case .found, .enRoute:
                enRouteView
            }
        }
        .navigationBarHidden(true)
        .onAppear { startFindingAnimation() }
        .onReceive(mainTimer) { _ in
            guard phase == .enRoute else { return }
            if etaSeconds > 0 { etaSeconds -= 1 }
            withAnimation(.linear(duration: 1)) {
                riderProgress = min(riderProgress + 0.002, 1.0)
            }
        }
        .onAppear {
            CSQ.trackScreenview("Grocery - Rider Tracking")
        }
    }

    // MARK: - Finding Phase

    private var findingView: some View {
        VStack(spacing: 0) {
            // Nav
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.csqTextPrimary)
                        .frame(width: 36, height: 36)
                        .background(Color.csqSurface)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            Spacer()

            // Pulsing circles
            ZStack {
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(Color.csqMartGreen.opacity(0.15 - Double(i) * 0.04), lineWidth: 1.5)
                        .frame(
                            width: 100 + CGFloat(i) * 50,
                            height: 100 + CGFloat(i) * 50
                        )
                        .scaleEffect(pulseScale + CGFloat(i) * 0.15)
                        .opacity(pulseOpacity - Double(i) * 0.15)
                        .animation(
                            .easeInOut(duration: 1.2).repeatForever(autoreverses: true).delay(Double(i) * 0.3),
                            value: pulseScale
                        )
                }

                // Centre icon
                ZStack {
                    Circle()
                        .fill(Color.csqMartGreen)
                        .frame(width: 80, height: 80)
                        .shadow(color: Color.csqMartGreen.opacity(0.4), radius: 16, x: 0, y: 6)
                    Image(systemName: "bicycle")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .frame(height: 280)

            VStack(spacing: 10) {
                Text(marketConfig.strings.riderFindingPartner)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.csqTextPrimary)
                Text(marketConfig.strings.riderFindingSubtitle)
                    .font(AppFont.body(14))
                    .foregroundColor(.csqTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            // Cancel option
            Button { dismiss() } label: {
                Text(marketConfig.strings.riderCancelOrder)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.csqError)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.csqError.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.full))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    // MARK: - En Route Phase (map + rider card)

    private var enRouteView: some View {
        VStack(spacing: 0) {
            // ── Simulated map (top ~55%) ──────────────────────────────────
            ZStack(alignment: .topLeading) {
                SimulatedMapView(riderProgress: riderProgress)
                    .frame(maxWidth: .infinity)
                    .opacity(mapOpacity)

                // Close button overlay
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.csqTextPrimary)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.9))
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 2)
                }
                .padding(16)
                .padding(.top, 8)
            }
            .frame(height: UIScreen.main.bounds.height * 0.48)

            // ── Rider card (bottom ~52%) ──────────────────────────────────
            VStack(spacing: 0) {
                // ETA banner
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.csqMartGreen.opacity(0.12))
                            .frame(width: 38, height: 38)
                        Image(systemName: "clock.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.csqMartGreen)
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text(marketConfig.strings.riderEstimatedArrival)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.csqTextSecondary)
                        Text(etaString)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.csqTextPrimary)
                    }
                    Spacer()
                    // Live pulse dot
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Color.csqSuccess)
                            .frame(width: 7, height: 7)
                            .scaleEffect(pulseScale)
                            .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: pulseScale)
                        Text(marketConfig.strings.riderLiveBadge)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.csqSuccess)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.csqSuccess.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.full))
                }
                .padding(16)
                .background(Color.csqSurface)

                Divider()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {

                        // Rider row
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(
                                        colors: [.csqMartGreen, Color(hex: "#1A9E82")],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 56, height: 56)
                                Text(riderInit)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(riderName)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.csqTextPrimary)
                                HStack(spacing: 6) {
                                    StarRating(rating: riderRating, size: 11)
                                    Text("\(riderRating, specifier: "%.1f") · 1,203 deliveries")
                                        .font(.system(size: 12))
                                        .foregroundColor(.csqTextSecondary)
                                }
                                Text(riderBike)
                                    .font(.system(size: 12))
                                    .foregroundColor(.csqTextSecondary)
                            }
                            Spacer()
                            HStack(spacing: 8) {
                                Button {
                                    CSQ.trackEvent("rider_call_tapped", properties: ["rider": riderName])
                                } label: {
                                    Image(systemName: "phone.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.csqSuccess)
                                        .frame(width: 40, height: 40)
                                        .background(Color.csqSuccess.opacity(0.1))
                                        .clipShape(Circle())
                                }
                                Button {
                                    CSQ.trackEvent("rider_message_tapped", properties: ["rider": riderName])
                                } label: {
                                    Image(systemName: "message.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.csqRideBlue)
                                        .frame(width: 40, height: 40)
                                        .background(Color.csqRideBlue.opacity(0.1))
                                        .clipShape(Circle())
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.csqSurface)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)

                        // Delivery route steps
                        DeliveryStepsRow(riderProgress: riderProgress)

                        // Safety button
                        Button {} label: {
                            HStack(spacing: 8) {
                                Image(systemName: "shield.fill")
                                    .font(.system(size: 14))
                                Text(marketConfig.strings.riderSafetyTools)
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundColor(.csqTextSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(Color.csqBackground)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.md)
                                    .stroke(Color.csqBorder, lineWidth: 1)
                            )
                        }

                        Color.clear.frame(height: 16)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                }
                .background(Color.csqBackground)
            }
            .offset(y: riderCardOffset)
            .opacity(riderCardOpacity)
        }
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Helpers

    private var etaString: String {
        let mins = etaSeconds / 60
        let secs = etaSeconds % 60
        if mins > 0 { return "\(mins) min \(secs < 10 ? "0" : "")\(secs) sec" }
        return "\(secs) sec"
    }

    // MARK: - Animation Sequence

    private func startFindingAnimation() {
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            pulseScale = 1.18
            pulseOpacity = 0.3
        }

        // Phase 1 → 2: rider found after 2.5s
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                phase = .found
                riderCardOffset = 0
                riderCardOpacity = 1
            }
            withAnimation(.easeIn(duration: 0.4)) {
                mapOpacity = 1
            }
            CSQ.trackEvent("delivery_rider_matched", properties: ["rider": riderName])
        }

        // Phase 2 → 3: start live movement after another 1.5s
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            withAnimation { phase = .enRoute }
        }
    }
}

// MARK: - Simulated Map View

struct SimulatedMapView: View {
    let riderProgress: CGFloat

    // Route: normalized CGPoints (0–1) from rider origin to destination
    private let route: [CGPoint] = [
        CGPoint(x: 0.78, y: 0.20),
        CGPoint(x: 0.60, y: 0.20),
        CGPoint(x: 0.60, y: 0.42),
        CGPoint(x: 0.40, y: 0.42),
        CGPoint(x: 0.40, y: 0.65),
        CGPoint(x: 0.28, y: 0.65),
        CGPoint(x: 0.28, y: 0.80)
    ]

    // City block layout
    private let blocks: [(CGRect, CGFloat)] = [
        (CGRect(x: 0.00, y: 0.00, width: 0.52, height: 0.15), 0.0),
        (CGRect(x: 0.65, y: 0.00, width: 0.35, height: 0.15), 0.0),
        (CGRect(x: 0.65, y: 0.25, width: 0.35, height: 0.12), 0.0),
        (CGRect(x: 0.00, y: 0.25, width: 0.52, height: 0.12), 0.0),
        (CGRect(x: 0.65, y: 0.48, width: 0.35, height: 0.14), 0.0),
        (CGRect(x: 0.48, y: 0.48, width: 0.10, height: 0.14), 0.0),
        (CGRect(x: 0.00, y: 0.48, width: 0.32, height: 0.14), 0.0),
        (CGRect(x: 0.00, y: 0.72, width: 0.20, height: 0.28), 0.0),
        (CGRect(x: 0.35, y: 0.72, width: 0.65, height: 0.28), 0.0),
        (CGRect(x: 0.48, y: 0.25, width: 0.10, height: 0.12), 0.0),
    ]

    private func riderPos(in size: CGSize) -> CGPoint {
        interpolate(progress: riderProgress, in: size)
    }

    private func interpolate(progress: CGFloat, in size: CGSize) -> CGPoint {
        let clampedProgress = max(0, min(1, progress))
        let totalSegments = route.count - 1
        guard totalSegments > 0 else { return toPoint(route[0], in: size) }

        let segLen = 1.0 / CGFloat(totalSegments)
        let segIdx = min(Int(clampedProgress / segLen), totalSegments - 1)
        let segProg = (clampedProgress - CGFloat(segIdx) * segLen) / segLen

        let a = route[segIdx]
        let b = route[segIdx + 1]
        return CGPoint(
            x: (a.x + (b.x - a.x) * segProg) * size.width,
            y: (a.y + (b.y - a.y) * segProg) * size.height
        )
    }

    private func toPoint(_ norm: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(x: norm.x * size.width, y: norm.y * size.height)
    }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size

            ZStack {
                // ── Map base ─────────────────────────────────────────────
                Color(hex: "#EDE9E3")

                // ── City blocks ───────────────────────────────────────────
                ForEach(0..<blocks.count, id: \.self) { i in
                    let r = blocks[i].0
                    Rectangle()
                        .fill(Color(hex: "#D4CFCA"))
                        .frame(
                            width: r.width * size.width,
                            height: r.height * size.height
                        )
                        .position(
                            x: (r.minX + r.width / 2) * size.width,
                            y: (r.minY + r.height / 2) * size.height
                        )
                }

                // ── Route line ────────────────────────────────────────────
                Canvas { ctx, _ in
                    var path = Path()
                    let pts = route.map { toPoint($0, in: size) }
                    path.move(to: pts[0])
                    for pt in pts.dropFirst() { path.addLine(to: pt) }
                    ctx.stroke(
                        path,
                        with: .color(Color.csqMartGreen.opacity(0.25)),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)
                    )
                    ctx.stroke(
                        path,
                        with: .color(Color.csqMartGreen),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round, dash: [8, 5])
                    )
                }

                // ── Destination pin ───────────────────────────────────────
                let dest = toPoint(route.last!, in: size)
                ZStack {
                    Circle()
                        .fill(Color.csqMartGreen.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Circle()
                        .fill(Color.csqMartGreen)
                        .frame(width: 26, height: 26)
                        .shadow(color: Color.csqMartGreen.opacity(0.4), radius: 6, x: 0, y: 3)
                    Image(systemName: "house.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                }
                .position(dest)

                // ── Rider marker ──────────────────────────────────────────
                let rPos = riderPos(in: size)
                ZStack {
                    Circle()
                        .fill(Color.csqMartGreen.opacity(0.2))
                        .frame(width: 42, height: 42)
                    Circle()
                        .fill(Color.csqMartGreen)
                        .frame(width: 28, height: 28)
                        .shadow(color: Color.csqMartGreen.opacity(0.5), radius: 6, x: 0, y: 3)
                    Image(systemName: "bicycle")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
                .position(rPos)
                .animation(.linear(duration: 1), value: riderProgress)

                // ── You are here label ────────────────────────────────────
                Text("You")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.csqMartGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .position(x: dest.x + 20, y: dest.y - 28)

                // ── Map attribution (realistic) ───────────────────────────
                Text("© CSQMaps")
                    .font(.system(size: 9))
                    .foregroundColor(Color.black.opacity(0.3))
                    .padding(6)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            }
            .clipShape(Rectangle())
        }
    }
}

// MARK: - Delivery Steps Row

struct DeliveryStepsRow: View {
    let riderProgress: CGFloat
    @EnvironmentObject var marketConfig: MarketConfig

    private var currentStep: Int {
        switch riderProgress {
        case ..<0.01: return 0
        case ..<0.4:  return 1
        case ..<0.85: return 2
        default:      return 3
        }
    }

    private var steps: [(String, String, Color)] {[
        (marketConfig.strings.orderStepConfirmed,      "checkmark.seal.fill", Color.csqSuccess),
        (marketConfig.strings.orderStepPacked,         "bag.fill",            Color.csqWarning),
        (marketConfig.strings.orderStepOutForDelivery, "bicycle",             Color.csqRideBlue),
        (marketConfig.strings.orderStepDelivered,      "house.fill",          Color.csqMartGreen)
    ]}

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<steps.count, id: \.self) { i in
                let (label, icon, color) = steps[i]
                let isActive   = i == currentStep
                let isComplete = i < currentStep

                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(isComplete || isActive ? color.opacity(0.15) : Color.csqBorder.opacity(0.3))
                            .frame(width: 34, height: 34)
                        Image(systemName: isComplete ? "checkmark" : icon)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(isComplete || isActive ? color : .csqTextTertiary)
                    }
                    .overlay(
                        Circle()
                            .stroke(isActive ? color : Color.clear, lineWidth: 2)
                    )
                    Text(label)
                        .font(.system(size: 9, weight: isActive ? .bold : .medium))
                        .foregroundColor(isActive ? color : .csqTextTertiary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity)

                if i < steps.count - 1 {
                    Rectangle()
                        .fill(i < currentStep ? Color.csqSuccess : Color.csqBorder.opacity(0.4))
                        .frame(height: 2)
                        .frame(maxWidth: 30)
                        .padding(.bottom, 22)
                }
            }
        }
        .padding(16)
        .background(Color.csqSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}
