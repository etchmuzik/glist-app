import SwiftUI

struct RulesSectionWelcomeView: View {
    var body: some View {
        VStack {
            Text("Welcome to the app!")
                .font(Theme.Fonts.display(size: 20))
                .foregroundColor(Color.theme.textPrimary)
            Text("Enjoy your stay")
                .font(Theme.Fonts.body(size: 14))
                .foregroundColor(Color.theme.textSecondary)
        }
    }
}
