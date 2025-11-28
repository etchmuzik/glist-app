import Foundation
import Combine
import StripePaymentSheet
import Supabase

enum PaymentStatus: Equatable, Sendable {
    case idle
    case preparing
    case ready
    case processing
    case success(transactionId: String)
    case failed(error: String)
}

enum PaymentMethod: Sendable {
    case applePay
    case creditCard
}

@MainActor
class PaymentManager: ObservableObject {
    static let shared = PaymentManager()
    @Published var status: PaymentStatus = .idle
    @Published var paymentSheet: PaymentSheet?
    @Published var paymentResult: PaymentSheetResult?
    private var currentTransactionId: String?

    
    // Prepare PaymentSheet by calling backend
    public func preparePaymentSheet(venueId: String, tableId: String?, amount: Double, currency: String = "aed", deposit: Bool = true) async throws {
        self.status = .preparing
        
        // 1. Call Supabase Edge Function to create PaymentIntent
        let body: [String: GlistAnyEncodable] = [
            "venueId": GlistAnyEncodable(venueId),
            "tableId": GlistAnyEncodable(tableId ?? ""),
            "amount": GlistAnyEncodable(amount),
            "currency": GlistAnyEncodable(currency),
            "deposit": GlistAnyEncodable(deposit)
        ]
        
        do {
            let result: PaymentIntentResponse = try await SupabaseManager.shared.client.functions.invoke("create-payment-intent", options: .init(body: body))
            
            self.currentTransactionId = result.transactionId
            STPAPIClient.shared.publishableKey = result.publishableKey
            
            var configuration = PaymentSheet.Configuration()
            configuration.merchantDisplayName = "Glist"
            configuration.customer = .init(id: result.customer, ephemeralKeySecret: result.ephemeralKey)
            configuration.allowsDelayedPaymentMethods = true
            configuration.applePay = .init(merchantId: "merchant.com.glist", merchantCountryCode: "AE")
            
            self.paymentSheet = PaymentSheet(paymentIntentClientSecret: result.paymentIntent, configuration: configuration)
            self.status = .ready
            
        } catch {
            print("Error preparing payment sheet: \(error)")
            self.status = .failed(error: error.localizedDescription)
            throw error
        }
    }

    
    func onPaymentCompletion(result: PaymentSheetResult) {
        self.paymentResult = result
        
        switch result {
        case .completed:
            self.status = .success(transactionId: self.currentTransactionId ?? "unknown")
        case .canceled:
            self.status = .idle
        case .failed(let error):
            self.status = .failed(error: error.localizedDescription)
        }
    }
    
    func reset() {
        status = .idle
        paymentSheet = nil
        paymentResult = nil
    }
}

private struct PaymentIntentResponse: Decodable, Sendable {
    let paymentIntent: String
    let publishableKey: String
    let customer: String
    let ephemeralKey: String
    let transactionId: String
}

enum PaymentError: LocalizedError, Sendable {
    case paymentDeclined
    case networkError
    case invalidAmount
    
    var errorDescription: String? {
        switch self {
        case .paymentDeclined:
            return "Payment was declined. Please try another payment method."
        case .networkError:
            return "Network error. Please check your connection and try again."
        case .invalidAmount:
            return "Invalid payment amount."
        }
    }
}


