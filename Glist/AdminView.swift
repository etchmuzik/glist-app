import SwiftUI
import UIKit

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
                        AdminTabButton(title: LocalizedStringKey("tab_guest_lists"), isSelected: selectedTab == 0) { selectedTab = 0 }
                        AdminTabButton(title: LocalizedStringKey("tab_venues"), isSelected: selectedTab == 1) { selectedTab = 1 }
                        AdminTabButton(title: LocalizedStringKey("tab_analytics"), isSelected: selectedTab == 2) { selectedTab = 2 }
                        AdminTabButton(title: LocalizedStringKey("tab_scanner"), isSelected: selectedTab == 3) { selectedTab = 3 }
                        AdminTabButton(title: LocalizedStringKey("tab_kyc"), isSelected: selectedTab == 4) { selectedTab = 4 }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    if let user = authManager.user, user.kycStatus != .verified {
                        AdminKYCAlert(status: user.kycStatus)
                            .padding(.horizontal, 20)
                    }
                    
                    // Content
                    TabView(selection: $selectedTab) {
                        GuestListManagementView()
                            .tag(0)
                        
                        VenueManagementView()
                            .tag(1)
                        
                        AnalyticsView()
                            .tag(2)
                        
                        StaffScannerWrapperView()
                            .tag(3)
                        
                        KYCReviewView()
                            .tag(4)
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
    let title: LocalizedStringKey
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

struct AdminKYCAlert: View {
    let status: KYCStatus
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: status == .verified ? "checkmark.seal.fill" : "shield.fill")
                .foregroundStyle(status.badgeColor)
                .font(.title3)
            VStack(alignment: .leading, spacing: 6) {
                Text(status == .verified ? "Admin KYC Verified" : "Complete KYC for Admin Tools")
                    .font(Theme.Fonts.body(size: 12))
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                Text(status == .verified ? "Identity and payout details confirmed." : "Upload ID and licensing documents to keep scanner and analytics access.")
                    .font(Theme.Fonts.body(size: 11))
                    .foregroundStyle(.gray)
            }
            Spacer()
        }
        .padding(14)
        .background(Color.theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct KYCReviewView: View {
    @State private var submissions: [KYCSubmission] = []
    @State private var isLoading = false
    @State private var filter: KYCStatus? = .pending
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    KYCFilterChip(title: "All", isSelected: filter == nil) { filter = nil; Task { await load() } }
                    KYCFilterChip(title: "Pending", isSelected: filter == .pending) { filter = .pending; Task { await load() } }
                    KYCFilterChip(title: "Verified", isSelected: filter == .verified) { filter = .verified; Task { await load() } }
                    KYCFilterChip(title: "Failed", isSelected: filter == .failed) { filter = .failed; Task { await load() } }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            
            if isLoading {
                ProgressView()
                    .tint(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if submissions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.seal")
                        .font(.system(size: 40))
                        .foregroundStyle(.gray)
                    Text("No submissions found")
                        .foregroundStyle(.gray)
                        .font(Theme.Fonts.body(size: 14))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(submissions) { submission in
                            KYCSubmissionCard(submission: submission) { newStatus in
                                Task { await update(submission: submission, to: newStatus) }
                            }
                        }
                    }
                    .padding(20)
                }
            }
        }
        .onAppear {
            Task { await load() }
        }
    }
    
    private func load() async {
        isLoading = true
        do {
            submissions = try await FirestoreManager.shared.fetchKYCSubmissions(status: filter)
        } catch {
            print("Failed to load KYC submissions: \(error)")
        }
        isLoading = false
    }
    
    private func update(submission: KYCSubmission, to status: KYCStatus) async {
        isLoading = true
        do {
            try await FirestoreManager.shared.updateKYCSubmissionStatus(
                submissionId: submission.id,
                userId: submission.userId,
                status: status,
                reviewerId: nil,
                notes: submission.notes
            )
            await load()
        } catch {
            print("Failed to update KYC status: \(error)")
            isLoading = false
        }
    }
}

struct KYCFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Fonts.body(size: 12))
                .fontWeight(.bold)
                .foregroundStyle(isSelected ? .black : .white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.white : Color.theme.surface.opacity(0.5))
                .clipShape(Capsule())
        }
    }
}

struct KYCSubmissionCard: View {
    let submission: KYCSubmission
    let onUpdate: (KYCStatus) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(submission.fullName.uppercased())
                    .font(Theme.Fonts.display(size: 16))
                Spacer()
                StatusPill(status: submission.status)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("\(submission.documentType) • \(submission.documentNumber)")
                    .font(Theme.Fonts.body(size: 12))
                    .foregroundStyle(.gray)
                Text("Submitted \(submission.submittedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(Theme.Fonts.body(size: 12))
                    .foregroundStyle(.gray)
            }
            
            if let notes = submission.notes, !notes.isEmpty {
                Text(notes)
                    .font(Theme.Fonts.body(size: 12))
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                if let front = submission.documentFrontData, let image = UIImage(data: front) {
                    DocumentImageRow(icon: "doc.text.viewfinder", label: "Front of ID", image: image)
                } else if let url = submission.documentFrontURL {
                    LinkRow(icon: "doc.text.viewfinder", label: "Front of ID", url: url)
                }
                if let back = submission.documentBackData, let image = UIImage(data: back) {
                    DocumentImageRow(icon: "doc.viewfinder", label: "Back of ID", image: image)
                } else if let url = submission.documentBackURL {
                    LinkRow(icon: "doc.viewfinder", label: "Back of ID", url: url)
                }
            }
            
