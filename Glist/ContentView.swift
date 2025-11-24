import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = AuthManager()
    @StateObject private var favoritesManager = FavoritesManager()
    @StateObject private var guestListManager = GuestListManager()
    @StateObject private var venueManager = VenueManager()
    @StateObject private var loyaltyManager = LoyaltyManager.shared

    // Controls whether we show the sleek onboarding screen first.
    @State private var showOnboarding: Bool = true

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
        if showOnboarding {
            OnboardingView(isLoggedIn: $showOnboarding)
                .preferredColorScheme(.dark)
        } else if authManager.isAuthenticated {
            MainTabView()
                .preferredColorScheme(.dark)
                .environmentObject(favoritesManager)
                .environmentObject(guestListManager)
                .environmentObject(authManager)
                .environmentObject(venueManager)
                .environmentObject(loyaltyManager)
                .onAppear {
                    // Start listening for guest list updates
                    if let userId = authManager.user?.id {
                        guestListManager.startListening(userId: userId)
                        
                        // Update Streak
                        Task {
                            try? await FirestoreManager.shared.updateStreak(userId: userId)
                        }
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
            
            SocialView()
                .tabItem {
                    Label("SOCIAL", systemImage: "person.2.fill")
                }

            ChatListView()
                .tabItem {
                    Label("MESSAGES", systemImage: "bubble.left.and.bubble.right.fill")
                }

            ProfileView()
                .tabItem {
                    Label("PROFILE", systemImage: "person")
                }
+++++++ REPLACE</parameter>
            
            
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
    @EnvironmentObject var loyaltyManager: LoyaltyManager
    @StateObject private var ticketManager = TicketManager()
    @State private var showSeedView = false
    @State private var showAccountSettings = false
    @State private var showNotifications = false
    @State private var showPrivacy = false
    @State private var showHelp = false
    @State private var showLogoutAlert = false
    @State private var showKYC = false
    @State private var selectedRequest: GuestListRequest?
    @State private var selectedTicket: EventTicket?
    @State private var showSubscription = false
    @State private var showInvite = false
    @State private var showRewards = false
    
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
                        headerSection
                        loyaltySection
                        guestListsSection
                        ticketsSection
                        bookingsSection
                        favoritesSection
                        inviteSection
                        settingsSection
                        developerSection
                    }
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle(LocalizedStringKey("profile_title"))
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
            .sheet(isPresented: $showKYC) {
                KYCSubmissionView()
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
                    date: request.date
                )
                .presentationDetents([.medium])
            }
            .sheet(item: $selectedTicket) { ticket in
                QRCodeView(
                    qrCodeId: ticket.qrCodeId,
                    venueName: ticket.venueName,
                    guestName: authManager.user?.name ?? "Guest",
                    date: ticket.eventDate
                )
                .presentationDetents([.medium])
            }
            .sheet(isPresented: $showSubscription) {
                SubscriptionView()
            }
            .sheet(isPresented: $showInvite) {
                InviteView()
            }
            .sheet(isPresented: $showRewards) {
                RewardsView()
            }
        }
    }

    // MARK: - Subviews

    private var headerSection: some View {
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
                                Text(LocalizedStringKey("upgrade_membership"))
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
                            Text(LocalizedStringKey("followers"))
                                .font(Theme.Fonts.body(size: 12))
                                .foregroundStyle(.gray)
                            }
                            
                            VStack {
                                Text("\(user.following.count)")
                                    .font(Theme.Fonts.display(size: 18))
                                    .foregroundStyle(.white)
                            Text(LocalizedStringKey("following"))
                                .font(Theme.Fonts.body(size: 12))
                                .foregroundStyle(.gray)
                            }
                            
                            NavigationLink(destination: SocialView()) {
                                Text(LocalizedStringKey("find_friends"))
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
                StatItem(value: "\(guestListManager.requests.count)", label: NSLocalizedString("guest_lists_title", comment: ""))
                StatItem(value: "\(bookingManager.bookings.count)", label: NSLocalizedString("bookings_title", comment: ""))
                StatItem(value: "\(favoriteVenues.count)", label: NSLocalizedString("favorites_title", comment: ""))
            }
            .padding(.top, 10)
        }
        .padding(.top, 20)
    }

    @ViewBuilder
    private var loyaltySection: some View {
        if let user = authManager.user {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    SectionHeader(title: NSLocalizedString("loyalty_rewards", comment: ""))
                    Spacer()
                    Button {
                        showRewards = true
                    } label: {
                        Text(LocalizedStringKey("redeem"))
                            .font(Theme.Fonts.body(size: 12))
                            .fontWeight(.bold)
                            .foregroundStyle(Color.theme.accent)
                            .padding(.horizontal, 16)
                    }
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        // Points Card
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "star.circle.fill")
                                    .foregroundStyle(.yellow)
                                Text(LocalizedStringKey("points"))
                                    .font(Theme.Fonts.body(size: 10))
                                    .fontWeight(.bold)
                                    .foregroundStyle(.gray)
                            }
                            
                            Text("\(user.rewardPoints)")
                                .font(Theme.Fonts.display(size: 24))
                                .foregroundStyle(.white)
                            
                            Text("Lifetime: \(user.lifetimePoints)")
                                .font(Theme.Fonts.body(size: 10))
                                .foregroundStyle(.gray)
                        }
                        .padding(16)
                        .frame(width: 140, height: 100)
                        .background(Color.theme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        // Streak Card
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "flame.fill")
                                    .foregroundStyle(.orange)
                                Text(LocalizedStringKey("streak"))
                                    .font(Theme.Fonts.body(size: 10))
                                    .fontWeight(.bold)
                                    .foregroundStyle(.gray)
                            }
                            
                            Text("\(user.currentStreak) WEEKS")
                                .font(Theme.Fonts.display(size: 24))
                                .foregroundStyle(.white)
                            
                            Text("Keep it up!")
                                .font(Theme.Fonts.body(size: 10))
                                .foregroundStyle(.gray)
                        }
                        .padding(16)
                        .frame(width: 140, height: 100)
                        .background(Color.theme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        // Referral Card
                        Button {
                            UIPasteboard.general.string = user.referralCode
                        } label: {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "person.2.fill")
                                        .foregroundStyle(.blue)
                                    Text("REFERRAL")
                                        .font(Theme.Fonts.body(size: 10))
                                        .fontWeight(.bold)
                                        .foregroundStyle(.gray)
                                }
                                
                                Text(user.referralCode)
                                    .font(Theme.Fonts.display(size: 20))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                
                                Text("Tap to copy")
                                    .font(Theme.Fonts.body(size: 10))
                                    .foregroundStyle(.gray)
                            }
                            .padding(16)
                            .frame(width: 140, height: 100)
                            .background(Color.theme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // Active Campaigns
                let campaigns = loyaltyManager.checkCampaigns(for: user)
                if !campaigns.isEmpty {
                    ForEach(campaigns) { campaign in
                        HStack(spacing: 16) {
                            Image(systemName: "gift.fill")
                                .font(.title2)
                                .foregroundStyle(.pink)
                                .frame(width: 40)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(campaign.title)
                                    .font(Theme.Fonts.body(size: 14))
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                
                                Text(campaign.message)
                                    .font(Theme.Fonts.body(size: 12))
                                    .foregroundStyle(.gray)
                            }
                            
                            Spacer()
                        }
                        .padding(16)
                        .background(Color.theme.surface.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 20)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var guestListsSection: some View {
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
    }

    @ViewBuilder
    private var ticketsSection: some View {
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
    }

    @ViewBuilder
    private var bookingsSection: some View {
        if !bookingManager.bookings.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "MY BOOKINGS")
                
                ForEach(bookingManager.bookings) { booking in
                    BookingCard(booking: booking)
                }
                .padding(.horizontal, 20)
            }
        }
    }

    @ViewBuilder
    private var favoritesSection: some View {
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
    }

    private var inviteSection: some View {
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
    }

    private var settingsSection: some View {
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
                    showKYC = true
                } label: {
                    SettingRow(icon: "checkmark.seal", title: "Identity Verification")
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
    
    private var developerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "DEVELOPER")
            
            VStack(spacing: 12) {
                Text("Current Role: \(authManager.userRole.rawValue.uppercased())")
                    .font(Theme.Fonts.body(size: 12))
                    .foregroundStyle(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        Button {
                            Task { try? await authManager.updateRole(to: .user) }
                        } label: {
                            Text("User")
                                .font(Theme.Fonts.body(size: 12))
                                .fontWeight(.bold)
                                .foregroundStyle(authManager.userRole == .user ? .black : .white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(authManager.userRole == .user ? .white : Color.theme.surface)
                                .clipShape(Capsule())
                        }
                        
                        Button {
                            Task { try? await authManager.updateRole(to: .promoter) }
                        } label: {
                            Text("Promoter")
                                .font(Theme.Fonts.body(size: 12))
                                .fontWeight(.bold)
                                .foregroundStyle(authManager.userRole == .promoter ? .black : .white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(authManager.userRole == .promoter ? .white : Color.theme.surface)
                                .clipShape(Capsule())
                        }
                        
                        Button {
                            Task { try? await authManager.updateRole(to: .admin) }
                        } label: {
                            Text("Admin")
                                .font(Theme.Fonts.body(size: 12))
                                .fontWeight(.bold)
                                .foregroundStyle(authManager.userRole == .admin ? .black : .white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(authManager.userRole == .admin ? .white : Color.theme.surface)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 20)
                }
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
    @State private var isAnimating = false
    @State private var showContent = false
    
    var body: some View {
        ZStack {
            // 1. Dynamic Background
            Color.black.ignoresSafeArea()
            
            // Ambient Orbs
            GeometryReader { proxy in
                ZStack {
                    Circle()
                        .fill(Color(hex: "9D00FF").opacity(0.3))
                        .frame(width: 300, height: 300)
                        .blur(radius: 80)
                        .offset(x: isAnimating ? -100 : 100, y: isAnimating ? -150 : 150)
                    
                    Circle()
                        .fill(Color(hex: "FF0055").opacity(0.2))
                        .frame(width: 250, height: 250)
                        .blur(radius: 80)
                        .offset(x: isAnimating ? 150 : -150, y: isAnimating ? 100 : -100)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            // 2. Content
            VStack(spacing: 0) {
                Spacer()
                
                // Logo Section
                VStack(spacing: 16) {
                    // Animated Crown Icon
                    Image(systemName: "crown.fill")
                        .font(.system(size: 70))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .white.opacity(0.5), radius: 20, x: 0, y: 0)
                        .scaleEffect(isAnimating ? 1.0 : 0.8)
                        .opacity(isAnimating ? 1 : 0)
                    
                    // Main Title
                    Text("LSTD")
                        .font(Theme.Fonts.display(size: 56))
                        .tracking(10)
                        .foregroundStyle(.white)
                        .shadow(color: Color(hex: "9D00FF").opacity(0.5), radius: 15, x: 0, y: 0)
                        .scaleEffect(isAnimating ? 1.0 : 0.9)
                        .opacity(isAnimating ? 1 : 0)
                    
                    // Tagline
                    Text("ACCESS THE UNACCESSIBLE")
                        .font(Theme.Fonts.body(size: 14))
                        .tracking(6)
                        .foregroundStyle(Color.white.opacity(0.7))
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                }
                .padding(.bottom, 60)
                
                Spacer()
                
                // 3. Action Button
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .heavy)
                    generator.impactOccurred()
                    
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        // Flip off onboarding so we route into auth/main flow
                        isLoggedIn = false
                    }
                } label: {
                    HStack(spacing: 12) {
                        Text("ENTER THE NIGHT")
                            .font(Theme.Fonts.body(size: 16))
                            .fontWeight(.bold)
                            .tracking(2)
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        ZStack {
                            Color.white
                            
                            // Subtle shimmer effect could go here
                        }
                    )
                    .clipShape(Capsule())
                    .shadow(color: .white.opacity(0.2), radius: 20, x: 0, y: 0)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 40)
            }
        }
        .onAppear {
            // Animation Sequence
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
            
            withAnimation(.easeOut(duration: 1.0).delay(0.5)) {
                showContent = true
            }
        }
    }
}

#Preview {
    ContentView()
}
