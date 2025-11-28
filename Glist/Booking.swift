import Foundation

enum BookingStatus: String, Codable, Sendable {
    case pending = "Pending"
    case holdPending = "Hold Pending"
    case confirmed = "Confirmed"
    case waitlisted = "Waitlisted"
    case autoPromoted = "Auto Promoted"
    case expired = "Expired"
    case paid = "Paid"
    case cancelled = "Cancelled"
}

struct Booking: Identifiable, Codable, Sendable {
    let id: UUID
    let userId: String
    let venueId: String
    let venueName: String
    let tableId: UUID
    let tableName: String
    let date: Date
    let depositAmount: Double
    let status: BookingStatus
    let createdAt: Date
}
