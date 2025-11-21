import SwiftUI

struct SubscriptionView: View {
    @StateObject private var subscriptionManager = SubscriptionManager()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 12) {
                            Text("ELEVATE YOUR NIGHT")
                                .font(Theme.Fonts.display(size: 28))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                            
                            Text("Unlock exclusive access and VIP treatment with a LSTD membership.")
                                .font(Theme.Fonts.body(size: 16))
                                .foregroundStyle(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, 20)
                        
                        // Tiers Carousel
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 20) {
                                ForEach(UserTier.allCases.filter { $0 != .standard }, id: \.self) { tier in
                                    TierCard(tier: tier, subscriptionManager: subscriptionManager)
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // FAQ / Info
                        VStack(alignment: .leading, spacing: 20) {
                            Text("MEMBERSHIP BENEFITS")
                                .font(Theme.Fonts.body(size: 14))
                                .fontWeight(.bold)
                                .foregroundStyle(.gray)
                                .padding(.horizontal, 24)
                            
                            VStack(spacing: 16) {
                                BenefitRow(icon: "star.fill", title: "Priority Access", description: "Skip the line at partner venues.")
                                BenefitRow(icon: "percent", title: "Exclusive Discounts", description: "Save on bookings and bottle service.")
                                BenefitRow(icon: "crown.fill", title: "VIP Treatment", description: "Get the best tables and concierge support.")
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .alert("Welcome to the Club!", isPresented: $subscriptionManager.showSuccess) {
                Button("Awesome!") { dismiss() }
            } message: {
                Text("You have successfully upgraded your membership.")
            }
            .alert("Upgrade Failed", isPresented: Binding<Bool>(
                get: { subscriptionManager.errorMessage != nil },
                set: { _ in subscriptionManager.errorMessage = nil }
            )) {
                Button("OK") { subscriptionManager.errorMessage = nil }
            } message: {
                Text(subscriptionManager.errorMessage ?? "")
            }
        }
    }
}

struct TierCard: View {
    let tier: UserTier
    @ObservedObject var subscriptionManager: SubscriptionManager
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text(tier.rawValue.uppercased())
                    .font(Theme.Fonts.display(size: 24))
                    .foregroundStyle(colorForTier(tier))
                
                Text("$\(Int(tier.price))/mo")
                    .font(Theme.Fonts.display(size: 32))
                    .foregroundStyle(.white)
            }
            
            Divider()
                .background(Color.gray.opacity(0.3))
            
            // Features
            VStack(alignment: .leading, spacing: 16) {
                ForEach(tier.features, id: \.self) { feature in
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(colorForTier(tier))
                        Text(feature)
                            .font(Theme.Fonts.body(size: 14))
                            .foregroundStyle(.white)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            // Action Button
            Button {
                Task {
                    await subscriptionManager.upgrade(to: tier)
                }
            } label: {
                if subscriptionManager.isProcessing {
                    ProgressView()
                        .tint(.black)
                } else {
                    Text("UPGRADE")
                        .font(Theme.Fonts.body(size: 16))
                        .fontWeight(.bold)
                        .foregroundStyle(.black)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.white)
            .clipShape(Capsule())
            .disabled(subscriptionManager.isProcessing)
        }
        .padding(24)
        .frame(width: 300, height: 450)
        .background(Color.theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(colorForTier(tier).opacity(0.5), lineWidth: 1)
        )
    }
    
    func colorForTier(_ tier: UserTier) -> Color {
        switch tier {
        case .vip: return Color(hex: "FFD700") // Gold
        case .member: return Color(hex: "9D00FF") // Purple
        default: return .gray
        }
    }
}

struct BenefitRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.theme.accent)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Theme.Fonts.body(size: 16))
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                
                Text(description)
                    .font(Theme.Fonts.body(size: 14))
                    .foregroundStyle(.gray)
            }
        }
    }
}

// Helper for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
