import SwiftUI

struct PayoutManagementView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var promoterManager = PromoterManager()
    @State private var selectedMethod: PayoutMethod = .bank
    @State private var amountInputs: [String: String] = [:]
    @State private var notesInputs: [String: String] = [:]
    @State private var alertMessage: String?
    @State private var showAlert = false
    
    private var pendingCommissions: [Commission] {
        promoterManager.commissions.filter { $0.status != .paid }
    }
    
    var body: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Payouts")
                        .font(Theme.Fonts.display(size: 20))
                        .foregroundStyle(.white)
                    Spacer()
                    Button {
                        Task { await promoterManager.fetchAllCommissions(limit: 200) }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(.white)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Picker("Method", selection: $selectedMethod) {
                    ForEach(PayoutMethod.allCases, id: \.self) { method in
                        Text(method.rawValue).tag(method)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                
                if promoterManager.isLoading {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else if pendingCommissions.isEmpty {
                    Text("No pending commissions.")
                        .font(Theme.Fonts.body(size: 14))
                        .foregroundStyle(.gray)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else {
                    List {
                        ForEach(pendingCommissions) { commission in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(commission.promoterName)
                                            .font(Theme.Fonts.body(size: 14))
                                            .fontWeight(.bold)
                                        Text(commission.venueName)
                                            .font(Theme.Fonts.body(size: 12))
                                            .foregroundStyle(.gray)
                                    }
                                    Spacer()
                                    Text(CurrencyFormatter.aed(commission.amount, locale: Locale(identifier: "en_AE")))
                                        .font(Theme.Fonts.body(size: 14))
                                        .foregroundStyle(.green)
                                }
                                
                                TextField("Payout Amount (AED)", text: Binding(
                                    get: { amountInputs[commission.id] ?? String(format: "%.2f", commission.amount) },
                                    set: { amountInputs[commission.id] = $0 }
                                ))
                                .keyboardType(.decimalPad)
                                
                                TextField("Notes (optional)", text: Binding(
                                    get: { notesInputs[commission.id] ?? "" },
                                    set: { notesInputs[commission.id] = $0 }
                                ))
                                
                                HStack {
                                    Text(commission.status.rawValue)
                                        .font(Theme.Fonts.body(size: 12))
                                        .foregroundStyle(.orange)
                                    
                                    if let payout = commission.payout {
                                        Text(payout.status.rawValue)
                                            .font(Theme.Fonts.body(size: 10))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.theme.surface.opacity(0.4))
                                            .clipShape(Capsule())
                                    }
                                    Spacer()
                                    if authManager.userRole == .admin {
                                        Button("Mark Paid") {
                                            Task {
                                                let amount = Double(amountInputs[commission.id] ?? "") ?? commission.amount
                                                do {
                                                    try await promoterManager.markCommissionPaid(commission.id, method: selectedMethod, amount: amount, notes: notesInputs[commission.id])
                                                    await promoterManager.fetchAllCommissions(limit: 200)
                                                    await MainActor.run {
                                                        alertMessage = "Payout recorded"
                                                        showAlert = true
                                                    }
                                                } catch {
                                                    await MainActor.run {
                                                        alertMessage = "Failed to mark paid: \(error.localizedDescription)"
                                                        showAlert = true
                                                    }
                                                }
                                            }
                                        }
                                        .font(Theme.Fonts.body(size: 12))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color.theme.accent)
                                        .clipShape(Capsule())
                                    }
                                }
                                .foregroundStyle(.white)
                            }
                            .listRowBackground(Color.theme.surface.opacity(0.5))
                        }
                    }
                    .listStyle(.plain)
                }
                
                Spacer()
            }
        }
        .onAppear {
            Task { await promoterManager.fetchAllCommissions(limit: 200) }
        }
        .alert(alertMessage ?? "", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }
    }
}
