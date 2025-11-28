import SwiftUI

struct VenueDetailView: View {
    let venue: Venue
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var socialManager: SocialManager
    @State private var showGuestListSheet = false
    @State private var showTableBooking = false
    @State private var selectedEvent: Event?
    
    @State private var showTickets = false
    @State private var selectedTicket: TicketOption? = nil
    @State private var showApplePay = false
    @State private var applePayAmount: Double = 0
    @State private var applePayDescription: String = ""
    @StateObject private var ticketManager = TicketManager()
    
    private var isUserRestricted: Bool {
        authManager.user?.isBanned == true || authManager.user?.isSoftBanned == true
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header Image
                Rectangle()
                    .fill(Color.theme.surface)
                    .frame(height: 300)
                    .overlay {
                        // Placeholder gradient until real images are added
                        LinearGradient(
                            colors: [.purple.opacity(0.3), .blue.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        
                        Image(systemName: "photo")
                            .font(.system(size: 40))
                            .foregroundStyle(Color.theme.textSecondary)
                    }
                    .overlay(alignment: .bottomLeading) {
                        LinearGradient(
                            colors: [.clear, Color.theme.background],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                
                VStack(alignment: .leading, spacing: 24) {
                    // Title Section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(venue.name.uppercased())
                                .font(Theme.Fonts.display(size: 32))
                                .foregroundStyle(Color.theme.textPrimary)
                            
                            if venue.isVerified {
                                VerifiedBadge(text: NSLocalizedString("verified_venue", comment: ""))
                            }
                            
                            Spacer()
                            
                            FavoriteButton(venueId: venue.id)
                        }
                        
                        HStack {
                            Text(venue.type.uppercased())
                                .font(Theme.Fonts.body(size: 14))
                                .foregroundStyle(Color.theme.accent)
                            
                            Circle()
                                .fill(Color.theme.textSecondary)
                                .frame(width: 4, height: 4)
                            
                            Image(systemName: "star.fill")
                                .foregroundStyle(Color.yellow)
                                .font(.caption)
                            Text(String(format: "%.1f", venue.rating))
                                .font(Theme.Fonts.body(size: 14))
                                .foregroundStyle(Color.theme.textPrimary)
                        }
                    }
                    
                    // Features
                    if !venue.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(venue.tags, id: \.self) { tag in
                                    HStack(spacing: 6) {
                                        Image(systemName: "sparkles")
                                        Text(tag)
                                            .font(Theme.Fonts.body(size: 12))
                                    }
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.theme.surface.opacity(0.5))
                                    .clipShape(Capsule())
                                }
                            }
                        }
                    }
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        if let user = authManager.user {
                            if user.isBanned {
                                SafetyCallout(
                                    title: NSLocalizedString("account_restricted", comment: ""),
                                    message: NSLocalizedString("account_restricted_msg", comment: "")
                                )
                            } else if user.isSoftBanned, let softBanUntil = user.softBanUntil {
                                SafetyCallout(
                                    title: NSLocalizedString("cooling_off_period", comment: ""),
                                    message: "You can browse venues, but bookings resume after \(softBanUntil.formatted(date: .abbreviated, time: .omitted)). No-show count: \(user.noShowCount)."
                                )
                            }
                        }
                        
