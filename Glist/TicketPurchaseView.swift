import SwiftUI
import UIKit
import StripePaymentSheet

struct TicketPurchaseView: View {
    let venue: Venue
    let event: Event
    let ticketType: TicketType
    let quantity: Int
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.locale) private var locale
    @StateObject private var ticketManager = TicketManager()
    @StateObject private var paymentManager = PaymentManager()
    
    @State private var isProcessing = false
    @State private var showSuccess = false
    @State private var errorMessage: String?
    @State private var transactionId: String?
    @State private var pkPassData: Data?
    @State private var showPaymentSheet = false
    
    var totalAmount: Double { ticketType.price * Double(quantity) }
    
    var body: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()
            
            if showSuccess {
                TicketSuccessView(transactionId: transactionId, pkPassData: pkPassData)
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
                            Text(CurrencyFormatter.aed(ticketType.price, locale: locale))
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
                            Text(CurrencyFormatter.aed(totalAmount, locale: locale))
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
                    
                    // Policies
                    let rules = BookingRulesProvider.forVenue(venue)
                    PolicyDisclosureRow(
                        rules: rules,
                        contextText: "By paying, you agree to: ID • Dress Code • Entry Policy"
                    )
                    .padding(.horizontal, 20)
                    
                    // Payment Button
                    Button {
                        startCheckout()
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
        .paymentSheet(isPresented: $showPaymentSheet, paymentSheet: paymentManager.paymentSheet!, onCompletion: paymentManager.onPaymentCompletion)
        .onChange(of: paymentManager.status) { _, newStatus in
            if case .ready = newStatus {
                showPaymentSheet = true
            } else if case .success(let txnId) = newStatus {
                createTickets(transactionId: txnId)
            } else if case .failed(let error) = newStatus {
                errorMessage = error
                isProcessing = false
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
    
    private func startCheckout() {
        isProcessing = true
        errorMessage = nil
        
        Task {
            do {
                try await paymentManager.preparePaymentSheet(
                    venueId: venue.id.uuidString,
                    tableId: nil,
                    amount: totalAmount,
                    currency: "aed",
                    deposit: false
                )
            } catch {
                // Error handled in PaymentManager status observation
                await MainActor.run {
                    isProcessing = false
                }
            }
        }
    }
    
    private func createTickets(transactionId: String) {
        Task {
            do {
                guard let userId = authManager.user?.id else { return }
                
                // Create tickets
                let createdTickets = try await ticketManager.purchaseTicket(
                    userId: userId,
                    event: event,
                    venue: venue,
                    ticketType: ticketType,
                    quantity: quantity
                )
                
                var passData: Data? = nil
                if let firstTicket = createdTickets.first {
                    passData = try await ticketManager.fetchPass(for: firstTicket)
                }
                
                await MainActor.run {
                    self.transactionId = transactionId
                    self.pkPassData = passData
                    self.isProcessing = false
                    withAnimation {
                        self.showSuccess = true
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Ticket creation failed: \(error.localizedDescription)"
                    self.isProcessing = false
                }
            }
        }
    }
}

struct TicketSuccessView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.scenePhase) private var scenePhase
    let transactionId: String?
    let pkPassData: Data?
    
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
            
            if pkPassData != nil {
                Button {
                    presentPass()
                } label: {
                    HStack {
                        Image(systemName: "wallet.pass")
                        Text("Add to Apple Wallet")
                    }
                    .font(Theme.Fonts.body(size: 14))
                    .fontWeight(.bold)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Color.white)
                    .clipShape(Capsule())
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
        .onChange(of: scenePhase) { _, _ in }
    }
    
    private func presentPass() {
        guard let data = pkPassData else { return }
        if let top = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?
            .rootViewController {
            AppleWalletManager.presentPass(from: data, in: top)
        }
    }
}
