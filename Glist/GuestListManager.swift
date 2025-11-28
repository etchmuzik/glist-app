import SwiftUI
import Combine


struct GuestListRequest: Identifiable, Codable, Sendable {
    let id: UUID
    let userId: String
    let venueId: String
    let venueName: String
    let name: String
    let email: String
    let date: Date
    let guestCount: Int
    let guestNames: [String] // Added guestNames
    let status: String // "Pending", "Confirmed", "Rejected"
    let qrCodeId: String?
}

@MainActor
class GuestListManager: ObservableObject {
    @Published var requests: [GuestListRequest] = []
    @Published var isLoading = false
    
    private var currentUserId: String?
    
    func fetchRequests(userId: String) {
        currentUserId = userId
        isLoading = true
        
        Task {
            do {
                let fetchedRequests = try await SupabaseDataManager.shared.fetchUserGuestListRequests(userId: userId)
                DispatchQueue.main.async {
                    self.requests = fetchedRequests
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    print("Error fetching guest lists: \(error)")
                    self.isLoading = false
                }
            }
        }
    }
    
    func clearRequests() {
        requests = []
    }
    
    func addRequest(userId: String, venueId: String, venueName: String, name: String, email: String, date: Date, guestCount: Int, guestNames: [String]) async throws {
        let newRequest = GuestListRequest(
            id: UUID(),
            userId: userId,
            venueId: venueId,
            venueName: venueName,
            name: name,
            email: email,
            date: date,
            guestCount: guestCount,
            guestNames: guestNames,
            status: "Pending",
            qrCodeId: UUID().uuidString
        )
        
        // Save to Supabase
        try await SupabaseDataManager.shared.submitGuestListRequest(newRequest)
        
        // Refresh requests
        fetchRequests(userId: userId)
        
        // Log Activity
        SocialManager.shared.logActivity(
            userId: userId,
            type: .guestList,
            title: "Joined Guest List",
            subtitle: "at \(venueName)",
            relatedId: venueId
        )
    }
}

