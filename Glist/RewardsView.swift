import SwiftUI

struct RewardsView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var loyaltyManager: LoyaltyManager
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedReward: LoyaltyManager.Reward?
    @State private var showConfirmation = false
    @State private var isRedeeming = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Points Header
                        if let user = authManager.user {
                            VStack(spacing: 8) {
                                Text("\(user.rewardPoints)")
                                    .font(Theme.Fonts.display(size: 48))
                                    .foregroundStyle(.white)
                                
                                Text(LocalizedStringKey("points"))
                                    .font(Theme.Fonts.body(size: 12))
                                    .tracking(2)
                                    .foregroundStyle(.gray)
                            }
                            .padding(.top, 40)
                        }
                        
                        // Rewards List
                        VStack(spacing: 16) {
                            ForEach(loyaltyManager.availableRewards) { reward in
                                RewardCard(reward: reward) {
                                    selectedReward = reward
                                    showConfirmation = true
                                }
                                .disabled((authManager.user?.rewardPoints ?? 0) < reward.cost)
                                .opacity((authManager.user?.rewardPoints ?? 0) < reward.cost ? 0.5 : 1.0)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle(LocalizedStringKey("redeem_reward"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(LocalizedStringKey("close")) {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
            .alert(LocalizedStringKey("redeem_reward"), isPresented: $showConfirmation) {
                Button(LocalizedStringKey("cancel"), role: .cancel) { }
                Button(LocalizedStringKey("redeem")) {
                    redeemSelectedReward()
                }
            } message: {
                if let reward = selectedReward {
                    Text(String(format: NSLocalizedString("redeem_confirm", comment: ""), reward.title, "\(reward.cost)"))
                }
            }
            .alert(LocalizedStringKey("error_title"), isPresented: Binding(get: { errorMessage != nil }, set: { _ in errorMessage = nil })) {
                Button(LocalizedStringKey("close"), role: .cancel) { }
            } message: {
                Text(errorMessage ?? NSLocalizedString("unknown_error", comment: ""))
            }
        }
    }
    
    private func redeemSelectedReward() {
        guard let user = authManager.user, let reward = selectedReward else { return }
        
        isRedeeming = true
        Task {
            do {
                try await loyaltyManager.redeemPoints(user: user, reward: reward)
                // Success haptic or alert could go here
                selectedReward = nil
            } catch {
                errorMessage = error.localizedDescription
            }
            isRedeeming = false
        }
    }
}

struct RewardCard: View {
    let reward: LoyaltyManager.Reward
    let action: () -> Void
    @Environment(\.locale) private var locale
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.theme.surface)
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: reward.icon)
                        .font(.title2)
                        .foregroundStyle(Color.theme.accent)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(reward.title)
                        .font(Theme.Fonts.body(size: 16))
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    
                    Text(reward.description)
                        .font(Theme.Fonts.body(size: 12))
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text("\(reward.cost)")
                        .font(Theme.Fonts.display(size: 18))
                        .foregroundStyle(.white)
                    Text(LocalizedStringKey("points_short"))
                        .font(Theme.Fonts.body(size: 10))
                        .fontWeight(.bold)
                        .foregroundStyle(.gray)
                }
            }
            .padding(16)
            .background(Color.theme.surface.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
