import Foundation

/// Quick test suite for Match Service
/// Run these tests to verify your API integration is working correctly
class MatchServiceTests {
    
    private let service = MatchService()
    
    // MARK: - Test API Connection
    
    func testAPIConnection() async {
        print("🧪 Testing API Connection...")
        
        do {
            let isConnected = try await APIConfiguration.shared.testConnection()
            if isConnected {
                print("✅ API Connection: SUCCESS")
            } else {
                print("❌ API Connection: FAILED")
            }
        } catch {
            print("❌ API Connection Error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Test Live Matches
    
    func testFetchLiveMatches() async {
        print("\n🧪 Testing Live Matches...")
        
        do {
            let matches = try await service.fetchLiveMatches()
            print("✅ Fetched \(matches.count) live matches")
            
            if let firstMatch = matches.first {
                print("   Sample: \(firstMatch.teams.home.name) vs \(firstMatch.teams.away.name)")
                print("   Score: \(firstMatch.goals.homeScore) - \(firstMatch.goals.awayScore)")
                print("   Status: \(firstMatch.status.displayText)")
            }
        } catch {
            print("❌ Error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Test Today's Matches
    
    func testFetchTodayMatches() async {
        print("\n🧪 Testing Today's Matches...")
        
        do {
            let matches = try await service.fetchTodayMatches()
            print("✅ Fetched \(matches.count) matches for today")
            
            if let firstMatch = matches.first {
                print("   Sample: \(firstMatch.teams.home.name) vs \(firstMatch.teams.away.name)")
                print("   Time: \(firstMatch.displayTime)")
            }
        } catch {
            print("❌ Error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Test Upcoming Matches
    
    func testFetchUpcomingMatches() async {
        print("\n🧪 Testing Upcoming Matches (7 days)...")
        
        do {
            let matches = try await service.fetchUpcomingMatches(days: 7)
            print("✅ Fetched \(matches.count) upcoming matches")
            
            let grouped = Dictionary(grouping: matches) { match in
                Calendar.current.startOfDay(for: match.date)
            }
            print("   Grouped into \(grouped.keys.count) different days")
        } catch {
            print("❌ Error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Test Past Matches
    
    func testFetchPastMatches() async {
        print("\n🧪 Testing Past Matches (last 7 days)...")
        
        do {
            let calendar = Calendar.current
            let to = Date()
            let from = calendar.date(byAdding: .day, value: -7, to: to) ?? to
            
            let matches = try await service.fetchPastMatches(from: from, to: to)
            let finishedMatches = matches.filter { $0.isFinished }
            
            print("✅ Fetched \(matches.count) matches (\(finishedMatches.count) finished)")
            
            if let firstMatch = finishedMatches.first {
                print("   Sample: \(firstMatch.teams.home.name) vs \(firstMatch.teams.away.name)")
                print("   Score: \(firstMatch.goals.homeScore) - \(firstMatch.goals.awayScore)")
            }
        } catch {
            print("❌ Error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Test Caching
    
    func testCaching() async {
        print("\n🧪 Testing Cache System...")
        
        do {
            // First fetch (should hit API)
            let start1 = Date()
            let matches1 = try await service.fetchLiveMatches()
            let time1 = Date().timeIntervalSince(start1)
            print("✅ First fetch: \(matches1.count) matches in \(String(format: "%.2f", time1))s")
            
            // Second fetch (should hit cache)
            let start2 = Date()
            let matches2 = try await service.fetchLiveMatches()
            let time2 = Date().timeIntervalSince(start2)
            print("✅ Second fetch: \(matches2.count) matches in \(String(format: "%.2f", time2))s")
            
            if time2 < time1 {
                print("   ⚡ Cache is working! Second fetch was faster")
            }
        } catch {
            print("❌ Error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Run All Tests
    
    func runAllTests() async {
        print("🚀 Starting Match Service Tests\n")
        print("=" + String(repeating: "=", count: 50))
        
        await testAPIConnection()
        await testFetchLiveMatches()
        await testFetchTodayMatches()
        await testFetchUpcomingMatches()
        await testFetchPastMatches()
        await testCaching()
        
        print("\n" + String(repeating: "=", count: 50))
        print("✅ All tests completed!")
    }
}

// MARK: - Usage Example

/*
 To run these tests, add this to your app or a test view:
 
 Task {
     let tests = MatchServiceTests()
     await tests.runAllTests()
 }
 
 Or run individual tests:
 
 Task {
     let tests = MatchServiceTests()
     await tests.testAPIConnection()
     await tests.testFetchLiveMatches()
 }
*/
