import Foundation
import Combine

struct Event: Identifiable, Codable, Sendable {
    let id = UUID()
    var name: String
    var date: Date
    var imageUrl: String? // Placeholder
    var description: String?
    var ticketTypes: [TicketType] = []
}

struct TicketType: Identifiable, Codable, Sendable {
    var id = UUID()
    var name: String
    var price: Double
    var totalQuantity: Int
    var availableQuantity: Int
    var description: String?
}
