import Foundation
import FirebaseFirestore
import Combine

class VenueManager: ObservableObject {
    @Published var venues: [Venue] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var listener: ListenerRegistration?
    
    init() {
        fetchVenues()
    }
    
    func fetchVenues() {
        isLoading = true
        errorMessage = nil
        
        // Set up real-time listener
        listener = Firestore.firestore()
            .collection("venues")
            .whereField("isActive", isEqualTo: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    print("Error fetching venues: \(error)")
                    // Fallback to hardcoded data if Firestore fails
                    self.venues = VenueData.dubaiVenues
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    // If no documents, use hardcoded data
                    self.venues = VenueData.dubaiVenues
                    return
                }
                
                if documents.isEmpty {
                    // Database is empty, use hardcoded data
                    self.venues = VenueData.dubaiVenues
                } else {
                    // Parse Firestore documents
                    self.venues = documents.compactMap { doc -> Venue? in
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
                            latitude: data["latitude"] as? Double ?? 25.2048, // Default to Dubai
                            longitude: data["longitude"] as? Double ?? 55.2708,
                            events: []
                        )
                        
                        // Set the ID from Firestore document ID
                        if let firestoreId = UUID(uuidString: doc.documentID) {
                            venue.id = firestoreId
                        }
                        
                        return venue
                    }
                }
            }
    }
    
    func seedDatabase() async throws {
        print("🌱 Seeding database with Dubai venues...")
        
        for venue in VenueData.dubaiVenues {
            try await FirestoreManager.shared.createVenue(venue)
            print("✅ Added: \(venue.name)")
        }
        
        print("🎉 Database seeded successfully!")
    }
    
    deinit {
        listener?.remove()
    }
}
