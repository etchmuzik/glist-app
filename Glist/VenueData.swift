import Foundation

struct VenueData {
    static let dubaiVenues: [Venue] = [
        Venue(
            name: "White Dubai",
            type: "Nightclub",
            location: "Meydan Racecourse",
            district: .meydan,
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
            ],
            isVerified: true,
            minimumAge: 21,
            safetyMessage: "Government-issued ID required • Security bag checks • Respectful conduct enforced",
            floorplanImage: "https://example.com/floorplan.jpg",
            bottleMenu: [
                BottleItem(name: "Belvedere 0.7L", price: 1500, type: "Vodka"),
                BottleItem(name: "Grey Goose 1.5L", price: 3200, type: "Vodka"),
                BottleItem(name: "Dom Perignon", price: 4500, type: "Champagne")
            ],
            weeklySchedule: [
                "Saturday": "URBN (Hip Hop)",
                "Tuesday": "Ladies Night"
            ],
            isTrending: true
        ),
        Venue(
            name: "Soho Garden",
            type: "Nightclub complex",
            location: "Meydan Racecourse",
            district: .meydan,
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
            ],
            isVerified: true,
            minimumAge: 21,
            safetyMessage: "Smart casual dress code • Entry subject to sobriety checks • Valid ID required",
            weeklySchedule: [
                "Friday": "Playground (Techno)",
                "Saturday": "Soho Saturdays"
            ],
            isTrending: true
        ),
        Venue(
            name: "BLU Dubai",
            type: "Nightclub",
            location: "V Hotel, Al Habtoor City",
            district: .alHabtoor,
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
            ],
            isVerified: true,
            minimumAge: 21,
            safetyMessage: "VIP tables held for 15 minutes past booking • ID and age verification at door"
        ),
        Venue(
            name: "1 OAK Dubai",
            type: "Nightclub",
            location: "JW Marriott Marquis",
            district: .downtown,
            description: "One Of A Kind. The Dubai outpost of the famous New York nightclub, offering a chic and exclusive clubbing experience.",
            rating: 4.5,
            price: "$$$$",
            dressCode: "Smart Elegant",
            imageName: "venue_1oak",
            tags: ["Exclusive", "Hip Hop", "Celebrity Spot"],
            latitude: 25.1855,
            longitude: 55.2580,
            events: [],
            isVerified: true,
            minimumAge: 21,
            safetyMessage: "Entry requires smart attire and matching ID; re-entry not guaranteed during peak hours"
        ),
        Venue(
            name: "Cove Beach",
            type: "Beach Club",
            location: "Bluewaters Island",
            district: .bluewaters,
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
            ],
            isVerified: true,
            minimumAge: 21,
            safetyMessage: "Poolside safety team on-site • Sun-protection and hydration encouraged • ID check at entry"
        ),
        Venue(
            name: "Sky 2.0",
            type: "Nightclub",
            location: "Dubai Design District",
            district: .d3,
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
            ],
            isVerified: true,
            minimumAge: 21,
            safetyMessage: "Open-air venue; weather-related closures possible • ID required • Bag check at entry"
        ),
        Venue(
            name: "Billionaire Dubai",
            type: "Dinner & Show",
            location: "Taj Hotel",
            district: .downtown,
            description: "A unique dining and entertainment experience featuring spectacular live shows and Italian & New Asian cuisine.",
            rating: 4.7,
            price: "$$$$$",
            dressCode: "Formal",
            imageName: "venue_billionaire",
            tags: ["Dinner Show", "Luxury", "Performance"],
            latitude: 25.1944,
            longitude: 55.2753,
            events: [],
            isVerified: true,
            minimumAge: 21,
            safetyMessage: "Dinner show requires seated arrivals • ID check and smart attire enforced"
        ),
        Venue(
            name: "Ce La Vi",
            type: "Lounge & Skybar",
            location: "Address Sky View",
            district: .downtown,
            description: "Iconic rooftop venue offering breathtaking views of the Burj Khalifa, perfect for sunset drinks and evening vibes.",
            rating: 4.8,
            price: "$$$$",
            dressCode: "Smart Casual",
            imageName: "venue_celavi",
            tags: ["View", "Rooftop", "Lounge", "Fine Dining"],
            latitude: 25.1972,
            longitude: 55.2744,
            events: [],
            isVerified: true,
            minimumAge: 21,
            safetyMessage: "Rooftop safety briefings in effect • ID required • Age 21+ after 8pm",
            bottleMenu: [
                BottleItem(name: "Moet & Chandon", price: 1200, type: "Champagne"),
                BottleItem(name: "Hendricks", price: 1400, type: "Gin")
            ],
            weeklySchedule: [
                "Wednesday": "Ladies Night",
                "Friday": "Sky High Brunch"
            ],
            isTrending: false
        )
    ]
}
