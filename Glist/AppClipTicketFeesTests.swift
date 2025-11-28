#if canImport(Testing)
import Testing

@Suite("App Clip Ticket Fees")
struct AppClipTicketFeesTests {
    // Replicate the fee policy used in AppClipTicketSelectionView
    let serviceFeeRate: Double = 0.05
    let processingFee: Double = 3.0

    func total(pricePerTicket: Double, quantity: Int) -> Double {
        let subtotal = pricePerTicket * Double(quantity)
        let service = subtotal * serviceFeeRate
        return subtotal + service + processingFee
    }

    @Test("Single GA Ticket totals correctly")
    func testSingleGATicket() async throws {
        let result = total(pricePerTicket: 200, quantity: 1)
        // 200 + 10 + 3 = 213
        #expect(result == 213)
    }

    @Test("Three VIP Tickets totals correctly")
    func testThreeVIPTickets() async throws {
        let result = total(pricePerTicket: 450, quantity: 3)
        // subtotal = 1350; service = 67.5; total = 1420.5
        #expect(result == 1420.5)
    }

    @Test("Zero quantity edge case applies processing fee")
    func testZeroQuantityEdgeCase() async throws {
        let result = total(pricePerTicket: 350, quantity: 0)
        // 0 + 0 + 3 = 3 (processing still applies)
        #expect(result == 3)
    }
}

#elseif canImport(XCTest)
import XCTest

final class AppClipTicketFeesTests: XCTestCase {
    let serviceFeeRate: Double = 0.05
    let processingFee: Double = 3.0

    func total(pricePerTicket: Double, quantity: Int) -> Double {
        let subtotal = pricePerTicket * Double(quantity)
        let service = subtotal * serviceFeeRate
        return subtotal + service + processingFee
    }

    func testSingleGATicket() {
        let result = total(pricePerTicket: 200, quantity: 1)
        XCTAssertEqual(result, 213)
    }

    func testThreeVIPTickets() {
        let result = total(pricePerTicket: 450, quantity: 3)
        XCTAssertEqual(result, 1420.5)
    }

    func testZeroQuantityEdgeCase() {
        let result = total(pricePerTicket: 350, quantity: 0)
        XCTAssertEqual(result, 3)
    }
}
#else
// XCTest/Testing not available in this target; no-op placeholder.
#endif
