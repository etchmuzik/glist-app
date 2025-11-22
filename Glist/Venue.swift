import Foundation
import MapKit

struct Venue: Identifiable {
    var id = UUID()
    let name: String
    let type: String // e.g., "Nightclub", "Beach Club", "Lounge"
    let location: String
    let description: String
    let rating: Double
    let price: String // e.g. "$$$"
    let dressCode: String // e.g. "Smart Casual"
    let imageName: String // Placeholder for now
    let tags: [String]
    let latitude: Double
    let longitude: Double
    var events: [Event] = []
    var tables: [Table] = []
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Venue, rhs: Venue) -> Bool {
        lhs.id == rhs.id
    }
}

extension Venue: Hashable {}

struct Table: Identifiable, Codable {
    var id = UUID()
    let name: String
    let capacity: Int
    let minimumSpend: Double
    var isAvailable: Bool = true
}
