import SwiftUI
import Combine

enum AppLanguage: String, CaseIterable {
    case english = "en"
    case arabic = "ar"
    
    var locale: Locale {
        Locale(identifier: self == .arabic ? "ar_AE" : "en_AE")
    }
    
    var isRTL: Bool {
        self == .arabic
    }
}

final class LocalizationManager: ObservableObject {
    @AppStorage("app_language") private var storedLanguage = AppLanguage.english.rawValue
    @Published private(set) var language: AppLanguage = .english
    
    init() {
        self.language = AppLanguage(rawValue: storedLanguage) ?? .english
        applySemanticDirection()
    }
    
    func setLanguage(_ language: AppLanguage) {
        storedLanguage = language.rawValue
        self.language = language
        applySemanticDirection()
    }
    
    var locale: Locale { language.locale }
    var usesRTL: Bool { language.isRTL }
    
    private func applySemanticDirection() {
        UIView.appearance().semanticContentAttribute = language.isRTL ? .forceRightToLeft : .forceLeftToRight
    }
}