                        HStack(spacing: 12) {
                            Button {
                                showGuestListSheet = true
                            } label: {
                                Text(LocalizedStringKey("join_guest_list"))
                                    .font(Theme.Fonts.body(size: 14))
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color.black)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 0))
                            }
                            .disabled(isUserRestricted)
                            
                            Button {
                                showTickets = true
                            } label: {
                                Text(LocalizedStringKey("buy_tickets"))
                                    .font(Theme.Fonts.body(size: 14))
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color.black)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 0))
                            }
                            .disabled(isUserRestricted)
                            
                            Button {
                                showTableBooking = true
                            } label: {
                                Text(LocalizedStringKey("book_table"))
                                    .font(Theme.Fonts.body(size: 14))
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color.black)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 0))
                            }
                            .disabled(isUserRestricted)
                            
                            if venue.events.isEmpty {
                                ShareLink(item: "Check out \(venue.name) on LSTD!") {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 20))
                                        .foregroundStyle(Color.white)
                                        .frame(width: 50, height: 50)
                                        .background(Color.theme.surface)
                                        .clipShape(RoundedRectangle(cornerRadius: 0))
                                }
                            }
                        }
                        
                        if !venue.events.isEmpty {
                            HStack(spacing: 12) {
                                Button {
                                    selectedEvent = venue.events.first
                                } label: {
                                    Text(LocalizedStringKey("buy_tickets"))
                                        .font(Theme.Fonts.body(size: 14))
                                        .fontWeight(.bold)
                                        .foregroundStyle(Color.black)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 50)
                                        .background(Color.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 0))
                                }
                                .disabled(isUserRestricted)
                                
                                ShareLink(item: "Check out \(venue.name) on LSTD!") {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 20))
                                        .foregroundStyle(Color.white)
                                        .frame(width: 50, height: 50)
                                        .background(Color.theme.surface)
                                        .clipShape(RoundedRectangle(cornerRadius: 0))
                                }
                            }
                        }
                    }
                    
                    // Events Section
                    if !venue.events.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text(LocalizedStringKey("upcoming_events"))
                                .font(Theme.Fonts.body(size: 12))
                                .fontWeight(.bold)
                                .foregroundStyle(Color.theme.textSecondary)
                            
                            ForEach(venue.events) { event in
                                Button {
                                    selectedEvent = event
                                } label: {
                                    HStack(spacing: 16) {
                                        // Date Box
                                        VStack(spacing: 2) {
                                            Text(event.date.formatted(.dateTime.month(.abbreviated)).uppercased())
                                                .font(Theme.Fonts.body(size: 10))
                                                .foregroundStyle(Color.theme.accent)
                                            Text(event.date.formatted(.dateTime.day()))
                                                .font(Theme.Fonts.display(size: 20))
                                                .foregroundStyle(Color.theme.textPrimary)
                                        }
                                        .frame(width: 50, height: 50)
                                        .background(Color.theme.surface)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(event.name.uppercased())
                                                .font(Theme.Fonts.display(size: 16))
                                                .foregroundStyle(Color.theme.textPrimary)
                                                .multilineTextAlignment(.leading)
                                            
                                            if let description = event.description {
                                                Text(description)
                                                    .font(Theme.Fonts.body(size: 12))
                                                    .foregroundStyle(Color.theme.textSecondary)
                                                    .lineLimit(1)
                                                    .multilineTextAlignment(.leading)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundStyle(Color.theme.textSecondary)
                                    }
                                    .padding(12)
                                    .background(Color.theme.surface.opacity(0.5))
                                }
                            }
                        }
                    }
                    
                    
                    
                    // Weekly Schedule
                    if !venue.weeklySchedule.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(LocalizedStringKey("weekly_schedule"))
                                .font(Theme.Fonts.body(size: 12))
                                .fontWeight(.bold)
                                .foregroundStyle(Color.theme.textSecondary)
                            
                            VStack(spacing: 1) {
                                ForEach(venue.weeklySchedule.sorted(by: { $0.key < $1.key }), id: \.key) { day, eventName in
                                    HStack {
                                        Text(day)
                                            .font(Theme.Fonts.body(size: 14))
                                            .foregroundStyle(Color.theme.textSecondary)
                                            .frame(width: 100, alignment: .leading)
                                        
                                        Text(eventName)
                                            .font(Theme.Fonts.body(size: 14))
                                            .fontWeight(.medium)
                                            .foregroundStyle(Color.theme.textPrimary)
                                        
                                        Spacer()
                                    }
                                    .padding()
                                    .background(Color.theme.surface)
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    // Floor Plan
                    if let floorplanImage = venue.floorplanImage {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(LocalizedStringKey("floor_plan"))
                                .font(Theme.Fonts.body(size: 12))
                                .fontWeight(.bold)
                                .foregroundStyle(Color.theme.textSecondary)
                            
                            if let url = URL(string: floorplanImage) {
                                AsyncImage(url: url) { image in
                                    image.resizable().scaledToFit()
                                } placeholder: {
                                    ZStack {
                                        Color.theme.surface
                                        ProgressView()
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            } else {
                                Image(systemName: "map")
                                    .font(.system(size: 40))
                                    .foregroundStyle(Color.theme.textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 200)
                                    .background(Color.theme.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    // Who's Going Section
                    let friendsAtVenue = socialManager.getFriendsAt(venueId: venue.id.uuidString)
                    if !friendsAtVenue.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(LocalizedStringKey("whos_going"))
                                .font(Theme.Fonts.body(size: 12))
                                .fontWeight(.bold)
                                .foregroundStyle(Color.theme.textSecondary)
                            
                            HStack(spacing: -10) {
                                ForEach(friendsAtVenue.prefix(5)) { friend in
                                    if let imageUrl = friend.profileImage, let url = URL(string: imageUrl) {
                                        AsyncImage(url: url) { image in
                                            image.resizable().scaledToFill()
                                        } placeholder: {
                                            Color.gray
                                        }
                                        .frame(width: 40, height: 40)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.black, lineWidth: 2))
                                    } else {
                                        Image(systemName: "person.circle.fill")
                                            .font(.system(size: 40))
                                            .foregroundStyle(.gray)
                                            .background(Circle().fill(Color.white))
                                            .overlay(Circle().stroke(Color.black, lineWidth: 2))
                                    }
                                }
                                
                                if friendsAtVenue.count > 5 {
                                    Text("+\(friendsAtVenue.count - 5)")
                                        .font(Theme.Fonts.body(size: 12))
                                        .fontWeight(.bold)
                                        .foregroundStyle(.white)
                                        .frame(width: 40, height: 40)
                                        .background(Color.gray)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.black, lineWidth: 2))
                                }
                            }
                        }
                    }
                    
                    // Description
                    VStack(alignment: .leading, spacing: 12) {
                        Text(LocalizedStringKey("about"))
                            .font(Theme.Fonts.body(size: 12))
                            .fontWeight(.bold)
                            .foregroundStyle(Color.theme.textSecondary)
                        
                        Text(venue.description)
                            .font(Theme.Fonts.body(size: 16))
                            .foregroundStyle(Color.theme.textPrimary)
                            .lineSpacing(6)
                    }
                    
                    if venue.isVerified || venue.safetyMessage != nil {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(LocalizedStringKey("trust_safety"))
                                .font(Theme.Fonts.body(size: 12))
                                .fontWeight(.bold)
                                .foregroundStyle(Color.theme.textSecondary)
                            
                            HStack(spacing: 12) {
                                if venue.isVerified {
                                    VerifiedBadge(text: NSLocalizedString("verified_venue", comment: ""))
                                }
                                
                                SafetyPill(icon: "person.badge.shield", text: "Age \(venue.minimumAge)+ • ID required")
                                SafetyPill(icon: "checkmark.shield", text: NSLocalizedString("venue_policies", comment: ""))
                            }
                            
                            if let safetyMessage = venue.safetyMessage {
                                Text(safetyMessage)
                                    .font(Theme.Fonts.body(size: 14))
                                    .foregroundStyle(Color.theme.textPrimary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        
                        // Rules & Policies
                        let rules = BookingRulesProvider.forVenue(venue)
                        RulesSectionView(rules: rules)
                    } else {
                        // If no safety section, place rules after description
                        // Rules & Policies
                        let rules = BookingRulesProvider.forVenue(venue)
                        RulesSectionView(rules: rules)
                    }
                    
                    // Info Grid
                    HStack(spacing: 16) {
                        // Price
                        VStack(alignment: .leading, spacing: 8) {
                            Text(LocalizedStringKey("price_label"))
                                .font(Theme.Fonts.body(size: 10))
                                .fontWeight(.bold)
                                .foregroundStyle(Color.theme.textSecondary)
                            
                            Text(venue.price)
                                .font(Theme.Fonts.body(size: 16))
                                .foregroundStyle(Color.theme.textPrimary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(Color.theme.surface)
                        
                        // Dress Code
                        VStack(alignment: .leading, spacing: 8) {
                            Text(LocalizedStringKey("dress_code_label"))
                                .font(Theme.Fonts.body(size: 10))
                                .fontWeight(.bold)
                                .foregroundStyle(Color.theme.textSecondary)
                            
                            Text(venue.dressCode)
                                .font(Theme.Fonts.body(size: 16))
                                .foregroundStyle(Color.theme.textPrimary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(Color.theme.surface)
                    }
                    
                    // Location & Rideshare
                    VStack(alignment: .leading, spacing: 12) {
                        Text(LocalizedStringKey("location_label"))
                            .font(Theme.Fonts.body(size: 12))
                            .fontWeight(.bold)
                            .foregroundStyle(Color.theme.textSecondary)
                        
                        // Open in Apple Maps
                        Button {
                            let query = venue.location.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                            if let url = URL(string: "http://maps.apple.com/?q=\(query)") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundStyle(Color.theme.textSecondary)
                                Text(venue.location)
                                    .font(Theme.Fonts.body(size: 16))
                                    .foregroundStyle(Color.theme.textPrimary)
                                    .multilineTextAlignment(.leading)
                                
                                Spacer()
                                
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundStyle(Color.theme.textSecondary)
                            }
                            .padding(12)
                            .background(Color.theme.surface)
                        }
                        
                        // Get a ride: Careem / Ekar / Apple Maps fallback
                        Button {
                            RideShareManager.openBestOption(for: venue)
                        } label: {
                            HStack {
                                Image(systemName: "car.fill")
                                    .foregroundStyle(Color.theme.accent)
                                Text(LocalizedStringKey("get_a_ride"))
                                    .font(Theme.Fonts.body(size: 16))
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color.theme.textPrimary)
                                
                                Spacer()
                                
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundStyle(Color.theme.textSecondary)
                            }
                            .padding(12)
                            .background(Color.theme.surface.opacity(0.9))
                        }
                    }
                    
                    // Tags
                    FlowLayout(items: venue.tags) { tag in
                        Text(tag.uppercased())
                            .font(Theme.Fonts.body(size: 10))
                            .fontWeight(.bold)
                            .foregroundStyle(Color.theme.textPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.theme.surface)
                            .overlay(
                                Rectangle()
                                    .stroke(Color.theme.surface, lineWidth: 1)
                            )
                    }
                }
                .padding(24)
            }

        .background(Color.theme.background)
            .ignoresSafeArea(edges: .top)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20))
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                }
            }
            .onAppear {
                if let user = authManager.user {
                    Task {
                        await socialManager.fetchFriendsGoing(venueId: venue.id.uuidString, currentUserFollowing: user.following)
                    }
                }
            }
            .sheet(item: $selectedEvent) { event in
                EventTicketView(venue: venue, event: event)
            }
            .sheet(isPresented: $showGuestListSheet) {
                GuestListFormView(venue: venue)
            }
            .sheet(isPresented: $showTableBooking) {
                TableBookingView(venue: venue)
            }
            .sheet(isPresented: $showTickets) {
                TicketSelectionView(selectedTicket: $selectedTicket) { ticket in
                    selectedTicket = ticket
                    showTickets = false
                    if !venue.events.isEmpty {
                        selectedEvent = venue.events.first
                    } else {
                        applePayAmount = ticket.price
                        applePayDescription = "Ticket: \(ticket.name) • \(ticket.phase)"
                        showApplePay = true
                    }
                }
            }
            .sheet(isPresented: $showApplePay) {
                TicketCheckoutView(
                    venueId: venue.id.uuidString,
                    venueName: venue.name,
                    amount: applePayAmount,
                    description: applePayDescription,
                    onSuccess: {
                        Task {
                            if let userId = authManager.user?.id, let ticketOption = selectedTicket {
                                let placeholderEvent = Event(
                                    name: "General Entry",
                                    date: Date(),
                                    imageUrl: nil,
                                    description: "General admission to \(venue.name)"
                                )
                                
                                let ticketType = TicketType(
                                    id: UUID(),
                                    name: ticketOption.name,
                                    price: ticketOption.price,
                                    totalQuantity: 999,
                                    availableQuantity: 999,
                                    description: ticketOption.phase
                                )
                                
                                do {
                                    _ = try await ticketManager.purchaseTicket(
                                        userId: userId,
                                        event: placeholderEvent,
                                        venue: venue,
                                        ticketType: ticketType,
                                        quantity: 1
                                    )
                                    print("Ticket created successfully via Apple Pay fallback")
                                } catch {
                                    print("Failed to create ticket after payment: \(error)")
                                }
                            }
                            showApplePay = false
                        }
                    },
                    onCancel: {
                        showApplePay = false
                    }
                )
            }
        
    }
    }
}

