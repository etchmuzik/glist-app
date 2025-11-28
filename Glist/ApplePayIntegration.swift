import SwiftUI
import StripePaymentSheet

struct TicketCheckoutView: View {
    let venueId: String
    let venueName: String
    let amount: Double
    let description: String
    let onSuccess: () -> Void
    let onCancel: () -> Void

    @ObservedObject var paymentManager = PaymentManager.shared
    @State private var showPaymentSheet = false
    @State private var errorMessage: String?

    var body: some View {
        if let paymentSheet = paymentManager.paymentSheet {
            content
                .paymentSheet(isPresented: $showPaymentSheet, paymentSheet: paymentSheet, onCompletion: paymentManager.onPaymentCompletion)
        } else {
            content
        }
    }

    private var content: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text("Complete Payment")
                    .font(Theme.Fonts.display(size: 24))
                    .foregroundStyle(.white)

                Text("Secure payment via Stripe")
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
            }

            // Payment Summary
            VStack(alignment: .leading, spacing: 16) {
                Text("Payment Summary")
                    .font(Theme.Fonts.body(size: 18, weight: .semibold))
                    .foregroundStyle(.white)

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(description)
                            .foregroundStyle(.gray)
                        Text(venueName)
                            .font(Theme.Fonts.body(size: 12))
                            .foregroundStyle(.gray.opacity(0.7))
                    }
                    Spacer()
                    Text(CurrencyFormatter.aed(amount))
                        .font(Theme.Fonts.display(size: 20))
                        .foregroundStyle(Color.theme.accent)
                }
            }
            .padding(20)
            .background(Color.theme.surface.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Status / Action
            if paymentManager.status == .preparing {
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(.white)
                    Text("Preparing payment...")
                        .foregroundStyle(.gray)
                }
                .frame(height: 80)
            } else if case .failed(let error) = paymentManager.status {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                        .font(.system(size: 24))
                    Text(error)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                    Button("Try Again") {
                        paymentManager.reset()
                        preparePayment()
                    }
                    .font(Theme.Fonts.body(size: 14))
                    .foregroundStyle(Color.theme.accent)
                }
                .frame(height: 100)
            } else {
                // Pay Button
                Button {
                    if paymentManager.status == .ready {
                        showPaymentSheet = true
                    } else {
                        preparePayment()
                    }
                } label: {
                    HStack {
                        Image(systemName: "creditcard.fill")
                        Text("Pay Now")
                    }
                    .font(Theme.Fonts.body(size: 16))
                    .fontWeight(.bold)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.white)
                    .clipShape(Capsule())
                }
                
                Text("Supports Apple Pay and Cards")
                    .font(Theme.Fonts.body(size: 12))
                    .foregroundStyle(.gray.opacity(0.7))
            }
        }
        .padding(24)
        .onAppear {
            preparePayment()
        }
        .onChange(of: paymentManager.status) { _, newStatus in
            if case .ready = newStatus {
                showPaymentSheet = true
            } else if case .success = newStatus {
                onSuccess()
            }
        }
    }

    private func preparePayment() {
        Task {
            do {
                try await paymentManager.preparePaymentSheet(
                    venueId: venueId,
                    tableId: nil, // Tickets don't have tableId
                    amount: amount,
                    currency: "aed",
                    deposit: false // Full payment for tickets usually
                )
            } catch {
                print("Failed to prepare payment: \(error)")
            }
        }
    }
}

// MARK: - Integration Examples

extension TicketCheckoutView {
    // Example for table reservations
    static func forBooking(venue: Venue, booking: Booking, onSuccess: @escaping () -> Void, onCancel: @escaping () -> Void) -> some View {
        TicketCheckoutView(
            venueId: venue.id.uuidString,
            venueName: venue.name,
            amount: booking.depositAmount,
            description: "Table reservation - \(booking.tableName)",
            onSuccess: onSuccess,
            onCancel: onCancel
        )
    }

    // Example for drink orders
    static func forDrinks(venueId: String, venueName: String, drinks: [(String, Double)], onSuccess: @escaping () -> Void, onCancel: @escaping () -> Void) -> some View {
        let totalAmount = drinks.reduce(0) { $0 + $1.1 }
        let description = drinks.count == 1 ? drinks[0].0 : "\(drinks.count) drinks"
        return TicketCheckoutView(
            venueId: venueId,
            venueName: venueName,
            amount: totalAmount,
            description: description,
            onSuccess: onSuccess,
            onCancel: onCancel
        )
    }
}

struct ApplePayButtonView: View {
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "apple.logo")
                Text("Pay with Apple Pay")
            }
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.white)
            .cornerRadius(8)
        }
    }
}
