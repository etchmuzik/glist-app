import Foundation
import SwiftUI
import Combine

class TicketManager: ObservableObject {
    @Published var tickets: [EventTicket] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func fetchUserTickets(userId: String) {
        isLoading = true
        Task {
            do {
                let tickets = try await FirestoreManager.shared.fetchUserTickets(userId: userId)
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
    
    func purchaseTicket(userId: String, event: Event, venue: Venue, ticketType: TicketType, quantity: Int) async throws {
        // Create tickets based on quantity
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
            
            try await FirestoreManager.shared.createTicket(newTicket)
        }
        
        // Refresh tickets
        fetchUserTickets(userId: userId)
    }
}
