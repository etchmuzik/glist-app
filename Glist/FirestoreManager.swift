import Foundation
import FirebaseFirestore

class FirestoreManager {
    static let shared = FirestoreManager()
    let db = Firestore.firestore()
    
    // MARK: - User Management
    
    func createUser(_ user: User) async throws {
        let userData: [String: Any] = [
            "email": user.email,
            "name": user.name,
            "role": user.role.rawValue,
            "createdAt": Timestamp(date: user.createdAt),
            "favoriteVenueIds": user.favoriteVenueIds,
            "fcmToken": user.fcmToken as Any,
            "notificationPreferences": [
                "guestListUpdates": user.notificationPreferences.guestListUpdates,
                "newVenues": user.notificationPreferences.newVenues,
                "promotions": user.notificationPreferences.promotions
            ],
            "rewardPoints": user.rewardPoints,
            "noShowCount": user.noShowCount,
            "isBanned": user.isBanned
        ]
        
        try await db.collection("users").document(user.id).setData(userData)
    }
    
    func fetchUser(userId: String) async throws -> User? {
        let document = try await db.collection("users").document(userId).getDocument()
        
        guard let data = document.data() else { return nil }
        
        return User(
            id: document.documentID,
            email: data["email"] as? String ?? "",
            name: data["name"] as? String ?? "",
            role: UserRole(rawValue: data["role"] as? String ?? "user") ?? .user,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            favoriteVenueIds: data["favoriteVenueIds"] as? [String] ?? [],
            profileImage: data["profileImage"] as? String,
            fcmToken: data["fcmToken"] as? String,
            notificationPreferences: {
                if let prefsData = data["notificationPreferences"] as? [String: Any] {
                    return NotificationPreferences(
                        guestListUpdates: prefsData["guestListUpdates"] as? Bool ?? true,
                        newVenues: prefsData["newVenues"] as? Bool ?? false,
                        promotions: prefsData["promotions"] as? Bool ?? false
                    )
                }
                return NotificationPreferences()
            }(),
            rewardPoints: data["rewardPoints"] as? Int ?? 0,
            noShowCount: data["noShowCount"] as? Int ?? 0,
            isBanned: data["isBanned"] as? Bool ?? false
        )
    }
    
    // MARK: - Venue Management
    
    func fetchVenues() async throws -> [Venue] {
        let snapshot = try await db.collection("venues")
            .whereField("isActive", isEqualTo: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc -> Venue? in
            let data = doc.data()
            var venue = Venue(
                name: data["name"] as? String ?? "",
                type: data["type"] as? String ?? "",
                location: data["location"] as? String ?? "",
                description: data["description"] as? String ?? "",
                rating: data["rating"] as? Double ?? 0.0,
                price: data["price"] as? String ?? "",
                dressCode: data["dressCode"] as? String ?? "",
                imageName: data["imageName"] as? String ?? "",
                tags: data["tags"] as? [String] ?? [],
                latitude: data["latitude"] as? Double ?? 25.2048,
                longitude: data["longitude"] as? Double ?? 55.2708,
                events: []
            )
            // Parse tables
            let tablesData = data["tables"] as? [[String: Any]] ?? []
            let tables = tablesData.compactMap { tableData -> Table? in
                guard let name = tableData["name"] as? String,
                      let capacity = tableData["capacity"] as? Int,
                      let minimumSpend = tableData["minimumSpend"] as? Double else { return nil }
                
                return Table(
                    id: UUID(uuidString: tableData["id"] as? String ?? "") ?? UUID(),
                    name: name,
                    capacity: capacity,
                    minimumSpend: minimumSpend,
                    isAvailable: tableData["isAvailable"] as? Bool ?? true
                )
            }
            venue.tables = tables
            
            // Set the ID from Firestore document ID
            if let firestoreId = UUID(uuidString: doc.documentID) {
                venue.id = firestoreId
            }
            return venue
        }
    }
    
