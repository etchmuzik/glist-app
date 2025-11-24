import Foundation
import UIKit
import Combine

final class StaffModeManager: ObservableObject {
    @Published private(set) var binding: DeviceBinding?
    @Published private(set) var lastScans: [ScanEvent] = []
    
    private let deviceId: String = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    private let maxHistory = 50
    
    func bindToStaff(userId: String, venueId: String) {
        binding = DeviceBinding(
            deviceId: deviceId,
            staffUserId: userId,
            venueId: venueId,
            boundAt: Date()
        )
    }
    
    func recordScan(code: String, venueId: String, entranceId: String, guestName: String?, partySize: Int?, result: ScanResultStatus) {
        let event = ScanEvent(
            code: code,
            venueId: venueId,
            entranceId: entranceId,
            deviceId: deviceId,
            scannedAt: Date(),
            result: result,
            guestName: guestName,
            partySize: partySize
        )
        
        if result == .offlineQueued {
            OfflineScanCache.shared.record(event)
        }
        
        lastScans.insert(event, at: 0)
        if lastScans.count > maxHistory {
            lastScans.removeLast(lastScans.count - maxHistory)
        }
    }
    
    func flushOffline(handler: ([ScanEvent]) async throws -> [UUID]) async {
        let pending = OfflineScanCache.shared.pending()
        guard !pending.isEmpty else { return }
        
        do {
            let processedIds = try await handler(pending)
            OfflineScanCache.shared.remove(ids: processedIds)
        } catch {
            print("Failed to flush offline scans: \(error)")
        }
    }
}
