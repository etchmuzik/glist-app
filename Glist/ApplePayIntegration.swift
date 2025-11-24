import SwiftUI
import PassKit

// MARK: - Apple Pay Button View
struct ApplePayButtonView: UIViewRepresentable {
    let action: () -> Void

    func makeUIView(context: Context) -> UIView {
        let paymentButton = PKPaymentButton(paymentButtonType: .buy, paymentButtonStyle: .black)
        paymentButton.addTarget(context.coordinator, action: #selector(Coordinator.tapped), for: .touchUpInside)
        return paymentButton
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }

    class Coordinator {
        let action: () -> Void
        init(action: @escaping () -> Void) {
            self.action = action
        }
        @objc func tapped() {
            action()
        }
    }
}

// MARK: - Apple Pay Checkout View
struct ApplePayCheckoutView: View {
    let venueName: String
    let amount: Double
    let description: String
    let onSuccess: () -> Void
    let onCancel: () -> Void

    @State private var isProcessingPayment = false
    @State private var errorMessage: String?
    @State private var paymentController: PKPaymentAuthorizationViewController?

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text("Complete Payment")
                    .font(Theme.Fonts.display(size: 24))
                    .foregroundStyle(.white)

                Text("Secure payment powered by Apple Pay")
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

            // Processing Indicator
            if isProcessingPayment {
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(.white)
                    Text("Processing your payment...")
                        .foregroundStyle(.gray)
                }
                .frame(height: 80)
            } else if let error = errorMessage {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                        .font(.system(size: 24))
                    Text(error)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }
                .frame(height: 80)
            } else {
                // Apple Pay Button
                ApplePayButtonView {
                    startApplePayPayment()
                }
                .frame(height: 48)
                .clipShape(Capsule())

                Text("Your payment information is secure and encrypted")
                    .font(Theme.Fonts.body(size: 12))
                    .foregroundStyle(.gray.opacity(0.7))
            }
        }
        .padding(24)
    }

    private func createPaymentRequest() -> PKPaymentRequest {
        let request = PKPaymentRequest()
        request.merchantIdentifier = "merchant.com.glist" // Replace with your actual merchant ID
        request.supportedNetworks = [.visa, .masterCard, .amex]
        request.merchantCapabilities = .capability3DS
        request.countryCode = "AE"
        request.currencyCode = "AED"
        request.requiredBillingContactFields = [.name, .emailAddress]

        let paymentItem = PKPaymentSummaryItem(label: description, amount: NSDecimalNumber(value: amount))
        let totalItem = PKPaymentSummaryItem(label: "LSTD", amount: NSDecimalNumber(value: amount))
        request.paymentSummaryItems = [paymentItem, totalItem]

        return request
    }

    private func startApplePayPayment() {
        guard PKPaymentAuthorizationViewController.canMakePayments() else {
            errorMessage = "Apple Pay is not available on this device. Please set up Apple Pay in your Wallet app."
            return
        }

        let request = createPaymentRequest()

        guard let paymentVC = PKPaymentAuthorizationViewController(paymentRequest: request) else {
            errorMessage = "Unable to initialize Apple Pay. Please try again."
            return
        }

        paymentVC.delegate = PaymentCoordinator(onSuccess: onSuccess, onCancel: onCancel)
        self.paymentController = paymentVC

        // Present the payment controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(paymentVC, animated: true)
        }
    }
}

// MARK: - Payment Coordinator
class PaymentCoordinator: NSObject, PKPaymentAuthorizationViewControllerDelegate {
    let onSuccess: () -> Void
    let onCancel: () -> Void

    init(onSuccess: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.onSuccess = onSuccess
        self.onCancel = onCancel
    }

    func paymentAuthorizationViewController(
        _ controller: PKPaymentAuthorizationViewController,
        didAuthorizePayment payment: PKPayment,
        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
    ) {
        // Simulate payment processing
        // In production, you'd integrate with Stripe, Adyen, or your payment processor
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // Simulate success 90% of the time for demo
            if Int.random(in: 1...10) != 1 {
                completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
                DispatchQueue.main.async {
                    self.onSuccess()
                }
            } else {
                let error = NSError(domain: "PaymentError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Payment declined"])
                completion(PKPaymentAuthorizationResult(status: .failure, errors: [error]))
                DispatchQueue.main.async {
                    self.onCancel()
                }
            }
        }
    }

    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        controller.dismiss(animated: true)
        onCancel()
    }
}

// MARK: - Integration Examples

extension ApplePayCheckoutView {
    // Example for table reservations
    static func forBooking(venue: Venue, booking: Booking, onSuccess: @escaping () -> Void, onCancel: @escaping () -> Void) -> some View {
        ApplePayCheckoutView(
            venueName: venue.name,
            amount: booking.depositAmount,
            description: "Table reservation - \(booking.tableName)",
            onSuccess: onSuccess,
            onCancel: onCancel
        )
    }

    // Example for drink orders
    static func forDrinks(venueName: String, drinks: [(String, Double)], onSuccess: @escaping () -> Void, onCancel: @escaping () -> Void) -> some View {
        let totalAmount = drinks.reduce(0) { $0 + $1.1 }
        let description = drinks.count == 1 ? drinks[0].0 : "\(drinks.count) drinks"
        return ApplePayCheckoutView(
            venueName: venueName,
            amount: totalAmount,
            description: description,
            onSuccess: onSuccess,
            onCancel: onCancel
        )
    }
}
