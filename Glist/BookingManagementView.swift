import SwiftUI

struct BookingManagementView: View {
    @State private var allBookings: [Booking] = []
    @State private var isLoading = false
    @State private var filterStatus: BookingStatus? = nil
    
    var filteredBookings: [Booking] {
        if let filter = filterStatus {
            return allBookings.filter { $0.status == filter }
        } else {
            return allBookings
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter Buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    FilterChip(title: "All", isSelected: filterStatus == nil) {
                        filterStatus = nil
                    }
                    FilterChip(title: "Confirmed", isSelected: filterStatus == .confirmed) {
                        filterStatus = .confirmed
                    }
                    FilterChip(title: "Pending", isSelected: filterStatus == .pending) {
                        filterStatus = .pending
                    }
                    FilterChip(title: "Hold Pending", isSelected: filterStatus == .holdPending) {
                        filterStatus = .holdPending
                    }
                    FilterChip(title: "Paid", isSelected: filterStatus == .paid) {
                        filterStatus = .paid
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
            } else if filteredBookings.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 40))
                        .foregroundStyle(.gray)
                    Text("No bookings found")
                        .font(Theme.Fonts.body(size: 14))
                        .foregroundStyle(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredBookings) { booking in
                            AdminBookingCard(booking: booking)
                        }
                    }
                    .padding(20)
                }
            }
        }
        .onAppear {
            loadBookings()
        }
    }
    
    private func loadBookings() {
        isLoading = true
        Task {
            do {
                allBookings = try await SupabaseDataManager.shared.fetchAllBookings()
                isLoading = false
            } catch {
                print("Error loading bookings: \(error)")
                isLoading = false
            }
        }
    }
}

struct AdminBookingCard: View {
    let booking: Booking
    
    var statusColor: Color {
        switch booking.status {
        case .confirmed, .paid: return .green
        case .pending, .holdPending: return .orange
        case .cancelled, .expired: return .red
        default: return .gray
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(booking.venueName.uppercased())
                        .font(Theme.Fonts.display(size: 16))
                        .foregroundStyle(.white)
                    
                    Text("Table: \(booking.tableName)")
                        .font(Theme.Fonts.body(size: 14))
                        .foregroundStyle(Color.theme.accent)
                }
                
                Spacer()
                
                Text(booking.status.rawValue.uppercased())
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
                DetailItem(icon: "calendar", text: booking.date.formatted(date: .abbreviated, time: .shortened))
                DetailItem(icon: "creditcard", text: CurrencyFormatter.aed(booking.depositAmount))
            }
            
            Divider().background(Color.gray.opacity(0.2))
            
            HStack {
                Text("User ID: \(booking.userId.prefix(8))...")
                    .font(Theme.Fonts.caption())
                    .foregroundStyle(.gray)
                Spacer()
                Text("Booked \(booking.createdAt.formatted(date: .numeric, time: .omitted))")
                    .font(Theme.Fonts.caption())
                    .foregroundStyle(.gray)
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
}
