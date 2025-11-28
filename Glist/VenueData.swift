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
            imageURL: "https://images.unsplash.com/photo-1514525253161-7a46d19cd819?auto=format&fit=crop&w=1600&q=80",
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
            weeklySchedule: [
                "Saturday": "URBN (Hip Hop)",
                "Tuesday": "Ladies Night"
            ],
            isTrending: true,
            isFeatured: true,
            featureEndDate: Date().addingTimeInterval(86400 * 14),
            featurePurchaseAmount: 1200
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
            imageURL: "https://images.unsplash.com/photo-1464375117522-1311d6a5b81f?auto=format&fit=crop&w=1600&q=80",
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
            isTrending: true,
            isFeatured: true,
            featureEndDate: Date().addingTimeInterval(86400 * 21),
            featurePurchaseAmount: 900
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
            imageURL: "https://images.unsplash.com/photo-1464375117522-1311d6a5b81f?auto=format&fit=crop&w=1600&q=80",
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
            imageURL: "https://images.unsplash.com/photo-1489515217757-5fd1be406fef?auto=format&fit=crop&w=1600&q=80",
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
            imageURL: "https://images.unsplash.com/photo-1504274066651-8d31a536b11a?auto=format&fit=crop&w=1600&q=80",
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
            imageURL: "https://images.unsplash.com/photo-1514525253161-7a46d19cd819?auto=format&fit=crop&w=1600&q=80",
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
            imageURL: "https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?auto=format&fit=crop&w=1600&q=80",
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
            imageURL: "https://images.unsplash.com/photo-1492684223066-81342ee5ff30?auto=format&fit=crop&w=1600&q=80",
            tags: ["View", "Rooftop", "Lounge", "Fine Dining"],
            latitude: 25.1972,
            longitude: 55.2744,
            events: [],
            isVerified: true,
            minimumAge: 21,
            safetyMessage: "Rooftop safety briefings in effect • ID required • Age 21+ after 8pm",
            weeklySchedule: [
                "Wednesday": "Ladies Night",
                "Friday": "Sky High Brunch"
            ],
            isTrending: false,
            isFeatured: false
        ),
        // Abu Dhabi / F1 Weekend Venues
        Venue(
            name: "Yas Marina Paddock Club",
            type: "VIP Hospitality",
            location: "Yas Marina Circuit",
            district: .yasMarina,
            description: "Trackside VIP hospitality for race weekend with direct circuit views and curated after-dark programming.",
            rating: 4.9,
            price: "$$$$$",
            dressCode: "Formal / Smart Chic",
            imageName: "venue_yas_paddock",
            imageURL: "https://images.unsplash.com/photo-1489515217757-5fd1be406fef?auto=format&fit=crop&w=1600&q=80",
            tags: ["F1", "VIP", "Hospitality", "Live Racing"],
            latitude: 24.4676,
            longitude: 54.6039,
            events: [
                Event(
                    name: "F1 Paddock Club Weekend",
                    date: Calendar.current.date(from: DateComponents(year: 2025, month: 11, day: 29)) ?? Date(),
                    imageUrl: nil,
                    description: "Full-weekend access with track viewing, chef’s table, and post-qualifying lounge sets."
                )
            ],
            tables: [
                Table(name: "Paddock Suite Table", capacity: 6, minimumSpend: 12000),
                Table(name: "Grid Walk Lounge", capacity: 4, minimumSpend: 8000)
            ],
            isVerified: true,
            minimumAge: 21,
            safetyMessage: "Accreditation required • Security screening at entry • ID and dress code enforced",
            weeklySchedule: [:],
            isTrending: true
        ),
        Venue(
            name: "Yas Island F1 After-Party",
            type: "Nightclub",
            location: "Yas Mall Activation Zone",
            district: .yasIsland,
            description: "Official after-race takeover featuring rotating headliners from team activation zones (Mercedes, Ferrari, Red Bull).",
            rating: 4.8,
            price: "$$$$",
            dressCode: "Smart Party",
            imageName: "venue_yas_afterparty",
            imageURL: "https://images.unsplash.com/photo-1492684223066-81342ee5ff30?auto=format&fit=crop&w=1600&q=80",
            tags: ["F1", "After Party", "Headliners", "Yas"],
            latitude: 24.4869,
            longitude: 54.6119,
            events: [
                Event(
                    name: "Team Garage Takeover",
                    date: Calendar.current.date(from: DateComponents(year: 2025, month: 11, day: 30)) ?? Date(),
                    imageUrl: nil,
                    description: "DJ rotation tied to team activations, with limited-access VIP skydeck."
                )
            ],
            tables: [
                Table(name: "Skydeck", capacity: 8, minimumSpend: 9000),
                Table(name: "Pit Lane Booth", capacity: 6, minimumSpend: 6000)
            ],
            isVerified: true,
            minimumAge: 21,
            safetyMessage: "Team-branded zones • ID check • Soft closing times align with circuit rules",
            weeklySchedule: [:],
            isTrending: true
        ),
        Venue(
            name: "Yas Island Hotel Lounge",
            type: "Lounge & Terrace",
            location: "W Abu Dhabi",
            district: .yasIsland,
            description: "Track-view terrace packages that bundle night access with hospitality suites and late-night DJs.",
            rating: 4.7,
            price: "$$$$",
            dressCode: "Smart Casual",
            imageName: "venue_yas_hotel",
            imageURL: "https://images.unsplash.com/photo-1504274066651-8d31a536b11a?auto=format&fit=crop&w=1600&q=80",
            tags: ["F1", "Terrace", "Hospitality", "Track View"],
            latitude: 24.4832,
            longitude: 54.6054,
            events: [
                Event(
                    name: "F1 Terrace Brunch",
                    date: Calendar.current.date(from: DateComponents(year: 2025, month: 11, day: 30)) ?? Date(),
                    imageUrl: nil,
                    description: "Daytime viewing with hospitality, rolls into DJ-led night session."
                )
            ],
            tables: [
                Table(name: "Track Terrace", capacity: 4, minimumSpend: 7000),
                Table(name: "Hospitality Pod", capacity: 6, minimumSpend: 8500)
            ],
            isVerified: true,
            minimumAge: 21,
            safetyMessage: "Trackside safety zones • ID and hotel access checks • Terrace capacity limits",
            weeklySchedule: [:],
            isTrending: true
        ),
        Venue(
            name: "Corniche Beach F1 Club",
            type: "Beach Club",
            location: "Abu Dhabi Corniche",
            district: .abuDhabiCorniche,
            description: "Beachfront F1 viewing with sunset sessions, non-alcoholic Ramadan-friendly menus, and late afters.",
            rating: 4.6,
            price: "$$$",
            dressCode: "Beach Chic",
            imageName: "venue_corniche_f1",
            imageURL: "https://images.unsplash.com/photo-1467348733814-f93fc480bec6?auto=format&fit=crop&w=1600&q=80",
            tags: ["F1", "Beach", "Sunset", "Viewing"],
            latitude: 24.4949,
            longitude: 54.3540,
            events: [
                Event(
                    name: "Sunset F1 Viewing",
                    date: Calendar.current.date(from: DateComponents(year: 2025, month: 11, day: 29)) ?? Date(),
                    imageUrl: nil,
                    description: "Corniche-side screens with curated sets and iftar-friendly options."
                )
            ],
            tables: [
                Table(name: "Waterfront Cabana", capacity: 6, minimumSpend: 5000),
                Table(name: "Sunset Daybed", capacity: 4, minimumSpend: 3200)
            ],
            isVerified: true,
            minimumAge: 21,
            safetyMessage: "Beach safety team • Respectful conduct enforced • ID checks at entry",
            weeklySchedule: [:],
            isTrending: false
        )
    ]
}
