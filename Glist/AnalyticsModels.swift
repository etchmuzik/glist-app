import Foundation

struct ConversionStats: Codable, Equatable, Sendable {
    let venueId: String
    let venueName: String
    let dateRangeLabel: String
    let sessions: Int
    let selections: Int
    let holds: Int
    let confirmed: Int
    let cancellations: Int
    let noShows: Int
    
    var selectionRate: Double {
        guard sessions > 0 else { return 0 }
        return Double(selections) / Double(sessions)
    }
    
    var holdToConfirmRate: Double {
        guard holds > 0 else { return 0 }
        return Double(confirmed) / Double(holds)
    }
    
    var cancelRate: Double {
        guard confirmed > 0 else { return 0 }
        return Double(cancellations) / Double(confirmed)
    }
    
    var noShowRate: Double {
        guard confirmed > 0 else { return 0 }
        return Double(noShows) / Double(confirmed)
    }
}

struct OccupancySnapshot: Codable, Equatable, Sendable {
    let venueId: String
    let venueName: String
    let date: Date
    let timeBandLabel: String
    let capacity: Int
    let booked: Int
    let waitlisted: Int
    let holdPending: Int
    
    var utilization: Double {
        guard capacity > 0 else { return 0 }
        return Double(booked) / Double(capacity)
    }
}

struct CancellationStats: Codable, Equatable, Sendable {
    let venueId: String
    let venueName: String
    let periodLabel: String
    let cancellations: Int
    let lateCancellations: Int
    let noShows: Int
    let feesRecovered: Double
}

struct PromoterPerformanceRow: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let promoterName: String
    let venueName: String?
    let covers: Int
    let revenue: Double
    let payoutAccrued: Double
    let payoutPaid: Double
}

struct CampaignPerformanceRow: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let campaign: String
    let source: String?
    let medium: String?
    let covers: Int
    let revenue: Double
    let discounts: Double
    let payout: Double
}

struct Invoice: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let bookingId: String
    let venueName: String
    let venueLegalEntity: String
    let customerName: String
    let customerEmail: String
    let invoiceDate: Date
    let currency: String
    let netAmount: Double
    let vatRate: Double
    let vatAmount: Double
    let totalAmount: Double
}

struct FinanceReportRow: Codable, Equatable, Sendable {
    let invoiceNumber: String
    let invoiceDate: Date
    let customerName: String
    let customerEmail: String
    let venueLegalEntity: String
    let netAmount: Double
    let vatRate: Double
    let vatAmount: Double
    let total: Double
    let currency: String
    let bookingId: String
    let promoterCode: String?
    let campaign: String?
    let paymentMethod: String?
}

enum SafetyEventType: String, Codable, Sendable {
    case noShowIncrement = "no_show_increment"
    case kycStatusChange = "kyc_status_change"
    case promoterReputationChange = "promoter_reputation_change"
    case resaleOfferCreated = "resale_offer_created"
    case ticketResold = "ticket_resold"
}

struct SafetyEvent: Identifiable, Codable, Sendable {
    let id: String
    let type: SafetyEventType
    let userId: String?
    let promoterId: String?
    let venueId: String?
    let previousValue: String?
    let newValue: String?
    let metadata: [String: String]
    let createdAt: Date
    
    init(
        id: String = UUID().uuidString,
        type: SafetyEventType,
        userId: String? = nil,
        promoterId: String? = nil,
        venueId: String? = nil,
        previousValue: String? = nil,
        newValue: String? = nil,
        metadata: [String: String] = [:],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.userId = userId
        self.promoterId = promoterId
        self.venueId = venueId
        self.previousValue = previousValue
        self.newValue = newValue
        self.metadata = metadata
        self.createdAt = createdAt
    }
}
