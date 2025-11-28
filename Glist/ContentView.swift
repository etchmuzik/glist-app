import SwiftUI
#if canImport(PassKit)
import PassKit
#endif

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var guestListManager: GuestListManager
    
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
        Group {
            if showOnboarding {
                OnboardingView(isLoggedIn: $showOnboarding)
                    .preferredColorScheme(.dark)
            } else if authManager.isAuthenticated {
                MainTabView()
                    .preferredColorScheme(.dark)
                    .onAppear {
                        // Start listening for guest list updates
                        if let userId = authManager.user?.id {
                            guestListManager.fetchRequests(userId: userId)
                            
                            // Update Streak
                            Task {
                                try? await SupabaseDataManager.shared.updateStreak(userId: userId)
                            }
                        }
                    }
                    .onDisappear {
                        guestListManager.clearRequests()
                    }
            } else {
                AuthView()
                    .preferredColorScheme(.dark)
            }
        }
        .onChange(of: authManager.isAuthenticated) { _, newValue in
            if !newValue {
                guestListManager.clearRequests()
                ConciergeChatManager.shared.tearDown()
            }
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject var favoritesManager: FavoritesManager
    @EnvironmentObject var guestListManager: GuestListManager
    @EnvironmentObject var venueManager: VenueManager
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var bookingManager: BookingManager
    @EnvironmentObject var loyaltyManager: LoyaltyManager
    @EnvironmentObject var chatManager: ConciergeChatManager
    @StateObject private var ticketManager = TicketManager()
    @State private var showSeedView = false
    @State private var showSettings = false
    @State private var showMessages = false
    @State private var selectedRequest: GuestListRequest?
    @State private var selectedTicket: EventTicket?
    @State private var showSubscription = false
    @State private var showInvite = false
    @State private var showRewards = false
#if canImport(PassKit)
    @State private var showAddPass = false
    @State private var passToAdd: PKPass?
    @State private var showPassUnavailableAlert = false
#endif
    @State private var showMusicScanner = false
    
    private var membershipCardSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let user = authManager.user {
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(0.9),
                                    Color.theme.surface.opacity(0.9)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 10)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(user.name.uppercased())
                                    .font(Theme.Fonts.body(size: 14))
                                    .foregroundStyle(.white.opacity(0.8))
                                Text(user.referralCode ?? "N/A")
                                    .font(Theme.Fonts.display(size: 22))
                                    .foregroundStyle(.white)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text(user.tier.rawValue.uppercased())
                                    .font(Theme.Fonts.body(size: 12))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.theme.accent.opacity(0.2))
                                    .clipShape(Capsule())
                                Text("ACTIVE")
                                    .font(Theme.Fonts.body(size: 10))
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                        }
                        
                            HStack(alignment: .center, spacing: 16) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Label("QR ACCESS", systemImage: "qrcode.viewfinder")
                                        .font(Theme.Fonts.body(size: 12))
                                        .foregroundStyle(.white.opacity(0.8))
                                    Text("Expires \(Date().addingTimeInterval(60*60*24*180).formatted(date: .numeric, time: .omitted))")
                                        .font(Theme.Fonts.body(size: 10))
                                        .foregroundStyle(.white.opacity(0.6))
                                }
                                Spacer()
                                walletButton
                            }
                        }
                        .padding(20)
                }
                .frame(maxWidth: .infinity)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("PERKS & PRIVILEGES")
                        .font(Theme.Fonts.body(size: 12))
                        .fontWeight(.bold)
                        .foregroundStyle(Color.theme.textSecondary)
                    VStack(alignment: .leading, spacing: 12) {
                        perkRow(icon: "globe.asia.australia", title: "Priority reservations", subtitle: "Exclusive slots at top venues.")
                        perkRow(icon: "star.circle", title: "Tailored picks", subtitle: "Curated lineups and ratings.")
                        perkRow(icon: "creditcard", title: "Perk discounts", subtitle: "Up to 20% with partners.")
                        perkRow(icon: "gift.fill", title: "Member-only offers", subtitle: "Drops and flash perks.")
                        perkRow(icon: "person.2.fill", title: "Meet & greet", subtitle: "Hosts and concierge access.")
                    }
                    .padding()
                    .background(Color.theme.surface.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    private func perkRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.theme.surface.opacity(0.6))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .foregroundStyle(.white)
                    .font(.system(size: 16, weight: .semibold))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.Fonts.body(size: 14))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(Theme.Fonts.body(size: 12))
                    .foregroundStyle(.white.opacity(0.7))
            }
            Spacer()
        }
    }
