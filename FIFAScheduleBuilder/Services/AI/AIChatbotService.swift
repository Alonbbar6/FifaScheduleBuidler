import Foundation
import Combine

/// AI Chatbot Assistant Service
/// Provides contextual help and answers to user questions about:
/// - Stadium information and amenities
/// - Directions and navigation
/// - Food options and ordering
/// - Parking and transportation
/// - Game day tips and best practices
class AIChatbotService: ObservableObject {
    static let shared = AIChatbotService()

    // MARK: - Published Properties

    @Published var messages: [ChatMessage] = []
    @Published var isTyping: Bool = false

    // MARK: - Private Properties

    private var stadiumContext: Stadium?
    private var scheduleContext: GameSchedule?
    private let knowledgeBase: StadiumKnowledgeBase
    private let wayfindingService = IndoorWayfindingService.shared

    private init() {
        self.knowledgeBase = StadiumKnowledgeBase()

        // Add welcome message
        addSystemMessage("Hi! I'm your FIFA 2026 game day assistant. I can help you with stadium info, directions, food options, parking, and more. How can I help you today?")
    }

    // MARK: - Public Methods

    /// Set the current stadium context for more relevant responses
    func setContext(stadium: Stadium?, schedule: GameSchedule?) {
        self.stadiumContext = stadium
        self.scheduleContext = schedule
    }

    /// Send a user message and get AI response
    func sendMessage(_ text: String) async {
        // Add user message
        let userMessage = ChatMessage(
            id: UUID().uuidString,
            role: .user,
            content: text,
            timestamp: Date()
        )

        await MainActor.run {
            messages.append(userMessage)
            isTyping = true
        }

        // Simulate AI processing delay
        try? await Task.sleep(nanoseconds: 800_000_000)

        // Generate AI response
        let response = await generateResponse(for: text)

        // Add AI response
        let aiMessage = ChatMessage(
            id: UUID().uuidString,
            role: .assistant,
            content: response,
            timestamp: Date()
        )

        await MainActor.run {
            messages.append(aiMessage)
            isTyping = false
        }
    }

    /// Clear chat history
    func clearChat() {
        messages.removeAll()
        addSystemMessage("Chat cleared. How can I help you?")
    }

    // MARK: - Private Methods

    private func addSystemMessage(_ content: String) {
        let message = ChatMessage(
            id: UUID().uuidString,
            role: .system,
            content: content,
            timestamp: Date()
        )
        messages.append(message)
    }

