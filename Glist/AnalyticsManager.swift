import Foundation
import SwiftUI
import Combine
import FirebaseFirestore

class AnalyticsManager: ObservableObject {
    @Published var venueAnalytics: [VenueAnalytics] = []
    @Published var totalRevenue: Double = 0
    @Published var totalBookings: Int = 0
    @Published var totalTickets: Int = 0
    @Published var isLoading = false
    @Published var selectedPeriod: AnalyticsPeriod = .week
    
    // Tonight / today overview across all venues
    @Published var todayRevenue: Double = 0
    @Published var todayBookings: Int = 0
    @Published var todayTickets: Int = 0
    @Published var todayGuestLists: Int = 0
    
    // Payments breakdown (today)
    @Published var todayPaidBookings: Int = 0
    @Published var todayUnpaidBookings: Int = 0
    
    // Alert counters
    @Published var alertsPendingKYC: Int = 0
    @Published var alertsNoShowEventsToday: Int = 0
    
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
    
    /// Fetches a high-level "today / tonight" overview across all venues.
    /// This is independent of the selected analytics period and is meant
    /// for the Tonight Overview cards in the admin dashboard.
    func fetchTodayOverview() async {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        // End of day = start of next day
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? now
        
        do {
            // Bookings today
            let bookingsSnapshot = try await db.collection("bookings")
                .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startOfDay))
                .whereField("date", isLessThan: Timestamp(date: endOfDay))
                .getDocuments()
            let bookingsRevenue = bookingsSnapshot.documents.reduce(0.0) { sum, doc in
                sum + (doc.data()["depositAmount"] as? Double ?? 0)
            }
            
            // Tickets purchased today
            let ticketsSnapshot = try await db.collection("tickets")
                .whereField("purchaseDate", isGreaterThanOrEqualTo: Timestamp(date: startOfDay))
                .whereField("purchaseDate", isLessThan: Timestamp(date: endOfDay))
                .getDocuments()
            let ticketsRevenue = ticketsSnapshot.documents.reduce(0.0) { sum, doc in
                sum + (doc.data()["price"] as? Double ?? 0)
            }
            
            // Guest list requests for today
            let guestListsSnapshot = try await db.collection("guestListRequests")
                .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startOfDay))
                .whereField("date", isLessThan: Timestamp(date: endOfDay))
                .getDocuments()
            
            let todayRev = bookingsRevenue + ticketsRevenue
            let todayBookCount = bookingsSnapshot.documents.count
            let todayTicketCount = ticketsSnapshot.documents.count
            let todayGuestListCount = guestListsSnapshot.documents.count
            
            // Payment status breakdown (Pending vs Paid)
            var paidCount = 0
            var unpaidCount = 0
            for doc in bookingsSnapshot.documents {
                if let status = doc.data()["status"] as? String {
                    if status == BookingStatus.paid.rawValue { paidCount += 1 }
                    if status == BookingStatus.pending.rawValue || status == BookingStatus.holdPending.rawValue {
                        unpaidCount += 1
                    }
                }
            }
            
            await MainActor.run {
                self.todayRevenue = todayRev
                self.todayBookings = todayBookCount
                self.todayTickets = todayTicketCount
                self.todayGuestLists = todayGuestListCount
                self.todayPaidBookings = paidCount
                self.todayUnpaidBookings = unpaidCount
            }
        } catch {
            print("Error fetching today overview: \(error)")
        }
    }
    
    /// Lightweight alert counters for the admin dashboard.
    /// - Pending KYC submissions
    /// - No-show safety events recorded today
    func fetchAlerts() async {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? now
        
        do {
            // Pending KYC submissions
            let kycSnapshot = try await db.collection("kycSubmissions")
                .whereField("status", isEqualTo: KYCStatus.pending.rawValue)
                .getDocuments()
            
            // No-show safety events today
            let safetySnapshot = try await db.collection("safetyEvents")
                .whereField("type", isEqualTo: SafetyEventType.noShowIncrement.rawValue)
                .whereField("createdAt", isGreaterThanOrEqualTo: Timestamp(date: startOfDay))
                .whereField("createdAt", isLessThan: Timestamp(date: endOfDay))
                .getDocuments()
            
            await MainActor.run {
                self.alertsPendingKYC = kycSnapshot.documents.count
                self.alertsNoShowEventsToday = safetySnapshot.documents.count
            }
        } catch {
            print("Error fetching alerts: \(error)")
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
            let revenue = CurrencyFormatter.aed(analytics.totalRevenue)
            let avgSpend = CurrencyFormatter.aed(analytics.averageSpend)
            csv += "\(analytics.venueName),\(revenue),\(analytics.totalBookings),\(analytics.totalTickets),\(analytics.totalGuestLists),\(avgSpend)\n"
        }
        
        return csv
    }
}