#if canImport(PassKit)
    private var walletButton: some View {
        Button {
            if let pass = loadMembershipPass() {
                passToAdd = pass
                showAddPass = true
            } else {
                showPassUnavailableAlert = true
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "wallet.pass")
                Text("Add to Wallet")
            }
            .font(Theme.Fonts.body(size: 12))
            .foregroundStyle(.black)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.white)
            .clipShape(Capsule())
        }
        .alert("Pass unavailable", isPresented: $showPassUnavailableAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Wallet pass is not packaged in this build.")
        }
        .sheet(isPresented: $showAddPass) {
            if let passToAdd {
                AddPassViewControllerWrapper(pass: passToAdd)
            }
        }
    }
    
    private func loadMembershipPass() -> PKPass? {
        guard let url = Bundle.main.url(forResource: "MembershipCard", withExtension: "pkpass") else { return nil }
        do {
            let data = try Data(contentsOf: url)
            return try PKPass(data: data)
        } catch {
            return nil
        }
    }
#else
    private var walletButton: some View {
        Button {} label: {
            HStack(spacing: 8) {
                Image(systemName: "wallet.pass")
                Text("Add to Wallet")
            }
            .font(Theme.Fonts.body(size: 12))
            .foregroundStyle(.black)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.white)
            .clipShape(Capsule())
        }
    }
#endif
    
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
                        membershipCardSection
                        headerSection
                        loyaltySection
                        guestListsSection
                        ticketsSection
                        marketplaceSection
                        toolsSection
                        bookingsSection
                        favoritesSection
                        inviteSection
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
                        showSettings = true
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
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(item: $selectedRequest) { request in
                QRCodeView(
                    qrCodeId: request.qrCodeId ?? request.id.uuidString,
                    venueName: request.venueName,
                    guestName: request.name,
                    date: request.date,
                    ticket: nil,
                    guestListRequest: request
                )
                .presentationDetents([.medium])
            }
            .sheet(item: $selectedTicket) { ticket in
                QRCodeView(
                    qrCodeId: ticket.qrCodeId,
                    venueName: ticket.venueName,
                    guestName: authManager.user?.name ?? "Guest",
                    date: ticket.eventDate,
                    ticket: ticket,
                    guestListRequest: nil
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
            .fullScreenCover(isPresented: $showMusicScanner) {
                MusicScannerView()
            }
            .sheet(isPresented: $showMessages) {
                ChatListView()
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
                            UIPasteboard.general.string = user.referralCode ?? ""
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
                                
                                Text(user.referralCode ?? "N/A")
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
    private var marketplaceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "MARKETPLACE")
            
            NavigationLink(destination: ResaleMarketplaceView()) {
                HStack(spacing: 16) {
                    Image(systemName: "cart.fill")
                        .font(.title2)
                        .foregroundStyle(Color.theme.accent)
                        .frame(width: 40)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Resale Marketplace")
                            .font(Theme.Fonts.body(size: 16))
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                        
                        Text("Buy and sell verified tickets")
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
            .padding(.horizontal, 20)
        }
    }
    
    @ViewBuilder
    private var toolsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "TOOLS")
            
            Button {
                showMusicScanner = true
            } label: {
                HStack(spacing: 16) {
                    Image(systemName: "shazam.logo.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                        .frame(width: 40)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Music Scanner")
                            .font(Theme.Fonts.body(size: 16))
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                        
                        Text("Identify songs playing now")
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
            .padding(.horizontal, 20)
            
            Button {
                showMessages = true
            } label: {
                HStack(spacing: 16) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.title2)
                        .foregroundStyle(Color.theme.accent)
                        .frame(width: 40)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Concierge Support")
                            .font(Theme.Fonts.body(size: 16))
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                        
                        Text("Chat with our support team")
                            .font(Theme.Fonts.body(size: 14))
                            .foregroundStyle(.gray)
                    }
                    
                    Spacer()
                    
                    let unreadCount = chatManager.chatThreads.reduce(0) { $0 + $1.unreadCount }
                    if unreadCount > 0 {
                         Text("\(unreadCount)")
                            .font(Theme.Fonts.body(size: 12))
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(6)
                            .background(Color.red)
                            .clipShape(Circle())
                    }
                    
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.gray)
                }
                .padding(16)
                .background(Color.theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 20)
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


    
    @ViewBuilder
    private var developerSection: some View {
        if authManager.userRole == .admin {
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
