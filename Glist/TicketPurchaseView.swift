import SwiftUI

struct TicketPurchaseView: View {
    let venue: Venue
    let event: Event
    let ticketType: TicketType
    let quantity: Int
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var ticketManager = TicketManager()
    @StateObject private var paymentManager = PaymentManager()
    
    @State private var isProcessing = false
    @State private var showSuccess = false
    @State private var errorMessage: String?
    @State private var transactionId: String?
    
    var totalAmount: Double {
        ticketType.price * Double(quantity)
    }
    
    var body: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()
            
            if showSuccess {
                TicketSuccessView(transactionId: transactionId)
            } else {
                VStack(spacing: 24) {
                    // Summary Card
                    VStack(spacing: 20) {
                        Text("ORDER SUMMARY")
                            .font(Theme.Fonts.body(size: 12))
                            .fontWeight(.bold)
                            .foregroundStyle(.gray)
                        
                        VStack(spacing: 8) {
                            Text(event.name.uppercased())
                                .font(Theme.Fonts.display(size: 24))
                                .foregroundStyle(.white)
                            
                            Text(venue.name)
                                .font(Theme.Fonts.body(size: 16))
                                .foregroundStyle(Color.theme.accent)
                        }
                        
                        Divider()
                            .background(Color.gray.opacity(0.3))
                        
                        HStack {
                            Text("Ticket Type")
                                .foregroundStyle(.gray)
                            Spacer()
                            Text(ticketType.name)
                                .foregroundStyle(.white)
                        }
                        .font(Theme.Fonts.body(size: 14))
                        
                        HStack {
                            Text("Quantity")
                                .foregroundStyle(.gray)
                            Spacer()
                            Text("\(quantity)")
                                .foregroundStyle(.white)
                        }
                        .font(Theme.Fonts.body(size: 14))
                        
                        HStack {
                            Text("Price per Ticket")
                                .foregroundStyle(.gray)
                            Spacer()
                            Text("$\(Int(ticketType.price))")
                                .foregroundStyle(.white)
                        }
                        .font(Theme.Fonts.body(size: 14))
                        
                        Divider()
                            .background(Color.gray.opacity(0.3))
                        
                        HStack {
                            Text("Total")
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                            Spacer()
                            Text("$\(Int(totalAmount))")
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                        }
                        .font(Theme.Fonts.body(size: 16))
                    }
                    .padding(24)
                    .background(Color.theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    Spacer()
                    
                    // Payment Button
                    Button {
                        processPayment()
                    } label: {
                        HStack {
                            if isProcessing {
                                ProgressView()
                                    .tint(.black)
                            } else {
                                Image(systemName: "apple.logo")
                                Text("Pay with Apple Pay")
                            }
                        }
                        .font(Theme.Fonts.body(size: 16))
                        .fontWeight(.bold)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.white)
                        .clipShape(Capsule())
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .disabled(isProcessing)
                }
            }
        }
        .navigationTitle("Checkout")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Payment Failed", isPresented: Binding<Bool>(
            get: { errorMessage != nil },
            set: { _ in errorMessage = nil }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }
    
    private func processPayment() {
        isProcessing = true
        errorMessage = nil
        
        Task {
            do {
                guard let userId = authManager.user?.id else {
                    throw PaymentError.invalidAmount
                }
                
                // Process payment first
                let txnId = try await paymentManager.processPayment(
                    amount: totalAmount,
                    method: .applePay,
                    bookingId: UUID().uuidString
                )
                
                // If payment succeeds, create tickets
                try await ticketManager.purchaseTicket(
                    userId: userId,
                    event: event,
                    venue: venue,
                    ticketType: ticketType,
                    quantity: quantity
                )
                
                await MainActor.run {
                    transactionId = txnId
                    isProcessing = false
                    withAnimation {
                        showSuccess = true
                    }
                }
            } catch let error as PaymentError {
                await MainActor.run {
                    errorMessage = error.errorDescription
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Purchase failed: \(error.localizedDescription)"
                    isProcessing = false
                }
            }
        }
    }
}

struct TicketSuccessView: View {
    @Environment(\.dismiss) var dismiss
    let transactionId: String?
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)
                .scaleEffect(1.0)
                .animation(.spring(), value: true)
            
            VStack(spacing: 8) {
                Text("PURCHASE CONFIRMED")
                    .font(Theme.Fonts.display(size: 24))
                    .foregroundStyle(.white)
                
                Text("Your tickets have been added to your profile.")
                    .font(Theme.Fonts.body(size: 16))
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                if let txnId = transactionId {
                    Text("Transaction ID: \(txnId)")
                        .font(Theme.Fonts.body(size: 12))
                        .foregroundStyle(.gray.opacity(0.7))
                        .padding(.top, 4)
                }
            }
            
            Button {
                // Dismiss all the way to root or venue detail
                // For now, just dismiss this sheet/view
                // In a real app, we might want to pop to root
                dismiss()
            } label: {
                Text("DONE")
                    .font(Theme.Fonts.body(size: 14))
                    .fontWeight(.bold)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .clipShape(Capsule())
            }
            .padding(.top, 20)
        }
    }
}
