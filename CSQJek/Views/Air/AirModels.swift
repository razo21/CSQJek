import SwiftUI

// MARK: - Core Types

enum CabinClass: String, CaseIterable, Identifiable {
    case economy  = "Economy"
    case business = "Business"
    case first    = "First"
    var id: String { rawValue }

    // Localized display name. `rawValue` stays English (analytics value / stable key).
    func displayName(for market: Market) -> String {
        guard market == .tokyo else { return rawValue }
        switch self {
        case .economy:  return "エコノミー"
        case .business: return "ビジネス"
        case .first:    return "ファースト"
        }
    }
}

enum TripType: String, CaseIterable {
    case oneWay    = "One Way"
    case roundTrip = "Round Trip"

    // Localized display name. `rawValue` stays English (stable key).
    func displayName(for market: Market) -> String {
        guard market == .tokyo else { return rawValue }
        switch self {
        case .oneWay:    return "片道"
        case .roundTrip: return "往復"
        }
    }
}

// Localized display text for a flight tag.
// The underlying tag string stays English — it drives `tagColor(_:)` logic in
// FlightResultsView and must remain a stable value. This maps only the visible text.
func airTagDisplay(_ tag: String, for market: Market) -> String {
    guard market == .tokyo else { return tag }
    switch tag {
    case "Best Value": return "お得"
    case "Fastest":    return "最速"
    case "Cheapest":   return "最安値"
    case "Non-stop":   return "直行便"
    case "Nonstop":    return "直行便"
    case "Direct":     return "直行便"
    default:           return tag
    }
}

// Localizes a flight duration string like "5h 20m" / "13h 30m" / "2h" / "45m"
// to "5時間20分" / "13時間30分" / "2時間" / "45分" for the Tokyo market.
// Leaves the Singapore market (and any unexpected format) untouched.
func airDurationDisplay(_ s: String, for market: Market) -> String {
    guard market == .tokyo else { return s }
    var hours: String? = nil
    var minutes: String? = nil
    for part in s.split(separator: " ") {
        if part.hasSuffix("h") { hours = String(part.dropLast()) }
        else if part.hasSuffix("m") { minutes = String(part.dropLast()) }
    }
    guard hours != nil || minutes != nil else { return s }
    return (hours.map { "\($0)時間" } ?? "") + (minutes.map { "\($0)分" } ?? "")
}

struct Airport: Identifiable, Hashable {
    let id          = UUID()
    let code        : String   // IATA
    let city        : String
    let name        : String
    let country     : String
    let countryCode : String   // ISO 3166-1 alpha-2 — used for badge rendering (emoji flags fail in Simulator)
}

extension Airport {
    // Localized city name for display. `code` (IATA) and stored `city` stay unchanged
    // because the Airport structs are shared singletons across both markets.
    func cityName(for market: Market) -> String {
        guard market == .tokyo else { return city }
        switch code {
        case "SIN": return "シンガポール"
        case "LHR": return "ロンドン"
        case "SYD": return "シドニー"
        case "NRT": return "東京"
        case "BKK": return "バンコク"
        case "KUL": return "クアラルンプール"
        case "HKG": return "香港"
        case "DXB": return "ドバイ"
        case "MNL": return "マニラ"
        case "ICN": return "ソウル"
        case "HND": return "東京"
        case "CDG": return "パリ"
        case "LAX": return "ロサンゼルス"
        default:    return city
        }
    }

    // Localized country name for display.
    func countryName(for market: Market) -> String {
        guard market == .tokyo else { return country }
        switch country {
        case "Singapore":   return "シンガポール"
        case "UK":          return "イギリス"
        case "Australia":   return "オーストラリア"
        case "Japan":       return "日本"
        case "Thailand":    return "タイ"
        case "Malaysia":    return "マレーシア"
        case "Hong Kong":   return "香港"
        case "UAE":         return "アラブ首長国連邦"
        case "Philippines": return "フィリピン"
        case "South Korea": return "韓国"
        case "France":      return "フランス"
        case "USA":         return "アメリカ"
        default:            return country
        }
    }

    // Localized airport name for display.
    func displayName(for market: Market) -> String {
        guard market == .tokyo else { return name }
        switch code {
        case "SIN": return "チャンギ国際空港"
        case "LHR": return "ヒースロー空港"
        case "SYD": return "キングスフォード・スミス空港"
        case "NRT": return "成田国際空港"
        case "BKK": return "スワンナプーム国際空港"
        case "KUL": return "クアラルンプール国際空港"
        case "HKG": return "香港国際空港"
        case "DXB": return "ドバイ国際空港"
        case "MNL": return "ニノイ・アキノ国際空港"
        case "ICN": return "仁川国際空港"
        case "HND": return "羽田空港"
        case "CDG": return "シャルル・ド・ゴール空港"
        case "LAX": return "ロサンゼルス国際空港"
        default:    return name
        }
    }
}

struct Airline {
    let code  : String
    let name  : String
    let color : Color
}

struct FlightSegment: Identifiable {
    let id            = UUID()
    let airline       : Airline
    let flightNumber  : String
    let origin        : Airport
    let destination   : Airport
    let departureTime : String   // "08:30"
    let arrivalTime   : String   // "14:55"
    let duration      : String   // "6h 25m"
    let aircraft      : String   // "Boeing 777-300ER"
    let cabin         : CabinClass
}

struct Flight: Identifiable {
    let id            = UUID()
    let segments      : [FlightSegment]
    let stops         : Int          // 0 = direct
    let totalDuration : String       // "6h 25m"
    let price         : Double       // SGD per pax
    let tags          : [String]     // ["Best Value", "Fastest"]
    let seatsLeft     : Int?         // nil = many available
    let baggage       : String       // "23kg checked + 7kg cabin"
    let refundable    : Bool

    var airline       : Airline      { segments[0].airline }
    var origin        : Airport      { segments[0].origin }
    var destination   : Airport      { segments.last!.destination }
    var departureTime : String       { segments[0].departureTime }
    var arrivalTime   : String       { segments.last!.arrivalTime }

    var stopsLabel: String {
        stops == 0 ? "Non-stop" : stops == 1 ? "1 stop" : "\(stops) stops"
    }

    // Localized stops label. Stored English `stopsLabel` is kept for non-Tokyo.
    func stopsLabelDisplay(for market: Market) -> String {
        guard market == .tokyo else { return stopsLabel }
        return stops == 0 ? "直行便" : "\(stops)回乗継"
    }

    // Localized baggage string for display. The stored `baggage` value stays English.
    // Patterns: "23kg checked + 7kg cabin" / "7kg cabin only".
    func baggageDisplay(for market: Market) -> String {
        guard market == .tokyo else { return baggage }
        return Self.localizeBaggage(baggage)
    }

