import XCTest
@testable import Glist

final class ResaleManagerTests: XCTestCase {
    private var ticket: EventTicket {
        EventTicket(
            id: UUID(),
            eventId: UUID(),
            eventName: "Skyline Sessions",
            eventDate: Date().addingTimeInterval(10_000),
            venueId: UUID(),
            venueName: "Skyline Lounge",
            userId: "user_test",
            ticketTypeId: UUID(),
            ticketTypeName: "VIP",
            price: 950,
            status: .valid,
            qrCodeId: "qr_test",
            purchaseDate: Date()
        )
    }

    func testPriceCapHonorsMultiplierAndPricingRules() {
        let baseTicket = ticket
        let cap = ResaleManager.shared.priceCap(for: baseTicket, pricingRules: [])
        XCTAssertLessThanOrEqual(cap, baseTicket.price * ResaleManager.shared.priceCapMultiplier, "Cap should never exceed multiplier of base price.")
    }

    func testValidatePriceThrowsWhenAboveCap() {
        let baseTicket = ticket
        let cap = ResaleManager.shared.priceCap(for: baseTicket, pricingRules: [])
        XCTAssertThrowsError(try ResaleManager.shared.validatePrice(cap + 20, for: baseTicket, pricingRules: [])) { error in
            XCTAssertTrue(error is ResaleError)
        }
    }

    func testValidatePriceAcceptsEqualOrLowerCap() {
        let baseTicket = ticket
        let cap = ResaleManager.shared.priceCap(for: baseTicket, pricingRules: [])
        XCTAssertNoThrow(try ResaleManager.shared.validatePrice(cap, for: baseTicket, pricingRules: []))
        XCTAssertNoThrow(try ResaleManager.shared.validatePrice(cap - 10, for: baseTicket, pricingRules: []))
    }
}
