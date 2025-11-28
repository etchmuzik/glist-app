import Foundation
import SwiftUI
import Combine
import Supabase

@MainActor
class PromoterManager: ObservableObject {
    @Published var promoter: Promoter?
    @Published var commissions: [Commission] = []
    @Published var guestLists: [GuestListRequest] = []
    @Published var isLoading = false
    @Published var totalEarnings: Double = 0
    @Published var pendingEarnings: Double = 0
    
    private let client = SupabaseManager.shared.client
    
    func fetchPromoterData(userId: String) async {
        isLoading = true
        
        do {
            // Fetch promoter profile
            if let promoterData = try await fetchPromoter(userId: userId) {
                await MainActor.run {
                    self.promoter = promoterData
                }
                
                // Fetch commissions
                try await fetchCommissions(promoterId: promoterData.id)
                
                // Fetch guest lists
                try await fetchPromoterGuestLists(promoterId: promoterData.id)
                
                // Calculate earnings
                await calculateEarnings()
            }
            
            await MainActor.run {
                isLoading = false
            }
        } catch {
            print("Error fetching promoter data: \(error)")
            await MainActor.run {
                isLoading = false
            }
        }
    }

    func fetchAllCommissions(limit: Int = 100) async {
        isLoading = true
        do {
            let fetchedCommissions: [Commission] = try await client
                .from("commissions")
                .select()
                .order("date", ascending: false)
                .limit(limit)
                .execute()
                .value
            
            await MainActor.run {
                self.commissions = fetchedCommissions
                self.isLoading = false
            }
        } catch {
            print("Error fetching all commissions: \(error)")
            await MainActor.run { self.isLoading = false }
        }
    }
    
    func updateReputation(promoterId: String, newScore: Int, venueId: String? = nil, reason: String = "manual_adjust") async throws {
        try await client
            .from("promoters")
            .update(["reputation_score": newScore])
            .eq("id", value: promoterId)
            .execute()
        
        let event = SafetyEvent(
            type: .promoterReputationChange,
            userId: nil,
            promoterId: promoterId,
            venueId: venueId,
            previousValue: "\(promoter?.reputationScore ?? 0)",
            newValue: "\(newScore)",
            metadata: ["reason": reason]
        )
        try await SupabaseDataManager.shared.logSafetyEvent(event)
        
        if promoter?.id == promoterId {
            await MainActor.run {
                self.promoter?.reputationScore = newScore
            }
        }
    }

    private func fetchPromoter(userId: String) async throws -> Promoter? {
        let promoters: [Promoter] = try await client
            .from("promoters")
            .select()
            .eq("user_id", value: userId)
            .execute()
            .value
        
        return promoters.first
    }
    
    private func fetchCommissions(promoterId: String) async throws {
        let fetchedCommissions: [Commission] = try await client
            .from("commissions")
            .select()
            .eq("promoter_id", value: promoterId)
            .order("date", ascending: false)
            .limit(50)
            .execute()
            .value
        
        await MainActor.run {
            self.commissions = fetchedCommissions
        }
    }
    
    private func fetchPromoterGuestLists(promoterId: String) async throws {
        let fetchedLists: [GuestListRequest] = try await client
            .from("guest_list_requests")
            .select()
            .eq("promoter_id", value: promoterId)
            .gt("date", value: Date())
            .order("date", ascending: true)
            .execute()
            .value
        
        await MainActor.run {
            self.guestLists = fetchedLists
        }
    }
    
    private func calculateEarnings() async {
        let total = commissions.filter { $0.status == .paid }.reduce(0) { $0 + $1.amount }
        let pending = commissions.filter { $0.status == .pending }.reduce(0) { $0 + $1.amount }
        
        await MainActor.run {
            self.totalEarnings = total
            self.pendingEarnings = pending
        }
    }
    
    func createCommission(for booking: Booking, promoterId: String, promoterName: String) async throws {
        guard let promoter = self.promoter else { return }
        
        let commissionAmount = booking.depositAmount * promoter.commissionRate
        
        let commission = Commission(
            promoterId: promoterId,
            promoterName: promoterName,
            bookingId: booking.id.uuidString,
            venueName: booking.venueName,
            amount: commissionAmount,
            status: .pending
        )
        
        try await client.from("commissions").insert(commission).execute()
    }

    func markCommissionPaid(_ commissionId: String, method: PayoutMethod, amount: Double, notes: String? = nil) async throws {
        let payout = CommissionPayout(method: method, amount: amount, status: .processing, notes: notes)
        
        // We need to update both status and payout field.
        // Since payout is a struct, we might need to encode it or pass it as a dictionary if Supabase expects JSONB.
        // Assuming Supabase handles Codable struct to JSONB conversion:
        
        let payload = UpdatePayload(status: .paid, payout: payout)
        
        try await client
            .from("commissions")
            .update(payload)
            .eq("id", value: commissionId)
            .execute()
    }
}

private struct UpdatePayload: Encodable, Sendable {
    let status: CommissionStatus
    let payout: CommissionPayout
}
