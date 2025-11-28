import SwiftUI

struct ResaleMarketplaceView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var ticketManager = TicketManager()
    @State private var resaleTickets: [EventTicket] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedTicket: EventTicket?
    @State private var showPurchaseConfirmation = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else if resaleTickets.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "ticket")
                            .font(.system(size: 48))
                            .foregroundStyle(.gray)
                        Text("No tickets available for resale right now.")
                            .font(Theme.Fonts.body(size: 16))
                            .foregroundStyle(.gray)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(resaleTickets) { ticket in
                                ResaleTicketRow(ticket: ticket) {
                                    selectedTicket = ticket
                                    showPurchaseConfirmation = true
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Resale Marketplace")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        loadTickets()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                loadTickets()
            }
            .alert("Confirm Purchase", isPresented: $showPurchaseConfirmation, presenting: selectedTicket) { ticket in
                Button("Cancel", role: .cancel) {}
                Button("Buy for \(CurrencyFormatter.aed(ticket.resalePrice ?? 0))") {
                    purchaseTicket(ticket)
                }
            } message: { ticket in
                Text("Are you sure you want to buy this ticket for \(ticket.eventName)?")
            }
            .alert("Error", isPresented: Binding(get: { errorMessage != nil }, set: { _ in errorMessage = nil })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
        }
    }
    
    private func loadTickets() {
        isLoading = true
        Task {
            do {
                let tickets = try await SupabaseDataManager.shared.fetchResaleTickets()
                await MainActor.run {
                    self.resaleTickets = tickets
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    private func purchaseTicket(_ ticket: EventTicket) {
        guard let userId = authManager.user?.id else { return }
        
        isLoading = true
        Task {
            do {
                try await ticketManager.purchaseResaleTicket(ticket: ticket, buyerId: userId)
                await MainActor.run {
                    self.isLoading = false
                    self.loadTickets() // Refresh list
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}

struct ResaleTicketRow: View {
    let ticket: EventTicket
    let onBuy: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(ticket.eventName)
                        .font(Theme.Fonts.bodyBold(size: 18))
                        .foregroundStyle(.white)
                    Text(ticket.venueName)
                        .font(Theme.Fonts.caption())
                        .foregroundStyle(.gray)
                }
                Spacer()
                Text(CurrencyFormatter.aed(ticket.resalePrice ?? 0))
                    .font(Theme.Fonts.display(size: 20))
                    .foregroundStyle(Color.theme.accent)
            }
            
            HStack {
                Label(ticket.eventDate.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                    .font(Theme.Fonts.caption())
                    .foregroundStyle(.gray)
                Spacer()
                Button(action: onBuy) {
                    Text("Buy Now")
                        .font(Theme.Fonts.bodyBold(size: 14))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.theme.accent)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
        }
        .padding()
        .background(Color.theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}
