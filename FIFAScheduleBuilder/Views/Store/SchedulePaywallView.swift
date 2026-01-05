import SwiftUI

struct SchedulePaywallView: View {
    let game: WorldCupGame?
    @StateObject private var premiumManager = PremiumManager.shared
    @Environment(\.dismiss) private var dismiss

    let onPurchaseComplete: () -> Void

    @State private var showingError = false

    var body: some View {
        #if os(iOS)
        NavigationView {
            content
                .navigationTitle("Upgrade to Premium")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
        }
        #else
        NavigationStack {
            content
                .navigationTitle("Upgrade to Premium")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
        }
        #endif
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("Unlock Premium Features")
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .multilineTextAlignment(.center)

                    Text("Free to try, premium for serious fans")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)

                // Game Info (if specific game provided)
                if let game = game {
                    GameInfoBanner(game: game)
                }

                // Premium Features
                VStack(alignment: .leading, spacing: 20) {
                    Text("Premium Features:")
                        .font(.title2)
                        .fontWeight(.bold)

                    ForEach(premiumManager.getPremiumFeatures()) { feature in
                        PaywallFeatureRow(
                            icon: feature.icon,
                            title: feature.title,
                            description: feature.description
                        )
                    }
                }

                // Social Proof
                SocialProofCard()

                // Price & Purchase Button
                VStack(spacing: 16) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(PremiumManager.PREMIUM_PRICE)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)

                        Text("one-time")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Text("Unlimited schedules • AI assistance • Real-time crowds • AR navigation")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Button {
                        Task {
                            do {
                                try await premiumManager.purchasePremium()
                                onPurchaseComplete()
                                dismiss()
                            } catch {
                                premiumManager.errorMessage = error.localizedDescription
                                showingError = true
                            }
                        }
                    } label: {
                        HStack {
                            if premiumManager.isProcessingPurchase {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "crown.fill")
                                Text("Upgrade to Premium")
                                Image(systemName: "crown.fill")
                            }
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(premiumManager.isProcessingPurchase)

                    // Restore purchases link
                    Button {
                        Task {
                            do {
                                try await premiumManager.restorePurchases()
                            } catch {
                                premiumManager.errorMessage = error.localizedDescription
                                showingError = true
                            }
                        }
                    } label: {
                        Text("Restore Purchases")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .disabled(premiumManager.isProcessingPurchase)
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
        .alert("Purchase Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {
                premiumManager.errorMessage = nil
            }
        } message: {
            Text(premiumManager.errorMessage ?? "An unknown error occurred")
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
        .background(
            Group {
                #if os(macOS)
                Color(nsColor: .windowBackgroundColor)
                #else
                Color(UIColor.systemBackground)
                #endif
            }
        )
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

            Text("\"The free version convinced me. Upgraded to Premium for unlimited schedules and real-time updates. Best $5 I've spent!\"")
                .font(.body)
                .italic()
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)

            Text("— Maria S., Verified User")
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
