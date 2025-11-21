import Foundation

enum BookingStatus: String, Codable {
    case pending = "Pending"
    case paid = "Paid"
    case cancelled = "Cancelled"
}

struct Booking: Identifiable, Codable {
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
