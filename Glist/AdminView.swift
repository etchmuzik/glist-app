import SwiftUI

struct AdminView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var venueManager: VenueManager
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom Tab Selector
                    HStack(spacing: 0) {
                        AdminTabButton(title: "GUEST LISTS", isSelected: selectedTab == 0) {
                            selectedTab = 0
                        }
                        AdminTabButton(title: "VENUES", isSelected: selectedTab == 1) {
                            selectedTab = 1
                        }
                        AdminTabButton(title: "ANALYTICS", isSelected: selectedTab == 2) {
                            selectedTab = 2
                        }
                        AdminTabButton(title: "SCANNER", isSelected: selectedTab == 3) {
                            selectedTab = 3
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Content
                    TabView(selection: $selectedTab) {
                        GuestListManagementView()
                            .tag(0)
                        
                        VenueManagementView()
                            .tag(1)
                        
                        AnalyticsView()
                            .tag(2)
                        
                        ScannerView()
                            .tag(3)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            .navigationTitle("ADMIN PANEL")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: DatabaseUpdateView()) {
                        Image(systemName: "arrow.triangle.2.circlepath.circle")
                            .foregroundStyle(.white)
                    }
                }
            }
        }
    }
}

struct AdminTabButton: View {
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

// MARK: - Guest List Management

struct GuestListManagementView: View {
    @State private var allRequests: [GuestListRequest] = []
    @State private var isLoading = false
    @State private var filterStatus: String = "All"
    
    var filteredRequests: [GuestListRequest] {
        if filterStatus == "All" {
            return allRequests
        } else {
            return allRequests.filter { $0.status == filterStatus }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter Buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    FilterChip(title: "All", isSelected: filterStatus == "All") {
                        filterStatus = "All"
                    }
                    FilterChip(title: "Pending", isSelected: filterStatus == "Pending") {
                        filterStatus = "Pending"
                    }
                    FilterChip(title: "Confirmed", isSelected: filterStatus == "Confirmed") {
                        filterStatus = "Confirmed"
                    }
                    FilterChip(title: "Rejected", isSelected: filterStatus == "Rejected") {
                        filterStatus = "Rejected"
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            
            // List
            if isLoading {
                ProgressView()
                    .tint(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredRequests.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "list.clipboard")
                        .font(.system(size: 40))
                        .foregroundStyle(.gray)
                    Text("No guest list requests")
                        .font(Theme.Fonts.body(size: 14))
                        .foregroundStyle(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredRequests) { request in
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
                allRequests = try await FirestoreManager.shared.fetchAllGuestListRequests()
                isLoading = false
            } catch {
                print("Error loading requests: \(error)")
                isLoading = false
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Fonts.body(size: 12))
                .fontWeight(.bold)
                .foregroundStyle(isSelected ? .black : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? .white : Color.theme.surface)
                .clipShape(Capsule())
        }
    }
}

struct AdminGuestListCard: View {
    let request: GuestListRequest
    let onUpdate: () -> Void
    @State private var isUpdating = false
    
    var statusColor: Color {
        switch request.status {
        case "Confirmed": return .green
        case "Rejected": return .red
        default: return .orange
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(request.venueName.uppercased())
                        .font(Theme.Fonts.display(size: 16))
                        .foregroundStyle(.white)
                    
                    Text(request.name)
                        .font(Theme.Fonts.body(size: 14))
                        .foregroundStyle(.gray)
                }
                
                Spacer()
                
                Text(request.status.uppercased())
                    .font(Theme.Fonts.body(size: 10))
                    .fontWeight(.bold)
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.2))
                    .clipShape(Capsule())
            }
            
            // Details
            HStack(spacing: 20) {
                DetailItem(icon: "envelope", text: request.email)
                DetailItem(icon: "calendar", text: request.date.formatted(.dateTime.month().day()))
                DetailItem(icon: "person.2", text: "\(request.guestCount) guests")
            }
            
