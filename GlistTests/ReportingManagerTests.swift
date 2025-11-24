import XCTest
@testable import Glist

final class ReportingManagerTests: XCTestCase {
    func testCSVIncludesHeaderAndEscapedValues() {
        let formatter = ReportingManager.defaultDateFormatter()
        let date = formatter.date(from: "2024-05-01")!
        let rows = [
            FinanceReportRow(
                invoiceNumber: "INV-001",
                invoiceDate: date,
                customerName: "Alice, Example",
                customerEmail: "alice@example.com",
                venueLegalEntity: "Glist LLC",
                netAmount: 100.0,
                vatRate: 0.05,
                vatAmount: 5.0,
                total: 105.0,
                currency: "AED",
                bookingId: "BKG-1",
                promoterCode: "PROMO1",
                campaign: "NYE",
                paymentMethod: "Card"
            )
        ]
        
        let csv = ReportingManager.csv(from: rows, dateFormatter: formatter)
        XCTAssertTrue(csv.contains("InvoiceNumber,InvoiceDate,CustomerName"), "CSV should contain header")
        XCTAssertTrue(csv.contains("\"Alice, Example\""), "CSV should escape commas with quotes")
        XCTAssertTrue(csv.contains("INV-001"), "CSV should include invoice number")
    }
}
