import SwiftUI
import ContentsquareSDK

private enum ResultsAccessID {
    static let backButton      = "air_results_btn_back"
    static let sortBar         = "air_results_sort_bar"
    static func sortTab(_ s: String) -> String { "air_results_sort_\(s.lowercased())" }
    static let filterScroll    = "air_results_filter_scroll"
    static func flightCard(_ i: Int) -> String { "air_results_card_\(i)" }
    static func selectButton(_ i: Int) -> String { "air_results_btn_select_\(i)" }
}

// MARK: - Sort + Filter

private enum SortMode: String, CaseIterable {
    case cheapest = "cheapest"
    case fastest  = "fastest"
    case best     = "best"
}

private enum FilterChip: String, CaseIterable {
    case nonStop    = "nonstop"
    case under10h   = "under10h"
    case refundable = "refundable"
    case morning    = "morning"
    case evening    = "evening"
}

// MARK: - FlightResultsView

struct FlightResultsView: View {
    let search          : FlightSearch
    @Binding var isAirPresented: Bool

    @EnvironmentObject var marketConfig: MarketConfig

    @State private var sortMode     : SortMode         = .best
    @State private var activeFilters: Set<FilterChip>  = []
    @State private var selectedFlight: Flight?         = nil
    @State private var showDetail   : Bool             = false
    @Environment(\.dismiss) var dismiss

    private let airBlue = Color(hex: "#1B3FAB")
    private let airSky  = Color(hex: "#4C8EF5")

    private func sortLabel(_ mode: SortMode) -> String {
        switch mode {
        case .cheapest: return marketConfig.strings.airSortCheapest
        case .fastest:  return marketConfig.strings.airSortFastest
        case .best:     return marketConfig.strings.airSortBest
        }
    }

    private func filterLabel(_ chip: FilterChip) -> String {
        switch chip {
        case .nonStop:    return marketConfig.strings.airFilterNonStop
        case .under10h:   return marketConfig.strings.airFilterUnder10h
        case .refundable: return marketConfig.strings.airFilterRefundable
        case .morning:    return marketConfig.strings.airFilterMorning
        case .evening:    return marketConfig.strings.airFilterEvening
        }
    }

    private var allFlights: [Flight] {
        Flight.mockResults(for: search, market: marketConfig.market)
    }

