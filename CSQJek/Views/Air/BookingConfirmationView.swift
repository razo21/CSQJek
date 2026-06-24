import SwiftUI
import ContentsquareSDK

private enum BookingAccessID {
    static let doneButton      = "air_booking_btn_done"
    static let downloadButton  = "air_booking_btn_download"
    static let shareButton     = "air_booking_btn_share"
    static let addCalendar     = "air_booking_btn_calendar"
}

struct BookingConfirmationView: View {
    let flight       : Flight
    let fare         : FlightDetailView.FareOption
    let search       : FlightSearch
    let totalPrice   : Double
    @Binding var isAirPresented: Bool

    @EnvironmentObject var marketConfig: MarketConfig

    @State private var checkScale   : CGFloat = 0
    @State private var checkOpacity : Double  = 0
    @State private var cardOffset   : CGFloat = 40
    @State private var cardOpacity  : Double  = 0

    private let airBlue  = Color(hex: "#1B3FAB")
    private let pnr      = "CSQ-\(Int.random(in: 10000...99999))"

    private func fareDisplayName(_ fare: FlightDetailView.FareOption) -> String {
        switch fare {
        case .lite:  return marketConfig.strings.airFareLite
        case .value: return marketConfig.strings.airFareValue
        case .flex:  return marketConfig.strings.airFareFlex
        }
    }

    private func fareBaggageShort(_ fare: FlightDetailView.FareOption) -> String {
        switch fare {
        case .lite:  return marketConfig.strings.airBaggageLite.components(separatedBy: " + ").first ?? marketConfig.strings.airBaggageLite
        case .value: return marketConfig.strings.airBaggageValue.components(separatedBy: " + ").first ?? marketConfig.strings.airBaggageValue
        case .flex:  return marketConfig.strings.airBaggageFlex.components(separatedBy: " + ").first ?? marketConfig.strings.airBaggageFlex
        }
    }

