import Foundation
import MapKit

struct Venue: Identifiable {
    var id = UUID()
    let name: String
    let type: String // e.g., "Nightclub", "Beach Club", "Lounge"
    let location: String
    var district: DubaiDistrict = .unknown
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
    var isVerified: Bool = false
    var minimumAge: Int = 21
    var safetyMessage: String? = nil
    
    // Rich Profile Data
    var floorplanImage: String?
    var bottleMenu: [BottleItem] = []
    var weeklySchedule: [String: String] = [:] // e.g. ["Monday": "Ladies Night"]
    var isTrending: Bool = false
    
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

struct BottleItem: Identifiable, Codable, Hashable {
    var id = UUID()
    let name: String
    let price: Double
    let type: String // Vodka, Champagne, etc.
}

extension Venue: Hashable {}

enum DubaiDistrict: String, CaseIterable, Codable {
    case marina = "Dubai Marina"
    case difc = "DIFC"
    case jbr = "JBR"
    case palm = "Palm Jumeirah"
    case meydan = "Meydan"
    case bluewaters = "Bluewaters Island"
    case d3 = "Dubai Design District"
    case downtown = "Downtown"
    case alHabtoor = "Al Habtoor City"
    case unknown = "Dubai"
    
    var displayName: String { rawValue }
}

struct Table: Identifiable, Codable {
    var id = UUID()
    let name: String
    let capacity: Int
    let minimumSpend: Double
    var isAvailable: Bool = true
}
