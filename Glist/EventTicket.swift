import Foundation

enum TicketStatus: String, Codable, Sendable {
    case valid = "Valid"
    case used = "Used"
    case refunded = "Refunded"
    case expired = "Expired"
}

struct EventTicket: Identifiable, Codable, Sendable {
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
    
    // Resale Info
    var resaleStatus: String? // "Active", "Sold", "Cancelled"
    var resalePrice: Double?
    var resaleOfferId: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case eventId = "event_id"
        case eventName = "event_name"
        case eventDate = "event_date"
        case venueId = "venue_id"
        case venueName = "venue_name"
        case userId = "user_id"
        case ticketTypeId = "ticket_type_id"
        case ticketTypeName = "ticket_type_name"
        case price
        case status
        case qrCodeId = "qr_code_id"
        case purchaseDate = "purchase_date"
        case resaleStatus = "resale_status"
        case resalePrice = "resale_price"
        case resaleOfferId = "resale_offer_id"
    }
}
