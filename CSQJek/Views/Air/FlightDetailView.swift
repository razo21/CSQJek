import SwiftUI
import ContentsquareSDK

private enum DetailAccessID {
    static let backButton     = "air_detail_btn_back"
    static let bookButton     = "air_detail_btn_book"
    static let fareToggle     = "air_detail_toggle_fare"
}

struct FlightDetailView: View {
    let flight          : Flight
    let search          : FlightSearch
    @Binding var isAirPresented: Bool

    @EnvironmentObject var marketConfig: MarketConfig

    @State private var selectedFare : FareOption = .flex
    @State private var showBooking  : Bool       = false
    @Environment(\.dismiss) var dismiss

    private let airBlue = Color(hex: "#1B3FAB")

    enum FareOption: String, CaseIterable {
        case lite   = "Lite"
        case value  = "Value"
        case flex   = "Flex"

        var priceAdd: Double {
            switch self { case .lite: return 0; case .value: return 45; case .flex: return 90 }
        }
        var baggage: String {
            switch self { case .lite: return "7kg cabin only"; case .value: return "20kg checked + 7kg cabin"; case .flex: return "30kg checked + 7kg cabin" }
        }
        var changeFee: String {
            switch self { case .lite: return "Not allowed"; case .value: return "S$75 fee"; case .flex: return "Free changes" }
        }
        var refund: String {
            switch self { case .lite: return "Non-refundable"; case .value: return "S$120 fee"; case .flex: return "Fully refundable" }
        }
        var meal: String {
            switch self { case .lite: return "Not included"; case .value: return "1 meal included"; case .flex: return "2 meals + snack" }
        }
        var seatSelection: String {
            switch self { case .lite: return "Paid"; case .value: return "Standard free"; case .flex: return "Any seat free" }
        }
        var miles: String {
            switch self { case .lite: return "50%"; case .value: return "100%"; case .flex: return "150%" }
        }
    }

    private var fareUpgradePerPax: Double {
        selectedFare.priceAdd * (marketConfig.market == .tokyo ? 100.0 : 1.0)
    }

    private var totalPrice: Double {
        (flight.price + fareUpgradePerPax) * Double(search.passengers)
    }

    private func fareDisplayName(_ fare: FareOption) -> String {
        switch fare {
        case .lite:  return marketConfig.strings.airFareLite
        case .value: return marketConfig.strings.airFareValue
        case .flex:  return marketConfig.strings.airFareFlex
        }
    }

    private func fareBaggage(_ fare: FareOption) -> String {
        switch fare {
        case .lite:  return marketConfig.strings.airBaggageLite
        case .value: return marketConfig.strings.airBaggageValue
        case .flex:  return marketConfig.strings.airBaggageFlex
        }
    }

    private func fareChangeFee(_ fare: FareOption) -> String {
        switch fare {
        case .lite:  return marketConfig.strings.airChangeLite
        case .value: return marketConfig.strings.airChangeValue
        case .flex:  return marketConfig.strings.airChangeFlex
        }
    }

    private func fareRefund(_ fare: FareOption) -> String {
        switch fare {
        case .lite:  return marketConfig.strings.airRefundLite
        case .value: return marketConfig.strings.airRefundValue
        case .flex:  return marketConfig.strings.airRefundFlex
        }
    }

    private func fareMeal(_ fare: FareOption) -> String {
        switch fare {
        case .lite:  return marketConfig.strings.airMealLite
        case .value: return marketConfig.strings.airMealValue
        case .flex:  return marketConfig.strings.airMealFlex
        }
    }

    private func fareSeat(_ fare: FareOption) -> String {
        switch fare {
        case .lite:  return marketConfig.strings.airSeatLite
        case .value: return marketConfig.strings.airSeatValue
        case .flex:  return marketConfig.strings.airSeatFlex
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.csqBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    headerCard
                        .padding(.horizontal, 16)

                    segmentDetails
                        .padding(.horizontal, 16)

                    fareSelector
                        .padding(.horizontal, 16)

                    fareFeatures
                        .padding(.horizontal, 16)

                    priceBreakdown
                        .padding(.horizontal, 16)

                    Spacer(minLength: 100) // space for sticky CTA
                }
                .padding(.top, 12)
            }

