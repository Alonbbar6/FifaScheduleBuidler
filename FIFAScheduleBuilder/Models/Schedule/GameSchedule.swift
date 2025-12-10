import Foundation
import CoreLocation

// MARK: - World Cup Game

struct WorldCupGame: Identifiable, Codable {
    let id: String
    let homeTeam: String
    let awayTeam: String
    let stadium: Stadium
    let kickoffTime: Date
    let matchday: String // e.g., "Group Stage - Match 1", "Quarter Final"
    
    var displayName: String {
        "\(homeTeam) vs \(awayTeam)"
    }
    
    var formattedKickoff: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
        return formatter.string(from: kickoffTime)
    }
}

// MARK: - Stadium

struct Stadium: Codable {
    let id: String
    let name: String
    let city: String
    let address: String
    let coordinate: Coordinate
    let capacity: Int
    let entryGates: [EntryGate]
    let foodOrderingAppScheme: String? // Stadium's official app URL scheme for food ordering
    let foodOrderingAppName: String?   // Stadium's official app name
    let foodOrderingWebURL: String?    // Web URL for food ordering (fallback if app not installed)

    var displayName: String {
        "\(name), \(city)"
    }

    var hasFoodOrderingApp: Bool {
        foodOrderingAppScheme != nil
    }

    var hasFoodOrderingWebsite: Bool {
        foodOrderingWebURL != nil
    }
}

struct Coordinate: Codable {
    let latitude: Double
    let longitude: Double
    
    var clLocation: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct EntryGate: Codable, Identifiable {
    let id: String
    let name: String // e.g., "North Gate A", "South Gate C"
    let coordinate: Coordinate
    let recommendedFor: [String] // Section numbers this gate serves
    let capacity: Int // Maximum people per hour this gate can process
    var currentCrowdLevel: CrowdLevel = .moderate
}

enum CrowdLevel: String, Codable {
    case clear = "Clear"
    case moderate = "Moderate"
    case crowded = "Crowded"
    case avoid = "Avoid"
    
    var color: String {
        switch self {
        case .clear: return "green"
        case .moderate: return "yellow"
        case .crowded: return "orange"
        case .avoid: return "red"
        }
    }
}

// MARK: - Game Schedule (The $2.99 Product)

struct GameSchedule: Identifiable, Codable {
    let id: String
    let game: WorldCupGame
    let userLocation: UserLocation
    let sectionNumber: String? // User's seat section (e.g., "118", "301")
    let scheduleSteps: [ScheduleStep]
    let recommendedGate: EntryGate
    let purchaseDate: Date
    let arrivalPreference: ArrivalPreference
    let transportationMode: TransportationMode
    let parkingReservation: ParkingReservation?
    let foodOrder: FoodOrder?
    let confidenceScore: Int // 0-100, represents probability of on-time arrival

    var isActive: Bool {
        // Schedule is active on game day
        Calendar.current.isDate(game.kickoffTime, inSameDayAs: Date())
    }

    var nextStep: ScheduleStep? {
        scheduleSteps.first { !$0.isCompleted && $0.scheduledTime > Date() }
    }

    var currentStep: ScheduleStep? {
        scheduleSteps.first { !$0.isCompleted && $0.scheduledTime <= Date() }
    }

    var hasParking: Bool {
        return transportationMode == .driving && parkingReservation != nil
    }

    var hasFoodOrder: Bool {
        return foodOrder != nil && foodOrder!.isActive
    }

    var confidenceDescription: String {
        switch confidenceScore {
        case 90...100:
            return "Excellent"
        case 80..<90:
            return "Very Good"
        case 70..<80:
            return "Good"
        case 60..<70:
            return "Fair"
        default:
            return "Moderate"
        }
    }

    var confidenceColor: String {
        switch confidenceScore {
        case 90...100:
            return "green"
        case 80..<90:
            return "blue"
        case 70..<80:
            return "yellow"
        case 60..<70:
            return "orange"
        default:
            return "red"
        }
    }
}

enum ArrivalPreference: String, Codable, CaseIterable {
    case relaxed = "Relaxed"
    case balanced = "Balanced"
    case efficient = "Efficient"
    
    var description: String {
        switch self {
        case .relaxed: return "Arrive early, enjoy the atmosphere"
        case .balanced: return "Arrive with time to spare"
        case .efficient: return "Arrive just in time"
        }
    }
    
