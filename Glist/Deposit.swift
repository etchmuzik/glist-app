import Foundation

/// A model representing a deposit made by a user at a venue.
public struct Deposit: Identifiable, Codable {
    /// The unique identifier for the deposit document.
    public var id: String?
    
    /// The identifier of the user who made the deposit.
    public let userId: String
    
    /// The identifier of the venue where the deposit was made.
    public let venueId: String
    
    /// The amount deposited in AED currency.
    public let amountAED: Decimal
    
    /// The provider handling the deposit.
    public let provider: String
    
    /// The date and time when the deposit was created.
    public let createdAt: Date
    
    /// Coding keys to map the properties to Firestore document fields.
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case venueId
        case amountAED
        case provider
        case createdAt
    }
    
    /// Custom decoder to convert amountAED from Double to Decimal.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        venueId = try container.decode(String.self, forKey: .venueId)
        let amountDouble = try container.decode(Double.self, forKey: .amountAED)
        amountAED = Decimal(amountDouble)
        provider = try container.decode(String.self, forKey: .provider)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
    
    /// Custom encoder to convert amountAED from Decimal to Double.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(venueId, forKey: .venueId)
        try container.encode((amountAED as NSDecimalNumber).doubleValue, forKey: .amountAED)
        try container.encode(provider, forKey: .provider)
        try container.encode(createdAt, forKey: .createdAt)
    }
    
    /// Creates a new Deposit instance.
    /// - Parameters:
    ///   - id: The optional identifier for the deposit document.
    ///   - userId: The identifier of the user who made the deposit.
    ///   - venueId: The identifier of the venue where the deposit was made.
    ///   - amountAED: The amount deposited in AED currency.
    ///   - provider: The provider handling the deposit.
    ///   - createdAt: The date and time when the deposit was created.
    public init(
        id: String? = nil,
        userId: String,
        venueId: String,
        amountAED: Decimal,
        provider: String,
        createdAt: Date
    ) {
        self.id = id
        self.userId = userId
        self.venueId = venueId
        self.amountAED = amountAED
        self.provider = provider
        self.createdAt = createdAt
    }
}
