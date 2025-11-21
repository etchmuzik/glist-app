import XCTest
@testable import Glist

final class QRCodeTests: XCTestCase {

    func testQRCodeGeneration() {
        let testString = "TestQR-123"
        let image = QRCodeGenerator.generate(from: testString)
        
        XCTAssertNotNil(image, "QR Code generation should return an image")
    }
    
    func testQRCodeGenerationEmptyString() {
        let testString = ""
        let image = QRCodeGenerator.generate(from: testString)
        
        XCTAssertNotNil(image, "QR Code generation should work even for empty string (though not useful)")
    }
}