    // Shared baggage localizer — handles each " + "-separated component and rewrites
    // "<weight> checked" → "受託手荷物<weight>", "<weight> cabin" → "機内持ち込み<weight>".
    static func localizeBaggage(_ english: String) -> String {
        english
            .components(separatedBy: " + ")
            .map { part -> String in
                let p = part.replacingOccurrences(of: " only", with: "")
                if let r = p.range(of: " checked") {
                    return "受託手荷物" + p[p.startIndex..<r.lowerBound]
                } else if let r = p.range(of: " cabin") {
                    return "機内持ち込み" + p[p.startIndex..<r.lowerBound]
                }
                return part
            }
            .joined(separator: " + ")
    }
}

// MARK: - Static Airport Registry

extension Airport {
    static let SIN = Airport(code: "SIN", city: "Singapore",    name: "Changi Airport",                country: "Singapore",   countryCode: "SG")
    static let LHR = Airport(code: "LHR", city: "London",       name: "Heathrow Airport",              country: "UK",          countryCode: "GB")
    static let SYD = Airport(code: "SYD", city: "Sydney",       name: "Kingsford Smith Airport",       country: "Australia",   countryCode: "AU")
    static let NRT = Airport(code: "NRT", city: "Tokyo",        name: "Narita International Airport",  country: "Japan",       countryCode: "JP")
    static let BKK = Airport(code: "BKK", city: "Bangkok",      name: "Suvarnabhumi Airport",          country: "Thailand",    countryCode: "TH")
    static let KUL = Airport(code: "KUL", city: "Kuala Lumpur", name: "KLIA",                          country: "Malaysia",    countryCode: "MY")
    static let HKG = Airport(code: "HKG", city: "Hong Kong",    name: "Hong Kong Int'l Airport",       country: "Hong Kong",   countryCode: "HK")
    static let DXB = Airport(code: "DXB", city: "Dubai",        name: "Dubai International Airport",   country: "UAE",         countryCode: "AE")
    static let MNL = Airport(code: "MNL", city: "Manila",       name: "Ninoy Aquino Int'l Airport",    country: "Philippines", countryCode: "PH")
    static let ICN = Airport(code: "ICN", city: "Seoul",        name: "Incheon International Airport", country: "South Korea", countryCode: "KR")
    static let HND = Airport(code: "HND", city: "Tokyo",        name: "Haneda Airport",                country: "Japan",       countryCode: "JP")
    static let CDG = Airport(code: "CDG", city: "Paris",        name: "Charles de Gaulle Airport",     country: "France",      countryCode: "FR")
    static let LAX = Airport(code: "LAX", city: "Los Angeles",  name: "Los Angeles Int'l Airport",     country: "USA",         countryCode: "US")
    static let MEL = Airport(code: "MEL", city: "Melbourne",    name: "Melbourne Airport",             country: "Australia",   countryCode: "AU")
    static let BNE = Airport(code: "BNE", city: "Brisbane",     name: "Brisbane Airport",              country: "Australia",   countryCode: "AU")
    static let PER = Airport(code: "PER", city: "Perth",        name: "Perth Airport",                 country: "Australia",   countryCode: "AU")
    static let ADL = Airport(code: "ADL", city: "Adelaide",     name: "Adelaide Airport",              country: "Australia",   countryCode: "AU")
    static let OOL = Airport(code: "OOL", city: "Gold Coast",   name: "Gold Coast Airport",            country: "Australia",   countryCode: "AU")
    static let CNS = Airport(code: "CNS", city: "Cairns",       name: "Cairns Airport",                country: "Australia",   countryCode: "AU")
    static let AKL = Airport(code: "AKL", city: "Auckland",     name: "Auckland Airport",              country: "New Zealand", countryCode: "NZ")
    static let DPS = Airport(code: "DPS", city: "Denpasar",     name: "Ngurah Rai Int'l Airport",      country: "Indonesia",   countryCode: "ID")

    private static let popularAirportsByMarket: [Market: [Airport]] = [
        .singapore: [SIN, BKK, KUL, HKG, NRT, ICN, SYD, DXB, LHR, CDG, MNL, LAX],
        .tokyo:     [NRT, HND, ICN, HKG, BKK, SIN, SYD, DXB, LHR, CDG, MNL, LAX],
        .sydney:    [SYD, MEL, BNE, PER, ADL, OOL, CNS, AKL, DPS, SIN, LAX, LHR],
    ]

    static func popularAirports(for market: Market) -> [Airport] {
        // Unhandled future markets fall back to the Singapore airport set.
        popularAirportsByMarket[market] ?? [SIN, BKK, KUL, HKG, NRT, ICN, SYD, DXB, LHR, CDG, MNL, LAX]
    }
}

// MARK: - Static Airline Registry

extension Airline {
    static let sia  = Airline(code: "SQ", name: "Singapore Airlines", color: Color(hex: "#1A3A6C"))
    static let scoot = Airline(code: "TR", name: "Scoot",             color: Color(hex: "#FFDD00"))
    static let airAsia = Airline(code: "AK", name: "AirAsia",         color: Color(hex: "#D71920"))
    static let cathay  = Airline(code: "CX", name: "Cathay Pacific",  color: Color(hex: "#006564"))
    static let emirates = Airline(code: "EK", name: "Emirates",       color: Color(hex: "#C41230"))
    static let qantas  = Airline(code: "QF", name: "Qantas",          color: Color(hex: "#E40000"))
    static let malaysia = Airline(code: "MH", name: "Malaysia Airlines", color: Color(hex: "#00325A"))
    static let ana    = Airline(code: "NH", name: "ANA",               color: Color(hex: "#13448B"))
    static let thai   = Airline(code: "TG", name: "Thai Airways",      color: Color(hex: "#6B047C"))
    static let korean = Airline(code: "KE", name: "Korean Air",        color: Color(hex: "#00256C"))
    static let jal     = Airline(code: "JL", name: "Japan Airlines",   color: Color(hex: "#CC0000"))
    static let british = Airline(code: "BA", name: "British Airways",  color: Color(hex: "#2B5EAE"))
    static let united  = Airline(code: "UA", name: "United Airlines",  color: Color(hex: "#002244"))
    static let jetstar = Airline(code: "JQ", name: "Jetstar",          color: Color(hex: "#FF5115"))
    static let virginAU = Airline(code: "VA", name: "Virgin Australia", color: Color(hex: "#E2231A"))
    static let rex     = Airline(code: "ZL", name: "Rex",              color: Color(hex: "#A6192E"))
    static let airNZ   = Airline(code: "NZ", name: "Air New Zealand",  color: Color(hex: "#00205B"))
}

// MARK: - Mock Flight Generator

struct FlightSearch {
    let origin      : Airport
    let destination : Airport
    let date        : Date
    let returnDate  : Date?
    let passengers  : Int
    let cabin       : CabinClass
}

