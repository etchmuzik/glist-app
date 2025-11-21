import SwiftUI

struct CheckoutView: View {
    let venue: Venue
    let table: Table
    let date: Date
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var bookingManager = BookingManager()
    @StateObject private var paymentManager = PaymentManager()
    
    @State private var isProcessing = false
    @State private var showSuccess = false
    @State private var errorMessage: String?
    @State private var transactionId: String?
    
    var depositAmount: Double {
        table.minimumSpend * 0.20
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.background.ignoresSafeArea()
                
                if showSuccess {
                    SuccessView(transactionId: transactionId)
                } else {
                    VStack(spacing: 24) {
                        // Summary Card
                        VStack(spacing: 20) {
                            Text("BOOKING SUMMARY")
                                .font(Theme.Fonts.body(size: 12))
                                .fontWeight(.bold)
                                .foregroundStyle(.gray)
                            
                            VStack(spacing: 8) {
                                Text(venue.name.uppercased())
                                    .font(Theme.Fonts.display(size: 24))
                                    .foregroundStyle(.white)
                                
                                Text(table.name)
                                    .font(Theme.Fonts.body(size: 16))
                                    .foregroundStyle(Color.theme.accent)
                            }
                            
                            Divider()
                                .background(Color.gray.opacity(0.3))
                            
                            HStack {
                                Text("Date")
                                    .foregroundStyle(.gray)
                                Spacer()
                                Text(date.formatted(date: .long, time: .omitted))
                                    .foregroundStyle(.white)
                            }
                            .font(Theme.Fonts.body(size: 14))
                            
                            HStack {
                                Text("Guests")
                                    .foregroundStyle(.gray)
                                Spacer()
                                Text("Up to \(table.capacity)")
                                    .foregroundStyle(.white)
                            }
                            .font(Theme.Fonts.body(size: 14))
                            
                            HStack {
                                Text("Minimum Spend")
                                    .foregroundStyle(.gray)
                                Spacer()
                                Text("$\(Int(table.minimumSpend))")
                                    .foregroundStyle(.white)
                            }
                            .font(Theme.Fonts.body(size: 14))
                            
                            Divider()
                                .background(Color.gray.opacity(0.3))
                            
                            HStack {
                                Text("Deposit Due Now")
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                Spacer()
                                Text("$\(Int(depositAmount))")
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
            .toolbar {
                if !showSuccess {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            }
            .alert("Payment Failed", isPresented: Binding<Bool>(
                get: { errorMessage != nil },
                set: { _ in errorMessage = nil }
            )) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
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
                    amount: depositAmount,
                    method: .applePay,
                    bookingId: UUID().uuidString
                )
                
                // If payment succeeds, create booking
                try await bookingManager.createBooking(
                    userId: userId,
                    venue: venue,
                    table: table,
                    date: date
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
                    errorMessage = "Booking failed: \(error.localizedDescription)"
                    isProcessing = false
                }
            }
        }
    }
}

struct SuccessView: View {
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
                Text("BOOKING CONFIRMED")
                    .font(Theme.Fonts.display(size: 24))
                    .foregroundStyle(.white)
                
                Text("Your table has been reserved.")
                    .font(Theme.Fonts.body(size: 16))
                    .foregroundStyle(.gray)
                
                if let txnId = transactionId {
                    Text("Transaction ID: \(txnId)")
                        .font(Theme.Fonts.body(size: 12))
                        .foregroundStyle(.gray.opacity(0.7))
                        .padding(.top, 4)
                }
            }
            
            Button {
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