            // Actions (only if pending)
            if request.status == "Pending" {
                HStack(spacing: 12) {
                    Button {
                        updateStatus(to: "Confirmed")
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("APPROVE")
                                .font(Theme.Fonts.body(size: 12))
                                .fontWeight(.bold)
                        }
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(.green)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .disabled(isUpdating)
                    
                    Button {
                        updateStatus(to: "Rejected")
                    } label: {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                            Text("REJECT")
                                .font(Theme.Fonts.body(size: 12))
                                .fontWeight(.bold)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(.red.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .disabled(isUpdating)
                }
            }
            
            // Actions (for Confirmed requests)
            if request.status == "Confirmed" {
                Button {
                    markAsNoShow()
                } label: {
                    HStack {
                        Image(systemName: "person.slash.fill")
                        Text("NO SHOW")
                            .font(Theme.Fonts.body(size: 12))
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(.gray)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .disabled(isUpdating)
            }
        }
        .padding(16)
        .background(Color.theme.surface.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    private func updateStatus(to status: String) {
        isUpdating = true
        Task {
            do {
                try await FirestoreManager.shared.updateGuestListStatus(
                    requestId: request.id.uuidString,
                    status: status
                )
                await MainActor.run {
                    isUpdating = false
                    onUpdate()
                }
            } catch {
                print("Error updating status: \(error)")
                isUpdating = false
            }
        }
    }
    
    private func markAsNoShow() {
        isUpdating = true
        Task {
            do {
                // Update status
                try await FirestoreManager.shared.updateGuestListStatus(
                    requestId: request.id.uuidString,
                    status: "No Show"
                )
                // Increment no-show count
                try await FirestoreManager.shared.incrementNoShowCount(userId: request.userId)
                
                await MainActor.run {
                    isUpdating = false
                    onUpdate()
                }
            } catch {
                print("Error marking no show: \(error)")
                isUpdating = false
            }
        }
    }
}

struct DetailItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.gray)
            Text(text)
                .font(Theme.Fonts.body(size: 12))
                .foregroundStyle(.gray)
        }
    }
}

// MARK: - Venue Management

struct VenueManagementView: View {
    @EnvironmentObject var venueManager: VenueManager
    @State private var showAddVenue = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Add Button
            Button {
                showAddVenue = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("ADD NEW VENUE")
                        .font(Theme.Fonts.body(size: 14))
                        .fontWeight(.bold)
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(20)
            
            // Venue List
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(venueManager.venues) { venue in
                        AdminVenueCard(venue: venue)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $showAddVenue) {
            AddVenueView()
        }
    }
}

struct AdminVenueCard: View {
    let venue: Venue
    
    var body: some View {
        HStack(spacing: 16) {
            Rectangle()
                .fill(Color.theme.surface)
                .frame(width: 80, height: 80)
                .overlay {
                    Image(systemName: "photo")
                        .foregroundStyle(.gray)
                }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(venue.name.uppercased())
                    .font(Theme.Fonts.display(size: 16))
                    .foregroundStyle(.white)
                
                Text(venue.type.uppercased())
                    .font(Theme.Fonts.body(size: 12))
                    .foregroundStyle(Color.theme.accent)
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                        Text(String(format: "%.1f", venue.rating))
                            .font(Theme.Fonts.body(size: 12))
                            .foregroundStyle(.gray)
                    }
                    
                    Text(venue.price)
                        .font(Theme.Fonts.body(size: 12))
                        .foregroundStyle(.gray)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.gray)
        }
        .padding(12)
        .background(Color.theme.surface.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct AddVenueView: View {
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var type = "Nightclub"
    @State private var location = ""
    @State private var description = ""
    @State private var price = "$$$"
    @State private var dressCode = "Smart Casual"
    
    let types = ["Nightclub", "Beach Club", "Lounge", "Rooftop Bar"]
    let prices = ["$", "$$", "$$$", "$$$$"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.background.ignoresSafeArea()
                
                Form {
                    Section("BASIC INFO") {
                        TextField("Venue Name", text: $name)
                        Picker("Type", selection: $type) {
                            ForEach(types, id: \.self) { type in
                                Text(type).tag(type)
                            }
                        }
                        TextField("Location", text: $location)
                    }
                    
                    Section("DETAILS") {
                        TextField("Description", text: $description, axis: .vertical)
                            .lineLimit(3...6)
                        Picker("Price Range", selection: $price) {
                            ForEach(prices, id: \.self) { price in
                                Text(price).tag(price)
                            }
                        }
                        TextField("Dress Code", text: $dressCode)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Add Venue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveVenue()
                    }
                    .disabled(name.isEmpty || location.isEmpty)
                }
            }
        }
    }
    
    private func saveVenue() {
        // TODO: Implement save
        dismiss()
    }
}