    private var filteredFlights: [Flight] {
        var list = allFlights
        for chip in activeFilters {
            switch chip {
            case .nonStop:    list = list.filter { $0.stops == 0 }
            case .under10h:   list = list.filter { durationMinutes($0.totalDuration) < 600 }
            case .refundable: list = list.filter { $0.refundable }
            case .morning:    list = list.filter {
                let h = Int($0.departureTime.prefix(2)) ?? 0
                return h >= 6 && h < 12
            }
            case .evening:    list = list.filter {
                let h = Int($0.departureTime.prefix(2)) ?? 0
                return h >= 18
            }
            }
        }
        switch sortMode {
        case .cheapest: list.sort { $0.price < $1.price }
        case .fastest:  list.sort { durationMinutes($0.totalDuration) < durationMinutes($1.totalDuration) }
        case .best:     list.sort { bestScore($0) > bestScore($1) }
        }
        return list
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.csqBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar
                sortBar
                filterRow
                resultsList
            }
        }
        .navigationBarHidden(true)
        .background(
            NavigationLink(
                destination: selectedFlight.map {
                    FlightDetailView(flight: $0, search: search, isAirPresented: $isAirPresented)
                },
                isActive: $showDetail
            ) { EmptyView() }
        )
        .onAppear {
            CSQ.trackScreenview("Air - Results")
            CSQ.trackEvent("air_results_shown", properties: [
                "origin": search.origin.code,
                "destination": search.destination.code,
                "results_count": filteredFlights.count
            ])
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        ZStack {
            LinearGradient(colors: [airBlue, airSky], startPoint: .leading, endPoint: .trailing)
                .ignoresSafeArea(edges: .top)

            VStack(spacing: 4) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                    .accessibilityIdentifier(ResultsAccessID.backButton)

                    Spacer()

                    VStack(spacing: 2) {
                        HStack(spacing: 6) {
                            Text(search.origin.code)
                                .font(.system(size: 18, weight: .bold))
                            Image(systemName: search.returnDate != nil ? "arrow.left.arrow.right" : "arrow.right")
                                .font(.system(size: 12))
                            Text(search.destination.code)
                                .font(.system(size: 18, weight: .bold))
                        }
                        .foregroundColor(.white)

                        Text("\(formattedDate(search.date)) · \(search.passengers) \(marketConfig.strings.airPax) · \(search.cabin.displayName(for: marketConfig.market))")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.8))
                    }

                    Spacer()
                    Color.clear.frame(width: 36, height: 36)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 12)
            }
        }
        .frame(height: 88)
    }

    // MARK: - Sort Bar

    private var sortBar: some View {
        HStack(spacing: 0) {
            ForEach(SortMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { sortMode = mode }
                    CSQ.trackEvent("air_sort_tapped", properties: ["mode": mode.rawValue])
                } label: {
                    VStack(spacing: 3) {
                        Text(sortLabel(mode))
                            .font(.system(size: 13, weight: sortMode == mode ? .semibold : .regular))
                            .foregroundColor(sortMode == mode ? airBlue : .csqTextSecondary)
                        if sortMode == mode {
                            // Price hint below active sort
                            if mode == .cheapest, let cheapest = allFlights.min(by: { $0.price < $1.price }) {
                                Text(marketConfig.market.formatPrice(cheapest.price))
                                    .font(.system(size: 10))
                                    .foregroundColor(airBlue)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        sortMode == mode
                            ? Color(hex: "#E8F0FE")
                            : Color.csqSurface
                    )
                }
                .accessibilityIdentifier(ResultsAccessID.sortTab(mode.rawValue))
                if mode != SortMode.allCases.last { Divider().frame(height: 28) }
            }
        }
        .background(Color.csqSurface)
        .overlay(Divider(), alignment: .bottom)
        .accessibilityIdentifier(ResultsAccessID.sortBar)
    }

    // MARK: - Filter Chips

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(FilterChip.allCases, id: \.self) { chip in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            if activeFilters.contains(chip) {
                                activeFilters.remove(chip)
                            } else {
                                activeFilters.insert(chip)
                            }
                        }
                        CSQ.trackEvent("air_filter_toggled", properties: ["filter": chip.rawValue])
                    } label: {
                        HStack(spacing: 4) {
                            if activeFilters.contains(chip) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            Text(filterLabel(chip))
                                .font(.system(size: 12, weight: activeFilters.contains(chip) ? .semibold : .regular))
                        }
                        .foregroundColor(activeFilters.contains(chip) ? .white : airBlue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(activeFilters.contains(chip) ? airBlue : Color(hex: "#E8F0FE"))
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Color.csqSurface)
        .overlay(Divider(), alignment: .bottom)
        .accessibilityIdentifier(ResultsAccessID.filterScroll)
    }

    // MARK: - Results List

    private var resultsList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 12) {
                // Results count
                HStack {
                    Text(marketConfig.strings.airFlightsFound(filteredFlights.count))
                        .font(.system(size: 13))
                        .foregroundColor(.csqTextSecondary)
                    Spacer()
                    Text(marketConfig.strings.airPricesPerPerson)
                        .font(.system(size: 11))
                        .foregroundColor(.csqTextTertiary)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                if filteredFlights.isEmpty {
                    emptyState
                } else {
                    ForEach(Array(filteredFlights.enumerated()), id: \.element.id) { index, flight in
                        FlightResultCard(
                            flight: flight,
                            passengers: search.passengers,
                            index: index
                        ) {
                            selectedFlight = flight
                            CSQ.trackEvent("air_flight_selected", properties: [
                                "airline": flight.airline.name,
                                "price": String(format: "%.0f", flight.price),
                                "stops": flight.stops,
                                "flight_number": flight.segments[0].flightNumber
                            ])
                            showDetail = true
                        }
                        .padding(.horizontal, 16)
                    }
                }

                Spacer(minLength: 24)
            }
        }
        .background(Color.csqBackground)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "airplane.departure")
                .font(.system(size: 48))
                .foregroundColor(Color.csqBorder)
                .padding(.top, 60)
            Text(marketConfig.strings.airNoFlightsMatch)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.csqTextPrimary)
            Text(marketConfig.strings.airRemoveFiltersHint)
                .font(.system(size: 13))
                .foregroundColor(.csqTextSecondary)
                .multilineTextAlignment(.center)
            Button {
                withAnimation { activeFilters.removeAll() }
            } label: {
                Text(marketConfig.strings.airClearFilters)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(airBlue)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Utilities

    private func durationMinutes(_ s: String) -> Int {
        // "7h 40m" → 460
        var total = 0
        if let hRange = s.range(of: "h") {
            total += (Int(s[s.startIndex..<hRange.lowerBound]) ?? 0) * 60
        }
        if let mRange = s.range(of: "m") {
            let from = s.range(of: "h ")?.upperBound ?? s.startIndex
            total += Int(s[from..<mRange.lowerBound]) ?? 0
        }
        return total
    }

    private func bestScore(_ f: Flight) -> Double {
        let maxPrice = allFlights.map(\.price).max() ?? 1
        let maxDur   = allFlights.map { durationMinutes($0.totalDuration) }.max() ?? 1
        let priceScore = 1 - (f.price / maxPrice)
        let durScore   = 1 - (Double(durationMinutes(f.totalDuration)) / Double(maxDur))
        let stopPenalty = Double(f.stops) * 0.15
        return (priceScore * 0.5 + durScore * 0.5) - stopPenalty
    }

    private func formattedDate(_ d: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "d MMM"
        return fmt.string(from: d)
    }
}

// MARK: - Flight Result Card

struct FlightResultCard: View {
    let flight     : Flight
    let passengers : Int
    let index      : Int
    let onSelect   : () -> Void

