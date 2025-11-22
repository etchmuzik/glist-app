import SwiftUI
import Charts
import Combine

struct PromoterDashboardView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var promoterManager = PromoterManager()
    
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
                                Text("EARNINGS")
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
                                    label: "Active Lists"
                                )
                                
                                PromoterStatCard(
                                    icon: "dollarsign.circle",
                                    value: "\(promoterManager.commissions.count)",
                                    label: "Commissions"
                                )
                                
                                PromoterStatCard(
                                    icon: "percent",
                                    value: "\(Int((promoterManager.promoter?.commissionRate ?? 0) * 100))%",
                                    label: "Rate"
                                )
                            }
                            .padding(.horizontal, 24)
                            
                            // Active Guest Lists
                            if !promoterManager.guestLists.isEmpty {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("ACTIVE GUEST LISTS")
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
                                    Text("RECENT COMMISSIONS")
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
            .navigationTitle("PROMOTER DASHBOARD")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if let userId = authManager.user?.id {
                    Task {
                        await promoterManager.fetchPromoterData(userId: userId)
                    }
                }
            }
        }
    }
}

struct EarningsCard: View {
    let title: String
    let amount: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title.uppercased())
                .font(Theme.Fonts.body(size: 10))
                .foregroundStyle(.gray)
            
            Text("$\(Int(amount))")
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
    let label: String
    
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
                Text("$\(Int(commission.amount))")
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
