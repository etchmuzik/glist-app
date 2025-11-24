import XCTest
@testable import Glist

final class OfflineScanCacheTests: XCTestCase {
    func testRecordAndPersist() {
        let cache = OfflineScanCache.shared
        cache.clearAll()
        
        let event = ScanEvent(
            code: "TEST-QR",
            venueId: "venue-1",
            entranceId: "entrance-a",
            deviceId: "device-x",
            result: .offlineQueued
        )
        cache.record(event)
        
        let pending = cache.pending()
        XCTAssertEqual(pending.count, 1)
        XCTAssertEqual(pending.first?.code, "TEST-QR")
    }
    
    func testRemoveProcessed() {
        let cache = OfflineScanCache.shared
        cache.clearAll()
        
        let event1 = ScanEvent(code: "1", venueId: "v", entranceId: "e", deviceId: "d", result: .offlineQueued)
        let event2 = ScanEvent(code: "2", venueId: "v", entranceId: "e", deviceId: "d", result: .offlineQueued)
        cache.record(event1)
        cache.record(event2)
        
        cache.remove(ids: [event1.id])
        let remaining = cache.pending()
        XCTAssertEqual(remaining.count, 1)
        XCTAssertEqual(remaining.first?.code, "2")
    }
}
