import Foundation
import Supabase

// MARK: - Helper Structs


final class SupabaseDataManager {
    static let shared = SupabaseDataManager()
    let client = SupabaseManager.shared.client
    
    private let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    // MARK: - User Management
    
    @available(*, deprecated, message: "User creation is now handled by database trigger")
    func createUser(_ user: User) async throws {
        let userData: [String: GlistAnyEncodable] = [
            "id": GlistAnyEncodable(user.id),
            "email": GlistAnyEncodable(user.email),
            "name": GlistAnyEncodable(user.name),
            "role": GlistAnyEncodable(user.role.rawValue),
            "created_at": GlistAnyEncodable(iso8601Formatter.string(from: user.createdAt)),
            "favorite_venue_ids": GlistAnyEncodable(user.favoriteVenueIds),
            "fcm_token": GlistAnyEncodable(user.fcmToken),
            "notification_preferences": GlistAnyEncodable([
                "guestListUpdates": user.notificationPreferences.guestListUpdates,
                "newVenues": user.notificationPreferences.newVenues,
                "promotions": user.notificationPreferences.promotions
            ]),
            "reward_points": GlistAnyEncodable(user.rewardPoints),
            "no_show_count": GlistAnyEncodable(user.noShowCount),
            "is_banned": GlistAnyEncodable(user.isBanned),
            "referral_code": GlistAnyEncodable(user.referralCode),
            "lifetime_points": GlistAnyEncodable(user.lifetimePoints)
        ]
        
        try await client.database.from("users").insert(userData).execute()
    }
    
    func fetchUser(userId: String) async throws -> User? {
        let query = client.database.from("users").select().eq("id", value: userId).single()
        do {
            let user: User = try await query.execute().value
            return user
        } catch {
            // PGRST116 is "The result contains 0 rows" when using .single().
            // This is expected when checking if a user exists.
            if let postgrestError = error as? PostgrestError, postgrestError.code == "PGRST116" {
                return nil
            }
            print("Error fetching user: \(error)")
            return nil
        }
    }
    
    func fetchAllUsers(limit: Int = 100) async throws -> [User] {
        let query = client.database.from("users")
            .select()
            .order("created_at", ascending: false)
            .limit(limit)
            
        return try await query.execute().value
    }
    
    func searchUsers(query: String) async throws -> [User] {
        let dbQuery = client.database.from("users")
            .select()
            .ilike("name", pattern: "\(query)%")
            .limit(20)
            
        return try await dbQuery.execute().value
    }
    
    func banUser(userId: String) async throws {
        try await updateUser(userId: userId, data: ["is_banned": GlistAnyEncodable(true)])
    }
    
    func unbanUser(userId: String) async throws {
        try await updateUser(userId: userId, data: ["is_banned": GlistAnyEncodable(false)])
    }
    
    func updateUser(userId: String, data: [String: GlistAnyEncodable]) async throws {
        try await client.database.from("users").update(data).eq("id", value: userId).execute()
    }
    
    func updateFCMToken(userId: String, token: String) async throws {
        try await updateUser(userId: userId, data: ["fcm_token": GlistAnyEncodable(token)])
    }
    
    // MARK: - Venue Management
    
    func fetchVenues() async throws -> [Venue] {
        let query = client.database.from("venues")
            .select()
            .eq("is_active", value: true)
            
        return try await query.execute().value
    }
    
    func fetchVenuesForManager(userId: String) async throws -> [Venue] {
        let query = client.database.from("venues")
            .select()
            .contains("manager_ids", value: "{\(userId)}")
            .eq("is_active", value: true)
            
        return try await query.execute().value
    }
    
    func createVenue(_ venue: Venue) async throws {
        try await client.database.from("venues").insert(venue).execute()
    }

    func updateVenue(_ venueId: String, venue: Venue) async throws {
        try await client.database.from("venues").update(venue).eq("id", value: venueId).execute()
    }
    
    func deleteVenue(venueId: String) async throws {
        try await client.database.from("venues").delete().eq("id", value: venueId).execute()
    }
    
    func deleteAllVenues() async throws {
        // Delete all venues where is_active is true or false (all rows)
        // We use a condition that is always true or simply don't filter if RLS allows
        try await client.database.from("venues").delete().neq("id", value: "00000000-0000-0000-0000-000000000000").execute()
    }
    
