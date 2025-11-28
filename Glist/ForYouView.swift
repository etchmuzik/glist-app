import SwiftUI

struct Recommendation: Identifiable, Hashable {
    let id: UUID
    let title: String
    let subtitle: String
    let tag: String
    let accentColor: Color
}

struct ForYouView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFilter: String = "All"
    @State private var path = NavigationPath()
    
    private let filters = ["All", "Tonight", "VIP", "Nearby"]
    
    private let recommendations: [Recommendation] = [
        Recommendation(id: UUID(), title: "Exclusive VIP Event", subtitle: "Join the elite party", tag: "VIP", accentColor: .purple),
        Recommendation(id: UUID(), title: "Concert Tonight", subtitle: "Live music downtown", tag: "Tonight", accentColor: .red),
        Recommendation(id: UUID(), title: "Cafe Nearby", subtitle: "Best coffee in town", tag: "Nearby", accentColor: .orange),
        Recommendation(id: UUID(), title: "VIP Lounge Access", subtitle: "Special privileges await", tag: "VIP", accentColor: .blue),
        Recommendation(id: UUID(), title: "Tonight’s Movie Night", subtitle: "Outdoor screening", tag: "Tonight", accentColor: .pink),
        Recommendation(id: UUID(), title: "New Restaurant Nearby", subtitle: "Try their signature dish", tag: "Nearby", accentColor: .green)
    ]
    
    private var filteredRecommendations: [Recommendation] {
        if selectedFilter == "All" {
            return recommendations
        } else {
            return recommendations.filter { $0.tag == selectedFilter }
        }
    }
    
    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(filters, id: \.self) { filter in
                        Text(filter).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding([.horizontal, .top], 16)
                
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(filteredRecommendations) { rec in
                            RecommendationCard(recommendation: rec) {
                                path.append(rec)
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("For You")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .navigationDestination(for: Recommendation.self) { rec in
                RecommendationDetailView(recommendation: rec)
            }
        }
    }
}

private struct RecommendationCard: View {
    let recommendation: Recommendation
    let onViewTap: () -> Void
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [recommendation.accentColor.opacity(0.8), recommendation.accentColor.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: recommendation.accentColor.opacity(0.3), radius: 6, x: 0, y: 4)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(recommendation.title)
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Text(recommendation.tag)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.25))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                
                Text(recommendation.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.85))
                
                HStack {
                    Button {
                        onViewTap()
                    } label: {
                        Text("View")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.white)
                            .foregroundColor(recommendation.accentColor)
                            .cornerRadius(12)
                    }
                    
                    Button {
                        // Save action placeholder
                    } label: {
                        Text("Save")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.3))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity)
        .fixedSize(horizontal: false, vertical: true)
    }
}

struct RecommendationDetailView: View {
    let recommendation: Recommendation
    
    var body: some View {
        VStack(spacing: 20) {
            Text(recommendation.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
            
            Text(recommendation.subtitle)
                .font(.title3)
                .foregroundColor(.secondary)
                .padding([.horizontal])
            
            Spacer()
        }
        .navigationTitle(recommendation.tag)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ForYouView()
}