    /// Generate contextual AI response based on user query
    private func generateResponse(for query: String) async -> String {
        let lowercaseQuery = query.lowercased()

        // Stadium-specific questions
        if let stadium = stadiumContext {
            // Food and concessions
            if lowercaseQuery.contains("food") || lowercaseQuery.contains("eat") ||
               lowercaseQuery.contains("concession") || lowercaseQuery.contains("restaurant") {
                return knowledgeBase.getFoodInfo(for: stadium)
            }

            // Parking questions
            if lowercaseQuery.contains("park") || lowercaseQuery.contains("lot") {
                return knowledgeBase.getParkingInfo(for: stadium)
            }

            // Gate and entry questions
            if lowercaseQuery.contains("gate") || lowercaseQuery.contains("enter") ||
               lowercaseQuery.contains("door") {
                return knowledgeBase.getEntryInfo(for: stadium)
            }

            // Amenities and facilities
            if lowercaseQuery.contains("bathroom") || lowercaseQuery.contains("restroom") ||
               lowercaseQuery.contains("wifi") || lowercaseQuery.contains("atm") {
                return knowledgeBase.getAmenitiesInfo(for: stadium)
            }

            // Seating and capacity - enhanced for "how do I get to my seat"
            if lowercaseQuery.contains("seat") || lowercaseQuery.contains("capacity") ||
               lowercaseQuery.contains("section") || lowercaseQuery.contains("find my seat") ||
               lowercaseQuery.contains("get to my seat") || lowercaseQuery.contains("where is my seat") {

                // Check if asking about directions to seat
                if lowercaseQuery.contains("how") || lowercaseQuery.contains("get to") ||
                   lowercaseQuery.contains("find") || lowercaseQuery.contains("where") {
                    return knowledgeBase.getSeatDirections(for: stadium, schedule: scheduleContext)
                } else {
                    return knowledgeBase.getSeatingInfo(for: stadium)
                }
            }

            // Bag policy
            if lowercaseQuery.contains("bag") || lowercaseQuery.contains("backpack") ||
               lowercaseQuery.contains("policy") || lowercaseQuery.contains("bring") {
                return knowledgeBase.getBagPolicy(for: stadium)
            }
        }

        // Navigation and directions
        if lowercaseQuery.contains("direction") || lowercaseQuery.contains("how to get") ||
           lowercaseQuery.contains("navigate") || lowercaseQuery.contains("route") {
            if let schedule = scheduleContext {
                return """
                I can help you navigate to \(schedule.game.stadium.name)!

                📍 From your location (\(schedule.userLocation.name)):
                • Tap "Start Navigation" on your schedule
                • Choose your preferred navigation app (Apple Maps, Google Maps, or Waze)
                • Your route is optimized to arrive \(schedule.arrivalPreference.description.lowercased())

                🚗 Transportation: \(schedule.transportationMode.rawValue)
                ⏰ Departure Time: \(schedule.scheduleSteps.first?.formattedTime ?? "Check your schedule")

                Need help with something else?
                """
            } else {
                return "To get navigation help, please open your game schedule and I'll provide personalized directions based on your starting location."
            }
        }

        // Timing and arrival questions
        if lowercaseQuery.contains("when") || lowercaseQuery.contains("time") ||
           lowercaseQuery.contains("early") || lowercaseQuery.contains("arrive") {
            if let schedule = scheduleContext {
                let arrivalTime = schedule.scheduleSteps.last?.scheduledTime ?? Date()
                let formatter = DateFormatter()
                formatter.timeStyle = .short

                return """
                ⏰ Your Personalized Game Day Timeline:

                🏁 Kickoff: \(schedule.game.formattedKickoff)
                🚪 Recommended Arrival: \(formatter.string(from: arrivalTime))
                🚗 Leave Your Location: \(schedule.scheduleSteps.first?.formattedTime ?? "See schedule")

                Based on your \(schedule.arrivalPreference.rawValue) preference, this gives you time to:
                • Clear security without rush
                • Grab food/drinks
                • Find your seat comfortably
                • Enjoy pre-game atmosphere

                💡 Tip: Crowds are typically highest 30-45 min before kickoff!
                """
            }
        }

        // Weather questions
        if lowercaseQuery.contains("weather") || lowercaseQuery.contains("rain") ||
           lowercaseQuery.contains("temperature") {
            return """
            🌤️ Weather Tips for Game Day:

            For the most accurate weather forecast, I recommend checking your weather app closer to game day.

            General Tips:
            • Most FIFA 2026 stadiums have partial or full roofs
            • Bring sunscreen for day games
            • Light jacket recommended for evening games
            • Check the stadium's bag policy before bringing umbrellas

            Which stadium are you attending? I can provide specific info about that venue!
            """
        }

        // Ticket questions
        if lowercaseQuery.contains("ticket") || lowercaseQuery.contains("seat") {
            return """
            🎫 Ticket & Seating Tips:

            • Have your tickets downloaded to your phone before arriving
            • Screenshot them in case of poor signal at the stadium
            • Arrive early if you need to pick up will-call tickets
            • Check which gate is closest to your section (I can help with that!)

            💡 Pro tip: Most stadiums use mobile-only tickets. Make sure your phone is charged!

            Need info about your specific seats or section?
            """
        }

        // Accessibility questions
        if lowercaseQuery.contains("wheelchair") || lowercaseQuery.contains("accessible") ||
           lowercaseQuery.contains("disability") || lowercaseQuery.contains("elevator") {
            if let stadium = stadiumContext {
                return """
                ♿️ Accessibility at \(stadium.name):

                All FIFA 2026 venues are ADA compliant with:
                • Wheelchair-accessible entrances at all gates
                • Elevators and ramps throughout
                • Accessible seating sections
                • Companion seating available
                • Accessible restrooms and concessions

                📞 For specific accommodations, contact the stadium directly:
                • They can arrange parking close to accessible entrances
                • Staff assistance available upon request

                For detailed accessibility info, visit the official \(stadium.name) website.
                """
            }
        }

        // Cash/payment questions
        if lowercaseQuery.contains("cash") || lowercaseQuery.contains("card") ||
           lowercaseQuery.contains("pay") || lowercaseQuery.contains("apple pay") {
            if let stadium = stadiumContext {
                return """
                💳 Payment at \(stadium.name):

                ⚠️ Most FIFA 2026 stadiums are CASHLESS venues.

                Accepted payment methods:
                • Credit/Debit cards
                • Apple Pay
                • Google Pay
                • Samsung Pay

                💡 Tips:
                • Have a backup card ready
                • Some stadiums offer reverse ATMs (exchange cash for prepaid cards)
                • Check your bank's international fees if visiting from abroad

                Need help finding the nearest ATM or reverse ATM?
                """
            }
        }

        // General help
        if lowercaseQuery.contains("help") || lowercaseQuery.contains("can you") {
            return """
            I'm here to help! I can answer questions about:

            🏟️ Stadium Info
            • Food & concessions
            • Parking & transportation
            • Gates & entry points
            • Amenities (WiFi, ATMs, restrooms)
            • Bag policies & what to bring

            🗺️ Navigation
            • Directions to the stadium
            • Best routes based on traffic
            • When to leave

            ⚽️ Game Day Tips
            • When to arrive
            • How to avoid crowds
            • Payment options
            • Weather preparation

            What would you like to know?
            """
        }

        // Default response for unrecognized queries
        return """
        I'd be happy to help! I specialize in:

        • Stadium information (food, parking, amenities)
        • Navigation and directions
        • Game day timing and tips
        • Entry procedures and policies

        Could you rephrase your question or ask about one of these topics?

        💡 Tip: Try asking "What food options are available?" or "When should I leave?"
        """
    }
}