struct GuestListFormView: View {
    let venue: Venue
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var guestListManager: GuestListManager
    @EnvironmentObject var authManager: AuthManager
    
    @State private var name = ""
    @State private var email = ""
    @State private var guests = 1
    @State private var guestNames: [String] = []
    @State private var date = Date()
    @State private var showSuccess = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.background.ignoresSafeArea()
                
                if showSuccess {
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                        // ... (success view content remains same)
                            .font(.system(size: 60))
                            .foregroundStyle(.white)
                        Text(LocalizedStringKey("request_sent"))
                            .font(Theme.Fonts.display(size: 24))
                            .foregroundStyle(.white)
                        Text(LocalizedStringKey("request_sent_msg"))
                            .font(Theme.Fonts.body(size: 16))
                            .foregroundStyle(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else if let user = authManager.user, user.isBanned {
                    SafetyCallout(
                        title: NSLocalizedString("booking_blocked", comment: ""),
                        message: NSLocalizedString("booking_blocked_msg", comment: "")
                    )
                    .padding()
                } else if let user = authManager.user, user.isSoftBanned, let softBanUntil = user.softBanUntil {
                    SafetyCallout(
                        title: NSLocalizedString("temporarily_paused", comment: ""),
                        message: "Guest list requests paused until \(softBanUntil.formatted(date: .abbreviated, time: .omitted)). Your no-show count is \(user.noShowCount)."
                    )
                    .padding()
                } else {
                    Form {
                        Section {
                            TextField(LocalizedStringKey("Full Name"), text: $name)
                            TextField(LocalizedStringKey("Email"), text: $email)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                        } header: {
                            Text(LocalizedStringKey("your_details"))
                        }
                        
                        Section {
                            DatePicker(LocalizedStringKey("Date"), selection: $date, displayedComponents: .date)
                            Stepper("Guests: \(guests)", value: $guests, in: 1...10)
                                .onChange(of: guests) { _, newValue in
                                    // Adjust guestNames array size
                                    if newValue > 1 {
                                        let additionalGuests = newValue - 1
                                        if guestNames.count < additionalGuests {
                                            guestNames.append(contentsOf: Array(repeating: "", count: additionalGuests - guestNames.count))
                                        } else if guestNames.count > additionalGuests {
                                            guestNames.removeLast(guestNames.count - additionalGuests)
                                        }
                                    } else {
                                        guestNames.removeAll()
                                    }
                                }
                            
                            if guests > 1 {
                                ForEach(0..<guestNames.count, id: \.self) { index in
                                    TextField("Guest \(index + 2) Name", text: $guestNames[index])
                                }
                            }
                        } header: {
                            Text(LocalizedStringKey("reservation"))
                        }
                    }
                    .scrollContentBackground(.hidden)
                    
                    // Policies for Guest List
                    let rules = BookingRulesProvider.forGuestList(venue)
                    PolicyDisclosureRow(
                        rules: rules,
                        contextText: "By submitting, you agree to: ID • Entry Policy • No-show policy"
                    )
                    .padding()
                }
            }
            .navigationTitle(showSuccess ? "" : "JOIN GUEST LIST")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(LocalizedStringKey("cancel")) {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
                
                if !showSuccess {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(LocalizedStringKey("submit")) {
                            Task {
                                do {
                                    let generator = UINotificationFeedbackGenerator()
                                    generator.notificationOccurred(.success)
                                    
                                    // Add request to manager
                                    try await guestListManager.addRequest(
                                        userId: authManager.user?.id ?? "",
                                        venueId: venue.id.uuidString,
                                        venueName: venue.name,
                                        name: name,
                                        email: email,
                                        date: date,
                                        guestCount: guests,
                                        guestNames: guestNames // Pass guest names
                                    )
                                    
                                    await MainActor.run {
                                        withAnimation {
                                            showSuccess = true
                                        }
                                    }
                                } catch {
                                    print("Error submitting guest list: \(error)")
                                }
                            }
                        }
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .disabled(name.isEmpty || email.isEmpty || (guests > 1 && guestNames.contains(where: { $0.isEmpty })) || authManager.user?.isBanned == true || authManager.user?.isSoftBanned == true)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct VerifiedBadge: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.seal.fill")
                .font(.caption)
            Text(text.uppercased())
                .font(Theme.Fonts.body(size: 10))
                .fontWeight(.bold)
        }
        .foregroundStyle(.green)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.green.opacity(0.15))
        .clipShape(Capsule())
    }
}