    // MARK: - Guest List Management
    
    func submitGuestListRequest(_ request: GuestListRequest) async throws {
        try await client.database.from("guest_list_requests").insert(request).execute()
    }
    
    func fetchUserGuestListRequests(userId: String) async throws -> [GuestListRequest] {
        let query = client.database.from("guest_list_requests")
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            
        return try await query.execute().value
    }
    
    func fetchAllGuestListRequests() async throws -> [GuestListRequest] {
        let query = client.database.from("guest_list_requests")
            .select()
            .order("created_at", ascending: false)
            
        return try await query.execute().value
    }
    
    func fetchGuestListRequests(forVenueIds venueIds: [String]) async throws -> [GuestListRequest] {
        guard !venueIds.isEmpty else { return [] }
        
        let query = client.database.from("guest_list_requests")
            .select()
            .in("venue_id", values: venueIds)
            .order("created_at", ascending: false)
            
        return try await query.execute().value
    }
    
    func updateGuestListStatus(requestId: String, status: String) async throws {
        let updates: [String: GlistAnyEncodable] = [
            "status": GlistAnyEncodable(status),
            "updated_at": GlistAnyEncodable(Date())
        ]
        try await client.database.from("guest_list_requests")
            .update(updates)
            .eq("id", value: requestId)
            .execute()
    }
    
    // MARK: - Favorites
    
    func updateFavorites(userId: String, venueIds: [String]) async throws {
        try await client.database.from("users")
            .update(["favorite_venue_ids": venueIds])
            .eq("id", value: userId)
            .execute()
    }
    
    // MARK: - Referral System
    
    func checkReferralCode(code: String) async throws -> String? {
        let params: [String: String] = ["code": code]
        do {
            let result: String? = try await client.database.rpc("check_referral_code", params: params).execute().value
            return result
        } catch {
            print("Error checking referral code: \(error)")
            return nil
        }
    }
    
    func processReferral(newUserId: String, referrerId: String) async throws {
        let params: [String: GlistAnyEncodable] = [
            "new_user_id": GlistAnyEncodable(newUserId),
            "referrer_id": GlistAnyEncodable(referrerId)
        ]
        try await client.database.rpc("process_referral", params: params).execute()
    }
    
    // MARK: - KYC
    
    func submitKYC(_ submission: KYCSubmission) async throws {
        try await client.database.from("kyc_submissions").insert(submission).execute()
        try await updateUser(userId: submission.userId, data: ["kyc_status": GlistAnyEncodable(KYCStatus.pending.rawValue)])
    }
    
    func fetchKYCSubmissions(status: KYCStatus? = nil, limit: Int = 50) async throws -> [KYCSubmission] {
        var query = client.database.from("kyc_submissions")
            .select()
        
        if let status = status {
            query = query.eq("status", value: status.rawValue)
        }
        
        return try await query
            .order("submitted_at", ascending: false)
            .limit(limit)
            .execute()
            .value
    }
    
    func updateKYCSubmissionStatus(submissionId: String, userId: String, status: KYCStatus, reviewerId: String?, notes: String? = nil) async throws {
        let updates: [String: GlistAnyEncodable] = [
            "status": GlistAnyEncodable(status.rawValue),
            "reviewed_by": GlistAnyEncodable(reviewerId),
            "reviewed_at": GlistAnyEncodable(Date()),
            "notes": GlistAnyEncodable(notes)
        ]
        
        try await client.database.from("kyc_submissions").update(updates).eq("id", value: submissionId).execute()
        try await updateUser(userId: userId, data: ["kyc_status": GlistAnyEncodable(status.rawValue)])
        
        let event = SafetyEvent(
            type: .kycStatusChange,
            userId: userId,
            previousValue: nil,
            newValue: status.rawValue,
            metadata: ["source": "admin_review", "submissionId": submissionId]
        )
        try await logSafetyEvent(event)
    }
    
    // MARK: - Rewards & Bans
    
    func addRewardPoints(userId: String, points: Int) async throws {
        let params: [String: GlistAnyEncodable] = [
            "user_id": GlistAnyEncodable(userId),
            "points": GlistAnyEncodable(points)
        ]
        try await client.database.rpc("add_reward_points", params: params).execute()
    }
    
    func incrementNoShowCount(userId: String) async throws {
        let params: [String: GlistAnyEncodable] = [
            "user_id_param": GlistAnyEncodable(userId)
        ]
        try await client.database.rpc("increment_no_show_count", params: params).execute()
    }
    
