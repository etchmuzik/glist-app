import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = AuthManager()
    @StateObject private var favoritesManager = FavoritesManager()
    @StateObject private var guestListManager = GuestListManager()
    @StateObject private var venueManager = VenueManager()
    
    init() {
        // Configure Tab Bar appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.black
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor.white
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.gray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.gray]
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        if authManager.isAuthenticated {
            MainTabView()
                .preferredColorScheme(.dark)
                .environmentObject(favoritesManager)
                .environmentObject(guestListManager)
                .environmentObject(authManager)
                .environmentObject(venueManager)
                .onAppear {
                    // Start listening for guest list updates
                    if let userId = authManager.user?.id {
                        guestListManager.startListening(userId: userId)
                    }
                }
                .onDisappear {
                    guestListManager.stopListening()
                }
        } else {
            AuthView()
                .preferredColorScheme(.dark)
                .environmentObject(authManager)
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        TabView {
            VenueListView()
                .tabItem {
                    Label("GUIDE", systemImage: "list.star")
                }
            
            VenueMapView()
                .tabItem {
                    Label("MAP", systemImage: "map")
                }
            
            ProfileView()
                .tabItem {
                    Label("PROFILE", systemImage: "person")
                }
            
            
            // Promoter tab - only visible for promoters
            if authManager.userRole == .promoter {
                PromoterDashboardView()
                    .tabItem {
                        Label("PROMOTER", systemImage: "chart.bar.fill")
                    }
            }
            
            // Admin tab - only visible for admins
            if authManager.userRole == .admin {
                AdminView()
                    .tabItem {
                        Label("ADMIN", systemImage: "shield.fill")
                    }
            }
        }
        .tint(.white)
    }
}

struct ProfileView: View {
    @EnvironmentObject var favoritesManager: FavoritesManager
    @EnvironmentObject var guestListManager: GuestListManager
    @EnvironmentObject var venueManager: VenueManager
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var bookingManager: BookingManager
    @StateObject private var ticketManager = TicketManager()
    @State private var showSeedView = false
    @State private var showAccountSettings = false
    @State private var showNotifications = false
    @State private var showPrivacy = false
    @State private var showHelp = false
    @State private var showLogoutAlert = false
    @State private var selectedRequest: GuestListRequest?
    @State private var selectedTicket: EventTicket?
    @State private var showSubscription = false
    @State private var showInvite = false
    
