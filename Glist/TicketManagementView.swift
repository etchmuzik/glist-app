import SwiftUI

struct TicketManagementView: View {
    @State private var allTickets: [EventTicket] = []
    @State private var isLoading = false
    @State private var filterStatus: TicketStatus? = nil
    @State private var resaleTicket: EventTicket?
    @State private var resaleFeedback: String?
    
    var filteredTickets: [EventTicket] {
        if let filter = filterStatus {
            return allTickets.filter { $0.status == filter }
        } else {
            return allTickets
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter Buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    FilterChip(title: "All", isSelected: filterStatus == nil) {
                        filterStatus = nil
                    }
                    FilterChip(title: "Valid", isSelected: filterStatus == .valid) {
                        filterStatus = .valid
                    }
                    FilterChip(title: "Used", isSelected: filterStatus == .used) {
                        filterStatus = .used
                    }
                    FilterChip(title: "Refunded", isSelected: filterStatus == .refunded) {
                        filterStatus = .refunded
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            
            // List
            if isLoading {
                ProgressView()
                    .tint(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredTickets.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "ticket")
                        .font(.system(size: 40))
                        .foregroundStyle(.gray)
                    Text("No tickets found")
                        .font(Theme.Fonts.body(size: 14))
                        .foregroundStyle(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredTickets) { ticket in
                            AdminTicketCard(ticket: ticket, onOfferResale: { selected in
                                resaleTicket = selected
                            })
                        }
                    }
                    .padding(20)
                }
            }
        }
        .onAppear {
            loadTickets()
        }
        .sheet(item: $resaleTicket) { ticket in
            ResaleOfferView(ticket: ticket, pricingRules: ResaleManager.shared.defaultPricingRules) { price in
                Task {
                    do {
                        try await ResaleManager.shared.publishOffer(for: ticket, price: price, pricingRules: ResaleManager.shared.defaultPricingRules)
                        resaleFeedback = "Resale offer recorded for \(ticket.eventName)"
                    } catch {
                        resaleFeedback = error.localizedDescription
                    }
                }
            }
        }
        .alert("Resale", isPresented: Binding(
            get: { resaleFeedback != nil },
            set: { _ in resaleFeedback = nil }
        )) {
            Button("OK") {}
        } message: {
            Text(resaleFeedback ?? "")
        }
    }
    
    private func loadTickets() {
        isLoading = true
        Task {
            do {
                allTickets = try await SupabaseDataManager.shared.fetchAllTickets()
                isLoading = false
            } catch {
                print("Error loading tickets: \(error)")
                isLoading = false
            }
        }
    }
}

struct AdminTicketCard: View {
    let ticket: EventTicket
    var onOfferResale: (EventTicket) -> Void = { _ in }
    
    var statusColor: Color {
        switch ticket.status {
        case .valid: return .green
        case .used: return .gray
        case .refunded: return .red
        case .expired: return .orange
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(ticket.eventName.uppercased())
                        .font(Theme.Fonts.display(size: 16))
                        .foregroundStyle(.white)
                    
                    Text(ticket.venueName)
                        .font(Theme.Fonts.body(size: 14))
                        .foregroundStyle(.gray)
                }
                
                Spacer()
                
                Text(ticket.status.rawValue.uppercased())
                    .font(Theme.Fonts.body(size: 10))
                    .fontWeight(.bold)
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.2))
                    .clipShape(Capsule())
            }
            
            // Details
            HStack(spacing: 20) {
                DetailItem(icon: "calendar", text: ticket.eventDate.formatted(date: .abbreviated, time: .shortened))
                DetailItem(icon: "ticket.fill", text: ticket.ticketTypeName)
            }
            
            Divider().background(Color.gray.opacity(0.2))
            
            HStack {
                Text("User ID: \(ticket.userId.prefix(8))...")
                    .font(Theme.Fonts.caption())
                    .foregroundStyle(.gray)
                Spacer()
                Text(CurrencyFormatter.aed(ticket.price))
                    .font(Theme.Fonts.body(size: 14))
                    .fontWeight(.bold)
                    .foregroundStyle(Color.theme.accent)
            }
            Button {
                onOfferResale(ticket)
            } label: {
                Text("Offer Resale")
                    .font(Theme.Fonts.body(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .tint(.white)
        }
        .padding(16)
        .background(Color.theme.surface.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}
