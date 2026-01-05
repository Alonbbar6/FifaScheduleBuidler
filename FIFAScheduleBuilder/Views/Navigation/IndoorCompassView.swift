import SwiftUI
import CoreLocation
import Combine

/// AR-style compass view for indoor seat navigation
/// Shows direction arrow, distance, and step-by-step instructions
struct IndoorCompassView: View {
    let schedule: GameSchedule
    @Environment(\.dismiss) private var dismiss
    @StateObject private var compassViewModel: IndoorCompassViewModel
    @State private var showingSteps = false

    init(schedule: GameSchedule) {
        self.schedule = schedule
        _compassViewModel = StateObject(wrappedValue: IndoorCompassViewModel(schedule: schedule))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background - match app theme
                Color(red: 0.949, green: 0.949, blue: 0.969)
                    .ignoresSafeArea()

                if let directions = compassViewModel.directions {
                    ScrollView {
                        VStack(spacing: 24) {
                            // AR Compass Display
                            compassDisplay(directions: directions)
                                .padding(.top, 20)

                            // Step-by-step instructions
                            instructionsPanel(directions: directions)
                                .padding(.horizontal)
                                .padding(.bottom, 40)
                        }
                    }
                } else {
                    // Loading or error state
                    loadingView
                }
            }
            .navigationTitle("Indoor Navigation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                            Text("Close")
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        compassViewModel.refreshDirections()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
    }

    // MARK: - Compass Display

    @ViewBuilder
    private func compassDisplay(directions: SeatNavigationDirections) -> some View {
        VStack(spacing: 20) {
            // Stadium name
            Text(directions.stadiumName)
                .font(.headline)
                .foregroundColor(.secondary)

            // Destination info
            Text("Section \(directions.section.sectionId)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            // Large directional arrow
            ZStack {
                // Compass background circle
                Circle()
                    .stroke(Color.blue.opacity(0.3), lineWidth: 3)
                    .frame(width: 280, height: 280)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.1), Color.green.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 280, height: 280)

                // Cardinal directions
                ForEach(["N", "E", "S", "W"], id: \.self) { direction in
                    Text(direction)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                        .offset(y: direction == "N" ? -140 : direction == "S" ? 140 : 0)
                        .offset(x: direction == "E" ? 140 : direction == "W" ? -140 : 0)
                }

                // Direction arrow
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 120))
                    .foregroundColor(.green)
                    .shadow(color: .green.opacity(0.5), radius: 20)
                    .rotationEffect(.degrees(directions.compassBearing))
                    .animation(.easeInOut(duration: 0.3), value: directions.compassBearing)

                // Center dot
                Circle()
                    .fill(Color.primary)
                    .frame(width: 12, height: 12)
            }
            .padding(.vertical, 30)

            // Distance and time stats
            HStack(spacing: 40) {
                VStack(spacing: 8) {
                    Image(systemName: "ruler")
                        .font(.title2)
                        .foregroundColor(.blue)
                    Text("\(directions.totalDistance)m")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("Distance")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()
                    .frame(height: 60)

                VStack(spacing: 8) {
                    Image(systemName: "clock.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                    Text("\(directions.estimatedTimeMinutes) min")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("Walking")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(red: 0.949, green: 0.949, blue: 0.969))
            .cornerRadius(16)
        }
    }

    // MARK: - Instructions Panel

    @ViewBuilder
    private func instructionsPanel(directions: SeatNavigationDirections) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header - Tappable to expand/collapse
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingSteps.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "list.bullet")
                        .foregroundColor(.blue)
                    Text("Step-by-Step Directions")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    Image(systemName: showingSteps ? "chevron.down" : "chevron.up")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14, weight: .semibold))
                }
                .padding()
                .background(Color(red: 0.949, green: 0.949, blue: 0.969))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Steps - Collapsible
            if showingSteps {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(Array(directions.steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 12) {
                            // Step number
                            ZStack {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 36, height: 36)

                                Text("\(index + 1)")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Image(systemName: step.icon)
                                        .foregroundColor(.blue)
                                        .font(.system(size: 18))
                                    Text(step.title)
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(.primary)
                                }

                                Text(step.description)
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondary)

                                if step.distance > 0 {
                                    Text("\(step.distance)m")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                        .padding(.top, 2)
                                }
                            }

                            Spacer()
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    }

                    // Nearby amenities
                    if !directions.nearbyRestrooms.isEmpty || !directions.nearbyConcessions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Nearby Amenities")
                                .font(.headline)
                                .foregroundColor(.primary)

                            if !directions.nearbyRestrooms.isEmpty {
                                ForEach(directions.nearbyRestrooms.prefix(2), id: \.id) { restroom in
                                    HStack {
                                        Image(systemName: "toilet")
                                            .foregroundColor(.blue)
                                        Text(restroom.name)
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                    }
                                }
                            }

                            if !directions.nearbyConcessions.isEmpty {
                                ForEach(directions.nearbyConcessions.prefix(2), id: \.id) { concession in
                                    HStack {
                                        Image(systemName: "cup.and.saucer")
                                            .foregroundColor(.orange)
                                        Text(concession.name)
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color(red: 0.949, green: 0.949, blue: 0.969))
                        .cornerRadius(12)
                    }
                }
                .padding()
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(Color.white)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 20, topTrailingRadius: 20))
        .shadow(color: Color.black.opacity(0.1), radius: 10, y: -5)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)

            Text("Loading navigation data...")
                .foregroundColor(.white)
        }
    }
}

