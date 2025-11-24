import SwiftUI

/// Mini version of the app for App Clips - provides instant booking
struct AppClipContentView: View {
    @State private var selectedVenue: Venue?
    @State private var selectedTable: (id: UUID, name: String, minSpend: Double)?
    @State private var bookingDate: Date = Date()
    @State private var guestCount = 4
    @State private var showApplePay = false

    private let clipContext = AppClipContext.shared

    var body: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(Color.theme.accent)
                        .font(.system(size: 24))
                    Text("LSTD")
                        .font(Theme.Fonts.display(size: 28))
                        .foregroundStyle(.white)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                ScrollView {
                    VStack(spacing: 24) {

                        // Quick Venue Selection
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Book Your Table")
                                .font(Theme.Fonts.display(size: 24))
                                .foregroundStyle(.white)

                            VenueSelectionCard(
                                venue: clipContext.detectedVenue,
                                onVenueSelect: { venue in
                                    selectedVenue = venue
                                }
                            )
                        }
                        .padding(.horizontal, 24)

                        if let venue = selectedVenue ?? clipContext.detectedVenue {

                            // Table Selection
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Choose Your Table")
                                    .font(Theme.Fonts.display(size: 20))
                                    .foregroundStyle(.white)

                                TableSelectionGrid(venue: venue) { table in
                                    selectedTable = table
                                }
                            }
                            .padding(.horizontal, 24)

                            if let table = selectedTable {

                                // Booking Details
                                BookingDetailsCard(
                                    venue: venue,
                                    table: table,
                                    date: $bookingDate,
                                    guestCount: $guestCount
                                )
                                .padding(.horizontal, 24)

                                // Apple Pay Button
                                VStack(spacing: 16) {
                                    totalPriceCard(venue: venue, table: table)

                                    ApplePayButtonView {
                                        showApplePay = true
                                    }
                                    .frame(height: 50)
                                    .clipShape(Capsule())
                                    .padding(.horizontal, 24)

                                    Text("Lightning-fast booking • Secure payment")
                                        .font(Theme.Fonts.body(size: 12))
                                        .foregroundStyle(.gray)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 24)
                }
            }
        }
        .sheet(isPresented: $showApplePay) {
            if let venue = selectedVenue ?? clipContext.detectedVenue,
               let table = selectedTable {
                ApplePayCheckoutView(
                    venueName: venue.name,
                    amount: table.minSpend,
                    description: "Table \(table.name) reservation",
                    onSuccess: {
                        showApplePay = false
                        // Show success and prompt to download full app
                        handleBookingSuccess()
                    },
                    onCancel: {
                        showApplePay = false
                    }
                )
            }
        }
        .onAppear {
            // Auto-populate if we have venue context from App Clip invocation
            if let venue = clipContext.detectedVenue {
                selectedVenue = venue
            }
        }
    }

    private func totalPriceCard(venue: Venue, table: (id: UUID, name: String, minSpend: Double)) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Payment Summary")
                .font(Theme.Fonts.body(size: 14, weight: .semibold))
                .foregroundStyle(.white)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Table \(table.name)")
                        .foregroundStyle(.gray)
                    Text("Minimum spend deposit")
                        .font(Theme.Fonts.body(size: 12))
                        .foregroundStyle(.gray.opacity(0.7))
                }
                Spacer()
                Text(CurrencyFormatter.aed(table.minSpend))
                    .font(Theme.Fonts.display(size: 20))
                    .foregroundStyle(Color.theme.accent)
            }
        }
        .padding(16)
        .background(Color.theme.surface.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 24)
    }

    private func handleBookingSuccess() {
        // Show full app download prompt
        // This would typically navigate to App Store or show banner
        print("Booking successful! Prompt user to download full LSTD app.")
    }
}

// MARK: - Supporting Views

struct VenueSelectionCard: View {
    let venue: Venue?
    let onVenueSelect: (Venue) -> Void