    // MARK: - Streak System
    
    func updateStreak(userId: String) async throws {
        let params: [String: GlistAnyEncodable] = [
            "user_id_param": GlistAnyEncodable(userId)
        ]
        try await client.database.rpc("update_streak", params: params).execute()
    }
    
    // MARK: - Table Bookings
    
    func createBooking(_ booking: Booking) async throws {
        try await client.database.from("bookings").insert(booking).execute()
    }
    
    func fetchUserBookings(userId: String) async throws -> [Booking] {
        let query = client.database.from("bookings")
            .select()
            .eq("user_id", value: userId)
            .order("date", ascending: false)
            
        return try await query.execute().value
    }
    
    func fetchAllBookings() async throws -> [Booking] {
        let query = client.database.from("bookings")
            .select()
            .order("date", ascending: false)
            
        return try await query.execute().value
    }
    
    // MARK: - Safety Event Logging
    
    func logSafetyEvent(_ event: SafetyEvent) async throws {
        try await client.database.from("safety_events").insert(event).execute()
    }
    
    // MARK: - Account Management
    
    func deleteUser(userId: String) async throws {
        try await client.database.from("users").delete().eq("id", value: userId).execute()
    }
    
    func updateProfileImage(userId: String, imageUrl: String) async throws {
        try await updateUser(userId: userId, data: ["profile_image": GlistAnyEncodable(imageUrl)])
    }
    
    // MARK: - Notification Preferences
    func updateNotificationPreferences(userId: String, data: [String: Any]) async throws {
        // Prefer using the strongly-typed struct to avoid partial JSON updates and actor isolation issues.
        // TODO: Remove this overload if not needed.
        guard let guestListUpdates = data["guestListUpdates"] as? Bool,
              let newVenues = data["newVenues"] as? Bool,
              let promotions = data["promotions"] as? Bool else {
            // If keys are missing or types mismatch, do nothing.
            return
        }
        let preferences = NotificationPreferences(guestListUpdates: guestListUpdates, newVenues: newVenues, promotions: promotions)
        try await updateNotificationPreferences(userId: userId, preferences: preferences)
    }
    
    func updateNotificationPreferences(userId: String, preferences: NotificationPreferences) async throws {
        let preferencesDict: [String: Bool] = [
            "guestListUpdates": preferences.guestListUpdates,
            "newVenues": preferences.newVenues,
            "promotions": preferences.promotions
        ]
        try await updateUser(userId: userId, data: ["notification_preferences": GlistAnyEncodable(preferencesDict)])
    }
    
    // MARK: - Resale
    
    func publishResaleOffer(ticket: EventTicket, offer: ResaleOffer) async throws {
        // Insert the resale offer
        try await client.database.from("resale_offers").insert(offer).execute()
        
        // Optionally update the ticket status to 'resale_pending' if that status exists
        // try await client.database.from("tickets").update(["status": "resale_pending"]).eq("id", value: ticket.id).execute()
    }
    
    // MARK: - Tickets
    
    func createTicket(_ ticket: EventTicket) async throws {
        try await client.database.from("tickets").insert(ticket).execute()
    }
    
    func fetchUserTickets(userId: String) async throws -> [EventTicket] {
        let query = client.database.from("tickets")
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            
        return try await query.execute().value
    }

    func fetchAllTickets() async throws -> [EventTicket] {
        let query = client.database.from("tickets")
            .select()
            .order("created_at", ascending: false)
            
        return try await query.execute().value
    }
    
    func purchaseResaleTicket(ticketId: String, buyerId: String, price: Double) async throws {
        let params: [String: GlistAnyEncodable] = [
            "ticket_id": GlistAnyEncodable(ticketId),
            "buyer_id": GlistAnyEncodable(buyerId),
            "price": GlistAnyEncodable(price)
        ]
        try await client.database.rpc("purchase_resale_ticket", params: params).execute()
    }
    
    func fetchResaleTickets() async throws -> [EventTicket] {
        let query = client.database.from("tickets")
            .select()
            .not("resale_price", operator: .is, value: "null") // Check if resale_price is not null
            .eq("status", value: "valid") // Ensure ticket is valid
            .order("created_at", ascending: false)
            
        return try await query.execute().value
    }
}

