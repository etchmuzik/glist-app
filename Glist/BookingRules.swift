import Foundation

struct BookingRules {
    let idRequirement: String
    let dressCode: String
    let cancellation: String
    let deposit: String
    let noShow: String
    let ageRequirement: String
}

enum BookingRulesProvider {
    static func forVenue(_ venue: Glist.Venue) -> BookingRules {
        return BookingRules(
            idRequirement: "Valid government-issued photo ID required.",
            dressCode: venue.dressCode,
            cancellation: "Cancellations must be made 24 hours in advance.",
            deposit: "A 20% deposit is required to secure your booking.",
            noShow: "No-shows will be charged a 50% fee.",
            ageRequirement: "Guests must be 21 years or older."
        )
    }
    
    static func forGuestList(_ venue: Glist.Venue) -> BookingRules {
        return BookingRules(
            idRequirement: "Valid government-issued photo ID required.",
            dressCode: venue.dressCode,
            cancellation: "Cancel anytime before the event starts.",
            deposit: "No deposit required (Free Entry).",
            noShow: "Strict Policy: No-shows will be banned from future guest list access.",
            ageRequirement: "Guests must be 21 years or older."
        )
    }
}