    func createVenue(_ venue: Venue) async throws {
        let venueData: [String: Any] = [
            "name": venue.name,
            "type": venue.type,
            "location": venue.location,
            "description": venue.description,
            "rating": venue.rating,
            "price": venue.price,
            "dressCode": venue.dressCode,
            "imageName": venue.imageName,
            "tags": venue.tags,
            "isActive": true,
            "createdAt": Timestamp(date: Date()),
            "updatedAt": Timestamp(date: Date()),
            "tables": venue.tables.map { [
                "id": $0.id.uuidString,
                "name": $0.name,
                "capacity": $0.capacity,
                "minimumSpend": $0.minimumSpend,
                "isAvailable": $0.isAvailable
            ] }
        ]
        
        try await db.collection("venues").document(venue.id.uuidString).setData(venueData)
    }
    
    // MARK: - Guest List Management
    
    func submitGuestListRequest(_ request: GuestListRequest) async throws {
        let requestData: [String: Any] = [
            "userId": request.userId,
            "venueId": request.venueId,
            "venueName": request.venueName,
            "name": request.name,
            "email": request.email,
            "date": Timestamp(date: request.date),
            "guestCount": request.guestCount,
            "status": request.status,
            "qrCodeId": request.qrCodeId ?? "",
            "createdAt": Timestamp(date: Date()),
            "updatedAt": Timestamp(date: Date())
        ]
        
        try await db.collection("guestListRequests").document(request.id.uuidString).setData(requestData)
    }
    
