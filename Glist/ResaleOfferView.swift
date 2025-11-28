import SwiftUI

struct ResaleOfferView: View {
    let ticket: EventTicket
    let pricingRules: [PricingRule]
    var onPublish: (Double) -> Void = { _ in }

    @State private var priceInput: String
    @State private var note: String = ""

    private let depositRatio: Double = 0.2

    @MainActor
    init(ticket: EventTicket, pricingRules: [PricingRule]? = nil, onPublish: @escaping (Double) -> Void = { _ in }) {
        self.ticket = ticket
        self.pricingRules = pricingRules ?? ResaleManager.shared.defaultPricingRules
        self.onPublish = onPublish
        _priceInput = State(initialValue: String(format: "%.0f", ticket.price))
    }

    private var dynamicPriceCap: Double {
        ResaleManager.shared.priceCap(for: ticket, pricingRules: pricingRules)
    }

    private var currentPrice: Double? {
        Double(priceInput.filter { "0123456789.".contains($0) })
    }

    private var depositAmount: Double {
        ticket.price * depositRatio
    }

    private var priceWarning: String? {
        guard let price = currentPrice else { return nil }
        if price > dynamicPriceCap {
            return "Ethical cap is \(CurrencyFormatter.aed(dynamicPriceCap)). Adjust to stay compliant."
        }
        return nil
    }

    private var eligibilityMessage: String {
        ResaleManager.shared.buyerEligibilityMessage()
    }

    var body: some View {
        VStack(spacing: 20) {
            header
            priceSection
            eligibilitySection
            depositSection
            publishButton
        }
        .padding(20)
        .cardStyle()
        .background(Color.theme.surface.opacity(0.6))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Offer Resale")
                .font(Theme.Fonts.display(size: 22))
                .foregroundStyle(.white)
            Text("\(ticket.eventName) · \(ticket.venueName)")
                .font(Theme.Fonts.body(size: 14))
                .foregroundStyle(.white.opacity(0.75))
        }
    }

    private var priceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Set a fair price")
                .font(Theme.Fonts.bodyBold(size: 16))
                .foregroundStyle(.white)

            TextField("AED", text: $priceInput)
                .keyboardType(.decimalPad)
                .font(Theme.Fonts.body(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.vertical, 10)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )

            Text("Cap: \(CurrencyFormatter.aed(dynamicPriceCap)) · Buyer pays deposit + your resale spread.")
                .font(Theme.Fonts.caption())
                .foregroundStyle(.gray)

            if let warning = priceWarning {
                Text(warning)
                    .font(Theme.Fonts.caption())
                    .foregroundStyle(.orange)
            }
        }
    }

    private var eligibilitySection: some View {
        HStack {
            Label("Verified resale buyer only", systemImage: "shield.checkerboard")
                .font(Theme.Fonts.body(size: 14))
                .foregroundStyle(.white)
            Spacer()
            Text(eligibilityMessage)
                .font(Theme.Fonts.caption())
                .foregroundStyle(.gray)
        }
        .padding()
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var depositSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Venue deposit")
                    .font(Theme.Fonts.caption())
                    .foregroundStyle(.gray)
                Text(CurrencyFormatter.aed(depositAmount))
                    .font(Theme.Fonts.bodyBold(size: 16))
                    .foregroundStyle(.white)
            }
            Spacer()
            Text("Retained until check-in")
                .font(Theme.Fonts.caption())
                .foregroundStyle(.gray)
        }
    }

    private var publishButton: some View {
        Button(action: publishOffer) {
            Text("Publish Resale Offer")
                .font(Theme.Fonts.body(size: 16, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding()
        }
        .buttonStyle(.borderedProminent)
        .tint(.white)
        .foregroundStyle(.black)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .disabled(currentPrice == nil || priceWarning != nil)
    }

    private func publishOffer() {
        guard let price = currentPrice, price <= dynamicPriceCap else { return }
        onPublish(price)
    }
}

struct ResaleOfferView_Previews: PreviewProvider {
    static var previews: some View {
        ResaleOfferView(ticket: EventTicket(
            id: UUID(),
            eventId: UUID(),
            eventName: "Desert Bloom",
            eventDate: Date().addingTimeInterval(5_000),
            venueId: UUID(),
            venueName: "Skyline Lounge",
            userId: "user_1234",
            ticketTypeId: UUID(),
            ticketTypeName: "VIP",
            price: 800,
            status: .valid,
            qrCodeId: "qr_001",
            purchaseDate: Date()
        ))
        .padding()
        .background(Theme.background)
        .preferredColorScheme(.dark)
    }
}

private extension View {
    func cardStyle() -> some View {
        self
            .background(Color.theme.surface.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 6)
    }
}
