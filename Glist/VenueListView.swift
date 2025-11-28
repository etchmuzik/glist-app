import SwiftUI

struct VenueListView: View {
    @EnvironmentObject var venueManager: VenueManager
    @EnvironmentObject var localeManager: LocalizationManager
    @State private var searchText = ""
    @State private var selectedDistrict: DubaiDistrict?
    @State private var selectedCity: String = "Dubai"
    
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
                
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 32) {
                        // City + Weather pills
                        HStack(spacing: 12) {
                            Capsule()
                                .fill(Color.white.opacity(0.08))
                                .overlay(
                                    HStack(spacing: 8) {
                                        Image(systemName: "location.fill")
                                        Text(selectedCity)
                                        Text("• 24°")
                                            .foregroundStyle(Color.white.opacity(0.7))
                                    }
                                    .font(Theme.Fonts.body(size: 12))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                )
                            Spacer()
                            Capsule()
                                .fill(Color.white.opacity(0.04))
                                .overlay(
                                    HStack(spacing: 8) {
                                        Text("World")
                                        Image(systemName: "globe")
                                    }
                                    .font(Theme.Fonts.body(size: 12))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                )
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        
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
                            // Happening this week
                            let weekEvents = venueManager.venues.filter { venue in
                                venue.events.contains { $0.date > Date().addingTimeInterval(-86400) && $0.date < Date().addingTimeInterval(7 * 86400) }
                            }
                            if !weekEvents.isEmpty {
                                VenueRail(title: "HAPPENING THIS WEEK", venues: weekEvents) {
                                    withAnimation {
                                        proxy.scrollTo("allVenuesSection", anchor: .top)
                                    }
                                }
                            }
                            
                            // AI-powered "Recommended For You" rail (local heuristic engine for now)
                            let recommended = RecommendationEngine.recommendedVenues(from: venueManager.venues, context: .default, limit: 10)
                            if !recommended.isEmpty {
                                VenueRail(title: "RECOMMENDED FOR YOU", venues: recommended) {
                                    withAnimation {
                                        proxy.scrollTo("allVenuesSection", anchor: .top)
                                    }
                                }
                            }
                            
                            // Tonight Near You (venues with upcoming events)
                            let tonightVenues = venueManager.venues.filter { !$0.events.isEmpty }
                            if !tonightVenues.isEmpty {
                                VenueRail(title: "TONIGHT NEAR YOU", venues: tonightVenues) {
                                    withAnimation {
                                        proxy.scrollTo("allVenuesSection", anchor: .top)
                                    }
                                }
                            }
                            
                            // Premium Lounges
                            let premiumLounges = venueManager.venues.filter { ($0.type.contains("Lounge") || $0.type.contains("Skybar")) && $0.price.count >= 4 }
                            if !premiumLounges.isEmpty {
                                VenueRail(title: "PREMIUM LOUNGES", venues: premiumLounges) {
                                    withAnimation {
                                        proxy.scrollTo("allVenuesSection", anchor: .top)
                                    }
                                }
                            }
                            
                            // Trending
                            let trendingVenues = venueManager.venues.filter { $0.isTrending }
                            if !trendingVenues.isEmpty {
                                VenueRail(title: "TRENDING NOW", venues: trendingVenues) {
                                    withAnimation {
                                        proxy.scrollTo("allVenuesSection", anchor: .top)
                                    }
                                }
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
                            .id("allVenuesSection")
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

}

struct VenueRail: View {
    let title: String
    let venues: [Venue]
    var onAllTap: (() -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(Theme.Fonts.body(size: 12))
                    .fontWeight(.bold)
                    .foregroundStyle(Color.theme.textSecondary)
                Spacer()
                if let onAllTap {
                    Button("All") {
                        onAllTap()
                    }
                    .font(Theme.Fonts.body(size: 12))
                    .foregroundStyle(Color.theme.accent)
                }
            }
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
                .padding(.bottom, 8)
            }
        }
        .padding(.vertical, 14)
        .background(Color.theme.surface.opacity(0.25))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }
}

struct VenueRailCard: View {
    let venue: Venue
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            AsyncImage(url: URL(string: venue.imageURL ?? "")) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        LinearGradient(colors: [.white.opacity(0.05), .black.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        ProgressView().tint(.white)
                    }
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    LinearGradient(colors: [.white.opacity(0.05), .black.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        .overlay(Image(systemName: "photo").font(.title).foregroundStyle(.white.opacity(0.6)))
                @unknown default:
                    Color.theme.surface
                }
            }
            .frame(width: 220, height: 130)
            .clipped()
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
            AsyncImage(url: URL(string: venue.imageURL ?? "")) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        LinearGradient(colors: [.gray.opacity(0.2), .black.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        ProgressView().tint(.white)
                    }
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    LinearGradient(colors: [.gray.opacity(0.2), .black.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        .overlay(Image(systemName: "photo").font(.largeTitle).foregroundStyle(.white.opacity(0.6)))
                @unknown default:
                    Color.theme.surface
                }
            }
            .frame(height: 260) // Taller image
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
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
                    
                    HStack(spacing: 12) {
                        Label(venue.district.displayName, systemImage: "mappin.and.ellipse")
                            .font(Theme.Fonts.body(size: 12))
                            .foregroundStyle(.white.opacity(0.8))
                        Label(venue.price, systemImage: "dollarsign.circle")
                            .font(Theme.Fonts.body(size: 12))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                .padding(16)
                .background(
                    LinearGradient(
                        colors: [.black.opacity(0.7), .clear],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .padding(.horizontal, 24)
            
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
    }
}