extension Flight {
    /// Returns a realistic set of mock results for any SIN-origin search.
    static func mockResults(for search: FlightSearch) -> [Flight] {
        let o = search.origin
        let d = search.destination

        switch d.code {
        case "BKK":
            return [
                Flight(segments: [FlightSegment(airline: .sia,    flightNumber: "SQ 708", origin: o, destination: d, departureTime: "07:15", arrivalTime: "08:35", duration: "2h 20m", aircraft: "Boeing 737 MAX 8", cabin: search.cabin)],
                       stops: 0, totalDuration: "2h 20m", price: 189,  tags: ["Non-stop", "Best Value"], seatsLeft: 4,    baggage: "20kg checked + 7kg cabin", refundable: false),
                Flight(segments: [FlightSegment(airline: .airAsia, flightNumber: "AK 702", origin: o, destination: d, departureTime: "09:45", arrivalTime: "11:05", duration: "2h 20m", aircraft: "Airbus A320neo", cabin: search.cabin)],
                       stops: 0, totalDuration: "2h 20m", price: 129,  tags: ["Cheapest"],               seatsLeft: 11,   baggage: "15kg checked + 7kg cabin", refundable: false),
                Flight(segments: [FlightSegment(airline: .thai,    flightNumber: "TG 412", origin: o, destination: d, departureTime: "14:20", arrivalTime: "15:45", duration: "2h 25m", aircraft: "Airbus A330-300", cabin: search.cabin)],
                       stops: 0, totalDuration: "2h 25m", price: 215,  tags: ["Fastest"],                seatsLeft: nil,  baggage: "23kg checked + 7kg cabin", refundable: true),
                Flight(segments: [FlightSegment(airline: .scoot,   flightNumber: "TR 602", origin: o, destination: d, departureTime: "22:10", arrivalTime: "23:30", duration: "2h 20m", aircraft: "Boeing 787-8", cabin: search.cabin)],
                       stops: 0, totalDuration: "2h 20m", price: 99,   tags: [],                          seatsLeft: 2,    baggage: "15kg checked + 7kg cabin", refundable: false),
            ]
        case "KUL":
            return [
                Flight(segments: [FlightSegment(airline: .sia,     flightNumber: "SQ 112", origin: o, destination: d, departureTime: "06:30", arrivalTime: "08:00", duration: "1h 30m", aircraft: "Boeing 737-800", cabin: search.cabin)],
                       stops: 0, totalDuration: "1h 30m", price: 149,  tags: ["Non-stop", "Fastest"],     seatsLeft: 6,    baggage: "20kg checked + 7kg cabin", refundable: false),
                Flight(segments: [FlightSegment(airline: .airAsia, flightNumber: "AK 720", origin: o, destination: d, departureTime: "10:00", arrivalTime: "11:30", duration: "1h 30m", aircraft: "Airbus A320neo", cabin: search.cabin)],
                       stops: 0, totalDuration: "1h 30m", price: 89,   tags: ["Cheapest"],                seatsLeft: 18,   baggage: "15kg checked + 7kg cabin", refundable: false),
                Flight(segments: [FlightSegment(airline: .malaysia, flightNumber: "MH 611",origin: o, destination: d, departureTime: "15:45", arrivalTime: "17:15", duration: "1h 30m", aircraft: "Airbus A330-300", cabin: search.cabin)],
                       stops: 0, totalDuration: "1h 30m", price: 172,  tags: ["Best Value"],              seatsLeft: nil,  baggage: "23kg checked + 7kg cabin", refundable: true),
            ]
        case "HKG":
            return [
                Flight(segments: [FlightSegment(airline: .cathay,  flightNumber: "CX 716", origin: o, destination: d, departureTime: "08:05", arrivalTime: "12:00", duration: "3h 55m", aircraft: "Airbus A350-900", cabin: search.cabin)],
                       stops: 0, totalDuration: "3h 55m", price: 349,  tags: ["Non-stop", "Best Value"],  seatsLeft: 3,    baggage: "23kg checked + 7kg cabin", refundable: true),
                Flight(segments: [FlightSegment(airline: .sia,     flightNumber: "SQ 890", origin: o, destination: d, departureTime: "11:30", arrivalTime: "15:20", duration: "3h 50m", aircraft: "Boeing 777-300ER", cabin: search.cabin)],
                       stops: 0, totalDuration: "3h 50m", price: 389,  tags: ["Fastest"],                 seatsLeft: nil,  baggage: "23kg checked + 7kg cabin", refundable: true),
                Flight(segments: [FlightSegment(airline: .scoot,   flightNumber: "TR 916", origin: o, destination: d, departureTime: "18:50", arrivalTime: "22:45", duration: "3h 55m", aircraft: "Boeing 787-9", cabin: search.cabin)],
                       stops: 0, totalDuration: "3h 55m", price: 219,  tags: ["Cheapest"],                seatsLeft: 8,    baggage: "15kg checked + 7kg cabin", refundable: false),
            ]
        case "NRT":
            return [
                Flight(segments: [FlightSegment(airline: .sia,     flightNumber: "SQ 634", origin: o, destination: d, departureTime: "09:00", arrivalTime: "16:40", duration: "7h 40m", aircraft: "Airbus A350-900ULR", cabin: search.cabin)],
                       stops: 0, totalDuration: "7h 40m", price: 689,  tags: ["Non-stop", "Fastest"],     seatsLeft: 5,    baggage: "23kg checked + 7kg cabin", refundable: true),
                Flight(segments: [FlightSegment(airline: .ana,     flightNumber: "NH 841", origin: o, destination: d, departureTime: "07:30", arrivalTime: "15:15", duration: "7h 45m", aircraft: "Boeing 787-9", cabin: search.cabin)],
                       stops: 0, totalDuration: "7h 45m", price: 645,  tags: ["Best Value"],              seatsLeft: nil,  baggage: "23kg checked + 7kg cabin", refundable: true),
                Flight(segments: [FlightSegment(airline: .scoot,   flightNumber: "TR 812", origin: o, destination: d, departureTime: "23:55", arrivalTime: "07:50+1", duration: "7h 55m", aircraft: "Boeing 787-8", cabin: search.cabin)],
                       stops: 0, totalDuration: "7h 55m", price: 399,  tags: ["Cheapest"],                seatsLeft: 12,   baggage: "15kg checked + 7kg cabin", refundable: false),
                Flight(segments: [FlightSegment(airline: .cathay,  flightNumber: "CX 714", origin: o, destination: Airport.HKG, departureTime: "08:05", arrivalTime: "12:00", duration: "3h 55m", aircraft: "Airbus A350-900", cabin: search.cabin),
                                  FlightSegment(airline: .cathay,  flightNumber: "CX 506", origin: Airport.HKG, destination: d, departureTime: "14:30", arrivalTime: "19:20", duration: "4h 50m", aircraft: "Boeing 777-300ER", cabin: search.cabin)],
                       stops: 1, totalDuration: "11h 15m", price: 558, tags: [],                          seatsLeft: nil,  baggage: "23kg checked + 7kg cabin", refundable: false),
            ]
        case "SYD":
            return [
                Flight(segments: [FlightSegment(airline: .sia,     flightNumber: "SQ 231", origin: o, destination: d, departureTime: "09:15", arrivalTime: "19:35", duration: "7h 20m", aircraft: "Boeing 777-300ER", cabin: search.cabin)],
                       stops: 0, totalDuration: "7h 20m", price: 749,  tags: ["Non-stop", "Fastest"],     seatsLeft: 2,    baggage: "30kg checked + 7kg cabin", refundable: true),
                Flight(segments: [FlightSegment(airline: .qantas,  flightNumber: "QF 001", origin: o, destination: d, departureTime: "06:50", arrivalTime: "17:00", duration: "7h 10m", aircraft: "Airbus A380-800", cabin: search.cabin)],
                       stops: 0, totalDuration: "7h 10m", price: 829,  tags: ["Best Value"],              seatsLeft: nil,  baggage: "30kg checked + 7kg cabin", refundable: true),
                Flight(segments: [FlightSegment(airline: .scoot,   flightNumber: "TR 218", origin: o, destination: d, departureTime: "21:30", arrivalTime: "07:45+1", duration: "7h 15m", aircraft: "Boeing 787-9", cabin: search.cabin)],
                       stops: 0, totalDuration: "7h 15m", price: 459,  tags: ["Cheapest"],                seatsLeft: 7,    baggage: "15kg checked + 7kg cabin", refundable: false),
            ]
        case "DXB":
            return [
                Flight(segments: [FlightSegment(airline: .emirates, flightNumber: "EK 404", origin: o, destination: d, departureTime: "02:15", arrivalTime: "06:05", duration: "7h 50m", aircraft: "Airbus A380-800", cabin: search.cabin)],
                       stops: 0, totalDuration: "7h 50m", price: 899,  tags: ["Non-stop"],                seatsLeft: 4,    baggage: "30kg checked + 7kg cabin", refundable: true),
                Flight(segments: [FlightSegment(airline: .sia,     flightNumber: "SQ 009", origin: o, destination: d, departureTime: "23:45", arrivalTime: "04:50+1", duration: "7h 05m", aircraft: "Airbus A350-900ULR", cabin: search.cabin)],
                       stops: 0, totalDuration: "7h 05m", price: 959,  tags: ["Fastest", "Best Value"],   seatsLeft: nil,  baggage: "30kg checked + 7kg cabin", refundable: true),
                Flight(segments: [FlightSegment(airline: .airAsia, flightNumber: "AK 302", origin: o, destination: Airport.KUL, departureTime: "08:00", arrivalTime: "09:30", duration: "1h 30m", aircraft: "Airbus A320neo", cabin: search.cabin),
                                  FlightSegment(airline: .airAsia, flightNumber: "AK 101", origin: Airport.KUL, destination: d, departureTime: "12:45", arrivalTime: "15:55", duration: "8h 10m", aircraft: "Airbus A330-300", cabin: search.cabin)],
                       stops: 1, totalDuration: "7h 55m", price: 549,  tags: ["Cheapest"],                seatsLeft: 9,    baggage: "20kg checked + 7kg cabin", refundable: false),
            ]
        case "LHR":
            return [
                Flight(segments: [FlightSegment(airline: .sia,     flightNumber: "SQ 317", origin: o, destination: d, departureTime: "23:55", arrivalTime: "06:05+1", duration: "13h 10m", aircraft: "Airbus A350-900ULR", cabin: search.cabin)],
                       stops: 0, totalDuration: "13h 10m", price: 1_289, tags: ["Non-stop", "Fastest"],   seatsLeft: 3,    baggage: "30kg checked + 7kg cabin", refundable: true),
                Flight(segments: [FlightSegment(airline: .sia,     flightNumber: "SQ 321", origin: o, destination: d, departureTime: "09:00", arrivalTime: "16:30+0", duration: "13h 30m", aircraft: "Boeing 777-300ER", cabin: search.cabin)],
                       stops: 0, totalDuration: "13h 30m", price: 1_189, tags: ["Best Value"],            seatsLeft: nil,  baggage: "30kg checked + 7kg cabin", refundable: true),
                Flight(segments: [FlightSegment(airline: .emirates, flightNumber: "EK 432", origin: o, destination: Airport.DXB, departureTime: "02:15", arrivalTime: "06:05", duration: "7h 50m", aircraft: "Airbus A380-800", cabin: search.cabin),
                                  FlightSegment(airline: .emirates, flightNumber: "EK 003", origin: Airport.DXB, destination: d, departureTime: "09:45", arrivalTime: "14:05", duration: "7h 20m", aircraft: "Airbus A380-800", cabin: search.cabin)],
                       stops: 1, totalDuration: "19h 50m", price: 869,   tags: ["Cheapest"],              seatsLeft: 6,    baggage: "30kg checked + 7kg cabin", refundable: false),
                Flight(segments: [FlightSegment(airline: .cathay,  flightNumber: "CX 714", origin: o, destination: Airport.HKG, departureTime: "08:05", arrivalTime: "12:00", duration: "3h 55m", aircraft: "Airbus A350-900", cabin: search.cabin),
                                  FlightSegment(airline: .cathay,  flightNumber: "CX 251", origin: Airport.HKG, destination: d, departureTime: "14:30", arrivalTime: "20:45", duration: "13h 15m", aircraft: "Boeing 777-300ER", cabin: search.cabin)],
                       stops: 1, totalDuration: "19h 40m", price: 949,   tags: [],                        seatsLeft: nil,  baggage: "23kg checked + 7kg cabin", refundable: false),
            ]
        default:
            // Generic fallback for any other destination
            return [
                Flight(segments: [FlightSegment(airline: .sia,     flightNumber: "SQ 500", origin: o, destination: d, departureTime: "08:00", arrivalTime: "12:30", duration: "4h 30m", aircraft: "Boeing 777-300ER", cabin: search.cabin)],
                       stops: 0, totalDuration: "4h 30m", price: 399,  tags: ["Non-stop", "Best Value"],  seatsLeft: 5,    baggage: "23kg checked + 7kg cabin", refundable: true),
                Flight(segments: [FlightSegment(airline: .scoot,   flightNumber: "TR 600", origin: o, destination: d, departureTime: "14:15", arrivalTime: "18:45", duration: "4h 30m", aircraft: "Boeing 787-8", cabin: search.cabin)],
                       stops: 0, totalDuration: "4h 30m", price: 269,  tags: ["Cheapest"],                seatsLeft: 10,   baggage: "15kg checked + 7kg cabin", refundable: false),
            ]
        }
    }

