import Foundation

enum ScanResultStatus: String, Codable {
    case success
    case duplicate
    case invalid
    case offlineQueued
}

struct ScanEvent: Identifiable, Codable {
    let id: UUID
    let code: String
    let venueId: String
    let entranceId: String
    let deviceId: String
    let scannedAt: Date
    let result: ScanResultStatus
    let guestName: String?
    let partySize: Int?
    
    init(
        id: UUID = UUID(),
        code: String,
        venueId: String,
        entranceId: String,
        deviceId: String,
        scannedAt: Date = Date(),
        result: ScanResultStatus,
        guestName: String? = nil,
        partySize: Int? = nil
    ) {
        self.id = id
        self.code = code
        self.venueId = venueId
        self.entranceId = entranceId
        self.deviceId = deviceId
        self.scannedAt = scannedAt
        self.result = result
        self.guestName = guestName
        self.partySize = partySize
    }
}

struct DeviceBinding: Codable, Equatable {
    let deviceId: String
    let staffUserId: String
    let venueId: String
    let boundAt: Date
}
