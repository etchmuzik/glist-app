import Foundation
import SwiftUI
import Combine
import FirebaseFirestore

class SocialManager: ObservableObject {
    static let shared = SocialManager()
    @Published var followingUsers: [User] = []
    @Published var followerUsers: [User] = []
    @Published var searchResults: [User] = []
    @Published var friendsAtVenues: [String: [User]] = [:]
    @Published var isLoading = false
    
    private let db = FirestoreManager.shared.db
    
    // MARK: - Follow System
    
    func followUser(currentUserId: String, targetUserId: String) async throws {
        // Add target to current user's following
        try await db.collection("users").document(currentUserId).updateData([
            "following": FieldValue.arrayUnion([targetUserId])
        ])
        
        // Add current user to target's followers
        try await db.collection("users").document(targetUserId).updateData([
            "followers": FieldValue.arrayUnion([currentUserId])
        ])
        
        // Refresh local data if needed
    }
    
    func unfollowUser(currentUserId: String, targetUserId: String) async throws {
        try await db.collection("users").document(currentUserId).updateData([
            "following": FieldValue.arrayRemove([targetUserId])
        ])
        
        try await db.collection("users").document(targetUserId).updateData([
            "followers": FieldValue.arrayRemove([currentUserId])
        ])
    }
    
    // MARK: - Search
    
    func searchUsers(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isLoading = true
        
        Task {
            do {
                let snapshot = try await db.collection("users")
                    .whereField("name", isGreaterThanOrEqualTo: query)
                    .whereField("name", isLessThan: query + "z")
                    .limit(to: 10)
                    .getDocuments()
                
                var users: [User] = []
                for doc in snapshot.documents {
                    if let user = try await FirestoreManager.shared.fetchUser(userId: doc.documentID) {
                        users.append(user)
                    }
                }
                
                await MainActor.run {
                    self.searchResults = users
                    self.isLoading = false
                }
            } catch {
                print("Search error: \(error)")
                await MainActor.run { self.isLoading = false }
            }
        }
    }
    
    // MARK: - Who's Going
    
    func getFriendsAt(venueId: String) -> [User] {
        return friendsAtVenues[venueId] ?? []
    }
    
    // Backward compatibility property
    var friendsAtVenue: [User] {
        return []
    }
    
    func fetchFriendsGoing(venueId: String, currentUserFollowing: [String]) async {
        guard !currentUserFollowing.isEmpty else { return }
        
        do {
            // 1. Get bookings for this venue
            let bookingsSnapshot = try await db.collection("bookings")
                .whereField("venueId", isEqualTo: venueId)
                .whereField("date", isGreaterThan: Date())
                .getDocuments()
            
            let bookingUserIds = Set(bookingsSnapshot.documents.compactMap { $0.data()["userId"] as? String })
            
            // 2. Get guest list requests for this venue
            let guestListSnapshot = try await db.collection("guestListRequests")
                .whereField("venueId", isEqualTo: venueId)
                .whereField("date", isGreaterThan: Date())
                .getDocuments()
            
            let guestListUserIds = Set(guestListSnapshot.documents.compactMap { $0.data()["userId"] as? String })
            
            // Combine all user IDs
            let allUserIds = bookingUserIds.union(guestListUserIds)
            
            // Filter for friends
            let friendsGoingIds = allUserIds.intersection(currentUserFollowing)
            
            // Fetch user details for these friends
            var friends: [User] = []
            for userId in friendsGoingIds {
                if let user = try await FirestoreManager.shared.fetchUser(userId: userId) {
                    // Check privacy
                    if !user.isPrivate {
                        friends.append(user)
                    }
                }
            }
            
            await MainActor.run {
                self.friendsAtVenues[venueId] = friends
            }
            
        } catch {
            print("Error fetching friends going: \(error)")
        }
    }
    // MARK: - Friend Requests
    
    func sendFriendRequest(currentUserId: String, targetUser: User) async throws {
        if targetUser.isPrivate {
            let request = FriendRequest(
                fromUserId: currentUserId,
                toUserId: targetUser.id,
                status: .pending,
                createdAt: Date()
            )
            try await db.collection("friend_requests").addDocument(from: request)
        } else {
            try await followUser(currentUserId: currentUserId, targetUserId: targetUser.id)
        }
    }
    
    func fetchPendingRequests(for userId: String) async throws -> [FriendRequest] {
        let snapshot = try await db.collection("friend_requests")
            .whereField("toUserId", isEqualTo: userId)
            .whereField("status", isEqualTo: RequestStatus.pending.rawValue)
            .getDocuments()
        
        return try snapshot.documents.compactMap { try $0.data(as: FriendRequest.self) }
    }
    
    func acceptRequest(_ request: FriendRequest) async throws {
        // 1. Perform the follow (bi-directional or uni-directional depending on app logic, assuming uni-directional follow here but approved)
        try await followUser(currentUserId: request.fromUserId, targetUserId: request.toUserId)
        
        // 2. Update request status
        if let id = request.id {
            try await db.collection("friend_requests").document(id).updateData(["status": RequestStatus.accepted.rawValue])
        }
    }
    
    func declineRequest(_ request: FriendRequest) async throws {
        if let id = request.id {
            try await db.collection("friend_requests").document(id).updateData(["status": RequestStatus.declined.rawValue])
        }
    }
    
    // MARK: - Activity Feed
    
    func logActivity(userId: String, type: ActivityType, title: String, subtitle: String, relatedId: String?) {
        let activity = ActivityItem(
            userId: userId,
            type: type,
            title: title,
            subtitle: subtitle,
            relatedId: relatedId,
            timestamp: Date()
        )
        try? db.collection("activities").addDocument(from: activity)
    }
    
    func fetchActivityFeed(followingUserIds: [String]) async throws -> [ActivityItem] {
        guard !followingUserIds.isEmpty else { return [] }
        
        // Firestore 'in' query is limited to 10 items. For real apps, we'd use a different approach (fan-out or multiple queries).
        // For now, we'll just fetch recent activities and filter in memory or limit to first 10 friends.
        
        let snapshot = try await db.collection("activities")
            .whereField("userId", in: Array(followingUserIds.prefix(10)))
            .order(by: "timestamp", descending: true)
            .limit(to: 20)
            .getDocuments()
            
        return try snapshot.documents.compactMap { try $0.data(as: ActivityItem.self) }
    }
}

// MARK: - Models

struct FriendRequest: Identifiable, Codable {
    @DocumentID var id: String?
    let fromUserId: String
    let toUserId: String
    let status: RequestStatus
    let createdAt: Date
}

enum RequestStatus: String, Codable {
    case pending, accepted, declined
}

struct ActivityItem: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let type: ActivityType
    let title: String
    let subtitle: String
    let relatedId: String? // e.g., venueId
    let timestamp: Date
}

enum ActivityType: String, Codable {
    case booking
    case guestList
    case review
    case follow
}
