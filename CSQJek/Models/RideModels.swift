import SwiftUI
import Foundation

// MARK: - Ride Models

struct RideOption: Identifiable {
    let id = UUID()
    let name: String
    let subtitle: String
    let iconName: String
    let price: Double
    let eta: Int        // minutes
    let capacity: Int
    let color: Color
    var disclaimer: String? = nil   // Gag fine-print shown in ride card
    var badge: String?  = nil       // e.g. "FAST", "速達" — nil = no badge
    var badgeColor: Color = .csqRideBlue
    var isHorse: Bool = false       // true → use rideOptionHorseMeta for capacity label
    var priceColor: Color? = nil    // override for gag rides (tank=warning, horse=success)
}

// MARK: - Ride History Item
// Defined here (not in ContentView) so MarketContent can reference it directly.

struct RideHistoryItem: Identifiable {
    let id = UUID()
    let rideType:    String
    let destination: String
    let date:        String
    let fare:        String
    let status:      String
    let iconName:    String
    let statusColor: Color
}

struct Location: Identifiable {
    let id = UUID()
    let name: String
    let address: String
    let iconName: String
    var coordinate: (lat: Double, lng: Double)?
}

struct Driver: Identifiable {
    let id = UUID()
    let name: String
    let rating: Double
    let trips: Int
    let plateNumber: String
    let carModel: String
    let carColor: String
    let avatarInitials: String
}

// MARK: - Sample Data

extension RideOption {
    static let allOptions: [RideOption] = [
        RideOption(
            name: "CSQRide",
            subtitle: "Affordable everyday rides",
            iconName: "car.fill",
            price: 8.50,
            eta: 4,
            capacity: 4,
            color: .csqPrimary
        ),
        RideOption(
            name: "CSQXpress",
            subtitle: "Fast pickup, no detours",
            iconName: "bolt.car.fill",
            price: 11.00,
            eta: 2,
            capacity: 4,
            color: .csqRideBlue
        ),
        RideOption(
            name: "CSQBlack",
            subtitle: "Premium comfort rides",
            iconName: "car.fill",
            price: 18.75,
            eta: 7,
            capacity: 4,
            color: Color(hex: "#1C1C2E")
        ),
        RideOption(
            name: "CSQ Tank",
            subtitle: "Military-grade ground transport",
            iconName: "shield.fill",
            price: 249.99,
            eta: 45,
            capacity: 1,
            color: Color(hex: "#5C6B2E"),
            disclaimer: "* Commander must clear own route · 3.2m clearance required · Tolls extra",
            priceColor: .csqWarning
        ),
        RideOption(
            name: "CSQ Horse",
            subtitle: "Eco-friendly. Hay-powered. Zero emissions.",
            iconName: "figure.equestrian.sports",
            price: 4.20,
            eta: 25,
            capacity: 1,
            color: Color(hex: "#8B5E3C"),
            disclaimer: "* Hay included · ETA subject to horse's mood · No refunds if horse",
            isHorse: true,
            priceColor: .csqSuccess
        )
    ]
}

extension Location {
    static let recentLocations: [Location] = [
        Location(name: "Home", address: "Toa Payoh HDB Hub, 480 Lor 6 Toa Payoh, 310480", iconName: "house.fill"),
        Location(name: "Capitol Tower", address: "168 Robinson Rd, Singapore 068912", iconName: "building.2.fill"),
        Location(name: "Changi Airport T3", address: "Airport Blvd, Singapore 819830", iconName: "airplane"),
        Location(name: "Woodlands Ave", address: "30 Woodlands Ave 2, Singapore 738343", iconName: "mappin.fill"),
        Location(name: "Resorts World Sentosa", address: "8 Sentosa Gateway, Singapore 098269", iconName: "star.fill"),
        Location(name: "Marina Bay Sands", address: "10 Bayfront Ave, Singapore 018956", iconName: "building.columns.fill"),
        Location(name: "Peranakan Place", address: "180 Orchard Rd, Singapore 238851", iconName: "house.and.flag.fill"),
        Location(name: "Haji Lane", address: "Haji Lane, Kampong Glam, Singapore 189225", iconName: "fork.knife")
    ]
}

extension Driver {
    static let sampleDriver = Driver(
        name: "Raj S.",
        rating: 4.9,
        trips: 2847,
        plateNumber: "SJD 9821 B",
        carModel: "Toyota Camry",
        carColor: "Silver",
        avatarInitials: "RS"
    )
}

// MARK: - Ride State
enum RideFlowState {
    case idle
    case searchingDestination
    case confirmingPickup
    case confirmingRide
    case driverFound
    case enRoute
    case arrived
}
