import SwiftUI
import UIKit

struct FavoriteButton: View {
    let venueId: UUID
    @EnvironmentObject var favoritesManager: FavoritesManager
    
    var body: some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                favoritesManager.toggleFavorite(venueId: venueId)
            }
        } label: {
            Image(systemName: favoritesManager.isFavorite(venueId: venueId) ? "heart.fill" : "heart")
                .font(.system(size: 24))
                .foregroundStyle(favoritesManager.isFavorite(venueId: venueId) ? .red : .white)
                .padding(8)
                .background(Color.theme.surface)
                .clipShape(Circle())
        }
    }
}