    private var formattedDeparture: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEE, d MMM yyyy"
        return fmt.string(from: search.date)
    }

    var body: some View {
        ZStack {
            // Sky gradient background
            LinearGradient(
                colors: [Color(hex: "#0D2B8A"), Color(hex: "#1B3FAB"), Color(hex: "#4C8EF5")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {

                    // Top bar
                    HStack {
                        Spacer()
                        HStack(spacing: 6) {
                            Image(systemName: "airplane")
                                .font(.system(size: 14, weight: .bold))
                            Text("CSQAir")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.top, 16)
                    .padding(.horizontal, 20)

                    // Success checkmark
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.15))
                                .frame(width: 100, height: 100)
                            Circle()
                                .fill(Color.white.opacity(0.25))
                                .frame(width: 78, height: 78)
                            Circle()
                                .fill(Color.white)
                                .frame(width: 60, height: 60)
                            Image(systemName: "checkmark")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(airBlue)
                                .scaleEffect(checkScale)
                                .opacity(checkOpacity)
                        }

                        Text(marketConfig.strings.airBookingConfirmed)
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text(marketConfig.strings.airTicketSentTo(marketConfig.strings.profileUserEmail))
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.75))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .opacity(cardOpacity)

                    // Boarding Pass Card
                    boardingPassCard
                        .padding(.horizontal, 20)
                        .offset(y: cardOffset)
                        .opacity(cardOpacity)

                    // Action Buttons
                    VStack(spacing: 10) {
                        HStack(spacing: 10) {
                            actionButton(icon: "arrow.down.doc.fill", label: marketConfig.strings.airETicketButton, id: BookingAccessID.downloadButton, color: Color.white.opacity(0.2))
                            actionButton(icon: "calendar.badge.plus", label: marketConfig.strings.airAddToCalButton, id: BookingAccessID.addCalendar, color: Color.white.opacity(0.2))
                            actionButton(icon: "square.and.arrow.up", label: marketConfig.strings.airShareButton, id: BookingAccessID.shareButton, color: Color.white.opacity(0.2))
                        }

                        Button {
                            CSQ.trackEvent("air_booking_done_tapped", properties: ["pnr": pnr])
                            isAirPresented = false
                        } label: {
                            Text(marketConfig.strings.airBackToAir)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(airBlue)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: AppRadius.full))
                                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                        }
                        .accessibilityIdentifier(BookingAccessID.doneButton)
                    }
                    .padding(.horizontal, 20)
                    .offset(y: cardOffset)
                    .opacity(cardOpacity)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            CSQ.trackScreenview("Air - Booking Confirmation")
            CSQ.trackEvent("air_booking_completed", properties: [
                "pnr": pnr,
                "airline": flight.airline.name,
                "route": "\(flight.origin.code)-\(flight.destination.code)",
                "fare": fare.rawValue,
                "total": String(format: "%.0f", totalPrice),
                "passengers": search.passengers
            ])

            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2)) {
                checkScale   = 1
                checkOpacity = 1
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.45)) {
                cardOffset  = 0
                cardOpacity = 1
            }
        }
    }

    // MARK: - Boarding Pass

    private var boardingPassCard: some View {
        VStack(spacing: 0) {
            // Top section — flight info
            VStack(spacing: 16) {
                // Airline + booking ref
                HStack {
                    HStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(flight.airline.color.opacity(0.12))
                                .frame(width: 36, height: 36)
                            Text(flight.airline.code)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(flight.airline.color)
                        }
                        Text(flight.airline.name)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.csqTextPrimary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(marketConfig.strings.airBookingRef)
                            .font(.system(size: 10))
                            .foregroundColor(.csqTextTertiary)
                        Text(pnr)
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(airBlue)
                    }
                }

                // Route
                HStack(alignment: .top, spacing: 0) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(flight.departureTime)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.csqTextPrimary)
                        Text(flight.origin.code)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(airBlue)
                        Text(flight.origin.cityName(for: marketConfig.market))
                            .font(.system(size: 11))
                            .foregroundColor(.csqTextSecondary)
                    }

                    Spacer()

                    VStack(spacing: 4) {
                        Text(airDurationDisplay(flight.totalDuration, for: marketConfig.market))
                            .font(.system(size: 10))
                            .foregroundColor(.csqTextTertiary)
                            .padding(.top, 10)
                        Image(systemName: "airplane")
                            .font(.system(size: 18))
                            .foregroundColor(airBlue)
                        Text(flight.stopsLabelDisplay(for: marketConfig.market))
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(flight.stops == 0 ? Color.csqSuccess : .csqTextTertiary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 3) {
                        Text(flight.arrivalTime)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.csqTextPrimary)
                        Text(flight.destination.code)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(airBlue)
                        Text(flight.destination.cityName(for: marketConfig.market))
                            .font(.system(size: 11))
                            .foregroundColor(.csqTextSecondary)
                    }
                }

                // Date + fare + flight number
                HStack(spacing: 16) {
                    infoChip(icon: "calendar", value: formattedDeparture)
                    infoChip(icon: "seat.fill", value: "\(fareDisplayName(fare)) · \(search.cabin.displayName(for: marketConfig.market))")
                    infoChip(icon: "person.fill", value: "\(search.passengers) \(marketConfig.strings.airPaxLabel)")
                }
            }
            .padding(20)
            .background(Color.csqSurface)

            // Tear-line separator
            HStack(spacing: 0) {
                Circle()
                    .fill(Color(hex: "#E8F0FE"))
                    .frame(width: 24, height: 24)
                    .offset(x: -12)
                HStack(spacing: 4) {
                    ForEach(0..<22, id: \.self) { _ in
                        Rectangle()
                            .fill(Color(hex: "#D1D9E0"))
                            .frame(width: 6, height: 1)
                    }
                }
                Circle()
                    .fill(Color(hex: "#E8F0FE"))
                    .frame(width: 24, height: 24)
                    .offset(x: 12)
            }
            .background(Color.clear)

            // Bottom section — passenger + baggage info
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(marketConfig.strings.airPassengerLabel2)
                        .font(.system(size: 10))
                        .foregroundColor(.csqTextTertiary)
                    Text(marketConfig.strings.airPassengerName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.csqTextPrimary)
                    Text(marketConfig.strings.airAdultEconomy)
                        .font(.system(size: 11))
                        .foregroundColor(.csqTextSecondary)
                }
                Spacer()
                VStack(alignment: .center, spacing: 4) {
                    Text(marketConfig.strings.airSeatLabel)
                        .font(.system(size: 10))
                        .foregroundColor(.csqTextTertiary)
                    Text("24A")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.csqTextPrimary)
                    Text(marketConfig.strings.airSeatWindow)
                        .font(.system(size: 11))
                        .foregroundColor(.csqTextSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(marketConfig.strings.airBaggageLabel2)
                        .font(.system(size: 10))
                        .foregroundColor(.csqTextTertiary)
                    Text(fareBaggageShort(fare))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.csqTextPrimary)
                    Text(marketConfig.strings.airCheckedLabel)
                        .font(.system(size: 11))
                        .foregroundColor(.csqTextSecondary)
                }
            }
            .padding(20)
            .background(Color(hex: "#F0F4FF"))

            // Barcode footer
            VStack(spacing: 8) {
                Image(systemName: "barcode")
                    .font(.system(size: 52))
                    .foregroundColor(airBlue.opacity(0.6))
                    .frame(maxWidth: .infinity)
                Text(pnr + flight.segments[0].flightNumber.replacingOccurrences(of: " ", with: ""))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.csqTextTertiary)
            }
            .padding(.vertical, 16)
            .background(Color.csqSurface)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
    }

    private func infoChip(icon: String, value: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(airBlue)
            Text(value)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.csqTextSecondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(hex: "#E8F0FE"))
        .clipShape(Capsule())
    }

    private func actionButton(icon: String, label: String, id: String, color: Color) -> some View {
        Button {} label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .accessibilityIdentifier(id)
    }
}
