import SwiftUI

struct VenueListView: View {
    @EnvironmentObject var venueManager: VenueManager
    @EnvironmentObject var localeManager: LocalizationManager
    @State private var searchText = ""
    @State private var selectedDistrict: DubaiDistrict?
    
    var filteredVenues: [Venue] {
        let base = venueManager.venues.filter { venue in
            if searchText.isEmpty { return true }
            return venue.name.localizedCaseInsensitiveContains(searchText) ||
            venue.type.localizedCaseInsensitiveContains(searchText) ||
            venue.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
        guard let district = selectedDistrict else { return base }
        return base.filter { $0.district == district }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.background.ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 32) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("dubai_title")
                                .font(Theme.Fonts.display(size: 48))
                                .foregroundStyle(Color.theme.textPrimary)
                            Text("nightlife_guide")
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
                            TextField(LocalizedStringKey("search_placeholder"), text: $searchText)
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

                        // District Filters
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                FilterChip(title: NSLocalizedString("All", comment: "All districts"), isSelected: selectedDistrict == nil) {
                                    selectedDistrict = nil
                                }
                                ForEach(DubaiDistrict.allCases.filter { $0 != .unknown }, id: \.self) { district in
                                    FilterChip(title: district.displayName, isSelected: selectedDistrict == district) {
                                        selectedDistrict = district
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // Curated Rails + AI-style Recommendations
                        if searchText.isEmpty && selectedDistrict == nil {
                            // AI-powered "Recommended For You" rail (local heuristic engine for now)
                            let recommended = RecommendationEngine.recommendedVenues(from: venueManager.venues, context: .default, limit: 10)
                            if !recommended.isEmpty {
                                VenueRail(title: "RECOMMENDED FOR YOU", venues: recommended)
                            }
                            
                            // Tonight Near You (venues with upcoming events)
                            let tonightVenues = venueManager.venues.filter { !$0.events.isEmpty }
                            if !tonightVenues.isEmpty {
                                VenueRail(title: "TONIGHT NEAR YOU", venues: tonightVenues)
                            }
                            
                            // Premium Lounges
                            let premiumLounges = venueManager.venues.filter { ($0.type.contains("Lounge") || $0.type.contains("Skybar")) && $0.price.count >= 4 }
                            if !premiumLounges.isEmpty {
                                VenueRail(title: "PREMIUM LOUNGES", venues: premiumLounges)
                            }
                            
                            // Trending
                            let trendingVenues = venueManager.venues.filter { $0.isTrending }
                            if !trendingVenues.isEmpty {
                                VenueRail(title: "TRENDING NOW", venues: trendingVenues)
                            }
                        }
                        
                        // List
                        if filteredVenues.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 40))
                                    .foregroundStyle(Color.theme.textSecondary.opacity(0.5))
                                Text("no_venues_found")
                                    .font(Theme.Fonts.body(size: 16))
                                    .foregroundStyle(Color.theme.textSecondary)
                            }
                            .padding(.top, 40)
                        } else {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("ALL VENUES")
                                    .font(Theme.Fonts.body(size: 12))
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color.theme.textSecondary)
                                    .padding(.horizontal, 24)
                                
                                ForEach(filteredVenues) { venue in
                                    NavigationLink(destination: VenueDetailView(venue: venue)) {
                                        VenueCard(venue: venue)
                                    }
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

struct VenueRail: View {
    let title: String
    let venues: [Venue]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(Theme.Fonts.body(size: 12))
                .fontWeight(.bold)
                .foregroundStyle(Color.theme.textSecondary)
                .padding(.horizontal, 24)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(venues) { venue in
                        NavigationLink(destination: VenueDetailView(venue: venue)) {
                            VenueRailCard(venue: venue)
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
}

struct VenueRailCard: View {
    let venue: Venue
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .fill(Color.theme.surface)
                .frame(width: 200, height: 120)
                .overlay {
                    Image(systemName: "photo")
                        .font(.title)
                        .foregroundStyle(Color.theme.textSecondary.opacity(0.5))
                }
                .overlay(alignment: .topTrailing) {
                    if venue.rating >= 4.8 {
                        Text(String(format: "%.1f", venue.rating))
                            .font(Theme.Fonts.body(size: 10))
                            .fontWeight(.bold)
                            .foregroundStyle(.black)
                            .padding(6)
                            .background(Color.white)
                            .clipShape(Circle())
                            .padding(8)
                    }
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(venue.name.uppercased())
                    .font(Theme.Fonts.display(size: 16))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(venue.type)
                        .font(Theme.Fonts.body(size: 10))
                        .foregroundStyle(Color.theme.textSecondary)
                        .lineLimit(1)
                    
                    if venue.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }
                }
            }
            .padding(12)
            .frame(width: 200, alignment: .leading)
            .background(Color.theme.surface.opacity(0.3))
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}

struct VenueCard: View {
    let venue: Venue
    @Environment(\.locale) private var locale

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
                            
                            if venue.isVerified {
                                VerifiedBadge(text: "Verified")
                            }
                            
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
                    // If price represents min spend in AED, you could format here; currently using literal string.
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
