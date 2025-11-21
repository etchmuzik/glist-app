import SwiftUI

struct EventTicketView: View {
    let venue: Venue
    let event: Event
    
    @Environment(\.dismiss) var dismiss
    @State private var selectedTicketType: TicketType?
    @State private var quantity = 1
    @State private var showCheckout = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Event Header
                    VStack(spacing: 16) {
                        Text(event.name.uppercased())
                            .font(Theme.Fonts.display(size: 24))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                        
                        HStack {
                            Image(systemName: "calendar")
                            Text(event.date.formatted(date: .long, time: .shortened))
                        }
                        .font(Theme.Fonts.body(size: 14))
                        .foregroundStyle(.gray)
                        
                        Text(venue.name)
                            .font(Theme.Fonts.body(size: 14))
                            .foregroundStyle(Color.theme.accent)
                    }
                    .padding(24)
                    
                    ScrollView {
                        VStack(spacing: 16) {
                            Text("SELECT TICKETS")
                                .font(Theme.Fonts.body(size: 12))
                                .fontWeight(.bold)
                                .foregroundStyle(.gray)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 20)
                            
                            ForEach(event.ticketTypes) { ticketType in
                                TicketTypeCard(
                                    ticketType: ticketType,
                                    isSelected: selectedTicketType?.id == ticketType.id
                                ) {
                                    selectedTicketType = ticketType
                                    quantity = 1 // Reset quantity when changing type
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.vertical, 20)
                    }
                    
                    // Bottom Bar
                    if let selected = selectedTicketType {
                        VStack(spacing: 20) {
                            // Quantity Selector
                            HStack {
                                Text("Quantity")
                                    .font(Theme.Fonts.body(size: 16))
                                    .foregroundStyle(.white)
                                
                                Spacer()
                                
                                HStack(spacing: 20) {
                                    Button {
                                        if quantity > 1 { quantity -= 1 }
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.title2)
                                            .foregroundStyle(.gray)
                                    }
                                    
                                    Text("\(quantity)")
                                        .font(Theme.Fonts.display(size: 20))
                                        .foregroundStyle(.white)
                                        .frame(width: 30)
                                    
                                    Button {
                                        if quantity < 10 { quantity += 1 }
                                    } label: {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title2)
                                            .foregroundStyle(.white)
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                            
                            Divider()
                                .background(Color.gray.opacity(0.3))
                            
                            // Total and Button
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("TOTAL")
                                        .font(Theme.Fonts.body(size: 12))
                                        .foregroundStyle(.gray)
                                    Text("$\(Int(selected.price) * quantity)")
                                        .font(Theme.Fonts.display(size: 24))
                                        .foregroundStyle(.white)
                                }
                                
                                Spacer()
                                
                                Button {
                                    showCheckout = true
                                } label: {
                                    Text("CHECKOUT")
                                        .font(Theme.Fonts.body(size: 16))
                                        .fontWeight(.bold)
                                        .foregroundStyle(.black)
                                        .padding(.horizontal, 32)
                                        .padding(.vertical, 16)
                                        .background(Color.white)
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 30)
                        }
                        .background(Color.theme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .ignoresSafeArea()
                    }
                }
            }
            .navigationTitle("Tickets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .navigationDestination(isPresented: $showCheckout) {
                if let ticketType = selectedTicketType {
                    TicketPurchaseView(
                        venue: venue,
                        event: event,
                        ticketType: ticketType,
                        quantity: quantity
                    )
                }
            }
        }
    }
}

struct TicketTypeCard: View {
    let ticketType: TicketType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(ticketType.name)
                        .font(Theme.Fonts.display(size: 18))
                        .foregroundStyle(.white)
                    
                    if let desc = ticketType.description {
                        Text(desc)
                            .font(Theme.Fonts.body(size: 12))
                            .foregroundStyle(.gray)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("$\(Int(ticketType.price))")
                        .font(Theme.Fonts.display(size: 18))
                        .foregroundStyle(Color.theme.accent)
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding(20)
            .background(isSelected ? Color.theme.surface : Color.theme.surface.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.white : Color.clear, lineWidth: 1)
            )
        }
    }
}
