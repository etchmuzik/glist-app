import Foundation
import Combine
import Supabase

/// Manager for handling BNPL payments and dynamic F1 pricing.
@MainActor
public class PaymentsManager: ObservableObject {
    /// Shared singleton instance.
    public static let shared = PaymentsManager()
    private let client = SupabaseManager.shared.client
    private let dubaiTimeZone = TimeZone(identifier: "Asia/Dubai")!

    private init() {}

    /// BNPL providers supported.
    public enum BNPLProvider: String, Codable, CaseIterable, Sendable {
        case tabby
        case tamara
    }

    /// Request to initiate a deposit via BNPL.
    public struct DepositRequest: Sendable {
        public let amountAED: Decimal
        public let userId: String
        public let venueId: String
        public let tableId: String?
        public let provider: BNPLProvider

        public init(amountAED: Decimal, userId: String, venueId: String, tableId: String?, provider: BNPLProvider) {
            self.amountAED = amountAED
            self.userId = userId
            self.venueId = venueId
            self.tableId = tableId
            self.provider = provider
        }
    }

    /// Deposit model stored in Supabase.
    public struct Deposit: Identifiable, Codable, Sendable {
        public var id: String?
        public let userId: String
        public let venueId: String
        public let amountAED: Decimal
        public let provider: BNPLProvider
        public let createdAt: Date

        enum CodingKeys: String, CodingKey {
            case id
            case userId
            case venueId
            case amountAED
            case provider
            case createdAt
        }

        public init(id: String? = nil, userId: String, venueId: String, amountAED: Decimal, provider: BNPLProvider, createdAt: Date) {
            self.id = id
            self.userId = userId
            self.venueId = venueId
            self.amountAED = amountAED
            self.provider = provider
            self.createdAt = createdAt
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decodeIfPresent(String.self, forKey: .id)
            userId = try container.decode(String.self, forKey: .userId)
            venueId = try container.decode(String.self, forKey: .venueId)
            let amountDouble = try container.decode(Double.self, forKey: .amountAED)
            amountAED = Decimal(amountDouble)
            provider = try container.decode(BNPLProvider.self, forKey: .provider)
            createdAt = try container.decode(Date.self, forKey: .createdAt)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encodeIfPresent(id, forKey: .id)
            try container.encode(userId, forKey: .userId)
            try container.encode(venueId, forKey: .venueId)
            try container.encode((amountAED as NSDecimalNumber).doubleValue, forKey: .amountAED)
            try container.encode(provider, forKey: .provider)
            try container.encode(createdAt, forKey: .createdAt)
        }
    }

    /// Initiates a BNPL deposit flow via Supabase Edge Functions.
    public func initiateBNPLDeposit(request: DepositRequest) async throws -> (Deposit, URL?) {
        let body: [String: GlistAnyEncodable] = [
            "venueId": GlistAnyEncodable(request.venueId),
            "amount": GlistAnyEncodable((request.amountAED as NSDecimalNumber).doubleValue),
            "provider": GlistAnyEncodable(request.provider.rawValue)
        ]
        
        // Call Supabase Edge Function 'create-bnpl-session'
        // Assuming response is JSON with transactionId and redirectUrl
        
        let result: BNPLResponse = try await client.functions.invoke("create-bnpl-session", options: .init(body: body))
        
        let deposit = Deposit(
            id: result.transactionId,
            userId: request.userId,
            venueId: request.venueId,
            amountAED: request.amountAED,
            provider: request.provider,
            createdAt: Date()
        )
        
        let redirectUrl = result.redirectUrl != nil ? URL(string: result.redirectUrl!) : nil
        
        return (deposit, redirectUrl)
    }

    private struct BNPLResponse: Decodable, Sendable {
        let transactionId: String
        let redirectUrl: String?
    }

    /// Records a deposit document into Supabase "deposits" table.
    public func recordDeposit(_ deposit: Deposit) async throws {
        try await client.database.from("deposits").insert(deposit).execute()
    }

    /// Checks if the given date falls within the F1 weekend (Nov 29 - Dec 1, 2025) in Dubai timezone.
    public func isF1Weekend(date: Date) -> Bool {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents(in: dubaiTimeZone, from: date)
        guard let localDate = calendar.date(from: components) else { return false }

        let startComponents = DateComponents(calendar: calendar, timeZone: dubaiTimeZone, year: 2025, month: 11, day: 29, hour: 0, minute: 0, second: 0)
        let endComponents = DateComponents(calendar: calendar, timeZone: dubaiTimeZone, year: 2025, month: 12, day: 1, hour: 23, minute: 59, second: 59)

        guard let startDate = startComponents.date, let endDate = endComponents.date else { return false }

        return (localDate >= startDate && localDate <= endDate)
    }

    /// Calculates a demand multiplier for pricing during the F1 weekend (2x to 3x).
    public func calculateF1DemandMultiplier(for date: Date, base: Double) async -> Double {
        if isF1Weekend(date: date) {
            // Could be dynamic based on demand, here a fixed range 2.0 - 3.0
            // Simulate async delay
            try? await Task.sleep(nanoseconds: 200_000_000)
            return Double.random(in: 2.0...3.0)
        } else {
            return 1.0
        }
    }

    /// Returns adjusted price for F1 weekend applying demand multiplier, using the booking date (not current date).
    public func adjustedPriceForF1(basePrice: Double, date: Date) async -> Double {
        guard isF1Weekend(date: date) else { return basePrice }
        let multiplier = await calculateF1DemandMultiplier(for: date, base: basePrice)
        return basePrice * multiplier
    }
}