            // Sticky Book CTA
            VStack(spacing: 0) {
                Divider()
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(marketConfig.market.formatPrice(totalPrice))
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(airBlue)
                        Text(search.passengers > 1
                             ? marketConfig.strings.airForPassengers(search.passengers)
                             : "\(marketConfig.strings.airPerPerson) · \(fareDisplayName(selectedFare))")
                            .font(.system(size: 11))
                            .foregroundColor(.csqTextSecondary)
                    }
                    Spacer()
                    Button {
                        CSQ.trackEvent("air_book_tapped", properties: [
                            "airline": flight.airline.name,
                            "route": "\(flight.origin.code)-\(flight.destination.code)",
                            "fare": selectedFare.rawValue,
                            "total": String(format: "%.0f", totalPrice)
                        ])
                        showBooking = true
                    } label: {
                        Text(marketConfig.strings.airBookNow)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 36)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(colors: [airBlue, Color(hex: "#0D2B8A")],
                                               startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.full))
                            .shadow(color: airBlue.opacity(0.35), radius: 8, x: 0, y: 4)
                    }
                    .accessibilityIdentifier(DetailAccessID.bookButton)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(Color.csqSurface)
            }
        }
        .navigationBarHidden(true)
        .overlay(alignment: .topLeading) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "#1C1C2E"))
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.white))
                    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
            }
            .accessibilityIdentifier(DetailAccessID.backButton)
            .padding(.leading, 16)
            .padding(.top, 8)
        }
        .fullScreenCover(isPresented: $showBooking) {
            BookingConfirmationView(
                flight: flight,
                fare: selectedFare,
                search: search,
                totalPrice: totalPrice,
                isAirPresented: $isAirPresented
            )
            .environmentObject(marketConfig)
        }
        .onAppear {
            CSQ.trackScreenview("Air - Flight Detail")
        }
    }

    // MARK: - Header Card

    private var headerCard: some View {
        VStack(spacing: 14) {
            // Airline row
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(flight.airline.color.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Text(flight.airline.code)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(flight.airline.color)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(flight.airline.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.csqTextPrimary)
                    Text(flight.segments.map(\.flightNumber).joined(separator: " → "))
                        .font(.system(size: 12))
                        .foregroundColor(.csqTextSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(flight.stopsLabelDisplay(for: marketConfig.market))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(flight.stops == 0 ? Color.csqSuccess : .csqTextSecondary)
                    Text(flight.segments[0].aircraft)
                        .font(.system(size: 11))
                        .foregroundColor(.csqTextTertiary)
                }
            }

            Divider()

            // Route visualiser
            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(flight.departureTime)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.csqTextPrimary)
                    Text(flight.origin.code)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(airBlue)
                    Text(flight.origin.cityName(for: marketConfig.market))
                        .font(.system(size: 12))
                        .foregroundColor(.csqTextSecondary)
                    Text(flight.origin.displayName(for: marketConfig.market))
                        .font(.system(size: 10))
                        .foregroundColor(.csqTextTertiary)
                        .lineLimit(2)
                        .frame(maxWidth: 110, alignment: .leading)
                }

                Spacer()

                VStack(spacing: 6) {
                    Text(airDurationDisplay(flight.totalDuration, for: marketConfig.market))
                        .font(.system(size: 11))
                        .foregroundColor(.csqTextTertiary)
                        .padding(.top, 10)
                    Image(systemName: "airplane")
                        .font(.system(size: 16))
                        .foregroundColor(airBlue)
                    Rectangle()
                        .fill(Color.csqBorder)
                        .frame(width: 60, height: 1)
                    Text(flight.stops == 0 ? marketConfig.strings.airDirect : (marketConfig.market == .tokyo ? "\(flight.stops)回乗継" : "\(flight.stops) stop"))
                        .font(.system(size: 10, weight: flight.stops == 0 ? .semibold : .regular))
                        .foregroundColor(flight.stops == 0 ? Color.csqSuccess : .csqTextTertiary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(flight.arrivalTime)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.csqTextPrimary)
                    Text(flight.destination.code)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(airBlue)
                    Text(flight.destination.cityName(for: marketConfig.market))
                        .font(.system(size: 12))
                        .foregroundColor(.csqTextSecondary)
                    Text(flight.destination.displayName(for: marketConfig.market))
                        .font(.system(size: 10))
                        .foregroundColor(.csqTextTertiary)
                        .lineLimit(2)
                        .frame(maxWidth: 110, alignment: .trailing)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
        .padding(16)
        .background(Color.csqSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.07), radius: 8, x: 0, y: 3)
    }

    // MARK: - Segment Details (layovers)

    private var segmentDetails: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(marketConfig.strings.airFlightDetails)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.csqTextPrimary)

            ForEach(Array(flight.segments.enumerated()), id: \.element.id) { idx, seg in
                VStack(alignment: .leading, spacing: 10) {
                    if idx > 0 {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.csqWarning)
                            Text("\(marketConfig.strings.airLayoverIn) \(flight.segments[idx-1].destination.cityName(for: marketConfig.market))")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.csqWarning)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.csqWarning.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    HStack(spacing: 14) {
                        // Timeline
                        VStack(spacing: 0) {
                            Circle().fill(airBlue).frame(width: 8, height: 8)
                            Rectangle().fill(Color.csqBorder).frame(width: 1, height: 50)
                            Circle().fill(Color.csqSuccess).frame(width: 8, height: 8)
                        }

                        VStack(alignment: .leading, spacing: 20) {
                            // Departure
                            HStack {
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(seg.departureTime)
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.csqTextPrimary)
                                    Text("\(seg.origin.cityName(for: marketConfig.market)) · \(seg.origin.code)")
                                        .font(.system(size: 12))
                                        .foregroundColor(.csqTextSecondary)
                                }
                                Spacer()
                                Text(airDurationDisplay(seg.duration, for: marketConfig.market))
                                    .font(.system(size: 11))
                                    .foregroundColor(.csqTextTertiary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.csqBackground)
                                    .clipShape(Capsule())
                            }

                            // Arrival
                            VStack(alignment: .leading, spacing: 1) {
                                Text(seg.arrivalTime)
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.csqTextPrimary)
                                Text("\(seg.destination.cityName(for: marketConfig.market)) · \(seg.destination.code)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.csqTextSecondary)
                            }
                        }
                    }

                    // Flight number + aircraft chip
                    HStack(spacing: 8) {
                        Label(seg.flightNumber, systemImage: "airplane")
                            .font(.system(size: 11))
                            .foregroundColor(.csqTextSecondary)
                        Text("·")
                            .foregroundColor(.csqTextTertiary)
                        Text(seg.aircraft)
                            .font(.system(size: 11))
                            .foregroundColor(.csqTextSecondary)
                    }
                    .padding(.leading, 22)
                }
            }
        }
        .padding(16)
        .background(Color.csqSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.07), radius: 8, x: 0, y: 3)
    }

    // MARK: - Fare Selector

    private var fareSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(marketConfig.strings.airChooseYourFare)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.csqTextPrimary)

            HStack(spacing: 8) {
                ForEach(FareOption.allCases, id: \.self) { fare in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { selectedFare = fare }
                        CSQ.trackEvent("air_fare_selected", properties: ["fare": fare.rawValue])
                    } label: {
                        VStack(spacing: 4) {
                            Text(fareDisplayName(fare))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(selectedFare == fare ? .white : .csqTextPrimary)
                            Text(fare.priceAdd == 0
                                 ? marketConfig.strings.airFareIncluded
                                 : "+\(marketConfig.market.formatPrice(fare.priceAdd * (marketConfig.market == .tokyo ? 100.0 : 1.0)))")
                                .font(.system(size: 11))
                                .foregroundColor(selectedFare == fare ? .white.opacity(0.85) : .csqTextSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedFare == fare ? airBlue : Color.csqBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(selectedFare == fare ? airBlue : Color.csqBorder, lineWidth: 1)
                        )
                    }
                }
            }
            .accessibilityIdentifier(DetailAccessID.fareToggle)
        }
        .padding(16)
        .background(Color.csqSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.07), radius: 8, x: 0, y: 3)
    }

    // MARK: - Fare Features

    private var fareFeatures: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(marketConfig.strings.airWhatsIncluded)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.csqTextPrimary)

            let features: [(String, String, String)] = [
                ("suitcase.fill",       marketConfig.strings.airBaggageLabel,      fareBaggage(selectedFare)),
                ("arrow.left.arrow.right", marketConfig.strings.airChangesLabel,   fareChangeFee(selectedFare)),
                ("dollarsign.arrow.circlepath", marketConfig.strings.airRefundLabel, fareRefund(selectedFare)),
                ("fork.knife",          marketConfig.strings.airMealsLabel,        fareMeal(selectedFare)),
                ("seat.fill",           marketConfig.strings.airSeatSelectionLabel, fareSeat(selectedFare)),
                ("star.fill",           marketConfig.strings.airMilesEarnedLabel,  selectedFare.miles + " " + marketConfig.strings.airOfBaseMiles),
            ]

            ForEach(features, id: \.0) { (icon, label, value) in
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 13))
                        .foregroundColor(airBlue)
                        .frame(width: 28)
                    Text(label)
                        .font(.system(size: 13))
                        .foregroundColor(.csqTextSecondary)
                    Spacer()
                    Text(value)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.csqTextPrimary)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 160, alignment: .trailing)
                }
                if label != marketConfig.strings.airMilesEarnedLabel { Divider() }
            }
        }
        .padding(16)
        .background(Color.csqSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.07), radius: 8, x: 0, y: 3)
    }

    // MARK: - Price Breakdown

    private var priceBreakdown: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(marketConfig.strings.airPriceBreakdown)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.csqTextPrimary)

            let baseFare   = flight.price * Double(search.passengers)
            let fareUpgrade = fareUpgradePerPax * Double(search.passengers)
            let taxes      = (baseFare + fareUpgrade) * 0.09
            let serviceFee = marketConfig.market == .tokyo ? 500.0 : 4.99

            Group {
                priceRow(marketConfig.strings.airBaseFare, marketConfig.market.formatPrice(baseFare))
                if fareUpgrade > 0 {
                    priceRow("\(fareDisplayName(selectedFare)) \(marketConfig.strings.airUpgrade)", "+\(marketConfig.market.formatPrice(fareUpgrade))")
                }
                priceRow(marketConfig.strings.airTaxesAndFees, marketConfig.market.formatPrice(taxes))
                priceRow(marketConfig.strings.airServiceFee, marketConfig.market.formatPrice(serviceFee))
                Divider()
                HStack {
                    Text(marketConfig.strings.telcoTotalLabel)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.csqTextPrimary)
                    Spacer()
                    Text(marketConfig.market.formatPrice(baseFare + fareUpgrade + taxes + serviceFee))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(airBlue)
                }
            }
        }
        .padding(16)
        .background(Color.csqSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.07), radius: 8, x: 0, y: 3)
    }

    private func priceRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.csqTextSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.csqTextPrimary)
        }
    }
}
