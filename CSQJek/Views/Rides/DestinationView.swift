import SwiftUI
import ContentsquareSDK

struct DestinationView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var marketConfig: MarketConfig
    @State private var destinationText = ""
    @State private var isFocused = false
    @State private var navigateToPickup = false
    @State private var selectedDestination: Location?

    private var recentLocations: [Location] { marketConfig.content.locations }

    var body: some View {
        let s = marketConfig.strings
        NavigationView {
            ZStack {
                // Map background (simulated)
                MapPlaceholder()
                    .ignoresSafeArea()

                // Overlay sheet
                VStack(spacing: 0) {
                    // Drag indicator
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.csqBorder)
                        .frame(width: 40, height: 4)
                        .padding(.top, 10)
                        .padding(.bottom, 16)

                    // Header
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.csqTextPrimary)
                                .frame(width: 36, height: 36)
                                .background(Color.csqBackground)
                                .clipShape(Circle())
                        }
                        Spacer()
                        Text(s.rideBookTitle)
                            .font(AppFont.display(17))
                            .foregroundColor(.csqTextPrimary)
                        Spacer()
                        Color.clear.frame(width: 36, height: 36)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)

                    // Location inputs
                    VStack(spacing: 0) {
                        // Pickup row
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color.csqSuccess)
                                .frame(width: 10, height: 10)
                            Text(s.rideCurrentLocation)
                                .font(.system(size: 15))
                                .foregroundColor(.csqTextSecondary)
                            Spacer()
                            Text(s.rideChangeLabel)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.csqPrimary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)

                        // Dashed line connector
                        HStack {
                            VStack(spacing: 2) {
                                ForEach(0..<4) { _ in
                                    Rectangle()
                                        .fill(Color.csqBorder)
                                        .frame(width: 1.5, height: 4)
                                }
                            }
                            .padding(.leading, 20)
                            Spacer()
                        }

                        // Destination row
                        HStack(spacing: 12) {
                            Image(systemName: "mappin.fill")
                                .font(.system(size: 13))
                                .foregroundColor(.csqPrimary)
                            TextField(s.homeSearchPlaceholder, text: $destinationText)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.csqTextPrimary)
                                .csqMaskContents(true)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color.csqPrimaryPastel)
                    }
                    .background(Color.csqSurface)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.lg)
                            .stroke(Color.csqBorder, lineWidth: 1)
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)

                    // Suggestions / Recents
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            // Section header
                            HStack {
                                Text(destinationText.isEmpty ? s.rideSavedAndRecent : s.rideSuggestions)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.csqTextTertiary)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)

                            ForEach(recentLocations) { location in
                                NavigationLink(
                                    destination: PickupLocationView(destination: location),
                                    isActive: Binding(
                                        get: { selectedDestination?.id == location.id },
                                        set: { if $0 { selectedDestination = location } }
                                    )
                                ) {
                                    EmptyView()
                                }

                                Button {
                                    selectedDestination = location
                                    destinationText = location.name
                                    CSQ.trackEvent("destination_selected", properties: [
                                        "location_name": location.name,
                                        "source":        "recent"
                                    ])
                                } label: {
                                    LocationSuggestionRow(location: location)
                                }
                                .buttonStyle(.plain)

                                if location.id != recentLocations.last?.id {
                                    Divider().padding(.leading, 56)
                                }
                            }
                        }
                        .background(Color.csqSurface)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.lg)
                                .stroke(Color.csqBorder, lineWidth: 1)
                        )
                        .padding(.horizontal, 16)
                    }

                    Spacer(minLength: 16)
                }
                .background(Color.csqSurface)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(color: Color.black.opacity(0.12), radius: 20, x: 0, y: -4)
                .frame(maxHeight: UIScreen.main.bounds.height * 0.72)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
            .navigationBarHidden(true)
            .onAppear {
                CSQ.trackScreenview("Ride - Destination")
            }
        }
    }
}

// MARK: - Location Row
struct LocationSuggestionRow: View {
    let location: Location

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.csqBackground)
                    .frame(width: 40, height: 40)
                Image(systemName: location.iconName)
                    .font(.system(size: 16))
                    .foregroundColor(.csqPrimary)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(location.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.csqTextPrimary)
                Text(location.address)
                    .font(.system(size: 12))
                    .foregroundColor(.csqTextSecondary)
                    .lineLimit(1)
            }
            Spacer()
            Image(systemName: "arrow.up.left")
                .font(.system(size: 12))
                .foregroundColor(.csqTextTertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Map Placeholder
// drawingGroup() flattens the Canvas layers into a single Metal-backed texture
// so the simulator only composites one layer instead of two separate Canvas passes.
// The static grid never changes, so this is a pure win with zero trade-offs.
struct MapPlaceholder: View {

    // Fixed car offsets — determined once, not recalculated each render.
    private let carOffsets: [(CGFloat, CGFloat)] = [(-60,-80),(80,-120),(-100,30),(40,50),(-20,-60)]
    private let carRotations: [Double] = [-18, 12, -5, 22, -28]

    var body: some View {
        ZStack {
            Color(hex: "#E8EDF2")

            // Single Canvas for roads + blocks — one draw call instead of two.
            Canvas { context, size in
                // Roads
                let roadColor = GraphicsContext.Shading.color(Color.white)
                for y in stride(from: 0.0, to: size.height, by: 60) {
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                    context.stroke(path, with: roadColor, lineWidth: 6)
                }
                for x in stride(from: 0.0, to: size.width, by: 80) {
                    var path = Path()
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                    context.stroke(path, with: roadColor, lineWidth: 6)
                }
                // Blocks
                let blockColors: [GraphicsContext.Shading] = [
                    .color(Color(hex: "#D4DCE8")),
                    .color(Color(hex: "#CBD5E0")),
                    .color(Color(hex: "#BFC8D6"))
                ]
                for row in 0..<8 {
                    for col in 0..<6 {
                        let rect = CGRect(x: CGFloat(col)*80+10, y: CGFloat(row)*60+10, width: 60, height: 40)
                        context.fill(Path(roundedRect: rect, cornerRadius: 4), with: blockColors[(row+col) % 3])
                    }
                }
            }
            .drawingGroup() // Rasterise to a single Metal texture — key for simulator perf

            // Location pin (kept outside drawingGroup so it stays crisp at all scales)
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(Color.csqPrimary)
                        .frame(width: 44, height: 44)
                        .shadow(color: Color.csqPrimary.opacity(0.35), radius: 8, x: 0, y: 3)
                    Image(systemName: "location.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
                Triangle()
                    .fill(Color.csqPrimary)
                    .frame(width: 14, height: 8)
                    .offset(y: -1)
            }
            .offset(y: -40)

            // Nearby driver icons — fixed positions, no random() on render path
            ForEach(0..<5) { i in
                Image(systemName: "car.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.csqRideBlue)
                    .rotationEffect(.degrees(carRotations[i]))
                    .offset(x: carOffsets[i].0, y: carOffsets[i].1)
            }
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