// MARK: - Models

struct ChatMessage: Identifiable, Codable {
    let id: String
    let role: MessageRole
    let content: String
    let timestamp: Date
}

enum MessageRole: String, Codable {
    case user = "user"
    case assistant = "assistant"
    case system = "system"
}

// MARK: - Knowledge Base

/// Stadium-specific knowledge base
/// In production, this would be populated from stadium websites and APIs
class StadiumKnowledgeBase {

    func getFoodInfo(for stadium: Stadium) -> String {
        // Customize based on stadium
        switch stadium.id {
        case "stadium-001": // Hard Rock Stadium
            return """
            🍔 Food at Hard Rock Stadium:

            The stadium offers 40+ food options including:
            • Fuku (fried chicken)
            • Sol Cubano (Cuban cuisine)
            • Benihana (Japanese)
            • Little Caesars (pizza)
            • Local Miami flavors

            📱 Mobile Ordering Available:
            • Download the Hard Rock Stadium app
            • Order ahead and skip lines
            • Pick up at express windows

            💡 Stadium is cashless - cards only!

            🌐 Full menu: https://www.hardrockstadium.com/concessions

            Want help ordering food?
            """

        case "stadium-002": // MetLife Stadium
            return """
            🍔 Food at MetLife Stadium:

            The stadium features diverse options:
            • Classic stadium fare
            • Local New York/New Jersey favorites
            • International cuisine
            • Vegetarian & vegan options

            📱 Mobile ordering through MetLife Stadium app

            💡 Stadium is cashless - cards only!

            🌐 Visit: https://www.metlifestadium.com/food-ordering

            Need recommendations?
            """

        default:
            return """
            🍔 Stadium Food Options:

            FIFA 2026 venues offer:
            • Traditional stadium food
            • Local regional specialties
            • International cuisine
            • Vegetarian/vegan options
            • Grab-and-go options

            📱 Many stadiums offer mobile ordering - check their official app!

            💡 Most venues are cashless

            Which stadium are you attending? I can provide specific details!
            """
        }
    }

