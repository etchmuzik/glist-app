import Foundation

import Combine

@MainActor
class VenueManager: ObservableObject {
    @Published var venues: [Venue] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init() {
        fetchVenues()
    }
    
    func fetchVenues() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let fetchedVenues = try await SupabaseDataManager.shared.fetchVenues()
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    if fetchedVenues.isEmpty {
                        // Fallback to hardcoded data if database is empty
                        self.venues = VenueData.dubaiVenues
                    } else {
                        self.venues = fetchedVenues
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    print("Error fetching venues: \(error)")
                    // Fallback to hardcoded data on error
                    self.venues = VenueData.dubaiVenues
                }
            }
        }
    }
    
    func seedDatabase() async throws {
        print("🌱 Seeding database with Dubai venues...")
        
        for venue in VenueData.dubaiVenues {
            try await SupabaseDataManager.shared.createVenue(venue)
            print("✅ Added: \(venue.name)")
        }
        
        print("🎉 Database seeded successfully!")
    }
    
    func deleteAllVenues() async throws {
        isLoading = true
        do {
            try await SupabaseDataManager.shared.deleteAllVenues()
            DispatchQueue.main.async {
                self.venues = []
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
}

