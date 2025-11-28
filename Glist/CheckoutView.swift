import SwiftUI
import StripePaymentSheet

struct CheckoutView: View {
    let venue: Venue
    let table: Table
    let date: Date
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.locale) private var locale
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var bookingManager = BookingManager()
    @StateObject private var paymentManager = PaymentManager()
    
    @State private var isProcessing = false
    @State private var showSuccess = false
    @State private var errorMessage: String?
    @State private var transactionId: String?
    @State private var effectiveMinimumSpend: Double?
    @State private var isPricingLoading = false
    @State private var showResaleSheet = false
    @State private var checkoutResaleMessage: String?
    
    var depositAmount: Double {
        let minimum = effectiveMinimumSpend ?? table.minimumSpend
        return minimum * 0.20
    }
    
    @State private var showPaymentSheet = false
    
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
                            Text(LocalizedStringKey("booking_summary"))
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
                                Text(LocalizedStringKey("date_label"))
                                    .foregroundStyle(.gray)
                                    .font(Theme.Fonts.body(size: 14))
                                Spacer()
                                Text(date.formatted(date: .long, time: .omitted))
                                    .foregroundStyle(.white)
                                    .font(Theme.Fonts.body(size: 14))
                            }
                            
                            HStack {
                                Text(LocalizedStringKey("guests_label"))
                                    .foregroundStyle(.gray)
                                    .font(Theme.Fonts.body(size: 14))
                                Spacer()
                                Text("Up to \(table.capacity)")
                                    .foregroundStyle(.white)
                                    .font(Theme.Fonts.body(size: 14))
                            }
                            
                            HStack {
                                Text(LocalizedStringKey("minimum_spend"))
                                    .foregroundStyle(.gray)
                                    .font(Theme.Fonts.body(size: 14))
                                Spacer()
                                Text(CurrencyFormatter.aed(effectiveMinimumSpend ?? table.minimumSpend, locale: locale))
                                    .foregroundStyle(.white)
                                    .font(Theme.Fonts.body(size: 14))
                            }
                            
                            if let effectiveMinimumSpend, effectiveMinimumSpend != table.minimumSpend {
                                Text("F1 weekend pricing applied")
                                    .font(Theme.Fonts.caption())
                                    .foregroundStyle(Color.theme.accent)
                            }
                            
                            if isPricingLoading {
                                ProgressView()
                                    .tint(.white)
                            }
                            
                            Divider()
                                .background(Color.gray.opacity(0.3))
                            
                            HStack {
                                Text(LocalizedStringKey("deposit_due"))
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                Spacer()
                                Text(CurrencyFormatter.aed(depositAmount, locale: locale))
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
                            contextText: "By paying, you agree to: ID • Dress Code • Deposit"
                        )
                        .padding(.horizontal, 20)
                        
                        // Payment Button
                        Button {
                            processPayment()
                        } label: {
                            HStack {
                                if isProcessing || paymentManager.status == .preparing {
                                    ProgressView()
                                        .tint(.black)
                                } else {
                                    Image(systemName: "creditcard.fill")
                                    Text("Pay Deposit")
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
                        .disabled(isProcessing || paymentManager.status == .preparing)
                        
                        Button {
                            showResaleSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "arrow.2.squarepath")
                                Text("Plan Resale Offer")
                            }
                            .font(Theme.Fonts.body(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.theme.surface)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                        .disabled(showResaleSheet)

                        // BNPL Option (Tabby)
                        Button {
                            processBNPL(provider: .tabby)
                        } label: {
                            HStack {
                                Text("Split in 4 with")
                                    .font(Theme.Fonts.body(size: 14))
                                Text("tabby")
                                    .font(.system(size: 16, weight: .black)) // Tabby logo style
                                    .foregroundStyle(Color(red: 0.2, green: 0.8, blue: 0.6)) // Tabby green
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.theme.surface)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                        .disabled(isProcessing || paymentManager.status == .preparing)
                    }
                }
            }
            .navigationTitle(LocalizedStringKey("checkout_title"))
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
            .sheet(isPresented: $showResaleSheet) {
                ResaleOfferView(ticket: pendingResaleTicket) { price in
                    Task {
                        do {
                            try await ResaleManager.shared.publishOffer(for: pendingResaleTicket, price: price, pricingRules: ResaleManager.shared.defaultPricingRules)
                            checkoutResaleMessage = "Resale offer created for \(venue.name)"
                        } catch {
                            checkoutResaleMessage = error.localizedDescription
                        }
                        showResaleSheet = false
                    }
                }
            }
            .alert("Resale", isPresented: Binding(
                get: { checkoutResaleMessage != nil },
                set: { _ in checkoutResaleMessage = nil }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(checkoutResaleMessage ?? "")
            }
            .alert("Payment Failed", isPresented: Binding<Bool>(
                get: { errorMessage != nil },
                set: { _ in errorMessage = nil }
            )) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .paymentSheet(isPresented: $showPaymentSheet, paymentSheet: paymentManager.paymentSheet!, onCompletion: paymentManager.onPaymentCompletion)
            .onChange(of: paymentManager.status) { _, newStatus in
                switch newStatus {
                case .ready:
                    showPaymentSheet = true
                    isProcessing = false
                case .success(let txnId):
                    completeBooking(transactionId: txnId)
                case .failed(let error):
                    errorMessage = error
                    isProcessing = false
                default:
                    break
                }
            }
        }
        .task {
            await recalculatePricing()
        }
    }
    
    private func processPayment() {
        isProcessing = true
        errorMessage = nil
        
        Task {
            do {
                try await paymentManager.preparePaymentSheet(
                    venueId: venue.id.uuidString,
                    tableId: table.id.uuidString,
                    amount: depositAmount
                )
            } catch {
                // Error handled by onChange(of: status)
            }
        }
    }
    
    private func processBNPL(provider: PaymentsManager.BNPLProvider) {
        isProcessing = true
        errorMessage = nil
        
        Task {
            do {
                guard let userId = authManager.user?.id else { return }
                
                let request = PaymentsManager.DepositRequest(
                    amountAED: Decimal(depositAmount),
                    userId: userId,
                    venueId: venue.id.uuidString,
                    tableId: table.id.uuidString,
                    provider: provider
                )
                
                let (deposit, redirectUrl) = try await PaymentsManager.shared.initiateBNPLDeposit(request: request)
                try await PaymentsManager.shared.recordDeposit(deposit)
                
                await MainActor.run {
                    isProcessing = false
                    if let url = redirectUrl {
                        UIApplication.shared.open(url)
                    } else {
                        completeBooking(transactionId: deposit.id ?? "bnpl_pending")
                    }
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = "BNPL Error: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func completeBooking(transactionId: String) {
        Task {
            do {
                guard let userId = authManager.user?.id else { return }
                
                try await bookingManager.createBooking(
                    userId: userId,
                    venue: venue,
                    table: table,
                    date: date,
                    status: .confirmed
                )
                
                await MainActor.run {
                    self.transactionId = transactionId
                    withAnimation {
                        showSuccess = true
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Booking failed: \(error.localizedDescription)"
                }
            }
        }
    }

    private var pendingResaleTicket: EventTicket {
        EventTicket(
            id: UUID(),
            eventId: UUID(),
            eventName: venue.name,
            eventDate: date,
            venueId: venue.id,
            venueName: venue.name,
            userId: authManager.user?.id ?? "guest",
            ticketTypeId: table.id,
            ticketTypeName: table.name,
            price: effectiveMinimumSpend ?? table.minimumSpend,
            status: .valid,
            qrCodeId: UUID().uuidString,
            purchaseDate: Date()
        )
    }
}

// MARK: - Helpers

extension CheckoutView {
    private func recalculatePricing() async {
        isPricingLoading = true
        let adjusted = await PaymentsManager.shared.adjustedPriceForF1(basePrice: table.minimumSpend, date: date)
        await MainActor.run {
            effectiveMinimumSpend = adjusted != table.minimumSpend ? adjusted : nil
            isPricingLoading = false
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
