import Foundation
import MapKit


struct Venue: Identifiable, Codable, Sendable {
    var id = UUID()
    var name: String
    var type: String // e.g., "Nightclub", "Beach Club", "Lounge"
    var location: String
    var district: DubaiDistrict = .unknown
    var description: String
    var rating: Double
    var price: String // e.g. "$$$"
    var dressCode: String // e.g. "Smart Casual"
    var imageName: String // Placeholder asset name
    var imageURL: String? // Remote hero image
    var tags: [String]
    var latitude: Double
    var longitude: Double
    var events: [Event] = []
    var tables: [Table] = []
    var isVerified: Bool = false
    var minimumAge: Int = 21

    var safetyMessage: String? = nil
    var whatsAppNumber: String? = nil
    var managerIds: [String] = [] // IDs of users who manage this venue
    
    // Rich Profile Data
    var floorplanImage: String?
    var weeklySchedule: [String: String] = [:] // e.g. ["Monday": "Ladies Night"]
    var isTrending: Bool = false
    var isFeatured: Bool = false
    var featureEndDate: Date? = nil
    var featurePurchaseAmount: Double? = nil
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case type
        case location
        case district
        case description
        case rating
        case price
        case dressCode = "dress_code"
        case imageName = "image_name"
        case imageURL = "image_url"
        case tags
        case latitude
        case longitude
        case events
        case tables
        case isVerified = "is_verified"
        case minimumAge = "minimum_age"
        case safetyMessage = "safety_message"
        case whatsAppNumber = "whatsapp_number"
        case managerIds = "manager_ids"
        
        // Rich Profile Data - Map to snake_case
        case floorplanImage = "floorplan_image"
        case weeklySchedule = "weekly_schedule"
        case isTrending = "is_trending"
        case isFeatured = "is_featured"
        case featureEndDate = "feature_end_date"
        case featurePurchaseAmount = "feature_purchase_amount"
    }
    
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

enum DubaiDistrict: String, CaseIterable, Codable, Sendable {
    case marina = "Dubai Marina"
    case difc = "DIFC"
    case jbr = "JBR"
    case palm = "Palm Jumeirah"
    case meydan = "Meydan"
    case bluewaters = "Bluewaters Island"
    case d3 = "Dubai Design District"
    case downtown = "Downtown"
    case alHabtoor = "Al Habtoor City"
    case yasIsland = "Yas Island"
    case yasMarina = "Yas Marina"
    case abuDhabiCorniche = "Abu Dhabi Corniche"
    case unknown = "Dubai"
    
    var displayName: String { rawValue }
}

struct Table: Identifiable, Codable, Sendable {
    var id = UUID()
    var name: String
    var capacity: Int
    var minimumSpend: Double
    var isAvailable: Bool = true
}