// MARK: - Analytics

struct AnalyticsView: View {
    @StateObject private var analyticsManager = AnalyticsManager()
    @State private var showExportSheet = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Period Selector
                Picker("Period", selection: $analyticsManager.selectedPeriod) {
                    Text("Day").tag(AnalyticsPeriod.day)
                    Text("Week").tag(AnalyticsPeriod.week)
                    Text("Month").tag(AnalyticsPeriod.month)
                    Text("Year").tag(AnalyticsPeriod.year)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .onChange(of: analyticsManager.selectedPeriod) { _, newValue in
                    Task {
                        await analyticsManager.fetchAnalytics(period: newValue)
                    }
                }
                
                // Summary Stats
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    AnalyticsStatCard(
                        title: "TOTAL REVENUE",
                        value: "$\(Int(analyticsManager.totalRevenue))",
                        icon: "dollarsign.circle.fill",
                        color: .green
                    )
                    AnalyticsStatCard(
                        title: "BOOKINGS",
                        value: "\(analyticsManager.totalBookings)",
                        icon: "calendar.circle.fill",
                        color: .blue
                    )
                    AnalyticsStatCard(
                        title: "TICKETS SOLD",
                        value: "\(analyticsManager.totalTickets)",
                        icon: "ticket.fill",
                        color: .purple
                    )
                    AnalyticsStatCard(
                        title: "AVG PER BOOKING",
                        value: analyticsManager.totalBookings > 0 ? "$\(Int(analyticsManager.totalRevenue / Double(analyticsManager.totalBookings)))" : "$0",
                        icon: "chart.line.uptrend.xyaxis",
                        color: .orange
                    )
                }
                .padding(.horizontal, 20)
                
                // Venue Performance
                if !analyticsManager.venueAnalytics.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("VENUE PERFORMANCE")
                                .font(Theme.Fonts.body(size: 12))
                                .fontWeight(.bold)
                                .foregroundStyle(.gray)
                            
                            Spacer()
                            
                            Button {
                                exportAnalytics()
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Export")
                                }
                                .font(Theme.Fonts.body(size: 12))
                                .foregroundStyle(Color.theme.accent)
                            }
                        }
                        
                        ForEach(analyticsManager.venueAnalytics.prefix(10)) { analytics in
                            VenueAnalyticsRow(analytics: analytics)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                if analyticsManager.isLoading {
                    ProgressView()
                        .tint(.white)
                        .padding(.vertical, 40)
                }
            }
            .padding(.vertical, 20)
        }
        .onAppear {
            Task {
                await analyticsManager.fetchAnalytics()
            }
        }
    }
    
    func exportAnalytics() {
        let csv = analyticsManager.exportAnalytics()
        let activityVC = UIActivityViewController(
            activityItems: [csv],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            activityVC.popoverPresentationController?.sourceView = rootVC.view
            rootVC.present(activityVC, animated: true)
        }
    }
}

