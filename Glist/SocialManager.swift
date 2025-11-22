import Foundation
import SwiftUI
import Combine
import FirebaseFirestore

class SocialManager: ObservableObject {
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
}
