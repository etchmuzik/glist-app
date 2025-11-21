import SwiftUI

struct BookingCard: View {
    let booking: Booking
    
    var statusColor: Color {
        switch booking.status {
        case .paid:
            return .green
        case .pending:
            return .orange
        case .cancelled:
            return .red
        }
    }
    
    var statusText: String {
        booking.status.rawValue
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(booking.venueName.uppercased())
                        .font(Theme.Fonts.display(size: 16))
                        .foregroundStyle(.white)
                    
                    Text(booking.tableName)
                        .font(Theme.Fonts.body(size: 14))
                        .foregroundStyle(Color.theme.accent)
                }
                
                Spacer()
                
                Text(statusText.uppercased())
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
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundStyle(.gray)
                    Text(booking.date.formatted(date: .abbreviated, time: .omitted))
                        .font(Theme.Fonts.body(size: 12))
                        .foregroundStyle(.gray)
                }
                
                HStack(spacing: 6) {
                    Image(systemName: "dollarsign.circle")
                        .font(.caption)
                        .foregroundStyle(.gray)
                    Text("$\(Int(booking.depositAmount)) deposit")
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
