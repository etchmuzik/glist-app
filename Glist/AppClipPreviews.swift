// Previews are debug-only; they can be excluded from release builds.
#if DEBUG
import SwiftUI

// MARK: - Seed Helpers for Previews
private struct PreviewSeed {
    static let venue = Glist.Venue(
        id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!,
        name: "UPSTAIRS Marina",
        type: "Nightclub",
        location: "Dubai Marina",
        district: .marina,
        description: "Skyline views with headline DJs and high-energy sets.",
        rating: 4.8,
        price: "$$$",
        dressCode: "Smart Casual",
        imageName: "venue_placeholder",
        imageURL: "https://images.unsplash.com/photo-1492684223066-81342ee5ff30?auto=format&fit=crop&w=1600&q=80",
        tags: ["Rooftop", "House", "Views"],
        latitude: 25.0803,
        longitude: 55.1390,
        isVerified: true,
        isTrending: true
    )
}

// MARK: - App Clip Content Preview
#Preview("App Clip – Seeded Booking Flow") {
    struct SeededAppClipPreviewHost: View {
        @State private var selectedVenue: Glist.Venue? = PreviewSeed.venue
        @State private var selectedTable: (id: UUID, name: String, minSpend: Double)? = (UUID(), "VIP Booth", 1800)
        @State private var bookingDate: Date = .now.addingTimeInterval(60.0 * 60.0 * 24.0)
        @State private var guestCount: Int = 4
        @State private var showApplePay = false
        @State private var showTickets = false
        @State private var selectedTicket: AppClipTicketOption? = nil

        var body: some View {
            // Use the actual AppClipContentView and let it read state via its own @State.
            // We can also set color scheme and background to match the app.
            AppClipContentView()
                .environment(\.colorScheme, .dark)
                .background(Color.theme.background)
        }
    }
    return SeededAppClipPreviewHost()
}

// MARK: - App Clip Ticket Selection Preview
#Preview("App Clip – Ticket Selection") {
    struct TicketPreviewHost: View {
        @State private var selected: AppClipTicketOption? = nil
        var body: some View {
            AppClipTicketSelectionView(selectedTicket: $selected) { _ in }
                .environment(\.colorScheme, .dark)
                .background(Color.theme.background)
        }
    }
    return TicketPreviewHost()
}

#endif