    func fetchUserGuestListRequests(userId: String) async throws -> [GuestListRequest] {
        let snapshot = try await db.collection("guestListRequests")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc -> GuestListRequest? in
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
    
    func fetchAllGuestListRequests() async throws -> [GuestListRequest] {
        let snapshot = try await db.collection("guestListRequests")
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc -> GuestListRequest? in
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
    
    func fetchGuestListRequest(qrCodeId: String) async throws -> GuestListRequest? {
        // First try to find by qrCodeId field
        let snapshot = try await db.collection("guestListRequests")
            .whereField("qrCodeId", isEqualTo: qrCodeId)
            .getDocuments()
        
        if let doc = snapshot.documents.first {
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
        
        // Fallback: try to find by document ID (if qrCodeId matches document ID)
        let doc = try await db.collection("guestListRequests").document(qrCodeId).getDocument()
        if doc.exists, let data = doc.data() {
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
        
        return nil
    }
    
    func updateGuestListStatus(requestId: String, status: String) async throws {
        try await db.collection("guestListRequests").document(requestId).updateData([
            "status": status,
            "updatedAt": Timestamp(date: Date())
        ])
    }
    
    // MARK: - Favorites
    
    func updateFavorites(userId: String, venueIds: [String]) async throws {
        try await db.collection("users").document(userId).updateData([
            "favoriteVenueIds": venueIds
        ])
    }
    
    func updateFCMToken(userId: String, token: String) async throws {
        try await db.collection("users").document(userId).updateData([
            "fcmToken": token
        ])
    }
    
    func updateUser(userId: String, data: [String: Any]) async throws {
        try await db.collection("users").document(userId).updateData(data)
    }
    
    func updateNotificationPreferences(userId: String, data: [String: Any]) async throws {
        try await db.collection("users").document(userId).updateData([
            "notificationPreferences": data
        ])
    }
    
    // MARK: - Rewards & Bans
    
    func addRewardPoints(userId: String, points: Int) async throws {
        let userRef = db.collection("users").document(userId)
        try await db.runTransaction({ (transaction, errorPointer) -> Any? in
            let userDocument: DocumentSnapshot
            do {
                try userDocument = transaction.getDocument(userRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            guard let oldPoints = userDocument.data()?["rewardPoints"] as? Int else {
                let error = NSError(
                    domain: "AppErrorDomain",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Unable to retrieve reward points from snapshot \(userDocument)"]
                )
                errorPointer?.pointee = error
                return nil
            }
            
            transaction.updateData(["rewardPoints": oldPoints + points], forDocument: userRef)
            return nil
        })
    }
    
    func incrementNoShowCount(userId: String) async throws {
        let userRef = db.collection("users").document(userId)
        try await db.runTransaction({ (transaction, errorPointer) -> Any? in
            let userDocument: DocumentSnapshot
            do {
                try userDocument = transaction.getDocument(userRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            guard let noShowCount = userDocument.data()?["noShowCount"] as? Int else {
                let error = NSError(
                    domain: "AppErrorDomain",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Unable to retrieve noShowCount from snapshot \(userDocument)"]
                )
                errorPointer?.pointee = error
                return nil
            }
            
            let newCount = noShowCount + 1
            var updates: [String: Any] = ["noShowCount": newCount]
            
            if newCount >= 5 {
                updates["isBanned"] = true
            }
            
            transaction.updateData(updates, forDocument: userRef)
            return nil
        })
    }
    
    // MARK: - Table Bookings
    
    func createBooking(_ booking: Booking) async throws {
        let bookingData: [String: Any] = [
            "userId": booking.userId,
            "venueId": booking.venueId,
            "venueName": booking.venueName,
            "tableId": booking.tableId.uuidString,
            "tableName": booking.tableName,
            "date": Timestamp(date: booking.date),
            "depositAmount": booking.depositAmount,
            "status": booking.status.rawValue,
            "createdAt": Timestamp(date: booking.createdAt)
        ]
        
        try await db.collection("bookings").document(booking.id.uuidString).setData(bookingData)
    }
    
    func fetchUserBookings(userId: String) async throws -> [Booking] {
        let snapshot = try await db.collection("bookings")
            .whereField("userId", isEqualTo: userId)
            .order(by: "date", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc -> Booking? in
            let data = doc.data()
            return Booking(
                id: UUID(uuidString: doc.documentID) ?? UUID(),
                userId: data["userId"] as? String ?? "",
                venueId: data["venueId"] as? String ?? "",
                venueName: data["venueName"] as? String ?? "",
                tableId: UUID(uuidString: data["tableId"] as? String ?? "") ?? UUID(),
                tableName: data["tableName"] as? String ?? "",
                date: (data["date"] as? Timestamp)?.dateValue() ?? Date(),
                depositAmount: data["depositAmount"] as? Double ?? 0.0,
                status: BookingStatus(rawValue: data["status"] as? String ?? "Pending") ?? .pending,
                createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
            )
        }
    }
    
    // MARK: - Tickets
    
    func createTicket(_ ticket: EventTicket) async throws {
        let data: [String: Any] = [
            "eventId": ticket.eventId.uuidString,
            "eventName": ticket.eventName,
            "eventDate": Timestamp(date: ticket.eventDate),
            "venueId": ticket.venueId.uuidString,
            "venueName": ticket.venueName,
            "userId": ticket.userId,
            "ticketTypeId": ticket.ticketTypeId.uuidString,
            "ticketTypeName": ticket.ticketTypeName,
            "price": ticket.price,
            "status": ticket.status.rawValue,
            "qrCodeId": ticket.qrCodeId,
            "purchaseDate": Timestamp(date: ticket.purchaseDate)
        ]
        
        try await db.collection("tickets").document(ticket.id.uuidString).setData(data)
    }
    
    func fetchUserTickets(userId: String) async throws -> [EventTicket] {
        let snapshot = try await db.collection("tickets")
            .whereField("userId", isEqualTo: userId)
            .order(by: "eventDate", descending: true)
            .getDocuments()
            
        return snapshot.documents.compactMap { doc -> EventTicket? in
            let data = doc.data()
            return EventTicket(
                id: UUID(uuidString: doc.documentID) ?? UUID(),
                eventId: UUID(uuidString: data["eventId"] as? String ?? "") ?? UUID(),
                eventName: data["eventName"] as? String ?? "",
                eventDate: (data["eventDate"] as? Timestamp)?.dateValue() ?? Date(),
                venueId: UUID(uuidString: data["venueId"] as? String ?? "") ?? UUID(),
                venueName: data["venueName"] as? String ?? "",
                userId: data["userId"] as? String ?? "",
                ticketTypeId: UUID(uuidString: data["ticketTypeId"] as? String ?? "") ?? UUID(),
                ticketTypeName: data["ticketTypeName"] as? String ?? "",
                price: data["price"] as? Double ?? 0.0,
                status: TicketStatus(rawValue: data["status"] as? String ?? "Valid") ?? .valid,
                qrCodeId: data["qrCodeId"] as? String ?? "",
                purchaseDate: (data["purchaseDate"] as? Timestamp)?.dateValue() ?? Date()
            )
        }
    }
}