    var body: some View {
        if let venue = venue {
            VStack(alignment: .leading, spacing: 12) {
                Text("Detected Venue")
                    .font(Theme.Fonts.body(size: 12, weight: .semibold))
                    .foregroundStyle(Color.theme.accent)

                HStack(spacing: 16) {
                    Rectangle()
                        .fill(Color.theme.surface)
                        .frame(width: 60, height: 60)
                        .overlay {
                            Image(systemName: "building.2")
                                .foregroundStyle(.gray)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(venue.name.uppercased())
                            .font(Theme.Fonts.display(size: 18))
                            .foregroundStyle(.white)

                        Text(venue.type.uppercased())
                            .font(Theme.Fonts.body(size: 12))
                            .foregroundStyle(Color.theme.accent)

                        HStack(spacing: 8) {
                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.yellow)
                                    .font(.system(size: 10))
                                Text(String(format: "%.1f", venue.rating))
                                    .font(Theme.Fonts.body(size: 12))
                                    .foregroundStyle(.gray)
                            }

                            Text(venue.price)
                                .font(Theme.Fonts.body(size: 12))
                                .foregroundStyle(.gray)
                        }
                    }
                }
            }
            .padding(16)
            .background(Color.theme.surface.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.theme.accent.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

struct TableSelectionGrid: View {
    let venue: Venue
    let onTableSelect: ((id: UUID, name: String, minSpend: Double)) -> Void

    // Mock table data - in real app this would come from venue data
    private var mockTables: [(UUID, String, Double)] {
        let basePrice = venuePriceToMultiplier(venue.price)
        return [
            (UUID(), "Table 1", basePrice),
            (UUID(), "VIP Booth", basePrice * 2.5),
            (UUID(), "Roof Terrace", basePrice * 3),
            (UUID(), "Skybox", basePrice * 5)
        ]
    }

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(mockTables, id: \.0) { tableInfo in
                TableCard(
                    name: tableInfo.1,
                    minSpend: tableInfo.2
                ) {
                    onTableSelect((tableInfo.0, tableInfo.1, tableInfo.2))
                }
            }
        }
    }

    private func venuePriceToMultiplier(_ priceRange: String) -> Double {
        switch priceRange {
        case "$$$": return 750
        case "$$": return 500
        default: return 1000
        }
    }
}

struct TableCard: View {
    let name: String
    let minSpend: Double
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "table.furniture")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.theme.accent)

                Text(name)
                    .font(Theme.Fonts.body(size: 14, weight: .semibold))
                    .foregroundStyle(.white)

                Text("From \(CurrencyFormatter.aed(minSpend, currency: "AED"))")
                    .font(Theme.Fonts.body(size: 12))
                    .foregroundStyle(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color.theme.surface.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

struct BookingDetailsCard: View {
    let venue: Venue
    let table: (id: UUID, name: String, minSpend: Double)
    @Binding var date: Date
    @Binding var guestCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Booking Details")
                .font(Theme.Fonts.display(size: 20))
                .foregroundStyle(.white)

            HStack(spacing: 16) {
                DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.compact)
                    .colorScheme(.dark)

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    HStack {
                        Button {
                            if guestCount > 1 { guestCount -= 1 }
                        } label: {
                            Image(systemName: "minus")
                                .foregroundStyle(.white)
                                .padding(8)
                                .background(Color.theme.surface)
                                .clipShape(Circle())
                        }

                        Text("\(guestCount)")
                            .font(Theme.Fonts.body(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 40)

                        Button {
                            if guestCount < 10 { guestCount += 1 }
                        } label: {
                            Image(systemName: "plus")
                                .foregroundStyle(.white)
                                .padding(8)
                                .background(Color.theme.surface)
                                .clipShape(Circle())
                        }
                    }

                    Text("Guests")
                        .font(Theme.Fonts.body(size: 12))
                        .foregroundStyle(.gray)
                }
            }
        }
        .padding(20)
        .background(Color.theme.surface.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - App Clip Context

class AppClipContext {
    static let shared = AppClipContext()

    // Detected context from App Clip invocation
    var detectedVenue: Venue?

    // Parse context from URL or QR code when App Clip is invoked
    func parseInvocationContext(url: URL) {
        // In real implementation, this would parse venue data from URL parameters
        // For demo, we'll set a mock venue
        detectedVenue = Venue(
            id: UUID(uuidString: "12345678-1234-1234-1234-123456789ABC")!,
            name: "UPSTAIRS Marina",
            type: "Nightclub",
            price: "$$$",
            rating: 4.8,
            reviewCount: 1250,
            image: "",
            distance: nil,
            location: "",
            isPopular: true,
            isVerified: true
        )
    }
}
