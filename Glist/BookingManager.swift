import Foundation
import SwiftUI
import Combine

class BookingManager: ObservableObject {
    @Published var bookings: [Booking] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func fetchUserBookings(userId: String) {
        isLoading = true
        Task {
            do {
                let bookings = try await FirestoreManager.shared.fetchUserBookings(userId: userId)
                await MainActor.run {
                    self.bookings = bookings
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to fetch bookings: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    func createBooking(userId: String, venue: Venue, table: Table, date: Date) async throws {
        // Calculate deposit (e.g., 20% of minimum spend)
        let depositAmount = table.minimumSpend * 0.20
        
        let newBooking = Booking(
            id: UUID(),
            userId: userId,
            venueId: venue.id.uuidString,
            venueName: venue.name,
            tableId: table.id,
            tableName: table.name,
            date: date,
            depositAmount: depositAmount,
            status: .holdPending,
            createdAt: Date()
        )
        
        // In a real app, we would process payment here first
        // For now, we assume payment is successful and save the booking
        
        try await FirestoreManager.shared.createBooking(newBooking)
        
        // Award Loyalty Points
        try await FirestoreManager.shared.addRewardPoints(userId: userId, points: LoyaltyManager.pointsPerBooking)
        
        // Schedule Reminder
        NotificationManager.shared.scheduleBookingReminder(for: newBooking)
        
        // Log Activity
        SocialManager.shared.logActivity(
            userId: userId,
            type: .booking,
            title: "Booked a table",
            subtitle: "at \(venue.name)",
            relatedId: venue.id.uuidString
        )
        
        // Refresh bookings
        fetchUserBookings(userId: userId)
    }
}
