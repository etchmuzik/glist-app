import SwiftUI

public struct GenericRecommendationDetailView<Item>: View where Item: RecommendationProtocol {
    public let recommendation: Item
    @Environment(\.dismiss) private var dismiss

    public init(recommendation: Item) {
        self.recommendation = recommendation
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(recommendation.title)
                    .font(.largeTitle)
                    .bold()
                    .padding(.top)

                Text(recommendation.tag)
                    .font(.caption)
                    .bold()
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.secondary.opacity(0.2)))
                    .foregroundColor(.secondary)

                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [recommendation.accentColor.opacity(0.7), recommendation.accentColor]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 200)
                    .cornerRadius(12)
                }

                Text(recommendation.subtitle)
                    .font(.body)
                    .foregroundColor(.primary)

                HStack(spacing: 20) {
                    Button("RSVP") {
                        // Action
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Get Directions") {
                        // Action
                    }
                    .buttonStyle(.bordered)

                    Button("Share") {
                        // Action
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.vertical)
            }
            .padding(.horizontal)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Close") {
                    dismiss()
                }
            }
        }
    }
}

public protocol RecommendationProtocol {
    var title: String { get }
    var subtitle: String { get }
    var tag: String { get }
    var accentColor: Color { get }
}

#if DEBUG
struct GenericRecommendationDetailView_Previews: PreviewProvider {

    struct PreviewRecommendation: RecommendationProtocol {
        let title: String
        let subtitle: String
        let tag: String
        let accentColor: Color
    }

    static var sample = PreviewRecommendation(
        title: "Cozy Italian Dinner",
        subtitle: "Experience authentic Italian dishes with a cozy ambiance right in the heart of the city.",
        tag: "Food & Drink",
        accentColor: .red
    )

    static var previews: some View {
        NavigationView {
            GenericRecommendationDetailView(recommendation: sample)
        }
    }
}
#endif