struct SafetyCallout: View {
    let title: String
    let message: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.shield.fill")
                .font(.title3)
                .foregroundStyle(.yellow)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title.uppercased())
                    .font(Theme.Fonts.body(size: 12))
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                Text(message)
                    .font(Theme.Fonts.body(size: 12))
                    .foregroundStyle(.gray)
            }
        }
        .padding(12)
        .background(Color.theme.surface.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct SafetyPill: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(Theme.Fonts.body(size: 12))
        }
        .foregroundStyle(Color.theme.textPrimary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.theme.surface.opacity(0.5))
        .clipShape(Capsule())
    }
}

// Helper for tags layout
struct FlowLayout<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let items: Data
    let content: (Data.Element) -> Content
    @State private var totalHeight: CGFloat = .zero
    
    var body: some View {
        GeometryReader { geometry in
            self.generateContent(in: geometry)
        }
        .frame(height: totalHeight)
    }
    
    private func generateContent(in geometry: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        
        return ZStack(alignment: .topLeading) {
            ForEach(items, id: \.self) { item in
                self.content(item)
                    .padding([.horizontal, .vertical], 4)
                    .alignmentGuide(.leading, computeValue: { d in
                        if (abs(width - d.width) > geometry.size.width) {
                            width = 0
                            height -= d.height
                        }
                        let result = width
                        if item == self.items.last! {
                            width = 0 // last item
                        } else {
                            width -= d.width
                        }
                        return result
                    })
                    .alignmentGuide(.top, computeValue: { d in
                        let result = height
                        if item == self.items.last! {
                            height = 0 // last item
                        }
                        return result
                    })
            }
        }
        .background(viewHeightReader($totalHeight))
    }
    
    private func viewHeightReader(_ binding: Binding<CGFloat>) -> some View {
        GeometryReader { geometry -> Color in
            DispatchQueue.main.async {
                binding.wrappedValue = geometry.size.height
            }
            return .clear
        }
    }
}

