import Foundation
import Combine

struct Event: Identifiable {
    let id = UUID()
    let name: String
    let date: Date
    let imageUrl: String? // Placeholder
    let description: String?
    var ticketTypes: [TicketType] = []
}

struct TicketType: Identifiable, Codable {
    var id = UUID()
    let name: String
    let price: Double
    let totalQuantity: Int
    var availableQuantity: Int
    let description: String?
}
