import Foundation
import SwiftUI
import Combine
import Supabase

@MainActor
class AnalyticsManager: ObservableObject {
    @Published var venueAnalytics: [VenueAnalytics] = []
    @Published var totalRevenue: Double = 0
    @Published var totalBookings: Int = 0
    @Published var totalTickets: Int = 0
    @Published var totalGuestLists: Int = 0
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
    
    private let client = SupabaseManager.shared.client
    
    func fetchAnalytics(period: AnalyticsPeriod = .week) async {
        isLoading = true
        selectedPeriod = period
        
        do {
            let (startDate, endDate) = getDateRange(for: period)
            let startISO = startDate.ISO8601Format()
            let endISO = endDate.ISO8601Format()
            
            // Fetch all venues
            let venues: [Venue] = try await client.database.from("venues").select().execute().value
            
            // Fetch all bookings in range
            let bookings: [Booking] = try await client.database.from("bookings")
                .select()
                .gte("date", value: startISO)
                .lte("date", value: endISO)
                .execute()
                .value
            
            // Fetch all tickets in range
            let tickets: [EventTicket] = try await client.database.from("tickets")
                .select()
                .gte("purchase_date", value: startISO)
                .lte("purchase_date", value: endISO)
                .execute()
                .value
            
            // Fetch all guest lists in range
            let guestLists: [GuestListRequest] = try await client.database.from("guest_list_requests")
                .select()
                .gte("date", value: startISO)
                .lte("date", value: endISO)
                .execute()
                .value
            
            var analytics: [VenueAnalytics] = []
            var totalRev: Double = 0
            var totalBook: Int = 0
            var totalTix: Int = 0
            
            for venue in venues {
                let venueId = venue.id.uuidString
                let venueName = venue.name
                
                // Filter for this venue
                let venueBookings = bookings.filter { $0.venueId == venueId }
                let venueTickets = tickets.filter { $0.venueId.uuidString == venueId }
                let venueGuestLists = guestLists.filter { $0.venueId == venueId }
                
                let bookingRevenue = venueBookings.reduce(0.0) { $0 + $1.depositAmount }
                let bookingCount = venueBookings.count
                
                let ticketRevenue = venueTickets.reduce(0.0) { $0 + $1.price }
                let ticketCount = venueTickets.count
                
                let guestListCount = venueGuestLists.count
                
                // Calculate peak hours
                let peakHours = calculatePeakHours(bookings: venueBookings)
                
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
    func fetchTodayOverview() async {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? now
        
        let startISO = startOfDay.ISO8601Format()
        let endISO = endOfDay.ISO8601Format()
        
        do {
            // Bookings today
            let bookings: [Booking] = try await client.database.from("bookings")
                .select()
                .gte("date", value: startISO)
                .lt("date", value: endISO)
                .execute()
                .value
                
            let bookingsRevenue = bookings.reduce(0.0) { $0 + $1.depositAmount }
            
            // Tickets purchased today
            let tickets: [EventTicket] = try await client.database.from("tickets")
                .select()
                .gte("purchase_date", value: startISO)
                .lt("purchase_date", value: endISO)
                .execute()
                .value
                
            let ticketsRevenue = tickets.reduce(0.0) { $0 + $1.price }
            
            // Guest list requests for today
            let guestLists: [GuestListRequest] = try await client.database.from("guest_list_requests")
                .select()
                .gte("date", value: startISO)
                .lt("date", value: endISO)
                .execute()
                .value
            
            let todayRev = bookingsRevenue + ticketsRevenue
            let todayBookCount = bookings.count
            let todayTicketCount = tickets.count
            let todayGuestListCount = guestLists.count
            
            // Payment status breakdown (Pending vs Paid)
            var paidCount = 0
            var unpaidCount = 0
            for booking in bookings {
                if booking.status == .paid { paidCount += 1 }
                if booking.status == .pending || booking.status == .holdPending {
                    unpaidCount += 1
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
    func fetchAlerts() async {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? now
        
        let startISO = startOfDay.ISO8601Format()
        let endISO = endOfDay.ISO8601Format()
        
        do {
            // Pending KYC submissions
            let kycCount = try await client.database.from("kyc_submissions")
                .select(head: true, count: .exact)
                .eq("status", value: KYCStatus.pending.rawValue)
                .execute()
                .count ?? 0
            
            // No-show safety events today
            let safetyCount = try await client.database.from("safety_events")
                .select(head: true, count: .exact)
                .eq("type", value: SafetyEventType.noShowIncrement.rawValue)
                .gte("created_at", value: startISO)
                .lt("created_at", value: endISO)
                .execute()
                .count ?? 0
            
            await MainActor.run {
                self.alertsPendingKYC = kycCount
                self.alertsNoShowEventsToday = safetyCount
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
    
    private func calculatePeakHours(bookings: [Booking]) -> [Int] {
        var hourCounts: [Int: Int] = [:]
        
        for booking in bookings {
            let hour = Calendar.current.component(.hour, from: booking.date)
            hourCounts[hour, default: 0] += 1
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

