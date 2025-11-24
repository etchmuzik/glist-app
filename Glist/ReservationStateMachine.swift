import Foundation

enum ReservationEvent {
    case paymentCaptured
    case holdExpired
    case userCancelled
    case hostCancelled
    case waitlistPromoted
    case waitlistConfirmed
}

struct BookingHold {
    let amount: Double
    let createdAt: Date
    let expiresAt: Date
    let requiresCapture: Bool
    
    var isExpired: Bool {
        Date() >= expiresAt
    }
}

struct CancellationPolicy {
    /// Hours before the reservation that the guest can cancel without fees.
    let freeCancellationWindowHours: Int
    /// Fee charged when cancelling after the free window. Can be zero for a pure hold release.
    let lateCancellationFee: Double
    /// Whether the guest can self-cancel in the app.
    let allowsSelfCancellation: Bool
}

enum ReservationStateMachine {
    static func transition(from state: BookingStatus, event: ReservationEvent) -> BookingStatus {
        switch (state, event) {
        case (.pending, .paymentCaptured), (.holdPending, .paymentCaptured):
            return .confirmed
        case (.waitlisted, .waitlistPromoted):
            return .autoPromoted
        case (.waitlisted, .waitlistConfirmed), (.autoPromoted, .paymentCaptured):
            return .confirmed
        case (.pending, .userCancelled),
             (.pending, .hostCancelled),
             (.confirmed, .userCancelled),
             (.confirmed, .hostCancelled):
            return .cancelled
        case (.holdPending, .holdExpired):
            return .expired
        default:
            return state
        }
    }
    
    static func isTerminal(_ state: BookingStatus) -> Bool {
        switch state {
        case .cancelled, .expired, .paid:
            return true
        default:
            return false
        }
    }
}
