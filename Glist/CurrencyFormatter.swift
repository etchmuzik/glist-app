import Foundation

enum CurrencyFormatter {
    private static func formatter(for locale: Locale) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        formatter.currencyCode = "AED"
        return formatter
    }
    
    static func aed(_ amount: Double, locale: Locale = Locale(identifier: "en_AE")) -> String {
        let formatter = formatter(for: locale)
        return formatter.string(from: NSNumber(value: amount)) ?? "AED \(amount)"
    }
}