struct AnalyticsStatCard: View {
    let title: String
    let value: String
    let icon: String
    var color: Color = .white
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
            }
            
            Text(value)
                .font(Theme.Fonts.display(size: 24))
                .foregroundStyle(.white)
            
            Text(title)
                .font(Theme.Fonts.body(size: 10))
                .foregroundStyle(.gray)
        }
        .padding(16)
        .background(Color.theme.surface.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct VenueAnalyticsRow: View {
    let analytics: VenueAnalytics
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(analytics.venueName)
                    .font(Theme.Fonts.body(size: 16))
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                
                Spacer()
                
                Text("$\(Int(analytics.totalRevenue))")
                    .font(Theme.Fonts.display(size: 18))
                    .foregroundStyle(.green)
            }
            
            HStack(spacing: 20) {
                VenueStatItem(icon: "calendar", value: "\(analytics.totalBookings)", label: "Bookings")
                VenueStatItem(icon: "ticket", value: "\(analytics.totalTickets)", label: "Tickets")
                VenueStatItem(icon: "person.2", value: "\(analytics.totalGuestLists)", label: "Lists")
            }
        }
        .padding(16)
        .background(Color.theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct VenueStatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(value)
                    .font(Theme.Fonts.body(size: 14))
            }
            .foregroundStyle(.white)
            
            Text(label)
                .font(Theme.Fonts.body(size: 10))
                .foregroundStyle(.gray)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    var color: Color = .white
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
            }
            
            Text(value)
                .font(Theme.Fonts.display(size: 28))
                .foregroundStyle(.white)
            
            Text(title)
                .font(Theme.Fonts.body(size: 10))
                .foregroundStyle(.gray)
        }
        .padding(16)
        .background(Color.theme.surface.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Scanner

struct ScannerView: View {
    @State private var scannedCode: String?
    @State private var scannedRequest: GuestListRequest?
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showScanner = false
    
    var body: some View {
        VStack {
            if let request = scannedRequest {
                // Show request details
                VStack(spacing: 24) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.green)
                    
                    Text("GUEST FOUND")
                        .font(Theme.Fonts.display(size: 24))
                        .foregroundStyle(.white)
                    
                    VStack(spacing: 8) {
                        Text(request.name)
                            .font(Theme.Fonts.display(size: 32))
                            .foregroundStyle(.white)
                        
                        Text("\(request.guestCount) Guests")
                            .font(Theme.Fonts.body(size: 18))
                            .foregroundStyle(.gray)
                    }
                    
                    VStack(spacing: 16) {
                        HStack {
                            Text("Venue:")
                                .foregroundStyle(.gray)
                            Spacer()
                            Text(request.venueName)
                                .foregroundStyle(.white)
                        }
                        
                        HStack {
                            Text("Date:")
                                .foregroundStyle(.gray)
                            Spacer()
                            Text(request.date.formatted(date: .long, time: .omitted))
                                .foregroundStyle(.white)
                        }
                        
                        HStack {
                            Text("Status:")
                                .foregroundStyle(.gray)
                            Spacer()
                            Text(request.status)
                                .foregroundStyle(request.status == "Confirmed" ? .green : .orange)
                        }
                    }
                    .padding()
                    .background(Color.theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    if request.status != "Checked In" {
                        Button {
                            checkIn(request)
                        } label: {
                            Text("CHECK IN")
                                .font(Theme.Fonts.body(size: 16))
                                .fontWeight(.bold)
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .clipShape(Capsule())
                        }
                    } else {
                        Text("ALREADY CHECKED IN")
                            .font(Theme.Fonts.body(size: 16))
                            .fontWeight(.bold)
                            .foregroundStyle(.green)
                    }
                    
                    Button("Scan Next") {
                        scannedRequest = nil
                        scannedCode = nil
                    }
                    .padding(.top)
                }
                .padding(40)
            } else {
                // Show Scanner Button
                Button {
                    showScanner = true
                } label: {
                    VStack(spacing: 16) {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 60))
                        Text("TAP TO SCAN")
                            .font(Theme.Fonts.body(size: 16))
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.theme.surface.opacity(0.1))
                }
            }
        }
        .sheet(isPresented: $showScanner) {
            QRScannerView(scannedCode: $scannedCode)
        }
        .onChange(of: scannedCode) { _, newValue in
            if let code = newValue {
                processScannedCode(code)
            }
        }
        .alert("Error", isPresented: Binding<Bool>(
            get: { errorMessage != nil },
            set: { _ in errorMessage = nil }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }
    
    private func processScannedCode(_ code: String) {
        isProcessing = true
        Task {
            do {
                if let request = try await FirestoreManager.shared.fetchGuestListRequest(qrCodeId: code) {
                    await MainActor.run {
                        scannedRequest = request
                        isProcessing = false
                    }
                } else {
                    await MainActor.run {
                        errorMessage = "Invalid QR Code"
                        isProcessing = false
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Error: \(error.localizedDescription)"
                    isProcessing = false
                }
            }
        }
    }
    
    private func checkIn(_ request: GuestListRequest) {
        Task {
            do {
                try await FirestoreManager.shared.updateGuestListStatus(requestId: request.id.uuidString, status: "Checked In")
                
                // Add reward points (e.g., 100 points)
                try await FirestoreManager.shared.addRewardPoints(userId: request.userId, points: 100)
                
                // Refresh local request
                if let updatedRequest = try await FirestoreManager.shared.fetchGuestListRequest(qrCodeId: request.qrCodeId ?? request.id.uuidString) {
                    await MainActor.run {
                        scannedRequest = updatedRequest
                    }
                }
            } catch {
                print("Error checking in: \(error)")
            }
        }
    }
}

#Preview {
    AdminView()
        .environmentObject(AuthManager())
        .environmentObject(VenueManager())
}
