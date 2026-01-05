import Foundation

/// Quick test to verify Transit Land API integration is working
/// Run this to see REAL crowd data in action!
class TestTransitCrowdData {

    static func runTest() async {
        print("=" * 60)
        print("🧪 TESTING TRANSIT LAND API INTEGRATION")
        print("=" * 60)

        let service = TransitCrowdDataService()

        // Test 1: Hard Rock Stadium, Miami
        print("\n📍 Test 1: Hard Rock Stadium")
        print("Coordinates: 25.9580, -80.2389")

        do {
            let hardRockCoord = Coordinate(latitude: 25.9580, longitude: -80.2389)

            let crowdData = try await service.getTransitBasedCrowdLevel(
                near: hardRockCoord,
                radiusMeters: 1000
            )

            print("\n✅ SUCCESS!")
            print("━" * 60)
            print("Crowd Level: \(crowdData.crowdLevel.emoji) \(crowdData.crowdLevel.rawValue)")
            print("Avg Delay: \(crowdData.averageDelaySeconds) seconds")
            print("Delayed Routes: \(crowdData.delayedRouteCount) of \(crowdData.totalRoutesChecked)")
            print("Confidence: \(Int(crowdData.confidence * 100))%")
            print("\n💡 Reasoning:")
            print("   \(crowdData.reasoning)")
            print("━" * 60)

        } catch {
            print("\n❌ ERROR: \(error.localizedDescription)")
            if let transitError = error as? TransitError {
                print("   Transit-specific error: \(transitError)")
            }
        }

        // Test 2: Combined prediction with CrowdIntelligenceService
        print("\n\n📍 Test 2: Full Crowd Intelligence Forecast")
        print("Using combined time + transit data")

        let crowdService = CrowdIntelligenceService.shared

        // Create mock stadium
        let hardRockStadium = Stadium(
            id: "hard-rock-stadium",
            name: "Hard Rock Stadium",
            city: "Miami",
            address: "347 Don Shula Dr, Miami Gardens, FL 33056",
            coordinate: Coordinate(latitude: 25.9580, longitude: -80.2389),
            capacity: 65326,
            entryGates: [
                EntryGate(
                    id: "gate-north",
                    name: "North Gate",
                    coordinate: Coordinate(latitude: 25.9590, longitude: -80.2389),
                    recommendedFor: ["101-120"],
                    capacity: 15000,
                    currentCrowdLevel: .clear
                ),
                EntryGate(
                    id: "gate-south",
                    name: "South Gate",
                    coordinate: Coordinate(latitude: 25.9570, longitude: -80.2389),
                    recommendedFor: ["201-220"],
                    capacity: 12000,
                    currentCrowdLevel: .clear
                )
            ],
            foodOrderingAppScheme: nil,
            foodOrderingAppName: nil,
            foodOrderingWebURL: nil
        )

        // Test forecast for kickoff in 1 hour
        let kickoffTime = Date().addingTimeInterval(3600)  // 1 hour from now

        let forecast = await crowdService.getStadiumCrowdForecast(
            for: hardRockStadium,
            at: kickoffTime
        )

        print("\n✅ FORECAST GENERATED!")
        print("━" * 60)
        print("Stadium: \(forecast.stadium.name)")
        print("Overall Crowd: \(forecast.emoji) \(forecast.overallCrowdIntensity.description)")
        print("Estimated Wait: \(forecast.estimatedWaitTimeMinutes) minutes")
        print("\n🚪 Recommended Gates:")
        for (index, gate) in forecast.recommendedGates.enumerated() {
            let crowdEmoji: String
            switch gate.currentCrowdLevel {
            case .clear: crowdEmoji = "🟢"
            case .moderate: crowdEmoji = "🟡"
            case .crowded: crowdEmoji = "🟠"
            case .avoid: crowdEmoji = "🔴"
            }
            print("   \(index + 1). \(gate.name) - \(crowdEmoji) \(gate.currentCrowdLevel.rawValue)")
        }
        print("━" * 60)

        print("\n\n" + "=" * 60)
        print("🎉 TESTS COMPLETE!")
        print("=" * 60)
    }
}

// Helper for repeating strings
extension String {
    static func *(lhs: String, rhs: Int) -> String {
        return String(repeating: lhs, count: rhs)
    }
}