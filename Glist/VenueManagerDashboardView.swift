import SwiftUI

struct VenueManagerDashboardView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var managedVenues: [Venue] = []
    @State private var isLoading = false
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom Tab Selector
                    HStack(spacing: 0) {
                        ManagerTabButton(title: "My Venues", isSelected: selectedTab == 0) { selectedTab = 0 }
                        ManagerTabButton(title: "Guest Lists", isSelected: selectedTab == 1) { selectedTab = 1 }
                        ManagerTabButton(title: "Scanner", isSelected: selectedTab == 2) { selectedTab = 2 }
                        ManagerTabButton(title: "Analytics", isSelected: selectedTab == 3) { selectedTab = 3 }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        TabView(selection: $selectedTab) {
                            // Tab 0: My Venues
                            ScrollView {
                                LazyVStack(spacing: 16) {
                                    if managedVenues.isEmpty {
                                        Text("No venues assigned.")
                                            .foregroundStyle(.gray)
                                            .padding(.top, 40)
                                    } else {
                                        ForEach(managedVenues) { venue in
                                            ManagerVenueCard(venue: venue)
                                        }
                                    }
                                }
                                .padding(20)
                            }
                            .tag(0)
                            
                            // Tab 1: Guest Lists (Scoped to managed venues)
                            ManagerGuestListsView(venueIds: managedVenues.map { $0.id.uuidString })
                                .tag(1)
                            
                            // Tab 2: Scanner
                            StaffScannerWrapperView(availableVenues: managedVenues)
                                .tag(2)
                            
                            // Tab 3: Analytics (Placeholder for now, scoped to venues)
                            ManagerAnalyticsView(venues: managedVenues)
                                .tag(3)
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                    }
                }
            }
            .navigationTitle("VENUE MANAGER")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadManagedVenues()
            }
        }
    }
    
    private func loadManagedVenues() {
        guard let userId = authManager.user?.id else { return }
        isLoading = true
        Task {
            do {
                managedVenues = try await SupabaseDataManager.shared.fetchVenuesForManager(userId: userId)
            } catch {
                print("Error loading managed venues: \(error)")
            }
            isLoading = false
        }
    }
}

struct ManagerTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Fonts.body(size: 12))
                .fontWeight(isSelected ? .bold : .regular)
                .foregroundStyle(isSelected ? .white : .gray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? Color.theme.surface : Color.clear)
        }
    }
}

struct ManagerVenueCard: View {
    let venue: Venue
    @State private var showEditor = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Hero Image
            if let url = venue.imageURL, let imageURL = URL(string: url) {
                AsyncImage(url: imageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(height: 150)
                .clipped()
            } else {
                Image(venue.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 150)
                    .clipped()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(venue.name.uppercased())
                        .font(Theme.Fonts.display(size: 18))
                        .foregroundStyle(.white)
                    Spacer()
                    Text(venue.type.uppercased())
                        .font(Theme.Fonts.body(size: 10))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.theme.accent.opacity(0.2))
                        .foregroundStyle(Color.theme.accent)
                        .clipShape(Capsule())
                }
                
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(.gray)
                    Text(venue.location)
                        .font(Theme.Fonts.body(size: 12))
                        .foregroundStyle(.gray)
                }
                
                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.vertical, 4)
                
                HStack {
                    Label("\(venue.tables.count) Tables", systemImage: "table.furniture")
                    Spacer()
                    Button {
                        showEditor = true
                    } label: {
                        Label("Edit Details", systemImage: "pencil")
                            .foregroundStyle(Color.theme.accent)
                    }
                }
                .font(Theme.Fonts.body(size: 12))
                .foregroundStyle(.white)
            }
            .padding(16)
            .background(Color.theme.surface)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .sheet(isPresented: $showEditor) {
            VenueEditorView(venue: venue) { updatedVenue in
                Task {
                    try? await SupabaseDataManager.shared.updateVenue(updatedVenue.id.uuidString, venue: updatedVenue)
                }
            }
        }
    }
}

struct ManagerGuestListsView: View {
    let venueIds: [String]
    @State private var requests: [GuestListRequest] = []
    @State private var isLoading = false
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView().tint(.white)
            } else if requests.isEmpty {
                Text("No guest list requests found.")
                    .foregroundStyle(.gray)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(requests) { request in
                            AdminGuestListCard(request: request) {
                                loadRequests()
                            }
                        }
                    }
                    .padding(20)
                }
            }
        }
        .onAppear {
            loadRequests()
        }
    }
    
    private func loadRequests() {
        isLoading = true
        Task {
            do {
                requests = try await SupabaseDataManager.shared.fetchGuestListRequests(forVenueIds: venueIds)
            } catch {
                print("Error loading requests: \(error)")
            }
            isLoading = false
        }
    }
}

struct ManagerAnalyticsView: View {
    let venues: [Venue]
    @StateObject private var analyticsManager = AnalyticsManager()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Summary Stats for Managed Venues
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    AnalyticsStatCard(
                        title: NSLocalizedString("total_revenue", comment: ""),
                        value: CurrencyFormatter.aed(analyticsManager.totalRevenue),
                        icon: "dollarsign.circle.fill",
                        color: .green
                    )
                    AnalyticsStatCard(
                        title: NSLocalizedString("bookings", comment: ""),
                        value: "\(analyticsManager.totalBookings)",
                        icon: "calendar.circle.fill",
                        color: .blue
                    )
                    AnalyticsStatCard(
                        title: NSLocalizedString("tickets_sold", comment: ""),
                        value: "\(analyticsManager.totalTickets)",
                        icon: "ticket.fill",
                        color: .purple
                    )
                    AnalyticsStatCard(
                        title: NSLocalizedString("guest_lists_title", comment: ""),
                        value: "\(analyticsManager.totalGuestLists)",
                        icon: "person.2.fill",
                        color: .orange
                    )
                }
                .padding(.horizontal, 20)
                
                // Per-Venue Performance
                if !analyticsManager.venueAnalytics.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(LocalizedStringKey("venue_performance"))
                            .font(Theme.Fonts.body(size: 12))
                            .fontWeight(.bold)
                            .foregroundStyle(.gray)
                            .padding(.horizontal, 20)
                        
                        ForEach(analyticsManager.venueAnalytics) { analytics in
                            VenueAnalyticsRow(analytics: analytics)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.vertical, 20)
        }
        .onAppear {
            Task {
                // Filter analytics to only show managed venues
                // Note: AnalyticsManager usually fetches everything for admin.
                // We might need to filter it here or update AnalyticsManager to support filtering.
                // For now, we'll fetch all and filter client-side for simplicity in this view.
                await analyticsManager.fetchAnalytics()
                
                let venueIds = Set(venues.map { $0.id.uuidString })
                let filteredVenueAnalytics = analyticsManager.venueAnalytics.filter { venueIds.contains($0.venueId) }
                
                // Re-calculate totals based on filtered venues
                let totalRev = filteredVenueAnalytics.reduce(0) { $0 + $1.totalRevenue }
                let totalBooks = filteredVenueAnalytics.reduce(0) { $0 + $1.totalBookings }
                let totalTix = filteredVenueAnalytics.reduce(0) { $0 + $1.totalTickets }
                let totalGL = filteredVenueAnalytics.reduce(0) { $0 + $1.totalGuestLists }
                
                await MainActor.run {
                    analyticsManager.venueAnalytics = filteredVenueAnalytics
                    analyticsManager.totalRevenue = totalRev
                    analyticsManager.totalBookings = totalBooks
                    analyticsManager.totalTickets = totalTix
                    analyticsManager.totalGuestLists = totalGL
                }
            }
        }
    }
}
