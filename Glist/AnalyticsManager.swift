import Foundation
import SwiftUI
import Combine

class AnalyticsManager: ObservableObject {
    @Published var venueAnalytics: [VenueAnalytics] = []
    @Published var totalRevenue: Double = 0
    @Published var totalBookings: Int = 0
    @Published var totalTickets: Int = 0
    @Published var isLoading = false
    @Published var selectedPeriod: AnalyticsPeriod = .week
    
    private let db = FirestoreManager.shared.db
    
    func fetchAnalytics(period: AnalyticsPeriod = .week) async {
        isLoading = true
        selectedPeriod = period
        
        do {
            let (startDate, endDate) = getDateRange(for: period)
            
            // Fetch all venues
            let venuesSnapshot = try await db.collection("venues").getDocuments()
            
            var analytics: [VenueAnalytics] = []
            var totalRev: Double = 0
            var totalBook: Int = 0
            var totalTix: Int = 0
            
            for venueDoc in venuesSnapshot.documents {
                let venueId = venueDoc.documentID
                let venueName = venueDoc.data()["name"] as? String ?? "Unknown"
                
                // Fetch bookings for this venue
                let bookingsSnapshot = try await db.collection("bookings")
                    .whereField("venueId", isEqualTo: venueId)
                    .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startDate))
                    .whereField("date", isLessThanOrEqualTo: Timestamp(date: endDate))
                    .getDocuments()
                
                let bookingRevenue = bookingsSnapshot.documents.reduce(0.0) { sum, doc in
                    sum + (doc.data()["depositAmount"] as? Double ?? 0)
                }
                let bookingCount = bookingsSnapshot.documents.count
                
                // Fetch tickets for this venue
                let ticketsSnapshot = try await db.collection("tickets")
                    .whereField("venueId", isEqualTo: venueId)
                    .whereField("purchaseDate", isGreaterThanOrEqualTo: Timestamp(date: startDate))
                    .whereField("purchaseDate", isLessThanOrEqualTo: Timestamp(date: endDate))
                    .getDocuments()
                
                let ticketRevenue = ticketsSnapshot.documents.reduce(0.0) { sum, doc in
                    sum + (doc.data()["price"] as? Double ?? 0)
                }
                let ticketCount = ticketsSnapshot.documents.count
                
                // Fetch guest lists
                let guestListsSnapshot = try await db.collection("guestListRequests")
                    .whereField("venueId", isEqualTo: venueId)
                    .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startDate))
                    .whereField("date", isLessThanOrEqualTo: Timestamp(date: endDate))
                    .getDocuments()
                
                let guestListCount = guestListsSnapshot.documents.count
                
                // Calculate peak hours
                let peakHours = calculatePeakHours(bookings: bookingsSnapshot.documents)
                
                let totalVenueRevenue = bookingRevenue + ticketRevenue
                let avgSpend = bookingCount > 0 ? totalVenueRevenue / Double(bookingCount) : 0
                
                let venueAnalytic = VenueAnalytics(
                    venueId: venueId,
                    venueName: venueName,
                    totalRevenue: totalVenueRevenue,
                    totalBookings: bookingCount,
                    totalTickets: ticketCount,
                    totalGuestLists: guestListCount,
                    averageSpend: avgSpend,
                    peakHours: peakHours,
                    period: period,
                    startDate: startDate,
                    endDate: endDate
                )
                
                analytics.append(venueAnalytic)
                totalRev += totalVenueRevenue
                totalBook += bookingCount
                totalTix += ticketCount
            }
            
            await MainActor.run {
                self.venueAnalytics = analytics.sorted { $0.totalRevenue > $1.totalRevenue }
                self.totalRevenue = totalRev
                self.totalBookings = totalBook
                self.totalTickets = totalTix
                self.isLoading = false
            }
            
        } catch {
            print("Error fetching analytics: \(error)")
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    private func getDateRange(for period: AnalyticsPeriod) -> (Date, Date) {
        let calendar = Calendar.current
        let now = Date()
        
        switch period {
        case .day:
            let start = calendar.startOfDay(for: now)
            return (start, now)
        case .week:
            let start = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            return (start, now)
        case .month:
            let start = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            return (start, now)
        case .year:
            let start = calendar.date(byAdding: .year, value: -1, to: now) ?? now
            return (start, now)
        }
    }
    
    private func calculatePeakHours(bookings: [QueryDocumentSnapshot]) -> [Int] {
        var hourCounts: [Int: Int] = [:]
        
        for doc in bookings {
            if let timestamp = doc.data()["date"] as? Timestamp {
                let date = timestamp.dateValue()
                let hour = Calendar.current.component(.hour, from: date)
                hourCounts[hour, default: 0] += 1
            }
        }
        
        // Return top 3 hours
        return hourCounts.sorted { $0.value > $1.value }
            .prefix(3)
            .map { $0.key }
    }
    
    func exportAnalytics() -> String {
        var csv = "Venue,Revenue,Bookings,Tickets,Guest Lists,Avg Spend\n"
        
        for analytics in venueAnalytics {
            csv += "\(analytics.venueName),$\(Int(analytics.totalRevenue)),\(analytics.totalBookings),\(analytics.totalTickets),\(analytics.totalGuestLists),$\(Int(analytics.averageSpend))\n"
        }
        
        return csv
    }
}
