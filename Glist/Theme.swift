import SwiftUI

struct Theme {
    static let background = Color.black
    static let surface = Color(white: 0.1)
    static let textPrimary = Color.white
    static let textSecondary = Color.gray
    static let accent = Color.white // Minimalist accent
    
    struct Fonts {
        static func display(size: CGFloat) -> Font {
            if Locale.current.language.languageCode?.identifier == "ar" {
                return .system(size: size, weight: .bold, design: .rounded)
            }
            return .system(size: size, weight: .bold, design: .default)
        }
        
        static func body(size: CGFloat, weight: Font.Weight = .regular) -> Font {
            if Locale.current.language.languageCode?.identifier == "ar" {
                return .system(size: size, weight: weight, design: .rounded)
            }
            return .system(size: size, weight: weight, design: .default)
        }
        
        static func bodyBold(size: CGFloat = 14) -> Font {
            if Locale.current.language.languageCode?.identifier == "ar" {
                return .system(size: size, weight: .bold, design: .rounded)
            }
            return .system(size: size, weight: .bold, design: .default)
        }
        
        static func caption(size: CGFloat = 12) -> Font {
            if Locale.current.language.languageCode?.identifier == "ar" {
                return .system(size: size, weight: .regular, design: .rounded)
            }
            return .system(size: size, weight: .regular, design: .default)
        }
    }
}

extension Color {
    static let theme = Theme.self
}
