import XCTest
@testable import Glist

final class ReservationStateMachineTests: XCTestCase {
    
    func testHoldTransitionsToConfirmedOnPayment() {
        let next = ReservationStateMachine.transition(from: .holdPending, event: .paymentCaptured)
        XCTAssertEqual(next, .confirmed)
    }
    
    func testHoldExpiresToExpired() {
        let next = ReservationStateMachine.transition(from: .holdPending, event: .holdExpired)
        XCTAssertEqual(next, .expired)
    }
    
    func testWaitlistPromotionFlow() {
        let promoted = ReservationStateMachine.transition(from: .waitlisted, event: .waitlistPromoted)
        XCTAssertEqual(promoted, .autoPromoted)
        
        let confirmed = ReservationStateMachine.transition(from: promoted, event: .paymentCaptured)
        XCTAssertEqual(confirmed, .confirmed)
    }
}
