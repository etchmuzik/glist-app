import XCTest
@testable import Glist

final class DynamicPricingEngineTests: XCTestCase {
    
    func testAppliesHighestPriorityRule() {
        let calendar = Calendar.current
        let date = calendar.date(from: DateComponents(year: 2024, month: 12, day: 31, hour: 23))!
        let context = PricingContext(date: date, capacity: 10, bookedCount: 9, basePrice: 200)
        
        let shoulderRule = PricingRule(
            name: "Shoulder Night",
            priority: 1,
            startHour: 17,
            endHour: 22,
            multiplier: 1.2
        )
        
        let nyeRule = PricingRule(
            name: "NYE Peak",
            priority: 10,
            startDate: calendar.date(byAdding: .day, value: -1, to: date),
            endDate: calendar.date(byAdding: .day, value: 1, to: date),
            startHour: 20,
            endHour: 24,
            minUtilization: 0.7,
            multiplier: 1.5,
            floorPrice: 250,
            ceilingPrice: 400
        )
        
        let price = DynamicPricingEngine.price(for: context, rules: [shoulderRule, nyeRule])
        XCTAssertEqual(price, 300, accuracy: 0.001)
    }
    
    func testPriceRangeReflectsAllMatchingRules() {
        let date = Calendar.current.date(from: DateComponents(year: 2024, month: 6, day: 1, hour: 21))!
        let context = PricingContext(date: date, capacity: 20, bookedCount: 10, basePrice: 150)
        
        let earlyRule = PricingRule(
            name: "Early Bird",
            priority: 1,
            startHour: 18,
            endHour: 21,
            multiplier: 0.9,
            floorPrice: 120
        )
        
        let peakRule = PricingRule(
            name: "Peak",
            priority: 2,
            startHour: 20,
            endHour: 23,
            multiplier: 1.3,
            ceilingPrice: 250
        )
        
        let range = DynamicPricingEngine.priceRange(for: context, rules: [earlyRule, peakRule])
        XCTAssertEqual(range.lowerBound, 135, accuracy: 0.001)
        XCTAssertEqual(range.upperBound, 195, accuracy: 0.001)
    }
}
