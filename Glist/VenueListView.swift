import SwiftUI

struct VenueListView: View {
    @EnvironmentObject var venueManager: VenueManager
    @State private var searchText = ""
    
    var filteredVenues: [Venue] {
        if searchText.isEmpty {
            return venueManager.venues
        } else {
            return venueManager.venues.filter { venue in
                venue.name.localizedCaseInsensitiveContains(searchText) ||
                venue.type.localizedCaseInsensitiveContains(searchText) ||
                venue.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.background.ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 32) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("DUBAI")
                                .font(Theme.Fonts.display(size: 48))
                                .foregroundStyle(Color.theme.textPrimary)
                            Text("NIGHTLIFE GUIDE")
                                .font(Theme.Fonts.body(size: 14))
                                .foregroundStyle(Color.theme.textSecondary)
                                .tracking(6)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        
                        // Search Bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(Color.theme.textSecondary)
                            TextField("Search clubs, vibes...", text: $searchText)
                                .foregroundStyle(Color.theme.textPrimary)
                                .tint(Color.theme.accent)
                        }
                        .padding(16)
                        .background(Color.theme.surface.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .padding(.horizontal, 24)
                        
                        // List
                        if filteredVenues.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 40))
                                    .foregroundStyle(Color.theme.textSecondary.opacity(0.5))
                                Text("No venues found")
                                    .font(Theme.Fonts.body(size: 16))
                                    .foregroundStyle(Color.theme.textSecondary)
                            }
                            .padding(.top, 40)
                        } else {
                            ForEach(filteredVenues) { venue in
                                NavigationLink(destination: VenueDetailView(venue: venue)) {
                                    VenueCard(venue: venue)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

struct VenueCard: View {
    let venue: Venue
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image Area
            Rectangle()
                .fill(Color.theme.surface)
                .frame(height: 260) // Taller image
                .overlay {
                    // Placeholder
                    LinearGradient(
                        colors: [.gray.opacity(0.2), .black.opacity(0.9)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundStyle(Color.theme.textSecondary.opacity(0.5))
                }
                .overlay(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(venue.type.uppercased())
                                .font(Theme.Fonts.body(size: 10))
                                .fontWeight(.bold)
                                .foregroundStyle(.black)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.white)
                            
                            Spacer()
                            
                            if venue.rating >= 4.8 {
                                Text("TRENDING")
                                    .font(Theme.Fonts.body(size: 10))
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.theme.accent)
                            }
                        }
                        
                        Text(venue.name.uppercased())
                            .font(Theme.Fonts.display(size: 28))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                    }
                    .padding(24)
                }
            
            // Info Area
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.caption)
                    Text(venue.location)
                        .font(Theme.Fonts.body(size: 12))
                }
                .foregroundStyle(Color.theme.textSecondary)
                
                Spacer()
                
                HStack(spacing: 16) {
                    Text(venue.price)
                        .font(Theme.Fonts.body(size: 12))
                        .foregroundStyle(Color.theme.textSecondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                        Text(String(format: "%.1f", venue.rating))
                            .font(Theme.Fonts.body(size: 12))
                            .foregroundStyle(Color.theme.textPrimary)
                    }
                }
            }
            .padding(20)
            .background(Color.theme.surface.opacity(0.3))
            .overlay(
                Rectangle()
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
        }
        .padding(.horizontal, 24)
    }
}
