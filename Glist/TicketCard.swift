import SwiftUI
import Combine

struct TicketCard: View {
    let ticket: EventTicket
    @Environment(\.locale) private var locale
    
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
                        .foregroundStyle(Color.theme.accent)
                }
                
                Spacer()
                
                Text(ticket.ticketTypeName.uppercased())
                    .font(Theme.Fonts.body(size: 10))
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.theme.accent.opacity(0.2))
                    .clipShape(Capsule())
            }
            
            // Details
            HStack(spacing: 20) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundStyle(.gray)
                    Text(ticket.eventDate.formatted(date: .abbreviated, time: .shortened))
                        .font(Theme.Fonts.body(size: 12))
                        .foregroundStyle(.gray)
                }
                
                HStack(spacing: 6) {
                    Image(systemName: "qrcode")
                        .font(.caption)
                        .foregroundStyle(.gray)
                    Text("Tap to show QR")
                        .font(Theme.Fonts.body(size: 12))
                        .foregroundStyle(.gray)
                }
                HStack(spacing: 6) {
                    Image(systemName: "creditcard")
                        .font(.caption)
                        .foregroundStyle(.gray)
                    Text(CurrencyFormatter.aed(ticket.price, locale: locale))
                        .font(Theme.Fonts.body(size: 12))
                        .foregroundStyle(.gray)
                }
            }
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
