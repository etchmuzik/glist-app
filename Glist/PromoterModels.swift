import Foundation

struct Promoter: Identifiable, Codable {
    let id: String
    let userId: String
    let name: String
    var commissionRate: Double // e.g., 0.10 for 10%
    var venueIds: [String] // Venues they can promote
    var totalEarnings: Double
    var activeGuestLists: Int
    var reputationScore: Int
    var kycStatus: KYCStatus
    var createdAt: Date
    
    init(id: String = UUID().uuidString, userId: String, name: String, commissionRate: Double = 0.10, venueIds: [String] = [], totalEarnings: Double = 0, activeGuestLists: Int = 0, reputationScore: Int = 80, kycStatus: KYCStatus = .pending, createdAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.name = name
        self.commissionRate = commissionRate
        self.venueIds = venueIds
        self.totalEarnings = totalEarnings
        self.activeGuestLists = activeGuestLists
        self.reputationScore = reputationScore
        self.kycStatus = kycStatus
        self.createdAt = createdAt
    }
}

struct Commission: Identifiable, Codable {
    let id: String
    let promoterId: String
    let promoterName: String
    let bookingId: String?
    let guestListId: String?
    let venueName: String
    let amount: Double
    var status: CommissionStatus
    let date: Date
    
    init(id: String = UUID().uuidString, promoterId: String, promoterName: String, bookingId: String? = nil, guestListId: String? = nil, venueName: String, amount: Double, status: CommissionStatus = .pending, date: Date = Date()) {
        self.id = id
        self.promoterId = promoterId
        self.promoterName = promoterName
        self.bookingId = bookingId
        self.guestListId = guestListId
        self.venueName = venueName
        self.amount = amount
        self.status = status
        self.date = date
    }
}

enum CommissionStatus: String, Codable {
    case pending = "Pending"
    case paid = "Paid"
    case cancelled = "Cancelled"
}

struct VenueAnalytics: Identifiable, Codable {
    let id: String
    let venueId: String
    let venueName: String
    var totalRevenue: Double
    var totalBookings: Int
    var totalTickets: Int
    var totalGuestLists: Int
    var averageSpend: Double
    var peakHours: [Int] // Hours of day (0-23)
    let period: AnalyticsPeriod
    let startDate: Date
    let endDate: Date
    
    init(id: String = UUID().uuidString, venueId: String, venueName: String, totalRevenue: Double = 0, totalBookings: Int = 0, totalTickets: Int = 0, totalGuestLists: Int = 0, averageSpend: Double = 0, peakHours: [Int] = [], period: AnalyticsPeriod = .week, startDate: Date = Date(), endDate: Date = Date()) {
        self.id = id
        self.venueId = venueId
        self.venueName = venueName
        self.totalRevenue = totalRevenue
        self.totalBookings = totalBookings
        self.totalTickets = totalTickets
        self.totalGuestLists = totalGuestLists
        self.averageSpend = averageSpend
        self.peakHours = peakHours
        self.period = period
        self.startDate = startDate
        self.endDate = endDate
    }
}

enum AnalyticsPeriod: String, Codable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    case year = "Year"
}
