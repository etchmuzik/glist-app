import Foundation
import Combine

enum ActivityType: String, Codable, CaseIterable, Sendable {
    case booking
    case guestList
    case review
    case follow
}

struct ActivityItem: Identifiable, Codable, Sendable {
    var id = UUID()
    let userId: String
    let title: String
    let subtitle: String
    let type: ActivityType
    let timestamp: Date
}

struct FriendRequest: Identifiable, Codable, Hashable, Sendable {
    var id = UUID()
    let fromUserId: String
    let toUserId: String
    var status: String = "pending"
    var createdAt: Date = Date()
}

/// Lightweight social manager placeholder to keep social flows compiling.
/// In production, these methods should be backed by Firestore collections.
@MainActor
final class SocialManager: ObservableObject {
    static let shared = SocialManager()
    
    @Published var searchResults: [User] = []
    @Published var demoMode: Bool = true
    
    private var cachedActivities: [ActivityItem] = []
    private var pendingRequests: [FriendRequest] = []
    private var friendsByVenue: [String: [User]] = [:]
    private var demoSeeded = false
    private var demoRequestsSeeded = false
    private let demoUsers: [String: User] = {
        let now = Date()
        let baseFavorites: [String] = []
        return [
            "demo-friend-1": User(id: "demo-friend-1", email: "laila@example.com", name: "Laila Khalid", role: .user, createdAt: now, favoriteVenueIds: baseFavorites, profileImage: "https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=400&q=80", referralCode: "LAILA01"),
            "demo-friend-2": User(id: "demo-friend-2", email: "omid@example.com", name: "Omid Rahman", role: .user, createdAt: now, favoriteVenueIds: baseFavorites, profileImage: "https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=400&q=80", referralCode: "OMID02"),
            "demo-friend-3": User(id: "demo-friend-3", email: "sara@example.com", name: "Sara Al Mansoori", role: .user, createdAt: now, favoriteVenueIds: baseFavorites, profileImage: "https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=400&q=80", referralCode: "SARA03")
        ]
    }()
    
    init() {}
    
    // MARK: - Activity Feed
    
    func logActivity(userId: String, type: ActivityType, title: String, subtitle: String, relatedId: String? = nil) {
        let item = ActivityItem(userId: userId, title: title, subtitle: subtitle, type: type, timestamp: Date())
        cachedActivities.append(item)
    }
    
    func fetchActivityFeed(followingUserIds: [String]) async throws -> [ActivityItem] {
        let feed = cachedActivities
            .filter { followingUserIds.contains($0.userId) }
            .sorted { $0.timestamp > $1.timestamp }
        return feed
    }

    /// Demo feed fallback for empty states.
    func demoActivities(currentUserId: String) -> [ActivityItem] {
        guard demoMode else { return [] }
        if !demoSeeded {
            cachedActivities.append(contentsOf: [
                ActivityItem(userId: currentUserId, title: "Booked a table", subtitle: "at Soho Garden", type: .booking, timestamp: Date().addingTimeInterval(-3600)),
                ActivityItem(userId: currentUserId, title: "Joined guest list", subtitle: "for 1 OAK Dubai", type: .guestList, timestamp: Date().addingTimeInterval(-7200)),
                ActivityItem(userId: currentUserId, title: "Left a review", subtitle: "for White Dubai", type: .review, timestamp: Date().addingTimeInterval(-10800)),
                ActivityItem(userId: currentUserId, title: "Followed", subtitle: "BLU Dubai", type: .follow, timestamp: Date().addingTimeInterval(-14400))
            ])
            demoSeeded = true
        }
        return cachedActivities.sorted { $0.timestamp > $1.timestamp }
    }

    /// Convenience to seed all demo data at once.
    func seedDemoDataIfNeeded(currentUserId: String) {
        guard demoMode else { return }
        _ = demoActivities(currentUserId: currentUserId)
        _ = demoFriendRequests(currentUserId: currentUserId)
    }
    
    // MARK: - Friend Requests
    
    func fetchPendingRequests(for userId: String) async throws -> [FriendRequest] {
        pendingRequests.filter { $0.toUserId == userId && $0.status == "pending" }
    }
    
    func sendFriendRequest(currentUserId: String, targetUser: User) async throws {
        // Avoid duplicates
        if pendingRequests.contains(where: { $0.fromUserId == currentUserId && $0.toUserId == targetUser.id }) { return }
        pendingRequests.append(FriendRequest(fromUserId: currentUserId, toUserId: targetUser.id))
    }
    
    func acceptRequest(_ request: FriendRequest) async throws {
        updateRequest(request, status: "accepted")
    }
    
    func declineRequest(_ request: FriendRequest) async throws {
        updateRequest(request, status: "declined")
    }
    
    private func updateRequest(_ request: FriendRequest, status: String) {
        if let idx = pendingRequests.firstIndex(of: request) {
            pendingRequests[idx].status = status
        }
    }
    
    func unfollowUser(currentUserId: String, targetUserId: String) async throws {
        // Placeholder: no-op for now.
    }

    /// Demo friend requests fallback for empty states.
    func demoFriendRequests(currentUserId: String) -> [FriendRequest] {
        guard demoMode else { return [] }
        if !demoRequestsSeeded {
            pendingRequests.append(contentsOf: [
                FriendRequest(fromUserId: "demo-friend-1", toUserId: currentUserId),
                FriendRequest(fromUserId: "demo-friend-2", toUserId: currentUserId)
            ])
            demoRequestsSeeded = true
        }
        return pendingRequests.filter { $0.toUserId == currentUserId && $0.status == "pending" }
    }

    func demoUser(for id: String) -> User? {
        demoUsers[id]
    }
    
    // MARK: - Search
    
    func searchUsers(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        Task {
            // In a full implementation, perform Firestore query. Here we return empty to keep UI responsive.
            await MainActor.run {
                self.searchResults = []
            }
        }
    }
    
    // MARK: - Venue Friends
    
    func fetchFriendsGoing(venueId: String, currentUserFollowing: [String]) async {
        // Placeholder: no-op; in production, query attendance for following users.
        friendsByVenue[venueId] = []
    }
    
    func getFriendsAt(venueId: String) -> [User] {
        friendsByVenue[venueId] ?? []
    }
}
