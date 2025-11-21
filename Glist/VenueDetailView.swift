import SwiftUI

struct VenueDetailView: View {
    let venue: Venue
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var socialManager = SocialManager()
    @State private var showGuestListSheet = false
    @State private var showTableBooking = false
    @State private var selectedEvent: Event?
    
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
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Button {
                                showGuestListSheet = true
                            } label: {
                                Text("JOIN GUEST LIST")
                                    .font(Theme.Fonts.body(size: 14))
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color.black)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 0))
                            }
                            
                            Button {
                                showTableBooking = true
                            } label: {
                                Text("BOOK A TABLE")
                                    .font(Theme.Fonts.body(size: 14))
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color.black)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 0))
                            }
                            
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
                                    Text("BUY TICKETS")
                                        .font(Theme.Fonts.body(size: 14))
                                        .fontWeight(.bold)
                                        .foregroundStyle(Color.black)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 50)
                                        .background(Color.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 0))
                                }
                                
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
                            Text("UPCOMING EVENTS")
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
                    
                        }
                    }
                    
                    // Who's Going Section
                    let friendsAtVenue = socialManager.getFriendsAt(venueId: venue.id)
                    if !friendsAtVenue.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("WHO'S GOING")
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
                        Text("ABOUT")
                            .font(Theme.Fonts.body(size: 12))
                            .fontWeight(.bold)
                            .foregroundStyle(Color.theme.textSecondary)
                        
                        Text(venue.description)
                            .font(Theme.Fonts.body(size: 16))
                            .foregroundStyle(Color.theme.textPrimary)
                            .lineSpacing(6)
                    }
                    
                    // Info Grid
                    HStack(spacing: 16) {
                        // Price
                        VStack(alignment: .leading, spacing: 8) {
                            Text("PRICE")
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
                            Text("DRESS CODE")
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
                    
                    // Location
                    VStack(alignment: .leading, spacing: 12) {
                        Text("LOCATION")
                            .font(Theme.Fonts.body(size: 12))
                            .fontWeight(.bold)
                            .foregroundStyle(Color.theme.textSecondary)
                        
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
                    await socialManager.fetchFriendsGoing(venueId: venue.id, currentUserFollowing: user.following)
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
    @State private var date = Date()
    @State private var showSuccess = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.background.ignoresSafeArea()
                
                if showSuccess {
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.white)
                        Text("REQUEST SENT")
                            .font(Theme.Fonts.display(size: 24))
                            .foregroundStyle(.white)
                        Text("You will receive a confirmation email shortly.")
                            .font(Theme.Fonts.body(size: 16))
                            .foregroundStyle(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    Form {
                        Section {
                            TextField("Full Name", text: $name)
                            TextField("Email", text: $email)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                        } header: {
                            Text("YOUR DETAILS")
                        }
                        
                        Section {
                            DatePicker("Date", selection: $date, displayedComponents: .date)
                            Stepper("Guests: \(guests)", value: $guests, in: 1...10)
                        } header: {
                            Text("RESERVATION")
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle(showSuccess ? "" : "JOIN GUEST LIST")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
                
                if !showSuccess {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Submit") {
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
                                        guestCount: guests
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
                        .disabled(name.isEmpty || email.isEmpty)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
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