            if submission.status == .pending {
                HStack(spacing: 12) {
                    Button {
                        onUpdate(.verified)
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                            Text("Approve")
                                .font(Theme.Fonts.body(size: 12))
                                .fontWeight(.bold)
                        }
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(.green)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    Button {
                        onUpdate(.failed)
                    } label: {
                        HStack {
                            Image(systemName: "xmark.seal.fill")
                            Text("Reject")
                                .font(Theme.Fonts.body(size: 12))
                                .fontWeight(.bold)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(.red.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
        .padding(16)
        .background(Color.theme.surface.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

struct LinkRow: View {
    let icon: String
    let label: String
    let url: String
    
    var body: some View {
        if let link = URL(string: url) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(.gray)
                Link(label, destination: link)
                    .font(Theme.Fonts.body(size: 12))
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
        }
    }
}

struct DocumentImageRow: View {
    let icon: String
    let label: String
    let image: UIImage
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(.gray)
                Text(label)
                    .font(Theme.Fonts.body(size: 12))
                Spacer()
            }
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 220)
                .clipShape(RoundedRectangle(cornerRadius: 12))
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
                    FilterChip(title: NSLocalizedString("filter_all", comment: ""), isSelected: filterStatus == "All") {
                        filterStatus = "All"
                    }
                    FilterChip(title: NSLocalizedString("filter_pending", comment: ""), isSelected: filterStatus == "Pending") {
                        filterStatus = "Pending"
                    }
                    FilterChip(title: NSLocalizedString("filter_confirmed", comment: ""), isSelected: filterStatus == "Confirmed") {
                        filterStatus = "Confirmed"
                    }
                    FilterChip(title: NSLocalizedString("filter_rejected", comment: ""), isSelected: filterStatus == "Rejected") {
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
                    Text(LocalizedStringKey("no_guest_requests"))
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

// Uses shared FilterChip from venue views

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
                    Text(LocalizedStringKey("add_new_venue"))
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
                Picker(LocalizedStringKey("period"), selection: $analyticsManager.selectedPeriod) {
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
                        title: NSLocalizedString("avg_per_booking", comment: ""),
                        value: analyticsManager.totalBookings > 0 ? CurrencyFormatter.aed(analyticsManager.totalRevenue / Double(analyticsManager.totalBookings)) : CurrencyFormatter.aed(0),
                        icon: "chart.line.uptrend.xyaxis",
                        color: .orange
                    )
                }
                .padding(.horizontal, 20)
                
                // Venue Performance
                if !analyticsManager.venueAnalytics.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text(LocalizedStringKey("venue_performance"))
                                .font(Theme.Fonts.body(size: 12))
                                .fontWeight(.bold)
                                .foregroundStyle(.gray)
                            
                            Spacer()
                            
                            Button {
                                exportAnalytics()
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "square.and.arrow.up")
                                    Text(LocalizedStringKey("export"))
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
                await analyticsManager.fetchTodayOverview()
                await analyticsManager.fetchAlerts()
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
            
            Text(LocalizedStringKey(title))
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
                
                Text(CurrencyFormatter.aed(analytics.totalRevenue))
                    .font(Theme.Fonts.display(size: 18))
                    .foregroundStyle(.green)
            }
            
            HStack(spacing: 20) {
                VenueStatItem(icon: "calendar", value: "\(analytics.totalBookings)", label: LocalizedStringKey("bookings"))
                VenueStatItem(icon: "ticket", value: "\(analytics.totalTickets)", label: LocalizedStringKey("tickets_sold"))
                VenueStatItem(icon: "person.2", value: "\(analytics.totalGuestLists)", label: LocalizedStringKey("guest_lists_title"))
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
    let label: LocalizedStringKey
    
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

struct StaffScannerWrapperView: View {
    @EnvironmentObject var venueManager: VenueManager
    @StateObject private var staffManager = StaffModeManager()
    @State private var selectedVenueId: String?
    @State private var entranceId: String = "Main Entrance"
    @State private var syncMessage: String?
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Picker("Venue", selection: Binding(
                    get: { selectedVenueId ?? venueManager.venues.first?.id.uuidString ?? "" },
                    set: { selectedVenueId = $0 }
                )) {
                    ForEach(venueManager.venues, id: \.id) { venue in
                        Text(venue.name).tag(venue.id.uuidString)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                
                TextField("Entrance", text: $entranceId)
                    .textInputAutocapitalization(.words)
                    .padding(8)
                    .background(Color.theme.surface.opacity(0.2))
                    .cornerRadius(8)
            }
            .padding(.horizontal)
            
            if let venueId = selectedVenueId ?? venueManager.venues.first?.id.uuidString {
                StaffCheckInView(
                    manager: staffManager,
                    venueId: venueId,
                    entranceId: entranceId,
                    syncHandler: { events in
                        // Stubbed backend sync: pretend all processed
                        await MainActor.run {
                            syncMessage = "Synced \(events.count) scans"
                        }
                        return events.map(\.id)
                    }
                )
            } else {
                Text("No venues available")
                    .foregroundColor(.gray)
            }
            
            if let syncMessage {
                Text(syncMessage)
                    .font(Theme.Fonts.body(size: 12))
                    .foregroundColor(Color.theme.textSecondary)
                    .padding(.bottom)
            }
        }
        .onAppear {
            if selectedVenueId == nil {
                selectedVenueId = venueManager.venues.first?.id.uuidString
            }
        }
    }
}

#Preview {
    AdminView()
        .environmentObject(AuthManager())
        .environmentObject(VenueManager())
}
