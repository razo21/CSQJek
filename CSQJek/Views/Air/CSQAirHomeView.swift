import SwiftUI
import ContentsquareSDK

// MARK: - Accessibility IDs
private enum AirHomeAccessID {
    static let closeButton     = "air_home_btn_close"
    static let tripTypeToggle  = "air_home_toggle_trip_type"
    static let originField     = "air_home_field_origin"
    static let destinationField = "air_home_field_destination"
    static let swapButton      = "air_home_btn_swap"
    static let departurePicker = "air_home_picker_departure"
    static let returnPicker    = "air_home_picker_return"
    static let passengerStepper = "air_home_stepper_passengers"
    static let cabinPicker     = "air_home_picker_cabin"
    static let searchButton    = "air_home_btn_search"
}

// MARK: - CSQAirHomeView

struct CSQAirHomeView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var marketConfig: MarketConfig

    @State private var tripType       : TripType   = .roundTrip
    @State private var origin         : Airport    = .SIN  // overridden in onAppear
    @State private var destination    : Airport?   = nil
    @State private var departureDate  : Date       = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var returnDate     : Date       = Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date()
    @State private var passengers     : Int        = 1
    @State private var cabin          : CabinClass = .economy

    @State private var showOriginPicker      = false
    @State private var showDestPicker        = false
    @State private var showResults           = false
    @State private var searchObject         : FlightSearch? = nil

    private let airBlue   = Color(hex: "#1B3FAB")
    private let airSky    = Color(hex: "#4C8EF5")
    private let airAccent = Color(hex: "#E8F0FE")

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [airBlue, airSky, Color(hex: "#85B8FF")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        headerBar
                            .padding(.top, 8)

                        heroText
                            .padding(.top, 24)
                            .padding(.bottom, 28)

                        searchCard
                            .padding(.horizontal, 16)
                            .padding(.bottom, 24)

                        popularDestinations
                            .padding(.bottom, 32)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showOriginPicker) {
                AirportPickerSheet(
                    selected: Binding(
                        get: { Optional(origin) },
                        set: { if let a = $0 { origin = a } }
                    ),
                    excluding: destination,
                    title: marketConfig.strings.airFromLabel
                )
                .environmentObject(marketConfig)
            }
            .sheet(isPresented: $showDestPicker) {
                AirportPickerSheet(
                    selected: Binding(
                        get: { destination },
                        set: { destination = $0 }
                    ),
                    excluding: origin,
                    title: marketConfig.strings.airToLabel
                )
                .environmentObject(marketConfig)
            }
            .background(
                NavigationLink(
                    destination: searchObject.map { FlightResultsView(search: $0, isAirPresented: $isPresented) },
                    isActive: $showResults
                ) { EmptyView() }
            )
        }
        .onAppear {
            switch marketConfig.market {
            case .tokyo:  origin = .NRT
            case .sydney: origin = .SYD
            default:      origin = .SIN   // Singapore + any future market
            }
            CSQ.trackScreenview("Air - Home")
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            Button { isPresented = false } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
            }
            .accessibilityIdentifier(AirHomeAccessID.closeButton)

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: "airplane")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Text("CSQAir")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            Spacer()

            // Balance placeholder
            VStack(alignment: .trailing, spacing: 1) {
                Text("CSQMiles")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.7))
                Text("12,840")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Hero

    private var heroText: some View {
        VStack(spacing: 8) {
            Text(marketConfig.strings.airHeroTitle)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(marketConfig.strings.airHeroSubtitle)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
        }
    }

    // MARK: - Search Card

    private var searchCard: some View {
        VStack(spacing: 0) {
            // Trip type toggle
            HStack(spacing: 0) {
                ForEach(TripType.allCases, id: \.self) { type in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { tripType = type }
                    } label: {
                        Text(type == .oneWay ? marketConfig.strings.airOneWayLabel : marketConfig.strings.airRoundTripLabel)
                            .font(.system(size: 13, weight: tripType == type ? .semibold : .regular))
                            .foregroundColor(tripType == type ? airBlue : Color.csqTextSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(tripType == type ? Color.white : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .padding(4)
            .background(Color(hex: "#EEF2FF"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding([.horizontal, .top], 16)
            .accessibilityIdentifier(AirHomeAccessID.tripTypeToggle)

            // Origin / Destination
            VStack(spacing: 0) {
                // Origin
                Button { showOriginPicker = true } label: {
                    routeRow(
                        label: marketConfig.strings.airFromLabel,
                        value: "\(origin.cityName(for: marketConfig.market)) (\(origin.code))",
                        icon: "airplane.departure",
                        color: airBlue
                    )
                }
                .accessibilityIdentifier(AirHomeAccessID.originField)

                Divider().padding(.leading, 56)

                // Swap button centered over divider
                HStack {
                    Spacer()
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            let prev = destination
                            destination = origin
                            let fallbackOrigin: Airport
                            switch marketConfig.market {
                            case .tokyo:  fallbackOrigin = .NRT
                            case .sydney: fallbackOrigin = .SYD
                            default:      fallbackOrigin = .SIN   // Singapore + any future market
                            }
                            origin = prev ?? fallbackOrigin
                        }
                        CSQ.trackEvent("air_swap_tapped")
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(airBlue)
                            .frame(width: 32, height: 32)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: airBlue.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                    .accessibilityIdentifier(AirHomeAccessID.swapButton)
                    .padding(.trailing, 16)
                }
                .padding(.vertical, -16)
                .zIndex(1)

                // Destination
                Button { showDestPicker = true } label: {
                    routeRow(
                        label: marketConfig.strings.airToLabel,
                        value: destination.map { "\($0.cityName(for: marketConfig.market)) (\($0.code))" } ?? marketConfig.strings.airSelectDest,
                        icon: "airplane.arrival",
                        color: destination != nil ? airBlue : Color.csqTextTertiary
                    )
                }
                .accessibilityIdentifier(AirHomeAccessID.destinationField)
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
            .padding(.horizontal, 16)
            .padding(.top, 12)

            // Dates
            HStack(spacing: 10) {
                dateField(
                    label: marketConfig.strings.airDepartLabel,
                    date: $departureDate,
                    icon: "calendar",
                    accessID: AirHomeAccessID.departurePicker
                )

                if tripType == .roundTrip {
                    dateField(
                        label: marketConfig.strings.airReturnLabel,
                        date: $returnDate,
                        icon: "calendar.badge.checkmark",
                        accessID: AirHomeAccessID.returnPicker
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)

            // Passengers + Cabin
            HStack(spacing: 10) {
                // Passengers
                HStack(spacing: 0) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 13))
                        .foregroundColor(airBlue)
                        .frame(width: 40)
                    Text(marketConfig.strings.airPassengerLabel(passengers))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.csqTextPrimary)
                    Spacer()
                    HStack(spacing: 12) {
                        Button {
                            if passengers > 1 { passengers -= 1 }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(passengers > 1 ? airBlue : Color.csqBorder)
                        }
                        Text("\(passengers)")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(airBlue)
                            .frame(minWidth: 20)
                        Button {
                            if passengers < 9 { passengers += 1 }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(airBlue)
                        }
                    }
                    .padding(.trailing, 12)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
                .accessibilityIdentifier(AirHomeAccessID.passengerStepper)

                // Cabin class
                Menu {
                    ForEach(CabinClass.allCases) { c in
                        Button(c.displayName(for: marketConfig.market)) { cabin = c }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "seat.fill")
                            .font(.system(size: 13))
                            .foregroundColor(airBlue)
                        Text(cabin.displayName(for: marketConfig.market))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.csqTextPrimary)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Color.csqTextTertiary)
                    }
                    .frame(height: 50)
                    .padding(.horizontal, 14)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
                }
                .accessibilityIdentifier(AirHomeAccessID.cabinPicker)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)

            // Search CTA
            Button {
                guard let dest = destination else { return }
                CSQ.trackEvent("air_search_tapped", properties: [
                    "origin": origin.code,
                    "destination": dest.code,
                    "cabin": cabin.rawValue,
                    "passengers": passengers
                ])
                searchObject = FlightSearch(
                    origin: origin,
                    destination: dest,
                    date: departureDate,
                    returnDate: tripType == .roundTrip ? returnDate : nil,
                    passengers: passengers,
                    cabin: cabin
                )
                showResults = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15, weight: .semibold))
                    Text(marketConfig.strings.airSearchFlights)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    destination != nil
                        ? LinearGradient(colors: [airBlue, Color(hex: "#0D2B8A")], startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(colors: [Color.csqBorder, Color.csqBorder], startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.full))
                .shadow(color: airBlue.opacity(destination != nil ? 0.35 : 0), radius: 8, x: 0, y: 4)
            }
            .disabled(destination == nil)
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 18)
            .accessibilityIdentifier(AirHomeAccessID.searchButton)
        }
        .background(Color(hex: "#F0F4FF"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 8)
    }

    // MARK: - Popular Destinations

    private var popularDestinations: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(marketConfig.strings.airPopularFromTitle)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(popularRoutes, id: \.airport.code) { route in
                        Button {
                            destination = route.airport
                            CSQ.trackEvent("air_popular_dest_tapped", properties: ["destination": route.airport.code])
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                AirCountryBadge(countryCode: route.airport.countryCode, size: 40)
                                Text(route.airport.cityName(for: marketConfig.market))
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.csqTextPrimary)
                                Text(marketConfig.market == .tokyo ? "\(route.fromPrice)〜" : "from \(route.fromPrice)")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(airBlue)
                            }
                            .padding(14)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(destination?.code == route.airport.code ? airBlue : Color.clear, lineWidth: 2)
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private static let singaporePopularRoutes: [(airport: Airport, fromPrice: String)] = [
        (.BKK, "S$99"),  (.KUL, "S$89"),  (.HKG, "S$219"),
        (.NRT, "S$399"), (.SYD, "S$459"), (.DXB, "S$549"), (.LHR, "S$869"),
    ]

    private static let popularRoutesByMarket: [Market: [(airport: Airport, fromPrice: String)]] = [
        .singapore: singaporePopularRoutes,
        .tokyo: [
            (.BKK, "¥12,000"), (.ICN, "¥8,500"),  (.HKG, "¥28,000"),
            (.SIN, "¥42,000"), (.SYD, "¥55,000"), (.DXB, "¥68,000"), (.LHR, "¥102,000"),
        ],
        .sydney: [
            (.MEL, "A$89"),  (.OOL, "A$75"),  (.BNE, "A$79"),
            (.AKL, "A$199"), (.DPS, "A$289"), (.SIN, "A$399"), (.LHR, "A$1,549"),
        ],
    ]

    private var popularRoutes: [(airport: Airport, fromPrice: String)] {
        // Unhandled future markets fall back to the Singapore routes.
        Self.popularRoutesByMarket[marketConfig.market] ?? Self.singaporePopularRoutes
    }

    // MARK: - Helpers

    private func routeRow(label: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(.csqTextTertiary)
                Text(value)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(color == airBlue ? .csqTextPrimary : .csqTextTertiary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 11))
                .foregroundColor(.csqTextTertiary)
                .padding(.trailing, 16)
        }
        .padding(.vertical, 14)
        .padding(.leading, 14)
    }

    private func dateField(label: String, date: Binding<Date>, icon: String, accessID: String) -> some View {
        HStack(spacing: 0) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(airBlue)
                .frame(width: 40)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 10))
                    .foregroundColor(.csqTextTertiary)
                DatePicker("", selection: date, displayedComponents: .date)
                    .labelsHidden()
                    .font(.system(size: 13))
                    .tint(airBlue)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
        .accessibilityIdentifier(accessID)
    }
}

