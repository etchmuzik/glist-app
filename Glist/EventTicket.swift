import Foundation

enum TicketStatus: String, Codable {
    case valid = "Valid"
    case used = "Used"
    case refunded = "Refunded"
    case expired = "Expired"
}

struct EventTicket: Identifiable, Codable {
    let id: UUID
    let eventId: UUID
    let eventName: String
    let eventDate: Date
    let venueId: UUID
    let venueName: String
    let userId: String
    let ticketTypeId: UUID
    let ticketTypeName: String
    let price: Double
    let status: TicketStatus
    let qrCodeId: String
    let purchaseDate: Date
}
