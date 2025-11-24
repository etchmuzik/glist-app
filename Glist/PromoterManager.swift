import Foundation
import SwiftUI
import Combine
import FirebaseFirestore

class PromoterManager: ObservableObject {
    @Published var promoter: Promoter?
    @Published var commissions: [Commission] = []
    @Published var guestLists: [GuestListRequest] = []
    @Published var isLoading = false
    @Published var totalEarnings: Double = 0
    @Published var pendingEarnings: Double = 0
    
    private let db = FirestoreManager.shared.db
    
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
    
    func updateReputation(promoterId: String, newScore: Int, venueId: String? = nil, reason: String = "manual_adjust") async throws {
        let promoterRef = db.collection("promoters").document(promoterId)
        try await promoterRef.updateData(["reputationScore": newScore])
        
        let event = SafetyEvent(
            type: .promoterReputationChange,
            userId: nil,
            promoterId: promoterId,
            venueId: venueId,
            previousValue: "\(promoter?.reputationScore ?? 0)",
            newValue: "\(newScore)",
            metadata: ["reason": reason]
        )
        try await FirestoreManager.shared.logSafetyEvent(event)
        
        if promoter?.id == promoterId {
            await MainActor.run {
                self.promoter?.reputationScore = newScore
            }
        }
    }
}
    
    private func fetchPromoter(userId: String) async throws -> Promoter? {
        let snapshot = try await db.collection("promoters")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        guard let doc = snapshot.documents.first else { return nil }
        let data = doc.data()
        
            return Promoter(
                id: doc.documentID,
                userId: data["userId"] as? String ?? "",
                name: data["name"] as? String ?? "",
                commissionRate: data["commissionRate"] as? Double ?? 0.10,
                venueIds: data["venueIds"] as? [String] ?? [],
                totalEarnings: data["totalEarnings"] as? Double ?? 0,
                activeGuestLists: data["activeGuestLists"] as? Int ?? 0,
                reputationScore: data["reputationScore"] as? Int ?? 80,
                kycStatus: KYCStatus(rawValue: data["kycStatus"] as? String ?? "") ?? .pending,
                createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
            )
        }
    
    private func fetchCommissions(promoterId: String) async throws {
        let snapshot = try await db.collection("commissions")
            .whereField("promoterId", isEqualTo: promoterId)
            .order(by: "date", descending: true)
            .limit(to: 50)
            .getDocuments()
        
        let fetchedCommissions = snapshot.documents.compactMap { doc -> Commission? in
            let data = doc.data()
            return Commission(
                id: doc.documentID,
                promoterId: data["promoterId"] as? String ?? "",
                promoterName: data["promoterName"] as? String ?? "",
                bookingId: data["bookingId"] as? String,
                guestListId: data["guestListId"] as? String,
                venueName: data["venueName"] as? String ?? "",
                amount: data["amount"] as? Double ?? 0,
                status: CommissionStatus(rawValue: data["status"] as? String ?? "Pending") ?? .pending,
                date: (data["date"] as? Timestamp)?.dateValue() ?? Date()
            )
        }
        
        await MainActor.run {
            self.commissions = fetchedCommissions
        }
    }
    
    private func fetchPromoterGuestLists(promoterId: String) async throws {
        let snapshot = try await db.collection("guestListRequests")
            .whereField("promoterId", isEqualTo: promoterId)
            .whereField("date", isGreaterThan: Date())
            .order(by: "date", descending: false)
            .getDocuments()
        
        let fetchedLists = snapshot.documents.compactMap { doc -> GuestListRequest? in
            let data = doc.data()
            return GuestListRequest(
                id: UUID(uuidString: doc.documentID) ?? UUID(),
                userId: data["userId"] as? String ?? "",
                venueId: data["venueId"] as? String ?? "",
                venueName: data["venueName"] as? String ?? "",
                name: data["name"] as? String ?? "",
                email: data["email"] as? String ?? "",
                date: (data["date"] as? Timestamp)?.dateValue() ?? Date(),
                guestCount: data["guestCount"] as? Int ?? 1,
                status: data["status"] as? String ?? "Pending",
                qrCodeId: data["qrCodeId"] as? String
            )
        }
        
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
        
        let commissionData: [String: Any] = [
            "promoterId": commission.promoterId,
            "promoterName": commission.promoterName,
            "bookingId": commission.bookingId ?? "",
            "venueName": commission.venueName,
            "amount": commission.amount,
            "status": commission.status.rawValue,
            "date": Timestamp(date: commission.date)
        ]
        
        try await db.collection("commissions").document(commission.id).setData(commissionData)
    }
}
