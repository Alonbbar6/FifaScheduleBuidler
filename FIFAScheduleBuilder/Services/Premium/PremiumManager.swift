import Foundation
import Combine
import StoreKit

/// Manages premium features and In-App Purchase
/// Free tier: 1 schedule, basic features
/// Premium ($4.99): Unlimited schedules, AI chatbot, real-time crowd data, advanced features
class PremiumManager: ObservableObject {
    static let shared = PremiumManager()

    // MARK: - Published Properties

    @Published var isPremium: Bool = false
    @Published var isProcessingPurchase: Bool = false
    @Published var errorMessage: String? = nil

    // MARK: - Constants

    /// Free tier schedule limit
    static let FREE_SCHEDULE_LIMIT = 1

    /// Premium price
    static let PREMIUM_PRICE = "$4.99"

    /// Product ID for In-App Purchase
    private let premiumProductID = "com.fifaschedulebuilder.premium"

    // MARK: - Initialization

    private init() {
        loadPremiumStatus()
    }

    // MARK: - Premium Status

    /// Check if user has premium access
    var hasPremiumAccess: Bool {
        return isPremium
    }

    /// Load premium status from UserDefaults (for development)
    /// In production, this would check StoreKit receipt validation
    private func loadPremiumStatus() {
        isPremium = UserDefaults.standard.bool(forKey: "isPremiumUser")
        print("💎 Premium status loaded: \(isPremium)")
    }

    /// Save premium status
    private func savePremiumStatus(_ status: Bool) {
        isPremium = status
        UserDefaults.standard.set(status, forKey: "isPremiumUser")
        print("💎 Premium status saved: \(status)")
    }

    // MARK: - Schedule Limits

    /// Check if user can create a new schedule
    func canCreateSchedule(currentCount: Int) -> Bool {
        if isPremium {
            return true // Unlimited for premium
        }
        return currentCount < Self.FREE_SCHEDULE_LIMIT
    }

    /// Get remaining free schedules
    func remainingFreeSchedules(currentCount: Int) -> Int {
        if isPremium {
            return Int.max // Unlimited
        }
        let remaining = Self.FREE_SCHEDULE_LIMIT - currentCount
        return max(0, remaining)
    }

    // MARK: - Feature Gates

    /// Check if AI Chatbot is available
    var canAccessAIChatbot: Bool {
        return isPremium
    }

    /// Check if real-time crowd intelligence is available
    var canAccessRealTimeCrowdData: Bool {
        return isPremium
    }

    /// Check if indoor AR compass is available
    var canAccessIndoorCompass: Bool {
        return isPremium
    }

    /// Check if advanced parking optimization is available
    var canAccessParkingOptimization: Bool {
        return isPremium
    }

    // MARK: - Purchase Flow

    /// Initiate premium purchase
    func purchasePremium() async throws {
        await MainActor.run {
            isProcessingPurchase = true
        }

        // TODO: Implement actual StoreKit 2 purchase flow
        // For now, this is a placeholder for development

        print("💎 Initiating premium purchase...")

        // Simulate purchase delay
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

        // Mock successful purchase for development
        await MainActor.run {
            savePremiumStatus(true)
            isProcessingPurchase = false
        }

        print("✅ Premium purchase successful!")
    }

    /// Restore previous purchases
    func restorePurchases() async throws {
        await MainActor.run {
            isProcessingPurchase = true
        }

        print("🔄 Restoring purchases...")

        // TODO: Implement actual StoreKit 2 restore flow
        // For now, this is a placeholder

        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        // Check if user has purchased before (mock for development)
        let hasPreviousPurchase = UserDefaults.standard.bool(forKey: "isPremiumUser")

        await MainActor.run {
            if hasPreviousPurchase {
                savePremiumStatus(true)
                print("✅ Purchases restored successfully!")
            } else {
                print("ℹ️ No previous purchases found")
            }
            isProcessingPurchase = false
        }
    }

    // MARK: - Development Helpers

    #if DEBUG
    /// Toggle premium status for testing (DEBUG only)
    func togglePremiumForTesting() {
        savePremiumStatus(!isPremium)
    }

    /// Reset premium status for testing (DEBUG only)
    func resetPremiumForTesting() {
        savePremiumStatus(false)
    }
    #endif

    // MARK: - Messaging

    /// Get upgrade message for feature
    func upgradeMessage(for feature: PremiumFeature) -> String {
        switch feature {
        case .unlimitedSchedules:
            return "Upgrade to Premium for unlimited schedules"
        case .aiChatbot:
            return "Unlock AI Assistant with Premium"
        case .realTimeCrowdData:
            return "Get real-time crowd intelligence with Premium"
        case .indoorCompass:
            return "Access AR Indoor Compass with Premium"
        case .parkingOptimization:
            return "Unlock advanced parking with Premium"
        }
    }

    /// Get feature list for paywall
    func getPremiumFeatures() -> [PremiumFeatureDescription] {
        return [
            PremiumFeatureDescription(
                icon: "calendar.badge.plus",
                title: "Unlimited Schedules",
                description: "Create schedules for all your games",
                color: "blue"
            ),
            PremiumFeatureDescription(
                icon: "message.badge.fill",
                title: "AI Assistant",
                description: "Smart chatbot for game day help",
                color: "purple"
            ),
            PremiumFeatureDescription(
                icon: "person.3.fill",
                title: "Real-Time Crowds",
                description: "Live gate & transit crowd data",
                color: "orange"
            ),
            PremiumFeatureDescription(
                icon: "safari",
                title: "AR Indoor Compass",
                description: "Navigate inside the stadium",
                color: "green"
            ),
            PremiumFeatureDescription(
                icon: "parkingsign.circle.fill",
                title: "Parking Optimization",
                description: "Find best parking spots",
                color: "indigo"
            ),
            PremiumFeatureDescription(
                icon: "bell.badge.fill",
                title: "Priority Notifications",
                description: "Never miss important updates",
                color: "red"
            )
        ]
    }
}

// MARK: - Supporting Types

enum PremiumFeature {
    case unlimitedSchedules
    case aiChatbot
    case realTimeCrowdData
    case indoorCompass
    case parkingOptimization
}

struct PremiumFeatureDescription: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let color: String
}
