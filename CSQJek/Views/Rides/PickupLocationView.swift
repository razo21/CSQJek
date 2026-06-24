import SwiftUI
import ContentsquareSDK

struct PickupLocationView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var marketConfig: MarketConfig
    let destination: Location
    @State private var pinOffset: CGSize = .zero
    @State private var isDragging = false
    @State private var navigateToConfirm = false
    @State private var selectedPickup = ""
    @State private var pickupAddress = ""   // set from marketConfig in onAppear

    var body: some View {
        let s = marketConfig.strings
        ZStack {
            // Map
            PickupMapView(isDragging: $isDragging, pinOffset: $pinOffset)
                .ignoresSafeArea()

            // Back button
            VStack {
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
                    Text(s.rideSetPickupTitle)
                        .font(AppFont.display(15))
                        .foregroundColor(.csqTextPrimary)
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

            // Draggable pin (center)
            VStack(spacing: 0) {
                ZStack {
                    if isDragging {
                        Circle()
                            .fill(Color.csqSuccess.opacity(0.2))
                            .frame(width: 60, height: 60)
                    }
                    Circle()
                        .fill(Color.csqSuccess)
                        .frame(width: 44, height: 44)
                        .shadow(color: Color.csqSuccess.opacity(0.4), radius: 10, x: 0, y: 4)
                    Image(systemName: "person.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
                .scaleEffect(isDragging ? 1.1 : 1.0)

                Triangle()
                    .fill(Color.csqSuccess)
                    .frame(width: 12, height: 7)
                    .offset(y: -1)

                if isDragging {
                    Circle()
                        .fill(Color.csqSuccess.opacity(0.3))
                        .frame(width: 8, height: 4)
                        .scaleEffect(x: 2, y: 1)
                        .offset(y: 2)
                }
            }
            .offset(pinOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        withAnimation(.spring(response: 0.3)) {
                            pinOffset = value.translation
                            isDragging = true
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.spring(response: 0.4)) {
                            pinOffset = .zero
                            isDragging = false
                        }
                    }
            )
            .animation(.spring(), value: isDragging)

            // Bottom sheet
            VStack(spacing: 0) {
                Spacer()
                VStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.csqBorder)
                        .frame(width: 40, height: 4)
                        .padding(.top, 10)
                        .padding(.bottom, 16)

                    // Destination summary
                    HStack(spacing: 12) {
                        Image(systemName: "mappin.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.csqPrimary)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(s.rideGoingTo)
                                .font(.system(size: 11))
                                .foregroundColor(.csqTextTertiary)
                            Text(destination.name)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.csqTextPrimary)
                        }
                        Spacer()
                        Text(s.rideChangeLabel)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.csqPrimary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                    Divider()

                    // Pickup address
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.csqSuccess)
                            .frame(width: 10, height: 10)
                            .padding(.leading, 9)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(s.ridePickupPoint)
                                .font(.system(size: 11))
                                .foregroundColor(.csqTextTertiary)
                            Text(pickupAddress)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.csqTextPrimary)
                        }
                        Spacer()
                        Button {
                        } label: {
                            Image(systemName: "location.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.csqPrimary)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)

                    Divider()

                    // Hint
                    HStack {
                        Image(systemName: "hand.draw.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.csqTextTertiary)
                        Text(s.rideDragHint)
                            .font(.system(size: 12))
                            .foregroundColor(.csqTextTertiary)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.csqBackground)

                    // Confirm button
                    NavigationLink(destination: ConfirmRideView(destination: destination, pickupAddress: pickupAddress), isActive: $navigateToConfirm) {
                        EmptyView()
                    }

                    CSQButton(s.rideConfirmPickup, icon: "checkmark") {
                        navigateToConfirm = true
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 28)
                }
                .background(Color.csqSurface)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(color: Color.black.opacity(0.12), radius: 20, x: 0, y: -4)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            CSQ.trackScreenview("Ride - Pickup")
            // Initialise pickup address from market config on first appear
            if pickupAddress.isEmpty {
                pickupAddress = marketConfig.strings.rideDefaultPickupAddress
                selectedPickup = marketConfig.strings.rideCurrentLocation
            }
        }
    }
}

struct PickupMapView: View {
    @Binding var isDragging: Bool
    @Binding var pinOffset: CGSize

    // Fixed driver positions — avoid array literals inside body
    private let driverOffsets: [(CGFloat, CGFloat)] = [(-80,-100),(100,-80),(-120,60),(60,80)]

    var body: some View {
        ZStack {
            Color(hex: "#E8EDF2")

            // Merged into one Canvas + drawingGroup for a single texture on simulator
            Canvas { context, size in
                let roadShading = GraphicsContext.Shading.color(Color.white)
                for y in stride(from: 0.0, to: size.height, by: 70) {
                    var p = Path(); p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: size.width, y: y))
                    context.stroke(p, with: roadShading, lineWidth: 8)
                }
                for x in stride(from: 0.0, to: size.width, by: 90) {
                    var p = Path(); p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: size.height))
                    context.stroke(p, with: roadShading, lineWidth: 8)
                }
                let blockShadings: [GraphicsContext.Shading] = [
                    .color(Color(hex: "#D4DCE8")), .color(Color(hex: "#CBD5E0")),
                    .color(Color(hex: "#C4D0DF")), .color(Color(hex: "#BACCD8"))
                ]
                for row in 0..<7 {
                    for col in 0..<5 {
                        let rect = CGRect(x: CGFloat(col)*90+12, y: CGFloat(row)*70+12, width: 66, height: 46)
                        context.fill(Path(roundedRect: rect, cornerRadius: 5), with: blockShadings[(row+col) % 4])
                    }
                }
            }
            .drawingGroup()

            // Accuracy ring — kept outside drawingGroup so spring animation is smooth
            Circle()
                .stroke(Color.csqSuccess.opacity(0.2), lineWidth: 20)
                .frame(width: 100, height: 100)
                .scaleEffect(isDragging ? 1.2 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)

            // Nearby drivers — fixed positions
            ForEach(0..<4) { i in
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 28, height: 28)
                        .shadow(color: Color.black.opacity(0.12), radius: 4, x: 0, y: 2)
                    Image(systemName: "car.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.csqRideBlue)
                }
                .offset(x: driverOffsets[i].0, y: driverOffsets[i].1)
            }
        }
    }
}