    static func mockResults(for search: FlightSearch, market: Market) -> [Flight] {
        switch market {
        case .sydney:    return mockResultsSydney(for: search)
        case .tokyo:     break   // Tokyo dataset handled below
        default:         return mockResults(for: search)   // Singapore + any future market
        }

        let o = search.origin   // NRT for Tokyo
        let d = search.destination

        switch d.code {
        case "BKK":
            return [
                Flight(segments: [FlightSegment(airline: .ana,    flightNumber: "NH 847", origin: o, destination: d, departureTime: "09:00", arrivalTime: "14:20", duration: "5h 20m", aircraft: "Boeing 787-9",        cabin: search.cabin)], stops: 0, totalDuration: "5h 20m", price: 38_000, tags: ["Non-stop", "Best Value"], seatsLeft: 5,   baggage: "20kg checked + 7kg cabin", refundable: true),
                Flight(segments: [FlightSegment(airline: .jal,    flightNumber: "JL 033", origin: o, destination: d, departureTime: "11:30", arrivalTime: "16:50", duration: "5h 20m", aircraft: "Airbus A350-900",      cabin: search.cabin)], stops: 0, totalDuration: "5h 20m", price: 41_000, tags: ["Fastest"],            seatsLeft: nil, baggage: "23kg checked + 7kg cabin", refundable: true),
                Flight(segments: [FlightSegment(airline: .thai,   flightNumber: "TG 683", origin: o, destination: d, departureTime: "22:45", arrivalTime: "04:05+1", duration: "5h 20m", aircraft: "Boeing 777-300ER", cabin: search.cabin)], stops: 0, totalDuration: "5h 20m", price: 28_000, tags: ["Cheapest"],           seatsLeft: 9,   baggage: "20kg checked + 7kg cabin", refundable: false),
            ]
        case "ICN":
            return [
                Flight(segments: [FlightSegment(airline: .ana,    flightNumber: "NH 985", origin: o, destination: d, departureTime: "08:15", arrivalTime: "10:45", duration: "2h 30m", aircraft: "Airbus A320neo",   cabin: search.cabin)], stops: 0, totalDuration: "2h 30m", price: 18_000, tags: ["Non-stop", "Fastest"],   seatsLeft: 6,   baggage: "20kg checked + 7kg cabin", refundable: true),
                Flight(segments: [FlightSegment(airline: .jal,    flightNumber: "JL 953", origin: o, destination: d, departureTime: "12:00", arrivalTime: "14:30", duration: "2h 30m", aircraft: "Boeing 737-800",   cabin: search.cabin)], stops: 0, totalDuration: "2h 30m", price: 22_000, tags: ["Best Value"],            seatsLeft: nil, baggage: "23kg checked + 7kg cabin", refundable: true),
                Flight(segments: [FlightSegment(airline: .korean, flightNumber: "KE 704", origin: o, destination: d, departureTime: "17:20", arrivalTime: "19:50", duration: "2h 30m", aircraft: "Airbus A330-300", cabin: search.cabin)], stops: 0, totalDuration: "2h 30m", price: 15_000, tags: ["Cheapest"],             seatsLeft: 14,  baggage: "20kg checked + 7kg cabin", refundable: false),
            ]
        case "HKG":
            return [
                Flight(segments: [FlightSegment(airline: .cathay, flightNumber: "CX 541", origin: o, destination: d, departureTime: "07:45", arrivalTime: "11:35", duration: "3h 50m", aircraft: "Airbus A350-900",   cabin: search.cabin)], stops: 0, totalDuration: "3h 50m", price: 52_000, tags: ["Non-stop", "Best Value"], seatsLeft: 3,   baggage: "23kg checked + 7kg cabin", refundable: true),
                Flight(segments: [FlightSegment(airline: .ana,    flightNumber: "NH 879", origin: o, destination: d, departureTime: "10:30", arrivalTime: "14:20", duration: "3h 50m", aircraft: "Boeing 787-9",      cabin: search.cabin)], stops: 0, totalDuration: "3h 50m", price: 48_000, tags: ["Fastest"],            seatsLeft: nil, baggage: "20kg checked + 7kg cabin", refundable: true),
                Flight(segments: [FlightSegment(airline: .jal,    flightNumber: "JL 069", origin: o, destination: d, departureTime: "22:00", arrivalTime: "01:50+1", duration: "3h 50m", aircraft: "Airbus A350",    cabin: search.cabin)], stops: 0, totalDuration: "3h 50m", price: 38_000, tags: ["Cheapest"],           seatsLeft: 11,  baggage: "20kg checked + 7kg cabin", refundable: false),
            ]
        case "SIN":
            return [
                Flight(segments: [FlightSegment(airline: .ana,    flightNumber: "NH 841", origin: o, destination: d, departureTime: "09:00", arrivalTime: "16:40", duration: "7h 40m", aircraft: "Boeing 787-9",        cabin: search.cabin)], stops: 0, totalDuration: "7h 40m", price: 75_000, tags: ["Non-stop", "Fastest"],   seatsLeft: 5,   baggage: "23kg checked + 7kg cabin", refundable: true),
                Flight(segments: [FlightSegment(airline: .jal,    flightNumber: "JL 711", origin: o, destination: d, departureTime: "11:00", arrivalTime: "18:40", duration: "7h 40m", aircraft: "Airbus A350-900",      cabin: search.cabin)], stops: 0, totalDuration: "7h 40m", price: 68_000, tags: ["Best Value"],            seatsLeft: nil, baggage: "23kg checked + 7kg cabin", refundable: true),
                Flight(segments: [FlightSegment(airline: .sia,    flightNumber: "SQ 634", origin: d,  destination: o, departureTime: "00:00", arrivalTime: "00:00", duration: "7h 40m", aircraft: "Airbus A350-900ULR",   cabin: search.cabin),
                                  FlightSegment(airline: .sia,    flightNumber: "SQ 635", origin: o,  destination: d, departureTime: "23:55", arrivalTime: "07:40+1", duration: "7h 45m", aircraft: "Airbus A350-900ULR", cabin: search.cabin)],
                       stops: 0, totalDuration: "7h 45m", price: 55_000, tags: ["Cheapest"], seatsLeft: 8, baggage: "20kg checked + 7kg cabin", refundable: false),
            ]
        case "SYD":
            return [
                Flight(segments: [FlightSegment(airline: .ana,    flightNumber: "NH 879", origin: o, destination: d, departureTime: "18:00", arrivalTime: "06:15+1", duration: "9h 15m", aircraft: "Boeing 787-9",    cabin: search.cabin)], stops: 0, totalDuration: "9h 15m", price: 92_000, tags: ["Non-stop", "Best Value"], seatsLeft: 4,   baggage: "23kg checked + 7kg cabin", refundable: true),
                Flight(segments: [FlightSegment(airline: .jal,    flightNumber: "JL 771", origin: o, destination: d, departureTime: "10:30", arrivalTime: "22:45", duration: "9h 15m",  aircraft: "Boeing 787-9",    cabin: search.cabin)], stops: 0, totalDuration: "9h 15m", price: 88_000, tags: ["Fastest"],            seatsLeft: nil, baggage: "23kg checked + 7kg cabin", refundable: true),
                Flight(segments: [FlightSegment(airline: .qantas, flightNumber: "QF 025", origin: o, destination: d, departureTime: "21:20", arrivalTime: "09:30+1", duration: "9h 10m", aircraft: "Airbus A380",    cabin: search.cabin)], stops: 0, totalDuration: "9h 10m", price: 78_000, tags: ["Cheapest"],           seatsLeft: 7,   baggage: "23kg checked + 7kg cabin", refundable: false),
            ]
        case "DXB":
            return [
                Flight(segments: [FlightSegment(airline: .emirates, flightNumber: "EK 319", origin: o, destination: d, departureTime: "22:55", arrivalTime: "05:25+1", duration: "11h 30m", aircraft: "Airbus A380-800", cabin: search.cabin)], stops: 0, totalDuration: "11h 30m", price: 120_000, tags: ["Non-stop"],               seatsLeft: 4,   baggage: "30kg checked + 7kg cabin", refundable: true),
                Flight(segments: [FlightSegment(airline: .ana,      flightNumber: "NH 219", origin: o, destination: d, departureTime: "10:00", arrivalTime: "17:25",   duration: "11h 25m", aircraft: "Boeing 777-300ER", cabin: search.cabin)], stops: 0, totalDuration: "11h 25m", price: 115_000, tags: ["Best Value", "Fastest"],   seatsLeft: nil, baggage: "30kg checked + 7kg cabin", refundable: true),
                Flight(segments: [FlightSegment(airline: .jal,      flightNumber: "JL 871", origin: o, destination: Airport.BKK, departureTime: "11:30", arrivalTime: "16:50", duration: "5h 20m", aircraft: "Airbus A350", cabin: search.cabin),
                                  FlightSegment(airline: .emirates, flightNumber: "EK 373", origin: Airport.BKK, destination: d, departureTime: "23:25", arrivalTime: "03:35+1", duration: "7h 10m", aircraft: "Boeing 777-300ER", cabin: search.cabin)],
                       stops: 1, totalDuration: "16h 05m", price: 88_000, tags: ["Cheapest"], seatsLeft: 6, baggage: "20kg checked + 7kg cabin", refundable: false),
            ]
        case "LHR":
            return [
                Flight(segments: [FlightSegment(airline: .ana,     flightNumber: "NH 211", origin: o, destination: d, departureTime: "11:00", arrivalTime: "15:50",   duration: "12h 50m", aircraft: "Boeing 777-300ER",   cabin: search.cabin)], stops: 0, totalDuration: "12h 50m", price: 165_000, tags: ["Non-stop", "Fastest"],   seatsLeft: 3,   baggage: "30kg checked + 7kg cabin", refundable: true),
                Flight(segments: [FlightSegment(airline: .jal,     flightNumber: "JL 041", origin: o, destination: d, departureTime: "12:05", arrivalTime: "17:05",   duration: "13h 00m", aircraft: "Boeing 787-9",        cabin: search.cabin)], stops: 0, totalDuration: "13h 00m", price: 148_000, tags: ["Best Value"],            seatsLeft: nil, baggage: "30kg checked + 7kg cabin", refundable: true),
                Flight(segments: [FlightSegment(airline: .british, flightNumber: "BA 008", origin: o, destination: d, departureTime: "22:20", arrivalTime: "05:05+1", duration: "13h 45m", aircraft: "Boeing 777-300ER",   cabin: search.cabin)], stops: 0, totalDuration: "13h 45m", price: 135_000, tags: ["Cheapest"],            seatsLeft: 8,   baggage: "23kg checked + 7kg cabin", refundable: false),
                Flight(segments: [FlightSegment(airline: .emirates, flightNumber: "EK 319", origin: o, destination: Airport.DXB, departureTime: "22:55", arrivalTime: "05:25+1", duration: "11h 30m", aircraft: "Airbus A380", cabin: search.cabin),
                                  FlightSegment(airline: .emirates, flightNumber: "EK 005", origin: Airport.DXB, destination: d, departureTime: "08:30", arrivalTime: "13:10", duration: "7h 40m",  aircraft: "Airbus A380", cabin: search.cabin)],
                       stops: 1, totalDuration: "22h 15m", price: 115_000, tags: [], seatsLeft: nil, baggage: "30kg checked + 7kg cabin", refundable: false),
            ]
        case "LAX":
            return [
                Flight(segments: [FlightSegment(airline: .ana,    flightNumber: "NH 106", origin: o, destination: d, departureTime: "17:00", arrivalTime: "09:55",   duration: "9h 55m",  aircraft: "Boeing 777-300ER", cabin: search.cabin)], stops: 0, totalDuration: "9h 55m",  price: 138_000, tags: ["Non-stop", "Fastest"],   seatsLeft: 4,   baggage: "23kg checked + 7kg cabin", refundable: true),
                Flight(segments: [FlightSegment(airline: .jal,    flightNumber: "JL 062", origin: o, destination: d, departureTime: "20:00", arrivalTime: "13:00",   duration: "10h 00m", aircraft: "Boeing 787-9",      cabin: search.cabin)], stops: 0, totalDuration: "10h 00m", price: 125_000, tags: ["Best Value"],            seatsLeft: nil, baggage: "23kg checked + 7kg cabin", refundable: true),
                Flight(segments: [FlightSegment(airline: .united, flightNumber: "UA 838", origin: o, destination: d, departureTime: "14:30", arrivalTime: "07:25",   duration: "9h 55m",  aircraft: "Boeing 777-200ER", cabin: search.cabin)], stops: 0, totalDuration: "9h 55m",  price: 112_000, tags: ["Cheapest"],           seatsLeft: 11,  baggage: "23kg checked + 7kg cabin", refundable: false),
            ]
        case "CDG":
            return [
                Flight(segments: [FlightSegment(airline: .ana,    flightNumber: "NH 201", origin: o, destination: d, departureTime: "11:30", arrivalTime: "17:10",   duration: "13h 40m", aircraft: "Boeing 787-9",      cabin: search.cabin)], stops: 0, totalDuration: "13h 40m", price: 158_000, tags: ["Non-stop", "Best Value"], seatsLeft: 5,   baggage: "30kg checked + 7kg cabin", refundable: true),
                Flight(segments: [FlightSegment(airline: .jal,    flightNumber: "JL 045", origin: o, destination: d, departureTime: "12:45", arrivalTime: "18:55",   duration: "13h 10m", aircraft: "Airbus A350-900",   cabin: search.cabin)], stops: 0, totalDuration: "13h 10m", price: 145_000, tags: ["Fastest"],            seatsLeft: nil, baggage: "30kg checked + 7kg cabin", refundable: true),
            ]
        default:
            return [
                Flight(segments: [FlightSegment(airline: .ana,    flightNumber: "NH 900", origin: o, destination: d, departureTime: "09:00", arrivalTime: "13:30", duration: "4h 30m", aircraft: "Boeing 787-9",    cabin: search.cabin)], stops: 0, totalDuration: "4h 30m", price: 55_000, tags: ["Non-stop", "Best Value"], seatsLeft: 5, baggage: "23kg checked + 7kg cabin", refundable: true),
                Flight(segments: [FlightSegment(airline: .jal,    flightNumber: "JL 900", origin: o, destination: d, departureTime: "14:15", arrivalTime: "18:45", duration: "4h 30m", aircraft: "Airbus A350-900", cabin: search.cabin)], stops: 0, totalDuration: "4h 30m", price: 42_000, tags: ["Cheapest"],           seatsLeft: 10, baggage: "20kg checked + 7kg cabin", refundable: false),
            ]
        }
    }