// MARK: - Tickets

struct TicketOption: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let phase: String
    let price: Double
}

struct TicketSelectionView: View {
    @Binding var selectedTicket: TicketOption?
    let onContinue: (TicketOption) -> Void
    
    private let ticketOptions: [TicketOption] = [
        TicketOption(name: "GA Early Bird", phase: "Early Bird", price: 150),
        TicketOption(name: "GA", phase: "General Admission", price: 200),
        TicketOption(name: "VIP Presale", phase: "Presale", price: 350),
        TicketOption(name: "VIP", phase: "VIP", price: 450)
    ]
    
    @Environment(\.dismiss) var dismiss
    
    @State private var quantity: Int = 1
    private let serviceFeeRate: Double = 0.05
    private let processingFee: Double = 3.0
    
    private var subtotal: Double {
        (selectedTicket?.price ?? 0) * Double(quantity)
    }
    private var serviceFee: Double {
        subtotal * serviceFeeRate
    }
    private var total: Double {
        subtotal + serviceFee + processingFee
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                List(ticketOptions, id: \.id) { option in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(option.name)
                                .font(Theme.Fonts.body(size: 16))
                                .foregroundStyle(Color.theme.textPrimary)
                            Text("\(Int(option.price)) AED")
                                .font(Theme.Fonts.body(size: 14))
                                .foregroundStyle(Color.theme.textSecondary)
                        }
                        Spacer()
                        if selectedTicket == option {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.theme.accent)
                        }
                    }
                    .contentShape(Rectangle())
                    .listRowBackground(Color.theme.surface.opacity(0.3))
                    .onTapGesture {
                        selectedTicket = option
                        quantity = 1
                    }
                }
                .listStyle(.plain)
                .frame(height: 260)
                
                if selectedTicket != nil {
                    VStack(spacing: 8) {
                        HStack {
                            Text(LocalizedStringKey("quantity"))
                                .font(Theme.Fonts.body(size: 16))
                                .foregroundStyle(Color.theme.textPrimary)
                            Spacer()
                            Stepper(value: $quantity, in: 1...10) {
                                Text("\(quantity)")
                                    .font(Theme.Fonts.body(size: 16))
                                    .foregroundStyle(Color.theme.textPrimary)
                                    .frame(width: 40)
                            }
                            .labelsHidden()
                        }
                        .padding()
                        .background(Color.theme.surface.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(LocalizedStringKey("subtotal"))
                                Spacer()
                                Text("\(Int(subtotal)) AED")
                            }
                            HStack {
                                Text(LocalizedStringKey("service_fee")) + Text(" (5%)")
                                Spacer()
                                Text("\(String(format: "%.2f", serviceFee)) AED")
                            }
                            HStack {
                                Text(LocalizedStringKey("processing"))
                                Spacer()
                                Text("\(String(format: "%.2f", processingFee)) AED")
                            }
                            Divider()
                                .background(Color.theme.textSecondary)
                            HStack {
                                Text(LocalizedStringKey("total"))
                                    .fontWeight(.bold)
                                Spacer()
                                Text("\(String(format: "%.2f", total)) AED")
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color.theme.accent)
                            }
                        }
                        .font(Theme.Fonts.body(size: 14))
                        .foregroundStyle(Color.theme.textPrimary)
                        .padding()
                        .background(Color.theme.surface.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 16)
                }
                
                Spacer()
            }
            .navigationTitle(LocalizedStringKey("select_ticket"))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(LocalizedStringKey("cancel")) {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Continue – \(CurrencyFormatter.aed(total))") {
                        if let ticket = selectedTicket {
                            let ticketWithFees = TicketOption(name: ticket.name, phase: ticket.phase, price: total)
                            onContinue(ticketWithFees)
                            dismiss()
                        }
                    }
                    .foregroundStyle(selectedTicket == nil ? .gray : .white)
                    .disabled(selectedTicket == nil)
                    .fontWeight(.bold)
                }
            }
            .background(Color.theme.background)
            .scrollContentBackground(.hidden)
        }
        .preferredColorScheme(.dark)
    }
}
