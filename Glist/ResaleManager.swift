import Combine
import Foundation

@MainActor
final class ResaleManager: ObservableObject {
    static let shared = ResaleManager()

    let priceCapMultiplier: Double = 1.12
    var defaultPricingRules: [PricingRule] = []

    private init() {}

    func priceCap(for ticket: EventTicket, pricingRules: [PricingRule]) -> Double {
        let context = PricingContext(
            date: ticket.eventDate,
            capacity: 400,
            bookedCount: 320,
            basePrice: ticket.price
        )

        let range = DynamicPricingEngine.priceRange(for: context, rules: pricingRules)
        return min(range.upperBound, ticket.price * priceCapMultiplier)
    }

    func validatePrice(_ price: Double, for ticket: EventTicket, pricingRules: [PricingRule]) throws {
        let cap = priceCap(for: ticket, pricingRules: pricingRules)
        guard price <= cap else {
            throw ResaleError.priceAboveCap(current: price, cap: cap)
        }
    }

    func buyerEligibilityMessage() -> String {
        "KYC approved · No bans in last 30 days"
    }

    func createOffer(for ticket: EventTicket, price: Double, pricingRules: [PricingRule]) throws -> ResaleOffer {
        try validatePrice(price, for: ticket, pricingRules: pricingRules)

        return ResaleOffer(
            ticketId: ticket.id,
            sellerId: ticket.userId,
            eventId: ticket.eventId,
            price: price,
            status: .pending,
            createdAt: Date()
        )
    }

    func publishOffer(for ticket: EventTicket, price: Double, pricingRules: [PricingRule]) async throws {
        let offer = try createOffer(for: ticket, price: price, pricingRules: pricingRules)
        try await SupabaseDataManager.shared.publishResaleOffer(ticket: ticket, offer: offer)
    }
}

struct ResaleOffer: Identifiable, Codable, Sendable {
    enum Status: String, Codable, Sendable {
        case active
        case pending
        case matched
        case completed
        case cancelled
    }

    let id: String
    let ticketId: UUID
    let sellerId: String
    let eventId: UUID
    let price: Double
    let status: Status
    let createdAt: Date

    init(
        id: String = UUID().uuidString,
        ticketId: UUID,
        sellerId: String,
        eventId: UUID,
        price: Double,
        status: Status,
        createdAt: Date
    ) {
        self.id = id
        self.ticketId = ticketId
        self.sellerId = sellerId
        self.eventId = eventId
        self.price = price
        self.status = status
        self.createdAt = createdAt
    }
}

enum ResaleError: Error, LocalizedError {
    case priceAboveCap(current: Double, cap: Double)

    var errorDescription: String? {
        switch self {
        case .priceAboveCap(let current, let cap):
            return "Price \(CurrencyFormatter.aed(current)) exceeds the ethical cap of \(CurrencyFormatter.aed(cap))."
        }
    }
}