    @EnvironmentObject var marketConfig: MarketConfig
    private let airBlue = Color(hex: "#1B3FAB")

    var body: some View {
        VStack(spacing: 0) {
            // Tag row
            if !flight.tags.isEmpty {
                HStack(spacing: 6) {
                    ForEach(flight.tags, id: \.self) { tag in
                        Text(airTagDisplay(tag, for: marketConfig.market))
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(tagColor(tag))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(tagColor(tag).opacity(0.12))
                            .clipShape(Capsule())
                    }
                    Spacer()
                    if let seats = flight.seatsLeft {
                        Text(marketConfig.market == .tokyo ? "残り\(seats)席" : "\(seats) seats left")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(seats <= 3 ? Color.csqWarning : .csqTextTertiary)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 10)
                .padding(.bottom, 8)

                Divider()
            }

            // Main flight row
            HStack(alignment: .center, spacing: 0) {
                // Airline badge
                VStack(spacing: 4) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(flight.airline.color.opacity(0.12))
                            .frame(width: 42, height: 42)
                        Text(flight.airline.code)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(flight.airline.color)
                    }
                    Text(flight.airline.name.components(separatedBy: " ").first ?? "")
                        .font(.system(size: 9))
                        .foregroundColor(.csqTextTertiary)
                        .lineLimit(1)
                }
                .frame(width: 58)

                // Departure
                VStack(alignment: .leading, spacing: 2) {
                    Text(flight.departureTime)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.csqTextPrimary)
                    Text(flight.origin.code)
                        .font(.system(size: 12))
                        .foregroundColor(.csqTextSecondary)
                }
                .frame(minWidth: 58, alignment: .leading)

                Spacer()

                // Duration + stops centre
                VStack(spacing: 4) {
                    Text(airDurationDisplay(flight.totalDuration, for: marketConfig.market))
                        .font(.system(size: 11))
                        .foregroundColor(.csqTextTertiary)
                    ZStack {
                        // Line
                        Rectangle()
                            .fill(Color.csqBorder)
                            .frame(height: 1)
                        // Stop dots
                        if flight.stops > 0 {
                            HStack {
                                ForEach(0..<flight.stops, id: \.self) { _ in
                                    Circle()
                                        .fill(Color.csqTextTertiary)
                                        .frame(width: 5, height: 5)
                                }
                            }
                        }
                        Image(systemName: "airplane")
                            .font(.system(size: 10))
                            .foregroundColor(.csqTextTertiary)
                            .offset(x: 8)
                    }
                    .frame(width: 80)
                    Text(flight.stopsLabelDisplay(for: marketConfig.market))
                        .font(.system(size: 10, weight: flight.stops == 0 ? .semibold : .regular))
                        .foregroundColor(flight.stops == 0 ? Color.csqSuccess : .csqTextTertiary)
                }

                Spacer()

                // Arrival
                VStack(alignment: .trailing, spacing: 2) {
                    Text(flight.arrivalTime)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.csqTextPrimary)
                    Text(flight.destination.code)
                        .font(.system(size: 12))
                        .foregroundColor(.csqTextSecondary)
                }
                .frame(minWidth: 58, alignment: .trailing)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, flight.tags.isEmpty ? 14 : 10)

            Divider()

            // Price + select row
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text(marketConfig.strings.cashCurrencyPrefix)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(airBlue)
                        Text("\(Int(flight.price))")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(airBlue)
                    }
                    Text(passengers > 1
                         ? marketConfig.strings.airPerPersonTotal(marketConfig.strings.cashCurrencyPrefix, Int(flight.price * Double(passengers)))
                         : marketConfig.strings.airPerPerson)
                        .font(.system(size: 10))
                        .foregroundColor(.csqTextTertiary)
                }

                Spacer()

                HStack(spacing: 12) {
                    // Baggage pill
                    HStack(spacing: 4) {
                        Image(systemName: "suitcase.fill")
                            .font(.system(size: 10))
                        Text(flight.baggageDisplay(for: marketConfig.market).components(separatedBy: " + ").first ?? "")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.csqTextSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.csqBackground)
                    .clipShape(Capsule())

                    Button(action: onSelect) {
                        Text(marketConfig.strings.airSelectButton)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 22)
                            .padding(.vertical, 10)
                            .background(airBlue)
                            .clipShape(Capsule())
                    }
                    .accessibilityIdentifier(ResultsAccessID.selectButton(index))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .background(Color.csqSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.07), radius: 8, x: 0, y: 3)
        .accessibilityIdentifier(ResultsAccessID.flightCard(index))
    }

    private func tagColor(_ tag: String) -> Color {
        switch tag {
        case "Cheapest":   return Color.csqSuccess
        case "Fastest":    return Color(hex: "#1B3FAB")
        case "Best Value": return Color(hex: "#7C3AED")
        case "Non-stop":   return Color(hex: "#0891B2")
        default:           return Color.csqTextSecondary
        }
    }
}
