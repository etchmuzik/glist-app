import SwiftUI
import Combine
import FirebaseFirestore

struct GuestListRequest: Identifiable, Codable {
    let id: UUID
    let userId: String
    let venueId: String
    let venueName: String
    let name: String
    let email: String
    let date: Date
    let guestCount: Int
    let status: String // "Pending", "Confirmed", "Rejected"
    let qrCodeId: String?
}

class GuestListManager: ObservableObject {
    @Published var requests: [GuestListRequest] = []
    @Published var isLoading = false
    
    private var listener: ListenerRegistration?
    private var currentUserId: String?
    
    func startListening(userId: String) {
        currentUserId = userId
        isLoading = true
        
        // Set up real-time listener for user's guest list requests
        listener = Firestore.firestore()
            .collection("guestListRequests")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                self.isLoading = false
                
                if let error = error {
                    print("Error fetching guest lists: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.requests = []
                    return
                }
                
                self.requests = documents.compactMap { doc -> GuestListRequest? in
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
            }
    }
    
    func stopListening() {
        listener?.remove()
        listener = nil
        requests = []
    }
    
    func addRequest(userId: String, venueId: String, venueName: String, name: String, email: String, date: Date, guestCount: Int) async throws {
        let newRequest = GuestListRequest(
            id: UUID(),
            userId: userId,
            venueId: venueId,
            venueName: venueName,
            name: name,
            email: email,
            date: date,
            guestCount: guestCount,
            status: "Pending",
            qrCodeId: UUID().uuidString // Generate a unique QR code ID
        )
        
        // Save to Firestore
        try await FirestoreManager.shared.submitGuestListRequest(newRequest)
    }
    
    deinit {
        listener?.remove()
    }
}