    var minutesBeforeKickoff: Int {
        switch self {
        case .relaxed: return 120 // 2 hours early
        case .balanced: return 90  // 1.5 hours early
        case .efficient: return 60 // 1 hour early
        }
    }
}

// MARK: - User Location

struct UserLocation: Codable {
    let name: String // e.g., "Marriott Hotel Downtown"
    let address: String
    let coordinate: Coordinate
}

// MARK: - Schedule Step

struct ScheduleStep: Identifiable, Codable {
    let id: String
    let scheduledTime: Date
    let title: String
    let description: String
    let icon: String // SF Symbol name
    let estimatedDuration: Int // minutes
    let stepType: StepType
    var isCompleted: Bool = false
    var actualCompletionTime: Date?
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: scheduledTime)
    }
    
    var timeUntil: String {
        let interval = scheduledTime.timeIntervalSince(Date())
        if interval < 0 {
            return "Now"
        }
        let minutes = Int(interval / 60)
        if minutes < 60 {
            return "\(minutes) min"
        }
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        return "\(hours)h \(remainingMinutes)m"
    }
}

enum StepType: String, Codable {
    case departure = "Leave Location"
    case transit = "Transit"
    case parking = "Park Vehicle"
    case arrival = "Arrive at Stadium"
    case foodPickup = "Pick Up Food"
    case entry = "Enter Stadium"
    case seating = "Find Your Seat"
    case milestone = "Milestone"
}

// MARK: - Mock Data for Development

extension WorldCupGame {
    static let mockGames: [WorldCupGame] = [
        WorldCupGame(
            id: "wc2026-001",
            homeTeam: "Argentina",
            awayTeam: "Brazil",
            stadium: Stadium.mockStadiums[0],
            kickoffTime: Date().addingTimeInterval(86400 * 3), // 3 days from now
            matchday: "Group Stage - Match 1"
        ),
        WorldCupGame(
            id: "wc2026-002",
            homeTeam: "Spain",
            awayTeam: "Germany",
            stadium: Stadium.mockStadiums[1],
            kickoffTime: Date().addingTimeInterval(86400 * 5), // 5 days from now
            matchday: "Group Stage - Match 2"
        ),
        WorldCupGame(
            id: "wc2026-003",
            homeTeam: "France",
            awayTeam: "England",
            stadium: Stadium.mockStadiums[0],
            kickoffTime: Date().addingTimeInterval(86400 * 7), // 7 days from now
            matchday: "Quarter Final"
        )
    ]
}

extension Stadium {
    static let mockStadiums: [Stadium] = [
        Stadium(
            id: "stadium-001",
            name: "Hard Rock Stadium",
            city: "Miami",
            address: "347 Don Shula Dr, Miami Gardens, FL 33056",
            coordinate: Coordinate(latitude: 25.9580, longitude: -80.2389),
            capacity: 65326,
            entryGates: [
                EntryGate(
                    id: "gate-north-a",
                    name: "North Gate A",
                    coordinate: Coordinate(latitude: 25.9590, longitude: -80.2389),
                    recommendedFor: ["101-120"],
                    capacity: 1200,
                    currentCrowdLevel: .clear
                ),
                EntryGate(
                    id: "gate-south-c",
                    name: "South Gate C",
                    coordinate: Coordinate(latitude: 25.9570, longitude: -80.2389),
                    recommendedFor: ["201-220"],
                    capacity: 1000,
                    currentCrowdLevel: .moderate
                ),
                EntryGate(
                    id: "gate-east-b",
                    name: "East Gate B",
                    coordinate: Coordinate(latitude: 25.9580, longitude: -80.2379),
                    recommendedFor: ["301-320"],
                    capacity: 800,
                    currentCrowdLevel: .crowded
                )
            ],
            foodOrderingAppScheme: "hardrockstadium",
            foodOrderingAppName: "Hard Rock Stadium",
            foodOrderingWebURL: "https://www.hardrockstadium.com/concessions"
        ),
        Stadium(
            id: "stadium-002",
            name: "MetLife Stadium",
            city: "New York",
            address: "1 MetLife Stadium Dr, East Rutherford, NJ 07073",
            coordinate: Coordinate(latitude: 40.8128, longitude: -74.0742),
            capacity: 82500,
            entryGates: [
                EntryGate(
                    id: "gate-a",
                    name: "Gate A",
                    coordinate: Coordinate(latitude: 40.8138, longitude: -74.0742),
                    recommendedFor: ["100-150"],
                    capacity: 1500,
                    currentCrowdLevel: .moderate
                )
            ],
            foodOrderingAppScheme: "metlifestadium",
            foodOrderingAppName: "MetLife Stadium",
            foodOrderingWebURL: "https://www.metlifestadium.com/food-ordering"
        )
    ]
}
