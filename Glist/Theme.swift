import SwiftUI

struct Theme {
    static let background = Color.black
    static let surface = Color(white: 0.1)
    static let textPrimary = Color.white
    static let textSecondary = Color.gray
    static let accent = Color.white // Minimalist accent
    
    struct Fonts {
        static func display(size: CGFloat) -> Font {
            .system(size: size, weight: .bold, design: .default)
        }
        
        static func body(size: CGFloat) -> Font {
            .system(size: size, weight: .regular, design: .default)
        }
    }
}

extension Color {
    static let theme = Theme.self
}
