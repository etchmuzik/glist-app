import Foundation

struct VenueData {
    static let dubaiVenues: [Venue] = [
        Venue(
            name: "White Dubai",
            type: "Nightclub",
            location: "Meydan Racecourse",
            description: "Dubai's ultimate outdoor rooftop nightlife experience. Known for its incredible light shows and top-tier DJ lineups.",
            rating: 4.8,
            price: "$$$$",
            dressCode: "Smart Elegant",
            imageName: "venue_white",
            tags: ["Rooftop", "Outdoor", "Hip Hop", "Electronic"],
            latitude: 25.1558,
            longitude: 55.3003,
            events: [
                Event(name: "URBN Saturdays", date: Date().addingTimeInterval(86400 * 2), imageUrl: nil, description: "The best of Hip Hop and R&B."),
                Event(name: "Ladies Night", date: Date().addingTimeInterval(86400 * 5), imageUrl: nil, description: "Complimentary drinks for ladies.")
            ]
        ),
        Venue(
            name: "Soho Garden",
            type: "Nightclub complex",
            location: "Meydan Racecourse",
            description: "A massive complex featuring multiple venues including Code, Soho Garden DXB, and more. The heart of Dubai's party scene.",
            rating: 4.7,
            price: "$$$",
            dressCode: "Smart Casual",
            imageName: "venue_soho",
            tags: ["Complex", "House", "Techno", "Garden"],
            latitude: 25.1560,
            longitude: 55.2990,
            events: [
                Event(name: "Playground", date: Date().addingTimeInterval(86400 * 1), imageUrl: nil, description: "Techno vibes all night."),
                Event(name: "Soho Saturdays", date: Date().addingTimeInterval(86400 * 3), imageUrl: nil, description: "International DJs.")
            ]
        ),
        Venue(
            name: "BLU Dubai",
            type: "Nightclub",
            location: "V Hotel, Al Habtoor City",
            description: "A high-energy nightclub known for its celebrity appearances, state-of-the-art sound system, and luxurious atmosphere.",
            rating: 4.6,
            price: "$$$$",
            dressCode: "Glamorous",
            imageName: "venue_blu",
            tags: ["Luxury", "Hip Hop", "Live Shows"],
            latitude: 25.1856,
            longitude: 55.2583,
            events: [
                Event(name: "BLU Sky", date: Date().addingTimeInterval(86400 * 4), imageUrl: nil, description: "Sky high partying.")
            ]
        ),
        Venue(
            name: "1 OAK Dubai",
            type: "Nightclub",
            location: "JW Marriott Marquis",
            description: "One Of A Kind. The Dubai outpost of the famous New York nightclub, offering a chic and exclusive clubbing experience.",
            rating: 4.5,
            price: "$$$$",
            dressCode: "Smart Elegant",
            imageName: "venue_1oak",
            tags: ["Exclusive", "Hip Hop", "Celebrity Spot"],
            latitude: 25.1855,
            longitude: 55.2580,
            events: []
        ),
        Venue(
            name: "Cove Beach",
            type: "Beach Club",
            location: "Bluewaters Island",
            description: "A stunning beach club with a Mediterranean vibe, featuring a pool, beach access, and a lively party atmosphere day and night.",
            rating: 4.6,
            price: "$$$",
            dressCode: "Beach Chic",
            imageName: "venue_cove",
            tags: ["Beach", "Pool", "Day Party", "Sunset"],
            latitude: 25.0785,
            longitude: 55.1218,
            events: [
                Event(name: "Rose All Day", date: Date().addingTimeInterval(86400 * 1), imageUrl: nil, description: "Unlimited Rose wine.")
            ]
        ),
        Venue(
            name: "Sky 2.0",
            type: "Nightclub",
            location: "Dubai Design District",
            description: "A revolutionary standalone nightclub in the heart of D3, known for its interactive design and grand scale entertainment.",
            rating: 4.9,
            price: "$$$$",
            dressCode: "Dress to Impress",
            imageName: "venue_sky",
            tags: ["Open Air", "Design", "Show", "Architecture"],
            latitude: 25.1872,
            longitude: 55.2980,
            events: [
                Event(name: "Boombox", date: Date().addingTimeInterval(86400 * 3), imageUrl: nil, description: "Old school hits.")
            ]
        ),
        Venue(
            name: "Billionaire Dubai",
            type: "Dinner & Show",
            location: "Taj Hotel",
            description: "A unique dining and entertainment experience featuring spectacular live shows and Italian & New Asian cuisine.",
            rating: 4.7,
            price: "$$$$$",
            dressCode: "Formal",
            imageName: "venue_billionaire",
            tags: ["Dinner Show", "Luxury", "Performance"],
            latitude: 25.1944,
            longitude: 55.2753,
            events: []
        ),
        Venue(
            name: "Ce La Vi",
            type: "Lounge & Skybar",
            location: "Address Sky View",
            description: "Iconic rooftop venue offering breathtaking views of the Burj Khalifa, perfect for sunset drinks and evening vibes.",
            rating: 4.8,
            price: "$$$$",
            dressCode: "Smart Casual",
            imageName: "venue_celavi",
            tags: ["View", "Rooftop", "Lounge", "Fine Dining"],
            latitude: 25.1972,
            longitude: 55.2744,
            events: []
        )
    ]
}
