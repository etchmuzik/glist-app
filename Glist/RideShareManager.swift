import Foundation
import UIKit

/// Handles deep links to ride-hailing / mapping apps (Careem, Ekar, Apple Maps).
///
/// NOTE: For Careem / Ekar custom URL schemes, you may need to add
/// LSApplicationQueriesSchemes entries in Info.plist to allow canOpenURL checks.
struct RideShareManager {
    enum Provider {
        case careem
        case ekar
        case appleMaps
    }
    
    // MARK: - URL Builders
    
    /// Best-effort Careem deep link.
    /// Scheme/parameters should be verified against latest Careem docs.
    static func careemURL(for venue: Venue) -> URL? {
        let nameEncoded = venue.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let lat = venue.latitude
        let lon = venue.longitude
        let urlString = "careem://open?destination_latitude=\(lat)&destination_longitude=\(lon)&destination_name=\(nameEncoded)"
        return URL(string: urlString)
    }
    
    /// Best-effort Ekar deep link (car sharing / rentals).
    /// This is a placeholder and should be aligned with Ekar's latest URL scheme.
    static func ekarURL(for venue: Venue) -> URL? {
        let nameEncoded = venue.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "ekar://open?destination_name=\(nameEncoded)&lat=\(venue.latitude)&lng=\(venue.longitude)"
        return URL(string: urlString)
    }
    
    /// Fallback: Apple Maps search for venue location.
    static func appleMapsURL(for venue: Venue) -> URL? {
        let query = venue.location.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? venue.name
        let urlString = "http://maps.apple.com/?q=\(query)&ll=\(venue.latitude),\(venue.longitude)"
        return URL(string: urlString)
    }
    
    // MARK: - Open Helpers
    
    /// Opens the best available ride/mapping option for this venue.
    /// Priority: Careem → Ekar → Apple Maps.
    static func openBestOption(for venue: Venue) {
        guard let application = UIApplication.sharedIfAvailable else { return }
        
        if let careem = careemURL(for: venue), application.canOpenURL(careem) {
            application.open(careem)
            return
        }
        
        if let ekar = ekarURL(for: venue), application.canOpenURL(ekar) {
            application.open(ekar)
            return
        }
        
        if let maps = appleMapsURL(for: venue) {
            application.open(maps)
        }
    }
}

// MARK: - UIApplication helper

private extension UIApplication {
    /// Safe access helper for UIApplication.shared (avoids issues in previews / extensions).
    static var sharedIfAvailable: UIApplication? {
        #if os(iOS)
        return UIApplication.value(forKeyPath: #keyPath(UIApplication.shared)) as? UIApplication
        #else
        return nil
        #endif
    }
}