    var favoriteVenues: [Venue] {
        venueManager.venues.filter { favoritesManager.isFavorite(venueId: $0.id) }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.background.ignoresSafeArea()
                
                // Ambient Background Glow
                Circle()
                    .fill(Color.theme.accent.opacity(0.1))
                    .frame(width: 300, height: 300)
                    .blur(radius: 100)
                    .offset(y: -200)
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header & Avatar
                        VStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .stroke(LinearGradient(colors: [.white.opacity(0.5), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                                    .frame(width: 110, height: 110)
                                
                                VStack(spacing: 16) {
                                    if let user = authManager.user {
                                        ZStack(alignment: .bottomTrailing) {
                                            Image(systemName: "person.circle.fill")
                                                .font(.system(size: 80))
                                                .foregroundStyle(.gray)
                                                .background(Circle().fill(Color.white))
                                            
                                            // Tier Badge
                                            if user.tier != .standard {
                                                Image(systemName: "crown.fill")
                                                    .font(.system(size: 20))
                                                    .foregroundStyle(.white)
                                                    .padding(8)
                                                    .background(Color(hex: user.tier == .vip ? "FFD700" : "9D00FF"))
                                                    .clipShape(Circle())
                                                    .overlay(Circle().stroke(Color.theme.background, lineWidth: 2))
                                                    .offset(x: 5, y: 5)
                                            }
                                        }
                                        
                                        VStack(spacing: 4) {
                                            Text(user.name)
                                                .font(Theme.Fonts.display(size: 24))
                                                .foregroundStyle(.white)
                                            
                                            Text(user.email)
                                                .font(Theme.Fonts.body(size: 14))
                                                .foregroundStyle(.gray)
                                            
                                            // Tier Label
                                            Text(user.tier.rawValue.uppercased())
                                                .font(Theme.Fonts.body(size: 12))
                                                .fontWeight(.bold)
                                                .foregroundStyle(Color(hex: user.tier == .standard ? "808080" : (user.tier == .vip ? "FFD700" : "9D00FF")))
                                                .padding(.top, 4)
                                        }
                                        
                                        // Upgrade Button (if not Member)
                                        if user.tier != .member {
                                            Button {
                                                showSubscription = true
                                            } label: {
                                                Text("UPGRADE MEMBERSHIP")
                                                    .font(Theme.Fonts.body(size: 12))
                                                    .fontWeight(.bold)
                                                    .foregroundStyle(.black)
                                                    .padding(.horizontal, 20)
                                                    .padding(.vertical, 10)
                                                    .background(Color.white)
                                                    .clipShape(Capsule())
                                            }
                                            .padding(.top, 8)
                                        }
                                        
                                        // Social Stats & Find Friends
                                        HStack(spacing: 20) {
                                            VStack {
                                                Text("\(user.followers.count)")
                                                    .font(Theme.Fonts.display(size: 18))
                                                    .foregroundStyle(.white)
                                                Text("Followers")
                                                    .font(Theme.Fonts.body(size: 12))
                                                    .foregroundStyle(.gray)
                                            }
                                            
                                            VStack {
                                                Text("\(user.following.count)")
                                                    .font(Theme.Fonts.display(size: 18))
                                                    .foregroundStyle(.white)
                                                Text("Following")
                                                    .font(Theme.Fonts.body(size: 12))
                                                    .foregroundStyle(.gray)
                                            }
                                            
                                            NavigationLink(destination: SocialView()) {
                                                Text("Find Friends")
                                                    .font(Theme.Fonts.body(size: 12))
                                                    .fontWeight(.bold)
                                                    .foregroundStyle(.black)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 8)
                                                    .background(Color.white)
                                                    .clipShape(Capsule())
                                            }
                                        }
                                        .padding(.top, 8)
                                    } else {
                                        Circle()
                                            .fill(Color.theme.surface)
                                            .frame(width: 100, height: 100)
                                            .overlay {
                                                Text("G")
                                                    .font(Theme.Fonts.display(size: 40))
                                                    .foregroundStyle(Color.theme.textPrimary)
                                            }
                                        
                                        VStack(spacing: 8) {
                                            Text("GUEST USER")
                                                .font(Theme.Fonts.display(size: 24))
                                                .foregroundStyle(Color.theme.textPrimary)
                                            
                                            Text("DUBAI, UAE")
                                                .font(Theme.Fonts.body(size: 12))
                                                .foregroundStyle(Color.theme.textSecondary)
                                                .tracking(2)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(Color.theme.surface)
                                                .clipShape(Capsule())
                                        }
                                    }
                                }
                            }
                            
                            // Stats Row
                            HStack(spacing: 40) {
                                StatItem(value: "\(guestListManager.requests.count)", label: "Guest Lists")
                                StatItem(value: "\(bookingManager.bookings.count)", label: "Bookings")
                                StatItem(value: "\(favoriteVenues.count)", label: "Favorites")
                            }
                            .padding(.top, 10)
                        }
                        .padding(.top, 20)
                        
                        // My Guest Lists
                        if !guestListManager.requests.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                SectionHeader(title: "MY GUEST LISTS")
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(guestListManager.requests) { request in
                                            Button {
                                                selectedRequest = request
                                            } label: {
                                                GuestListTicket(
                                                    venueName: request.venueName,
                                                    date: request.date.formatted(.dateTime.month().day()),
                                                    status: request.status
                                                )
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                        }
                        
                        // My Tickets
                        if !ticketManager.tickets.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                SectionHeader(title: "MY TICKETS")
                                
                                ForEach(ticketManager.tickets) { ticket in
                                    Button {
                                        selectedTicket = ticket
                                    } label: {
                                        TicketCard(ticket: ticket)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        // My Bookings
                        if !bookingManager.bookings.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                SectionHeader(title: "MY BOOKINGS")
                                
                                ForEach(bookingManager.bookings) { booking in
                                    BookingCard(booking: booking)
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        // Favorites
                        if !favoriteVenues.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                SectionHeader(title: "FAVORITES")
                                
                                ForEach(favoriteVenues) { venue in
                                    NavigationLink(destination: VenueDetailView(venue: venue)) {
                                        HStack(spacing: 16) {
                                            Rectangle()
                                                .fill(Color.theme.surface)
                                                .frame(width: 70, height: 70)
                                                .overlay {
                                                    Image(systemName: "photo")
                                                        .foregroundStyle(Color.theme.textSecondary)
                                                }
                                            
                                            VStack(alignment: .leading, spacing: 6) {
                                                Text(venue.name.uppercased())
                                                    .font(Theme.Fonts.display(size: 16))
                                                    .foregroundStyle(Color.theme.textPrimary)
                                                
                                                Text(venue.type.uppercased())
                                                    .font(Theme.Fonts.body(size: 12))
                                                    .foregroundStyle(Color.theme.accent)
                                                
                                                HStack(spacing: 4) {
                                                    Image(systemName: "star.fill")
                                                        .font(.caption2)
                                                        .foregroundStyle(.yellow)
                                                    Text(String(format: "%.1f", venue.rating))
                                                        .font(Theme.Fonts.body(size: 12))
                                                        .foregroundStyle(Color.theme.textSecondary)
                                                }
                                            }
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.right")
                                                .foregroundStyle(Color.theme.textSecondary)
                                        }
                                        .padding(12)
                                        .background(Color.theme.surface.opacity(0.3))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        // Invite Friends
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "GROW YOUR NETWORK")
                            
                            Button {
                                showInvite = true
                            } label: {
                                HStack(spacing: 16) {
                                    Image(systemName: "gift.fill")
                                        .font(.title2)
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [Color.theme.accent, Color.purple],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 40)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Invite Friends")
                                            .font(Theme.Fonts.body(size: 16))
                                            .fontWeight(.bold)
                                            .foregroundStyle(.white)
                                        
                                        Text("Earn rewards for every friend who joins")
                                            .font(Theme.Fonts.body(size: 14))
                                            .foregroundStyle(.gray)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(.gray)
                                }
                                .padding(16)
                                .background(Color.theme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Settings Section
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "SETTINGS")
                            
                            VStack(spacing: 0) {
                                Button {
                                    showAccountSettings = true
                                } label: {
                                    SettingRow(icon: "person.circle", title: "Account Settings")
                                }
                                
                                Divider()
                                    .background(Color.theme.surface)
                                    .padding(.leading, 64)
                                
                                Button {
                                    showNotifications = true
                                } label: {
                                    SettingRow(icon: "bell", title: "Notifications")
                                }
                                
                                Divider()
                                    .background(Color.theme.surface)
                                    .padding(.leading, 64)
                                
                                Button {
                                    showPrivacy = true
                                } label: {
                                    SettingRow(icon: "lock", title: "Privacy & Security")
                                }
                                
                                Divider()
                                    .background(Color.theme.surface)
                                    .padding(.leading, 64)
                                
                                Button {
                                    showHelp = true
                                } label: {
                                    SettingRow(icon: "questionmark.circle", title: "Help & Support")
                                }
                                
                                Divider()
                                    .background(Color.theme.surface)
                                    .padding(.leading, 64)
                                
                                Button {
                                    showLogoutAlert = true
                                } label: {
                                    SettingRow(icon: "arrow.right.square", title: "Logout", color: .red)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("PROFILE")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // Action
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(.white)
                    }
                }
            }
            .onAppear {
                // Fetch data when view appears
                if let userId = authManager.user?.id {
                    bookingManager.fetchUserBookings(userId: userId)
                    ticketManager.fetchUserTickets(userId: userId)
                }
            }
            .sheet(isPresented: $showSeedView) {
                DatabaseSeedView()
            }
            .sheet(isPresented: $showAccountSettings) {
                AccountSettingsView()
            }
            .sheet(isPresented: $showNotifications) {
                NotificationsView()
            }
            .sheet(isPresented: $showPrivacy) {
                PrivacyView()
            }
            .sheet(isPresented: $showHelp) {
                HelpView()
            }
            .alert("Logout", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Logout", role: .destructive) {
                    do {
                        try authManager.signOut()
                    } catch {
                        print("Error logging out: \(error)")
                    }
                }
            } message: {
                Text("Are you sure you want to logout?")
            }
            .sheet(item: $selectedRequest) { request in
                QRCodeView(
                    qrCodeId: request.qrCodeId ?? request.id.uuidString,
                    venueName: request.venueName,
                    guestName: request.name,
                    date: request.date.formatted(date: .long, time: .omitted)
                )
                .presentationDetents([.medium])
            }
            .sheet(item: $selectedTicket) { ticket in
                QRCodeView(
                    qrCodeId: ticket.qrCodeId,
                    venueName: ticket.venueName,
                    guestName: authManager.user?.name ?? "Guest",
                    date: ticket.eventDate.formatted(date: .long, time: .shortened)
                )
                .presentationDetents([.medium])
            }
            .sheet(isPresented: $showSubscription) {
                SubscriptionView()
            }
            .sheet(isPresented: $showInvite) {
                InviteView()
            }
        }
    }
}

struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(Theme.Fonts.body(size: 12))
            .fontWeight(.bold)
            .foregroundStyle(Color.theme.textSecondary)
            .padding(.horizontal, 20)
    }
}

