import Foundation
import SwiftUI

class InviteManager: ObservableObject {
    @Published var inviteCode: String = ""
    @Published var inviteCount: Int = 0
    @Published var showShareSheet = false
    
    func generateInviteCode(userId: String) {
        // Generate a unique invite code based on user ID
        let code = String(userId.prefix(8).uppercased())
        inviteCode = code
    }
    
    func getInviteMessage() -> String {
        return """
        🌟 Join me on LSTD - Dubai's #1 Nightlife App!
        
        Get exclusive access to:
        ✨ VIP table bookings
        🎫 Event tickets
        👥 See where your friends are going
        🗺️ Discover the hottest venues
        
        Use my code: \(inviteCode)
        
        Download now: https://glist.app/invite/\(inviteCode)
        """
    }
    
    func trackInvite(userId: String) async throws {
        // In a real app, this would track the invite in Firestore
        // and potentially reward the user with perks
        await MainActor.run {
            inviteCount += 1
        }
    }
    
    func redeemInviteCode(_ code: String, userId: String) async throws {
        // Validate and redeem invite code
        // In a real app, this would:
        // 1. Check if code is valid
        // 2. Link the new user to the inviter
        // 3. Grant rewards to both users
        print("Redeeming invite code: \(code) for user: \(userId)")
    }
}
