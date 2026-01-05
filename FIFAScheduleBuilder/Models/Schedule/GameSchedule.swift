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

    var emoji: String {
        switch self {
        case .clear: return "🟢"
        case .moderate: return "🟡"
        case .crowded: return "🟠"
        case .avoid: return "🔴"
        }
    }

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

// MARK: - Real FIFA 2026 Data (Loaded from JSON)

extension WorldCupGame {
    /// Real FIFA World Cup 2026 games loaded from local JSON
    /// Works offline - no internet connection required
    static var mockGames: [WorldCupGame] {
        WorldCupDataLoader.shared.loadGames()
    }

    /// Get upcoming games (next N matches chronologically)
    static func upcomingGames(limit: Int = 10) -> [WorldCupGame] {
        WorldCupDataLoader.shared.loadUpcomingGames(limit: limit)
    }
}

extension Stadium {
    /// Real FIFA World Cup 2026 stadiums loaded from local JSON
    /// Includes all 16 host venues across USA, Canada, and Mexico
    static var mockStadiums: [Stadium] {
        WorldCupDataLoader.shared.loadStadiums()
    }

    /// Get stadium by ID
    static func stadium(withId id: String) -> Stadium? {
        mockStadiums.first { $0.id == id }
    }
}
