import SwiftUI
import Charts
import Combine

struct PromoterDashboardView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var promoterManager = PromoterManager()
    @State private var showKYC = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.background.ignoresSafeArea()
                
                if promoterManager.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Earnings Summary
                            VStack(spacing: 16) {
                                Text(LocalizedStringKey("earnings"))
                                    .font(Theme.Fonts.body(size: 12))
                                    .fontWeight(.bold)
                                    .foregroundStyle(.gray)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                HStack(spacing: 16) {
                                    EarningsCard(
                                        title: "Total Earned",
                                        amount: promoterManager.totalEarnings,
                                        color: .green
                                    )
                                    
                                    EarningsCard(
                                        title: "Pending",
                                        amount: promoterManager.pendingEarnings,
                                        color: .orange
                                    )
                                }
                            }
                            .padding(.horizontal, 24)
                            
                            // Stats Row
                            HStack(spacing: 20) {
                                PromoterStatCard(
                                    icon: "list.bullet.clipboard",
                                    value: "\(promoterManager.guestLists.count)",
                                    label: LocalizedStringKey("active_lists")
                                )
                                
                                PromoterStatCard(
                                    icon: "dollarsign.circle",
                                    value: "\(promoterManager.commissions.count)",
                                    label: LocalizedStringKey("commissions")
                                )
                                
                                PromoterStatCard(
                                    icon: "percent",
                                    value: "\(Int((promoterManager.promoter?.commissionRate ?? 0) * 100))%",
                                    label: LocalizedStringKey("rate")
                                )
                            }
                            .padding(.horizontal, 24)
                            
                            if let promoter = promoterManager.promoter {
                                PromoterTrustStack(promoter: promoter) {
                                    showKYC = true
                                }
                                    .padding(.horizontal, 24)
                            }
                            
                            // Active Guest Lists
                            if !promoterManager.guestLists.isEmpty {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text(LocalizedStringKey("active_lists"))
                                        .font(Theme.Fonts.body(size: 12))
                                        .fontWeight(.bold)
                                        .foregroundStyle(.gray)
                                    
                                    ForEach(promoterManager.guestLists.prefix(5)) { request in
                                        PromoterGuestListCard(request: request)
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                            
                            // Recent Commissions
                            if !promoterManager.commissions.isEmpty {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text(LocalizedStringKey("recent_commissions"))
                                        .font(Theme.Fonts.body(size: 12))
                                        .fontWeight(.bold)
                                        .foregroundStyle(.gray)
                                    
                                    ForEach(promoterManager.commissions.prefix(10)) { commission in
                                        CommissionRow(commission: commission)
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle(LocalizedStringKey("promoter_dashboard"))
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if let userId = authManager.user?.id {
                    Task {
                        await promoterManager.fetchPromoterData(userId: userId)
                    }
                }
            }
            .sheet(isPresented: $showKYC) {
                KYCSubmissionView()
            }
        }
    }
}

struct EarningsCard: View {
    let title: String
    let amount: Double
    let color: Color
    @Environment(\.locale) private var locale
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title.uppercased())
                .font(Theme.Fonts.body(size: 10))
                .foregroundStyle(.gray)
            
            Text(CurrencyFormatter.aed(amount, locale: locale))
                .font(Theme.Fonts.display(size: 28))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct PromoterStatCard: View {
    let icon: String
    let value: String
    let label: LocalizedStringKey
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.theme.accent)
            
            Text(value)
                .font(Theme.Fonts.display(size: 20))
                .foregroundStyle(.white)
            
            Text(label)
                .font(Theme.Fonts.body(size: 10))
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct PromoterGuestListCard: View {
    let request: GuestListRequest
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(request.venueName)
                    .font(Theme.Fonts.body(size: 16))
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                
                Text(request.name)
                    .font(Theme.Fonts.body(size: 14))
                    .foregroundStyle(.gray)
                
                Text("\(request.guestCount) guests • \(request.date.formatted(date: .abbreviated, time: .shortened))")
                    .font(Theme.Fonts.body(size: 12))
                    .foregroundStyle(.gray)
            }
            
            Spacer()
            
            Text(request.status)
                .font(Theme.Fonts.body(size: 12))
                .fontWeight(.bold)
                .foregroundStyle(statusColor(request.status))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(statusColor(request.status).opacity(0.2))
                .clipShape(Capsule())
        }
        .padding(16)
        .background(Color.theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    func statusColor(_ status: String) -> Color {
        switch status {
        case "Confirmed": return .green
        case "Pending": return .orange
        case "Rejected": return .red
        default: return .gray
        }
    }
}

struct CommissionRow: View {
    let commission: Commission
    @Environment(\.locale) private var locale
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(commission.venueName)
                    .font(Theme.Fonts.body(size: 14))
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                
                Text(commission.date.formatted(date: .abbreviated, time: .omitted))
                    .font(Theme.Fonts.body(size: 12))
                    .foregroundStyle(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(CurrencyFormatter.aed(commission.amount, locale: locale))
                    .font(Theme.Fonts.body(size: 16))
                    .fontWeight(.bold)
                    .foregroundStyle(.green)
                
            Text(commission.status.rawValue)
                .font(Theme.Fonts.body(size: 10))
                .foregroundStyle(commission.status == .paid ? .green : .orange)
        }
        }
        .padding(12)
        .background(Color.theme.surface.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct PromoterTrustStack: View {
    let promoter: Promoter
    let onStartKYC: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TRUST & SAFETY")
                .font(Theme.Fonts.body(size: 12))
                .fontWeight(.bold)
                .foregroundStyle(.gray)
            
            HStack(spacing: 12) {
                KYCStatusCard(status: promoter.kycStatus, onTap: onStartKYC)
                PromoterReputationCard(score: promoter.reputationScore)
            }
        }
    }
}

struct KYCStatusCard: View {
    let status: KYCStatus
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                Label(status.badgeText.uppercased(), systemImage: "person.text.rectangle")
                    .font(Theme.Fonts.body(size: 12))
                    .fontWeight(.bold)
                    .foregroundStyle(status.badgeColor)
                    .lineLimit(2)
                
                Text(status == .verified ? "Identity verified for payouts" : "Start verification to unlock payouts and higher limits.")
                    .font(Theme.Fonts.body(size: 11))
                    .foregroundStyle(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(Color.theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct PromoterReputationCard: View {
    let score: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("REPUTATION")
                    .font(Theme.Fonts.body(size: 12))
                    .fontWeight(.bold)
                    .foregroundStyle(.gray)
                Spacer()
                Text("\(score)/100")
                    .font(Theme.Fonts.body(size: 12))
                    .foregroundStyle(.white)
            }
            
            ProgressView(value: Double(score), total: 100)
                .tint(score >= 80 ? .green : .orange)
            
            Text(score >= 80 ? "Guests trust your lists. Keep confirmations on-time." : "Respond faster and avoid cancellations to improve.")
                .font(Theme.Fonts.body(size: 11))
                .foregroundStyle(.gray)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