struct StatItem: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(Theme.Fonts.display(size: 20))
                .foregroundStyle(.white)
            Text(label.uppercased())
                .font(Theme.Fonts.body(size: 10))
                .foregroundStyle(Color.gray)
        }
    }
}

struct SettingRow: View {
    let icon: String
    let title: String
    var color: Color = Color.theme.textPrimary
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color == .red ? color : Color.theme.textSecondary)
                .frame(width: 24)
            
            Text(title)
                .font(Theme.Fonts.body(size: 16))
                .foregroundStyle(color)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.theme.textSecondary.opacity(0.5))
        }
        .padding(16)
        .background(Color.theme.surface.opacity(0.3))
        .overlay(
            Rectangle()
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}

struct GuestListTicket: View {
    let venueName: String
    let date: String
    let status: String
    
    var statusColor: Color {
        status == "Confirmed" ? .green : .orange
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top Part
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("GUEST LIST")
                        .font(Theme.Fonts.body(size: 10))
                        .fontWeight(.bold)
                        .foregroundStyle(Color.gray)
                    Spacer()
                    Image(systemName: "infinity")
                        .font(.caption)
                        .foregroundStyle(Color.gray)
                }
                
                Text(venueName.uppercased())
                    .font(Theme.Fonts.display(size: 20))
                    .foregroundStyle(.black)
                    .lineLimit(1)
            }
            .padding(16)
            .frame(height: 80)
            .background(Color.white)
            
            // Divider
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.theme.background)
                    .frame(width: 10, height: 10)
                    .offset(x: -5)
                
                Line()
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [4]))
                    .foregroundStyle(Color.gray.opacity(0.3))
                    .frame(height: 1)
                
                Circle()
                    .fill(Color.theme.background)
                    .frame(width: 10, height: 10)
                    .offset(x: 5)
            }
            .background(Color.white)
            
            // Bottom Part
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("DATE")
                        .font(Theme.Fonts.body(size: 8))
                        .foregroundStyle(Color.gray)
                    Text(date)
                        .font(Theme.Fonts.body(size: 14))
                        .fontWeight(.bold)
                        .foregroundStyle(.black)
                }
                
                Spacer()
                
                Text(status.uppercased())
                    .font(Theme.Fonts.body(size: 10))
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.1))
                    .foregroundStyle(statusColor)
                    .clipShape(Capsule())
            }
            .padding(16)
            .background(Color.white)
        }
        .frame(width: 260)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        return path
    }
}

struct OnboardingView: View {
    @Binding var isLoggedIn: Bool

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Background texture/gradient (subtle)
            LinearGradient(
                colors: [Color(white: 0.1), .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo Area
                VStack(spacing: 24) {
                    Image(systemName: "crown.fill") // Changed icon to something more "clubby"
                        .font(.system(size: 60))
                        .foregroundStyle(.white)
                    
                    Text("GLIST")
                        .font(Theme.Fonts.display(size: 48))
                        .tracking(8)
                        .foregroundStyle(.white)

                    Text("DUBAI NIGHTLIFE GUIDE")
                        .font(Theme.Fonts.body(size: 14))
                        .tracking(4)
                        .foregroundStyle(Color.gray)
                }
                
                Spacer()

                // Action
                Button {
                    withAnimation {
                        isLoggedIn = true
                    }
                } label: {
                    Text("ENTER")
                        .font(Theme.Fonts.body(size: 16))
                        .fontWeight(.bold)
                        .tracking(4)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.white)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
            }
        }
    }
}

#Preview {
    ContentView()
}
