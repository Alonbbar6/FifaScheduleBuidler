import Foundation

/// Service to load FIFA World Cup 2026 data from local JSON file
/// This ensures offline-first functionality - works without internet connection
class WorldCupDataLoader {
    static let shared = WorldCupDataLoader()

    private init() {}

    // MARK: - Data Models for JSON Parsing

    struct WorldCupData: Codable {
        let tournament: TournamentInfo
        let stadiums: [StadiumData]
        let matches: [MatchData]
    }

    struct TournamentInfo: Codable {
        let name: String
        let startDate: String
        let endDate: String
        let totalMatches: Int
        let totalTeams: Int
    }

    struct StadiumData: Codable {
        let id: String
        let name: String
        let city: String
        let country: String
        let address: String
        let latitude: Double
        let longitude: Double
        let capacity: Int
        let timezone: String
        let entryGates: [EntryGateData]
        let foodOrderingAppScheme: String?
        let foodOrderingAppName: String?
        let foodOrderingWebURL: String?
    }

    struct EntryGateData: Codable {
        let id: String
        let name: String
        let latitude: Double
        let longitude: Double
        let recommendedFor: [String]
        let capacity: Int
        let currentCrowdLevel: String
    }

    struct MatchData: Codable {
        let id: String
        let matchNumber: Int
        let homeTeam: String
        let awayTeam: String
        let stadiumId: String
        let kickoffTime: String
        let matchday: String
        let round: String
        let status: String
    }

    // MARK: - Public API

    /// Load all World Cup data from JSON file
    func loadData() -> WorldCupData? {
        guard let url = Bundle.main.url(forResource: "WorldCup2026Data", withExtension: "json") else {
            print("❌ WorldCup2026Data.json not found in bundle")
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let worldCupData = try decoder.decode(WorldCupData.self, from: data)
            print("✅ Loaded \(worldCupData.matches.count) matches from JSON")
            return worldCupData
        } catch {
            print("❌ Error loading World Cup data: \(error)")
            return nil
        }
    }

    /// Convert JSON data to app models (Stadium)
    func loadStadiums() -> [Stadium] {
        guard let data = loadData() else { return [] }

        return data.stadiums.map { stadiumData in
            Stadium(
                id: stadiumData.id,
                name: stadiumData.name,
                city: stadiumData.city,
                address: stadiumData.address,
                coordinate: Coordinate(
                    latitude: stadiumData.latitude,
                    longitude: stadiumData.longitude
                ),
                capacity: stadiumData.capacity,
                entryGates: stadiumData.entryGates.map { gateData in
                    EntryGate(
                        id: gateData.id,
                        name: gateData.name,
                        coordinate: Coordinate(
                            latitude: gateData.latitude,
                            longitude: gateData.longitude
                        ),
                        recommendedFor: gateData.recommendedFor,
                        capacity: gateData.capacity,
                        currentCrowdLevel: CrowdLevel(rawValue: gateData.currentCrowdLevel.capitalized) ?? .moderate
                    )
                },
                foodOrderingAppScheme: stadiumData.foodOrderingAppScheme,
                foodOrderingAppName: stadiumData.foodOrderingAppName,
                foodOrderingWebURL: stadiumData.foodOrderingWebURL
            )
        }
    }

    /// Convert JSON data to app models (WorldCupGame)
    func loadGames() -> [WorldCupGame] {
        guard let data = loadData() else { return [] }

        let stadiums = loadStadiums()
        let stadiumsById = Dictionary(uniqueKeysWithValues: stadiums.map { ($0.id, $0) })

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        // Fallback formatter without fractional seconds
        let fallbackFormatter = ISO8601DateFormatter()
        fallbackFormatter.formatOptions = [.withInternetDateTime]

        return data.matches.compactMap { matchData in
            guard let stadium = stadiumsById[matchData.stadiumId] else {
                print("⚠️ Stadium not found for match \(matchData.id)")
                return nil
            }

            // Try parsing with fractional seconds first, then without
            guard let kickoffDate = dateFormatter.date(from: matchData.kickoffTime) ??
                                   fallbackFormatter.date(from: matchData.kickoffTime) else {
                print("⚠️ Could not parse date for match \(matchData.id): \(matchData.kickoffTime)")
                return nil
            }

            return WorldCupGame(
                id: matchData.id,
                homeTeam: matchData.homeTeam,
                awayTeam: matchData.awayTeam,
                stadium: stadium,
                kickoffTime: kickoffDate,
                matchday: matchData.matchday
            )
        }
    }

    /// Get matches sorted by date (upcoming first)
    func loadUpcomingGames(limit: Int? = nil) -> [WorldCupGame] {
        let allGames = loadGames()
        let sortedGames = allGames.sorted { $0.kickoffTime < $1.kickoffTime }

        if let limit = limit {
            return Array(sortedGames.prefix(limit))
        }
        return sortedGames
    }

    /// Get matches for a specific stadium
    func loadGames(forStadium stadiumId: String) -> [WorldCupGame] {
        let allGames = loadGames()
        return allGames.filter { $0.stadium.id == stadiumId }
    }

    /// Get matches for a specific date
    func loadGames(forDate date: Date) -> [WorldCupGame] {
        let allGames = loadGames()
        let calendar = Calendar.current
        return allGames.filter { game in
            calendar.isDate(game.kickoffTime, inSameDayAs: date)
        }
    }
}
