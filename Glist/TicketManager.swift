import Foundation
import SwiftUI
import Combine

@MainActor
class TicketManager: ObservableObject {
    @Published var tickets: [EventTicket] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func fetchUserTickets(userId: String) {
        isLoading = true
        Task {
            do {
                let tickets = try await SupabaseDataManager.shared.fetchUserTickets(userId: userId)
                await MainActor.run {
                    self.tickets = tickets
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to fetch tickets: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    func purchaseTicket(userId: String, event: Event, venue: Venue, ticketType: TicketType, quantity: Int) async throws -> [EventTicket] {
        var created: [EventTicket] = []
        
        for _ in 0..<quantity {
            let newTicket = EventTicket(
                id: UUID(),
                eventId: event.id,
                eventName: event.name,
                eventDate: event.date,
                venueId: venue.id,
                venueName: venue.name,
                userId: userId,
                ticketTypeId: ticketType.id,
                ticketTypeName: ticketType.name,
                price: ticketType.price,
                status: .valid,
                qrCodeId: UUID().uuidString, // Unique QR code for each ticket
                purchaseDate: Date()
            )
            
            try await SupabaseDataManager.shared.createTicket(newTicket)
            created.append(newTicket)
            
            // Award Loyalty Points
            try await SupabaseDataManager.shared.addRewardPoints(userId: userId, points: LoyaltyManager.pointsPerTicket)
        }
        
        // Refresh tickets
        fetchUserTickets(userId: userId)
        return created
    }
    
    /// Fetch a signed .pkpass for the given ticket from the backend.
    func fetchPass(for ticket: EventTicket) async throws -> Data? {
        try await PassService.shared.fetchPass(ticketId: ticket.id)
    }
    func purchaseResaleTicket(ticket: EventTicket, buyerId: String) async throws {
        guard let price = ticket.resalePrice else { return }
        try await SupabaseDataManager.shared.purchaseResaleTicket(ticketId: ticket.id.uuidString, buyerId: buyerId, price: price)
        // Refresh tickets
        fetchUserTickets(userId: buyerId)
    }
}
