import Foundation

/// Simple heuristic-based recommendation engine.
///
/// This is a local "AI-style" recommender that ranks venues based on
/// recency, rating, trending status, events, and price band.
/// It is intentionally deterministic and side-effect free so it can be
/// unit-tested and later swapped out for a backend ML service.
struct RecommendationEngine {
    struct Context {
        /// Optional preferred district for the current user/session.
        let preferredDistrict: DubaiDistrict?
        /// Typical group size (used to favor higher-capacity / premium venues later).
        let groupSize: Int
        /// Flag to boost trending/nightlife-heavy venues.
        let prefersNightlife: Bool
        
        static let `default` = Context(preferredDistrict: nil, groupSize: 4, prefersNightlife: true)
    }
    
    static func recommendedVenues(from venues: [Venue], context: Context = .default, limit: Int = 10) -> [Venue] {
        guard !venues.isEmpty else { return [] }
        
        let scored: [(venue: Venue, score: Double)] = venues.map { venue in
            var score: Double = 0
            
            // Base score from rating
            score += (venue.rating * 10) // 4.8 → 48 pts
            
            // Trending boost
            if venue.isTrending {
                score += 15
            }
            
            // Events boost (we want venues with something happening)
            if !venue.events.isEmpty {
                score += 10
            }
            
            // District preference boost
            if let preferred = context.preferredDistrict, venue.district == preferred {
                score += 8
            }
            
            // Price band: slightly favor mid-to-high price venues for nightlife
            let priceLength = venue.price.count
            if context.prefersNightlife {
                if priceLength >= 3 { score += 5 }
                if priceLength >= 4 { score += 3 }
            }
            
            return (venue, score)
        }
        
        return scored
            .sorted { $0.score > $1.score }
            .prefix(limit)
            .map { $0.venue }
    }
}