// MARK: - View Model

class IndoorCompassViewModel: ObservableObject {
    @Published var directions: SeatNavigationDirections?
    @Published var currentHeading: Double = 0

    private let schedule: GameSchedule
    private let wayfindingService = IndoorWayfindingService.shared

    init(schedule: GameSchedule) {
        self.schedule = schedule
        // Load directions asynchronously
        Task {
            await loadDirections()
        }
    }

    func loadDirections() async {
        print("🔍 IndoorCompassViewModel: Starting loadDirections()")

        // Ensure stadium data is loaded first
        print("🔍 IndoorCompassViewModel: Ensuring data loaded...")
        await wayfindingService.ensureDataLoaded()
        print("✅ IndoorCompassViewModel: Data ensure complete")

        let stadium = schedule.game.stadium
        let recommendedGate = schedule.recommendedGate

        print("🔍 IndoorCompassViewModel: Stadium info:")
        print("   - Stadium ID: \(stadium.id)")
        print("   - Stadium Name: \(stadium.name)")
        print("   - Recommended Gate: \(recommendedGate.name)")

        // Map gate name to ID
        var gateId: String?
        switch stadium.id {
        case "stadium-001", "hard-rock-stadium":
            if recommendedGate.name.lowercased().contains("north") { gateId = "gate-north" }
            else if recommendedGate.name.lowercased().contains("south") { gateId = "gate-south" }
            else if recommendedGate.name.lowercased().contains("east") { gateId = "gate-east" }
            else if recommendedGate.name.lowercased().contains("west") { gateId = "gate-west" }
        default:
            break
        }

        print("🔍 IndoorCompassViewModel: Gate mapping result: \(gateId ?? "nil")")

        // Get sample section (in production, this would come from user's ticket)
        let sectionId = "101"
        print("🔍 IndoorCompassViewModel: Target section: \(sectionId)")

        if let gateId = gateId {
            print("🔍 IndoorCompassViewModel: Calling getDirections...")
            let result = wayfindingService.getDirections(
                from: gateId,
                to: sectionId,
                in: stadium.id
            )

            if let result = result {
                print("✅ IndoorCompassViewModel: Directions generated successfully")
                print("   - Total distance: \(result.totalDistance)m")
                print("   - Steps: \(result.steps.count)")
            } else {
                print("❌ IndoorCompassViewModel: getDirections returned nil")
            }

            // Update on main thread
            await MainActor.run {
                directions = result
                print("✅ IndoorCompassViewModel: UI updated with directions")
            }
        } else {
            print("❌ IndoorCompassViewModel: No gateId mapped, cannot get directions")
        }
    }

    func refreshDirections() {
        Task {
            await loadDirections()
        }
    }
}

// MARK: - Preview

#Preview {
    let mockGame = WorldCupGame.mockGames[0]
    let mockLocation = UserLocation(
        name: "Marriott Hotel",
        address: "123 Main St, Miami, FL",
        coordinate: Coordinate(latitude: 25.7617, longitude: -80.1918)
    )

    let mockSchedule = GameSchedule(
        id: "preview-schedule",
        game: mockGame,
        userLocation: mockLocation,
        sectionNumber: "118",
        scheduleSteps: [],
        recommendedGate: mockGame.stadium.entryGates[0],
        purchaseDate: Date(),
        arrivalPreference: .balanced,
        transportationMode: .publicTransit,
        parkingReservation: nil,
        foodOrder: nil,
        confidenceScore: 92
    )

    IndoorCompassView(schedule: mockSchedule)
}
