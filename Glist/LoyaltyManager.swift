import Foundation
import Combine

class LoyaltyManager: ObservableObject {
    static let shared = LoyaltyManager()
    
    // Points Constants
    static let pointsPerBooking = 100
    static let pointsPerTicket = 50
    static let pointsPerReferral = 500
    static let pointsPerReferralSignup = 200
    static let pointsPerStreakWeek = 50
    
    // Tier Thresholds (Lifetime Points)
    static let vipThreshold = 1000
    static let memberThreshold = 5000
    
    @Published var activeCampaigns: [Campaign] = []
    
    struct Campaign: Identifiable {
        let id = UUID()
        let title: String
        let message: String
        let type: CampaignType
    }
    
    enum CampaignType {
        case birthday
        case anniversary
        case lapsed
        case eventDay
        case streak
    }
    
    func calculateTier(lifetimePoints: Int) -> UserTier {
        if lifetimePoints >= LoyaltyManager.memberThreshold {
            return .member
        } else if lifetimePoints >= LoyaltyManager.vipThreshold {
            return .vip
        } else {
            return .standard
        }
    }
    
    func checkCampaigns(for user: User) -> [Campaign] {
        var campaigns: [Campaign] = []
        let calendar = Calendar.current
        let today = Date()
        
        // Birthday Campaign
        if let dob = user.dateOfBirth {
            let dobComponents = calendar.dateComponents([.month, .day], from: dob)
            let todayComponents = calendar.dateComponents([.month, .day], from: today)
            if dobComponents.month == todayComponents.month && dobComponents.day == todayComponents.day {
                campaigns.append(Campaign(title: "Happy Birthday! 🎂", message: "Enjoy double points on all bookings today!", type: .birthday))
            }
        }
        
        // Anniversary Campaign (Member since)
        let joinComponents = calendar.dateComponents([.month, .day], from: user.createdAt)
        let todayComponents = calendar.dateComponents([.month, .day], from: today)
        if joinComponents.month == todayComponents.month && joinComponents.day == todayComponents.day && !calendar.isDate(user.createdAt, inSameDayAs: today) {
             campaigns.append(Campaign(title: "Happy Anniversary! 🎉", message: "Thanks for being with us another year. Here's a special offer for you.", type: .anniversary))
        }
        
        // Lapsed User Campaign
        if let lastVisit = user.lastVisitDate {
            let daysSinceVisit = calendar.dateComponents([.day], from: lastVisit, to: today).day ?? 0
            if daysSinceVisit > 30 {
                campaigns.append(Campaign(title: "We Miss You! 👋", message: "Come back and get 10% off your next booking.", type: .lapsed))
            }
        }
        
        // Streak Campaign
        if user.currentStreak > 0 && user.currentStreak % 4 == 0 { // Every 4 weeks/visits
             campaigns.append(Campaign(title: "Streak on Fire! 🔥", message: "You've visited \(user.currentStreak) weeks in a row! Claim your reward.", type: .streak))
        }
        
        return campaigns
    }
    
    struct Reward: Identifiable {
        let id = UUID()
        let title: String
        let description: String
        let cost: Int
        let icon: String
    }
    
    let availableRewards: [Reward] = [
        Reward(title: "Free Drink", description: "Redeem for a house beverage", cost: 500, icon: "wineglass.fill"),
        Reward(title: "Skip the Line", description: "Priority entry for you and a guest", cost: 1000, icon: "figure.walk.motion"),
        Reward(title: "Table Upgrade", description: "Upgrade to next tier table (subject to availability)", cost: 2500, icon: "arrow.up.circle.fill"),
        Reward(title: "Valet Parking", description: "Free valet parking", cost: 300, icon: "car.fill")
    ]
    
    func redeemPoints(user: User, reward: Reward) async throws {
        guard user.rewardPoints >= reward.cost else {
            throw NSError(domain: "LoyaltyError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Insufficient points"])
        }
        
        // Deduct points
        try await FirestoreManager.shared.addRewardPoints(userId: user.id, points: -reward.cost)
        
        // In a real app, we would create a "Redemption" record in Firestore
        // For now, we just deduct points
    }
    
    func getPerks(for tier: UserTier) -> [String] {
        switch tier {
        case .standard:
            return ["Earn Points on Bookings", "Birthday Rewards"]
        case .vip:
            return ["1.5x Points Multiplier", "Priority Booking", "No Cover Charge", "Birthday Rewards"]
        case .member:
            return ["2x Points Multiplier", "Concierge Service", "Exclusive Events", "Free VIP Entry", "Birthday Rewards"]
        }
    }
}