    /// Sydney market results — SYD-origin Australian domestic + international routes.
    /// Prices use the same SGD-scale numeric values as the Singapore dataset (rendered as A$).
    static func mockResultsSydney(for search: FlightSearch) -> [Flight] {
        let o = search.origin   // SYD for Sydney
        let d = search.destination

        switch d.code {
        case "MEL":
            return [
                Flight(segments: [FlightSegment(airline: .qantas,   flightNumber: "QF 401", origin: o, destination: d, departureTime: "07:00", arrivalTime: "08:35", duration: "1h 35m", aircraft: "Boeing 737-800", cabin: search.cabin)],
                       stops: 0, totalDuration: "1h 35m", price: 159, tags: ["Non-stop", "Best Value"], seatsLeft: 5,   baggage: "23kg checked + 7kg cabin", refundable: true),
                Flight(segments: [FlightSegment(airline: .jetstar,  flightNumber: "JQ 510", origin: o, destination: d, departureTime: "09:40", arrivalTime: "11:15", duration: "1h 35m", aircraft: "Airbus A320neo", cabin: search.cabin)],
                       stops: 0, totalDuration: "1h 35m", price: 89,  tags: ["Cheapest"],                seatsLeft: 14,  baggage: "7kg cabin only",           refundable: false),
                Flight(segments: [FlightSegment(airline: .virginAU, flightNumber: "VA 822", origin: o, destination: d, departureTime: "14:25", arrivalTime: "16:00", duration: "1h 35m", aircraft: "Boeing 737-800", cabin: search.cabin)],
                       stops: 0, totalDuration: "1h 35m", price: 129, tags: ["Fastest"],                 seatsLeft: nil, baggage: "23kg checked + 7kg cabin", refundable: true),
            ]
        case "BNE":
            return [
                Flight(segments: [FlightSegment(airline: .qantas,   flightNumber: "QF 510", origin: o, destination: d, departureTime: "06:30", arrivalTime: "07:55", duration: "1h 25m", aircraft: "Airbus A330-200", cabin: search.cabin)],
                       stops: 0, totalDuration: "1h 25m", price: 145, tags: ["Non-stop", "Fastest"],     seatsLeft: 6,   baggage: "23kg checked + 7kg cabin", refundable: true),
                Flight(segments: [FlightSegment(airline: .jetstar,  flightNumber: "JQ 560", origin: o, destination: d, departureTime: "11:10", arrivalTime: "12:35", duration: "1h 25m", aircraft: "Airbus A321neo", cabin: search.cabin)],
                       stops: 0, totalDuration: "1h 25m", price: 79,  tags: ["Cheapest"],                seatsLeft: 18,  baggage: "7kg cabin only",           refundable: false),
                Flight(segments: [FlightSegment(airline: .virginAU, flightNumber: "VA 920", origin: o, destination: d, departureTime: "16:45", arrivalTime: "18:10", duration: "1h 25m", aircraft: "Boeing 737-800", cabin: search.cabin)],
                       stops: 0, totalDuration: "1h 25m", price: 132, tags: ["Best Value"],              seatsLeft: nil, baggage: "23kg checked + 7kg cabin", refundable: true),
            ]
        case "OOL":
            return [
                Flight(segments: [FlightSegment(airline: .jetstar,  flightNumber: "JQ 410", origin: o, destination: d, departureTime: "08:15", arrivalTime: "09:40", duration: "1h 25m", aircraft: "Airbus A320neo", cabin: search.cabin)],
                       stops: 0, totalDuration: "1h 25m", price: 75,  tags: ["Cheapest", "Best Value"],  seatsLeft: 20,  baggage: "7kg cabin only",           refundable: false),
                Flight(segments: [FlightSegment(airline: .virginAU, flightNumber: "VA 511", origin: o, destination: d, departureTime: "12:30", arrivalTime: "13:55", duration: "1h 25m", aircraft: "Boeing 737-800", cabin: search.cabin)],
                       stops: 0, totalDuration: "1h 25m", price: 119, tags: ["Non-stop", "Fastest"],     seatsLeft: 8,   baggage: "23kg checked + 7kg cabin", refundable: true),
            ]
        case "PER":
            return [
                Flight(segments: [FlightSegment(airline: .qantas,   flightNumber: "QF 645", origin: o, destination: d, departureTime: "08:00", arrivalTime: "11:10", duration: "5h 10m", aircraft: "Airbus A330-300", cabin: search.cabin)],
                       stops: 0, totalDuration: "5h 10m", price: 349, tags: ["Non-stop", "Fastest"],     seatsLeft: 4,   baggage: "30kg checked + 7kg cabin", refundable: true),
                Flight(segments: [FlightSegment(airline: .virginAU, flightNumber: "VA 685", origin: o, destination: d, departureTime: "13:20", arrivalTime: "16:35", duration: "5h 15m", aircraft: "Boeing 737-800", cabin: search.cabin)],
                       stops: 0, totalDuration: "5h 15m", price: 329, tags: ["Best Value"],              seatsLeft: nil, baggage: "23kg checked + 7kg cabin", refundable: true),
                Flight(segments: [FlightSegment(airline: .jetstar,  flightNumber: "JQ 970", origin: o, destination: d, departureTime: "22:05", arrivalTime: "01:20+1", duration: "5h 15m", aircraft: "Boeing 787-8", cabin: search.cabin)],
                       stops: 0, totalDuration: "5h 15m", price: 219, tags: ["Cheapest"],                seatsLeft: 11,  baggage: "7kg cabin only",           refundable: false),
            ]
        case "AKL":
            return [
                Flight(segments: [FlightSegment(airline: .airNZ,    flightNumber: "NZ 104", origin: o, destination: d, departureTime: "09:30", arrivalTime: "14:35", duration: "3h 05m", aircraft: "Boeing 787-9", cabin: search.cabin)],
                       stops: 0, totalDuration: "3h 05m", price: 289, tags: ["Non-stop", "Best Value"],  seatsLeft: 5,   baggage: "23kg checked + 7kg cabin", refundable: true),
                Flight(segments: [FlightSegment(airline: .qantas,   flightNumber: "QF 143", origin: o, destination: d, departureTime: "12:15", arrivalTime: "17:20", duration: "3h 05m", aircraft: "Airbus A330-200", cabin: search.cabin)],
                       stops: 0, totalDuration: "3h 05m", price: 315, tags: ["Fastest"],                 seatsLeft: nil, baggage: "30kg checked + 7kg cabin", refundable: true),
                Flight(segments: [FlightSegment(airline: .jetstar,  flightNumber: "JQ 201", origin: o, destination: d, departureTime: "19:40", arrivalTime: "00:45+1", duration: "3h 05m", aircraft: "Airbus A321neo", cabin: search.cabin)],
                       stops: 0, totalDuration: "3h 05m", price: 199, tags: ["Cheapest"],                seatsLeft: 9,   baggage: "7kg cabin only",           refundable: false),
            ]
        case "SIN":
            return [
                Flight(segments: [FlightSegment(airline: .sia,      flightNumber: "SQ 232", origin: o, destination: d, departureTime: "10:15", arrivalTime: "16:35", duration: "8h 20m", aircraft: "Airbus A350-900", cabin: search.cabin)],
                       stops: 0, totalDuration: "8h 20m", price: 645, tags: ["Non-stop", "Best Value"],  seatsLeft: 3,   baggage: "30kg checked + 7kg cabin", refundable: true),
                Flight(segments: [FlightSegment(airline: .qantas,   flightNumber: "QF 081", origin: o, destination: d, departureTime: "11:50", arrivalTime: "18:00", duration: "8h 10m", aircraft: "Airbus A380-800", cabin: search.cabin)],
                       stops: 0, totalDuration: "8h 10m", price: 689, tags: ["Fastest"],                 seatsLeft: nil, baggage: "30kg checked + 7kg cabin", refundable: true),
                Flight(segments: [FlightSegment(airline: .scoot,    flightNumber: "TR 13",  origin: o, destination: d, departureTime: "22:40", arrivalTime: "05:05+1", duration: "8h 25m", aircraft: "Boeing 787-9", cabin: search.cabin)],
                       stops: 0, totalDuration: "8h 25m", price: 399, tags: ["Cheapest"],                seatsLeft: 12,  baggage: "20kg checked + 7kg cabin", refundable: false),
            ]
        case "LAX":
            return [
                Flight(segments: [FlightSegment(airline: .qantas,   flightNumber: "QF 011", origin: o, destination: d, departureTime: "11:30", arrivalTime: "06:30", duration: "13h 00m", aircraft: "Airbus A380-800", cabin: search.cabin)],
                       stops: 0, totalDuration: "13h 00m", price: 1_189, tags: ["Non-stop", "Fastest"],  seatsLeft: 4,   baggage: "30kg checked + 7kg cabin", refundable: true),
                Flight(segments: [FlightSegment(airline: .united,   flightNumber: "UA 870", origin: o, destination: d, departureTime: "21:50", arrivalTime: "16:35", duration: "13h 45m", aircraft: "Boeing 787-9", cabin: search.cabin)],
                       stops: 0, totalDuration: "13h 45m", price: 1_089, tags: ["Best Value"],           seatsLeft: nil, baggage: "23kg checked + 7kg cabin", refundable: true),
                Flight(segments: [FlightSegment(airline: .airNZ,    flightNumber: "NZ 104", origin: o, destination: Airport.AKL, departureTime: "09:30", arrivalTime: "14:35", duration: "3h 05m", aircraft: "Boeing 787-9", cabin: search.cabin),
                                  FlightSegment(airline: .airNZ,    flightNumber: "NZ 002", origin: Airport.AKL, destination: d, departureTime: "16:45", arrivalTime: "07:15", duration: "12h 30m", aircraft: "Boeing 787-9", cabin: search.cabin)],
                       stops: 1, totalDuration: "16h 45m", price: 899, tags: ["Cheapest"],               seatsLeft: 7,   baggage: "23kg checked + 7kg cabin", refundable: false),
            ]
        case "LHR":
            return [
                Flight(segments: [FlightSegment(airline: .qantas,   flightNumber: "QF 001", origin: o, destination: Airport.SIN, departureTime: "11:50", arrivalTime: "18:00", duration: "8h 10m", aircraft: "Airbus A380-800", cabin: search.cabin),
                                  FlightSegment(airline: .qantas,   flightNumber: "QF 001", origin: Airport.SIN, destination: d, departureTime: "20:30", arrivalTime: "05:25+1", duration: "14h 25m", aircraft: "Airbus A380-800", cabin: search.cabin)],
                       stops: 1, totalDuration: "23h 35m", price: 1_649, tags: ["Best Value"],           seatsLeft: 3,   baggage: "30kg checked + 7kg cabin", refundable: true),
                Flight(segments: [FlightSegment(airline: .emirates, flightNumber: "EK 413", origin: o, destination: Airport.DXB, departureTime: "21:20", arrivalTime: "05:25+1", duration: "14h 05m", aircraft: "Airbus A380-800", cabin: search.cabin),
                                  FlightSegment(airline: .emirates, flightNumber: "EK 001", origin: Airport.DXB, destination: d, departureTime: "08:30", arrivalTime: "13:10", duration: "7h 40m", aircraft: "Airbus A380-800", cabin: search.cabin)],
                       stops: 1, totalDuration: "25h 50m", price: 1_549, tags: ["Cheapest"],             seatsLeft: nil, baggage: "30kg checked + 7kg cabin", refundable: false),
                Flight(segments: [FlightSegment(airline: .sia,      flightNumber: "SQ 232", origin: o, destination: Airport.SIN, departureTime: "10:15", arrivalTime: "16:35", duration: "8h 20m", aircraft: "Airbus A350-900", cabin: search.cabin),
                                  FlightSegment(airline: .sia,      flightNumber: "SQ 322", origin: Airport.SIN, destination: d, departureTime: "23:30", arrivalTime: "06:30+1", duration: "14h 00m", aircraft: "Airbus A350-900ULR", cabin: search.cabin)],
                       stops: 1, totalDuration: "24h 15m", price: 1_725, tags: ["Fastest"],              seatsLeft: 6,   baggage: "30kg checked + 7kg cabin", refundable: true),
            ]
        default:
            // Generic fallback for any other destination
            return [
                Flight(segments: [FlightSegment(airline: .qantas,   flightNumber: "QF 500", origin: o, destination: d, departureTime: "08:00", arrivalTime: "12:30", duration: "4h 30m", aircraft: "Airbus A330-300", cabin: search.cabin)],
                       stops: 0, totalDuration: "4h 30m", price: 399, tags: ["Non-stop", "Best Value"],  seatsLeft: 5,   baggage: "23kg checked + 7kg cabin", refundable: true),
                Flight(segments: [FlightSegment(airline: .jetstar,  flightNumber: "JQ 600", origin: o, destination: d, departureTime: "14:15", arrivalTime: "18:45", duration: "4h 30m", aircraft: "Boeing 787-8", cabin: search.cabin)],
                       stops: 0, totalDuration: "4h 30m", price: 269, tags: ["Cheapest"],                seatsLeft: 10,  baggage: "7kg cabin only",           refundable: false),
            ]
        }
    }
}
