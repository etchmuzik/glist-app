import Foundation

struct PromoterAttribution: Codable, Equatable, Sendable {
    let code: String
    let promoterId: String?
    let campaign: String?
    let source: String?
    let medium: String?
    let bookingId: UUID?
    
    init(
        code: String,
        promoterId: String? = nil,
        campaign: String? = nil,
        source: String? = nil,
        medium: String? = nil,
        bookingId: UUID? = nil
    ) {
        self.code = code
        self.promoterId = promoterId
        self.campaign = campaign
        self.source = source
        self.medium = medium
        self.bookingId = bookingId
    }
}

enum PromoterAttributionManager {
    static func link(baseURL: URL, payload: PromoterAttribution) -> URL? {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        var items: [URLQueryItem] = [
            URLQueryItem(name: "pc", value: payload.code)
        ]
        
        if let promoterId = payload.promoterId {
            items.append(URLQueryItem(name: "pid", value: promoterId))
        }
        if let campaign = payload.campaign {
            items.append(URLQueryItem(name: "cmp", value: campaign))
        }
        if let source = payload.source {
            items.append(URLQueryItem(name: "src", value: source))
        }
        if let medium = payload.medium {
            items.append(URLQueryItem(name: "med", value: medium))
        }
        if let bookingId = payload.bookingId {
            items.append(URLQueryItem(name: "bid", value: bookingId.uuidString))
        }
        
        components?.queryItems = items
        return components?.url
    }
    
    static func parse(url: URL) -> PromoterAttribution? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        
        let lookup: [String: String] = Dictionary(
            uniqueKeysWithValues: (components.queryItems ?? []).compactMap { item in
                guard let value = item.value else { return nil }
                return (item.name, value)
            }
        )
        
        guard let code = lookup["pc"] ?? lookup["promoter_code"] else { return nil }
        
        let bookingId = lookup["bid"].flatMap { UUID(uuidString: $0) }
        
        return PromoterAttribution(
            code: code,
            promoterId: lookup["pid"],
            campaign: lookup["cmp"] ?? lookup["campaign"],
            source: lookup["src"],
            medium: lookup["med"],
            bookingId: bookingId
        )
    }
}
