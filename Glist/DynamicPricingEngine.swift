import Foundation

struct PricingContext {
    let date: Date
    let capacity: Int
    let bookedCount: Int
    let basePrice: Double
    
    var utilization: Double {
        guard capacity > 0 else { return 0 }
        return Double(bookedCount) / Double(capacity)
    }
    
    var hour: Int {
        Calendar.current.component(.hour, from: date)
    }
}

struct PricingRule: Identifiable, Codable {
    let id: UUID
    let name: String
    let priority: Int
    let startDate: Date?
    let endDate: Date?
    let daysOfWeek: Set<Int> // Sunday = 1 ... Saturday = 7
    let startHour: Int?
    let endHour: Int?
    let minUtilization: Double?
    let maxUtilization: Double?
    let multiplier: Double?
    let overridePrice: Double?
    let floorPrice: Double?
    let ceilingPrice: Double?
    
    init(
        id: UUID = UUID(),
        name: String,
        priority: Int = 0,
        startDate: Date? = nil,
        endDate: Date? = nil,
        daysOfWeek: Set<Int> = Set(1...7),
        startHour: Int? = nil,
        endHour: Int? = nil,
        minUtilization: Double? = nil,
        maxUtilization: Double? = nil,
        multiplier: Double? = nil,
        overridePrice: Double? = nil,
        floorPrice: Double? = nil,
        ceilingPrice: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.priority = priority
        self.startDate = startDate
        self.endDate = endDate
        self.daysOfWeek = daysOfWeek
        self.startHour = startHour
        self.endHour = endHour
        self.minUtilization = minUtilization
        self.maxUtilization = maxUtilization
        self.multiplier = multiplier
        self.overridePrice = overridePrice
        self.floorPrice = floorPrice
        self.ceilingPrice = ceilingPrice
    }
    
    func applies(to context: PricingContext) -> Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: context.date)
        
        if let startDate, context.date < startDate { return false }
        if let endDate, context.date > endDate { return false }
        if !daysOfWeek.contains(weekday) { return false }
        if let startHour, context.hour < startHour { return false }
        if let endHour, context.hour >= endHour { return false }
        if let minUtilization, context.utilization < minUtilization { return false }
        if let maxUtilization, context.utilization > maxUtilization { return false }
        
        return true
    }
    
    func apply(to basePrice: Double, context: PricingContext) -> Double {
        var price = overridePrice ?? basePrice * (multiplier ?? 1.0)
        
        if let floorPrice {
            price = max(price, floorPrice)
        }
        if let ceilingPrice {
            price = min(price, ceilingPrice)
        }
        
        return price
    }
}

enum DynamicPricingEngine {
    static func price(for context: PricingContext, rules: [PricingRule]) -> Double {
        let applicable = rules
            .filter { $0.applies(to: context) }
            .sorted { lhs, rhs in lhs.priority > rhs.priority }
        
        guard let rule = applicable.first else {
            return context.basePrice
        }
        
        return rule.apply(to: context.basePrice, context: context)
    }
    
    static func priceRange(for context: PricingContext, rules: [PricingRule]) -> ClosedRange<Double> {
        let matching = rules.filter { $0.applies(to: context) }
        guard !matching.isEmpty else {
            return context.basePrice...context.basePrice
        }
        
        let adjusted = matching.map { $0.apply(to: context.basePrice, context: context) }
        guard let minPrice = adjusted.min(), let maxPrice = adjusted.max() else {
            return context.basePrice...context.basePrice
        }
        
        return minPrice...maxPrice
    }
}