    func getParkingInfo(for stadium: Stadium) -> String {
        return """
        🅿️ Parking at \(stadium.name):

        Options:
        • Stadium parking lots (reserve in advance recommended)
        • Nearby parking garages
        • Street parking (limited availability)

        💡 Tips:
        • Prices are typically lower when reserved online
        • Arrive early for better spots
        • Use apps like ParkMobile, SpotHero, or ParkWhiz

        📱 Tap "Reserve Parking" in your schedule to find available spots!

        Want help finding parking near the stadium?
        """
    }

    func getEntryInfo(for stadium: Stadium) -> String {
        let gateNames = stadium.entryGates.map { $0.name }.joined(separator: ", ")

        return """
        🚪 Entry Gates at \(stadium.name):

        Available gates: \(gateNames)

        💡 Your schedule recommends the best gate based on:
        • Your seat section
        • Current crowd levels
        • Shortest wait times

        ⏰ Gates typically open 2 hours before kickoff

        Security Tips:
        • Have your ticket ready on your phone
        • Follow the clear bag policy
        • Allow extra time for security screening

        Want to know which gate is best for you?
        """
    }

    func getAmenitiesInfo(for stadium: Stadium) -> String {
        return """
        🏟️ Amenities at \(stadium.name):

        📶 WiFi: Free WiFi available throughout the stadium

        🚻 Restrooms: Located on all concourse levels
        • Family restrooms available
        • Accessible facilities at all levels

        💳 ATMs: Located near main concourses
        • Note: Most stadiums have reverse ATMs (cash → prepaid card)

        🏥 First Aid: Medical stations on each level

        📱 Charging Stations: Available at select locations

        🎁 Team Stores: Official merchandise available

        Need help finding something specific?
        """
    }

    func getSeatingInfo(for stadium: Stadium) -> String {
        return """
        🪑 Seating at \(stadium.name):

        Capacity: \(stadium.capacity.formatted()) fans

        Seating Areas:
        • Lower Bowl (100-level sections)
        • Middle Level (200-level sections)
        • Upper Deck (300-level sections)
        • Club Seats & Suites (premium areas)

        💡 Tips:
        • Your ticket will specify your section, row, and seat
        • Stadium staff can help you find your section
        • Arrive early to familiarize yourself with the venue

        Each gate has recommended sections - check your schedule!
        """
    }

    func getBagPolicy(for stadium: Stadium) -> String {
        return """
        🎒 Bag Policy at \(stadium.name):

        ✅ ALLOWED:
        • Clear plastic bags (12" x 6" x 12" or smaller)
        • Small clutch purses (4.5" x 6.5" or smaller)
        • Medically necessary items
        • Diaper bags (accompanying infants)

        ❌ NOT ALLOWED:
        • Backpacks
        • Large purses
        • Coolers
        • Briefcases
        • Luggage of any kind

        💡 Pro Tip: Travel light! Most items can be left in your car.

        📋 Full policy: Check the official \(stadium.name) website

        Questions about specific items?
        """
    }

