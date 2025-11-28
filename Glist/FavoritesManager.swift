import SwiftUI
import Combine

@MainActor
class FavoritesManager: ObservableObject {
    @Published var favoriteVenueIds: Set<UUID> = []
    
    private let saveKey = "FavoriteVenueIds"
    
    init() {
        // Load from UserDefaults
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([UUID].self, from: data) {
            favoriteVenueIds = Set(decoded)
        }
    }
    
    func toggleFavorite(venueId: UUID) {
        if favoriteVenueIds.contains(venueId) {
            favoriteVenueIds.remove(venueId)
        } else {
            favoriteVenueIds.insert(venueId)
        }
        save()
    }
    
    func isFavorite(venueId: UUID) -> Bool {
        favoriteVenueIds.contains(venueId)
    }
    
    private func save() {
        if let encoded = try? JSONEncoder().encode(Array(favoriteVenueIds)) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
}
