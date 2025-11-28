import SwiftUI

struct PolicyDisclosureRow: View {
    let rules: BookingRules
    let contextText: String

    @State private var showDetails = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(contextText)
                .font(Theme.Fonts.caption())
                .foregroundColor(Theme.textSecondary)

            Button("Learn More") {
                showDetails.toggle()
            }
            .font(Theme.Fonts.bodyBold(size: 12))
            .sheet(isPresented: $showDetails) {
                NavigationStack {
                    ScrollView {
                        RulesSectionView(rules: rules)
                    }
                    .navigationTitle("Policies")
                    .toolbar {
                        Button("Close") {
                            showDetails = false
                        }
                    }
                }
            }
        }
    }
}
