import SwiftUI

struct InviteView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var inviteManager = InviteManager()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 12) {
                            Image(systemName: "gift.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.theme.accent, Color.purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            Text("INVITE FRIENDS")
                                .font(Theme.Fonts.display(size: 28))
                                .foregroundStyle(.white)
                            
                            Text("Share the VIP experience and earn rewards")
                                .font(Theme.Fonts.body(size: 16))
                                .foregroundStyle(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                        
                        // Invite Code Card
                        VStack(spacing: 20) {
                            Text("YOUR INVITE CODE")
                                .font(Theme.Fonts.body(size: 12))
                                .fontWeight(.bold)
                                .foregroundStyle(.gray)
                            
                            Text(inviteManager.inviteCode)
                                .font(Theme.Fonts.display(size: 36))
                                .foregroundStyle(.white)
                                .tracking(4)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 20)
                                .background(Color.theme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.theme.accent.opacity(0.3), lineWidth: 1)
                                )
                            
                            Button {
                                UIPasteboard.general.string = inviteManager.inviteCode
                            } label: {
                                HStack {
                                    Image(systemName: "doc.on.doc")
                                    Text("Copy Code")
                                }
                                .font(Theme.Fonts.body(size: 14))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.theme.surface)
                                .clipShape(Capsule())
                            }
                        }
                        .padding(24)
                        .background(Color.theme.surface.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .padding(.horizontal, 24)
                        
                        // Stats
                        HStack(spacing: 40) {
                            VStack(spacing: 8) {
                                Text("\(inviteManager.inviteCount)")
                                    .font(Theme.Fonts.display(size: 32))
                                    .foregroundStyle(.white)
                                
                                Text("Friends Invited")
                                    .font(Theme.Fonts.body(size: 12))
                                    .foregroundStyle(.gray)
                            }
                            
                            VStack(spacing: 8) {
                                Text("\(inviteManager.inviteCount * 10)")
                                    .font(Theme.Fonts.display(size: 32))
                                    .foregroundStyle(Color.theme.accent)
                                
                                Text("Points Earned")
                                    .font(Theme.Fonts.body(size: 12))
                                    .foregroundStyle(.gray)
                            }
                        }
                        .padding(.vertical, 20)
                        
                        // Rewards
                        VStack(alignment: .leading, spacing: 16) {
                            Text("REWARDS")
                                .font(Theme.Fonts.body(size: 14))
                                .fontWeight(.bold)
                                .foregroundStyle(.gray)
                                .padding(.horizontal, 24)
                            
                            VStack(spacing: 12) {
                                RewardRow(
                                    icon: "star.fill",
                                    title: "10 Points per Friend",
                                    description: "Earn points when friends join"
                                )
                                
                                RewardRow(
                                    icon: "ticket.fill",
                                    title: "Free Event Ticket",
                                    description: "After 5 successful invites"
                                )
                                
                                RewardRow(
                                    icon: "crown.fill",
                                    title: "VIP Upgrade",
                                    description: "After 10 successful invites"
                                )
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // Share Button
                        Button {
                            shareInvite()
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("SHARE INVITE")
                            }
                            .font(Theme.Fonts.body(size: 16))
                            .fontWeight(.bold)
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .clipShape(Capsule())
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
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
                    .foregroundStyle(.white)
                }
            }
            .onAppear {
                if let userId = authManager.user?.id {
                    inviteManager.generateInviteCode(userId: userId)
                }
            }
        }
    }
    
    func shareInvite() {
        let message = inviteManager.getInviteMessage()
        let activityVC = UIActivityViewController(
            activityItems: [message],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            activityVC.popoverPresentationController?.sourceView = rootVC.view
            rootVC.present(activityVC, animated: true)
        }
    }
}

struct RewardRow: View {
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
            
            Spacer()
        }
        .padding(16)
        .background(Color.theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