// MARK: - Country Badge
// Renders a solid circle with the 2-letter ISO country code.
// Emoji flags don't render in iOS Simulator — this is the reliable alternative.

struct AirCountryBadge: View {
    let countryCode : String   // ISO 3166-1 alpha-2, e.g. "SG", "JP"
    var size        : CGFloat = 36

    private let airBlue = Color(hex: "#1B3FAB")

    var body: some View {
        ZStack {
            Circle()
                .fill(airBlue)
                .frame(width: size, height: size)
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                .frame(width: size, height: size)
            Text(countryCode)
                .font(.system(size: size * 0.32, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .tracking(0.5)
        }
    }
}

// MARK: - Airport Picker Sheet

struct AirportPickerSheet: View {
    @Binding var selected: Airport?
    let excluding : Airport?
    let title     : String
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var marketConfig: MarketConfig
    @State private var query = ""

    private var filtered: [Airport] {
        let all = Airport.popularAirports(for: marketConfig.market)
        let q = query.lowercased()
        let m = marketConfig.market
        let base = q.isEmpty ? all : all.filter {
            $0.city.lowercased().contains(q) ||
            $0.code.lowercased().contains(q) ||
            $0.name.lowercased().contains(q) ||
            $0.country.lowercased().contains(q) ||
            $0.cityName(for: m).lowercased().contains(q) ||
            $0.displayName(for: m).lowercased().contains(q) ||
            $0.countryName(for: m).lowercased().contains(q)
        }
        return base.filter { $0.code != excluding?.code }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.csqTextTertiary)
                    TextField(marketConfig.market == .tokyo ? "都市名または空港コードで検索" : "Search city or airport code", text: $query)
                        .font(.system(size: 15))
                        .csqMaskContents(true)
                }
                .padding(12)
                .background(Color.csqBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                List(filtered) { airport in
                    Button {
                        selected = airport
                        dismiss()
                    } label: {
                        HStack(spacing: 14) {
                            AirCountryBadge(countryCode: airport.countryCode, size: 36)
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 8) {
                                    Text(airport.cityName(for: marketConfig.market))
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.csqTextPrimary)
                                    Text(airport.code)
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color(hex: "#1B3FAB"))
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                }
                                Text(airport.displayName(for: marketConfig.market))
                                    .font(.system(size: 12))
                                    .foregroundColor(.csqTextSecondary)
                            }
                            Spacer()
                            if selected?.code == airport.code {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color(hex: "#1B3FAB"))
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .listRowBackground(Color.csqSurface)
                }
                .listStyle(.plain)
            }
            .background(Color.csqBackground.ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(marketConfig.market == .tokyo ? "完了" : "Done") { dismiss() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(hex: "#1B3FAB"))
                }
            }
        }
    }
}
