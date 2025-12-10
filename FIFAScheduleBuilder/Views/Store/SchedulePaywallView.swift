import SwiftUI

struct SchedulePaywallView: View {
    let game: WorldCupGame
    @StateObject private var storeManager = StoreManager.shared
    @Environment(\.dismiss) private var dismiss

    let onPurchaseComplete: () -> Void

    @State private var showingError = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .yellow],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Text("Your Stress-Free Schedule")
                            .font(.system(.title, design: .rounded, weight: .bold))
                            .multilineTextAlignment(.center)

                        Text("Never miss kickoff again")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)

                    // Game Info
                    GameInfoBanner(game: game)

                    // What You Get
                    VStack(alignment: .leading, spacing: 20) {
                        Text("What You Get:")
                            .font(.title2)
                            .fontWeight(.bold)

                        PaywallFeatureRow(
                            icon: "map.fill",
                            title: "Optimized Route",
                            description: "Real-time traffic data and crowd intelligence"
                        )

                        PaywallFeatureRow(
                            icon: "door.left.hand.open",
                            title: "Best Entry Gate",
                            description: "Personalized for your section with shortest wait"
                        )

                        PaywallFeatureRow(
                            icon: "clock.fill",
                            title: "Step-by-Step Timeline",
                            description: "Know exactly when to leave and what to do"
                        )

                        PaywallFeatureRow(
                            icon: "checkmark.seal.fill",
                            title: "On-Time Guarantee",
                            description: "Confidence score showing your arrival probability"
                        )

                        PaywallFeatureRow(
                            icon: "bell.fill",
                            title: "Live Updates",
                            description: "Real-time crowd alerts and schedule adjustments"
                        )

                        PaywallFeatureRow(
                            icon: "safari",
                            title: "AR Indoor Compass",
                            description: "Navigate inside the stadium to your seat"
                        )
                    }

                    // Social Proof
                    SocialProofCard()

                    // Price & Purchase Button
                    VStack(spacing: 16) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(storeManager.schedulePrice)
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)

                            Text("per schedule")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Text("One-time purchase • Instant delivery • 30-day guarantee")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        Button {
                            Task {
                                let success = await storeManager.purchaseSchedule(for: game)
                                if success {
                                    onPurchaseComplete()
                                    dismiss()
                                } else if let error = storeManager.errorMessage {
                                    showingError = true
                                }
                            }
                        } label: {
                            HStack {
                                if storeManager.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "sparkles")
                                    Text("Get My Schedule")
                                    Image(systemName: "sparkles")
                                }
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(storeManager.isLoading)

                        // Restore purchases link
                        Button {
                            Task {
                                await storeManager.restorePurchases()
                            }
                        } label: {
                            Text("Restore Purchases")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        .disabled(storeManager.isLoading)
                    }
                    .padding(.vertical, 20)

                    // Fine print
                    Text("Payment will be charged to your Apple ID account. Price shown is in USD and may vary by region.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
            }
            .navigationTitle("Schedule Purchase")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Purchase Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {
                    storeManager.errorMessage = nil
                }
            } message: {
                Text(storeManager.errorMessage ?? "An unknown error occurred")
            }
        }
    }
}

// MARK: - Supporting Views

struct GameInfoBanner: View {
    let game: WorldCupGame

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "sportscourt.fill")
                .font(.title)
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 4) {
                Text(game.displayName)
                    .font(.headline)

                Text(game.formattedKickoff)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
    }
}

struct PaywallFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct SocialProofCard: View {
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)

                Text("4.9/5")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }

            Text("\"Used this for the Argentina match. Got to my seat 45 minutes early with zero stress. Worth every penny!\"")
                .font(.body)
                .italic()
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)

            Text("— Javi M., Miami")
                .font(.caption)
                .foregroundColor(.secondary)

            Divider()
                .padding(.vertical, 8)

            HStack(spacing: 24) {
                VStack {
                    Text("12,847")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("Fans Helped")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()
                    .frame(height: 40)

                VStack {
                    Text("94%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("On-Time Rate")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()
                    .frame(height: 40)

                VStack {
                    Text("38 min")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Text("Avg. Early")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.green.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    SchedulePaywallView(
        game: WorldCupGame.mockGames[0],
        onPurchaseComplete: {}
    )
}