    func getSeatDirections(for stadium: Stadium, schedule: GameSchedule?) -> String {
        guard let schedule = schedule else {
            return """
            🪑 Finding Your Seat:

            To help you find your seat, I need to know your ticket information!

            General tips for finding seats at \(stadium.name):
            1️⃣ **Check your ticket** for:
               • Section number (e.g., 101, 201, 301)
               • Row letter or number
               • Seat number

            2️⃣ **Enter through recommended gate**
               • Your schedule shows the best gate for your section
               • Look for signs pointing to your section range

            3️⃣ **Follow the signs**
               • Sections 100-199: Lower Bowl
               • Sections 200-299: Middle Level
               • Sections 300-399: Upper Deck

            4️⃣ **Ask stadium staff (ushers)**
               • They're stationed at each level
               • Show them your ticket and they'll point the way

            💡 Tip: Take a photo of the nearest section marker when you leave your seat - makes it easier to find your way back!

            Do you have your section number? I can give you more specific directions!
            """
        }

        let recommendedGate = schedule.recommendedGate

        // Try to get detailed wayfinding data
        let stadiumId = stadium.id
        if let gateId = mapGateToDataId(recommendedGate.name, stadiumId: stadiumId),
           let sampleSection = getSampleSection(for: stadiumId),
           let directions = IndoorWayfindingService.shared.getDirections(
               from: gateId,
               to: sampleSection,
               in: stadiumId
           ) {
            // We have detailed navigation data!
            var response = """
            🧭 Detailed Navigation to Your Seat at \(stadium.name):

            **Your Recommended Route:**

            """

            for (index, step) in directions.steps.enumerated() {
                response += "\n\(index + 1)️⃣ **\(step.title)**"
                response += "\n   \(step.description)"
                if step.distance > 0 {
                    response += "\n   📏 \(step.distance)m"
                }
                response += "\n"
            }

            response += """

            ⏱️ **Estimated Time:** \(directions.estimatedTimeMinutes) min
            📏 **Total Distance:** \(directions.totalDistance) meters
            🧭 **Direction:** \(compassDirection(directions.compassBearing))

            """

            // Add nearby amenities
            if !directions.nearbyRestrooms.isEmpty {
                response += "\n🚻 **Nearby Restrooms:**"
                for restroom in directions.nearbyRestrooms.prefix(2) {
                    response += "\n   • \(restroom.name)"
                }
                response += "\n"
            }

            if !directions.nearbyConcessions.isEmpty {
                response += "\n🍔 **Nearby Concessions:**"
                for concession in directions.nearbyConcessions.prefix(2) {
                    response += "\n   • \(concession.name)"
                }
                response += "\n"
            }

            response += """

            💡 **Pro Tip:** Look for the large section numbers on the concourse!

            Need directions to a different section? Just ask!
            """

            return response
        }

        // Fallback to general directions
        return """
        🧭 How to Get to Your Seat at \(stadium.name):

        **Your Recommended Route:**

        1️⃣ **Enter at: \(recommendedGate.name)**
           ✅ This gate is closest to your seating area
           ✅ Lower crowd levels expected

        2️⃣ **Once Inside:**
           • Look for directional signs showing section numbers
           • Stadium staff (ushers) wear uniforms - they can help!
           • Most sections are clearly marked with large numbers

        3️⃣ **General Layout:**
           Sections at \(stadium.name):
           • **100-level**: Lower Bowl (closest to field)
           • **200-level**: Middle Tier (great views)
           • **300-level**: Upper Deck (full stadium view)

        4️⃣ **Navigation Tips:**
           • Use escalators/stairs to reach your level
           • Follow concourse around until you see your section number
           • Ushers at each section entrance will check tickets
           • Seat numbers usually go from lowest (aisle) to highest

        📱 **Pro Tips:**
        • Download your ticket before entering (weak signal inside)
        • Take a photo of nearby landmarks when you leave your seat
        • Food/bathrooms are on the concourse behind seating areas
        • Allow 5-10 min to find your seat from the gate

        🗺️ **Need More Help?**
        Many stadiums have:
        • Interactive kiosks with maps
        • Mobile apps with seat finder features
        • Guest services desks on each level

        What's your section number? I can provide more specific directions!
        """
    }

    private func mapGateToDataId(_ gateName: String, stadiumId: String) -> String? {
        // Map our EntryGate names to the stadium data gate IDs
        switch stadiumId {
        case "stadium-001", "hard-rock-stadium":
            if gateName.lowercased().contains("north") { return "gate-north" }
            if gateName.lowercased().contains("south") { return "gate-south" }
            if gateName.lowercased().contains("east") { return "gate-east" }
            if gateName.lowercased().contains("west") { return "gate-west" }
        default:
            return nil
        }
        return nil
    }

    private func getSampleSection(for stadiumId: String) -> String? {
        // Return a sample section for demonstration
        switch stadiumId {
        case "stadium-001", "hard-rock-stadium":
            return "101" // We have data for section 101
        default:
            return nil
        }
    }

    private func compassDirection(_ bearing: Double) -> String {
        switch bearing {
        case 0..<22.5, 337.5...360: return "North ⬆️"
        case 22.5..<67.5: return "Northeast ↗️"
        case 67.5..<112.5: return "East ➡️"
        case 112.5..<157.5: return "Southeast ↘️"
        case 157.5..<202.5: return "South ⬇️"
        case 202.5..<247.5: return "Southwest ↙️"
        case 247.5..<292.5: return "West ⬅️"
        case 292.5..<337.5: return "Northwest ↖️"
        default: return "Forward"
        }
    }
}
