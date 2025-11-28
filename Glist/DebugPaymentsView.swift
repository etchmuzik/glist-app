import SwiftUI

struct DebugPaymentsView: View {
    @State private var basePrice: Double = 100.0
    @State private var amountAED: String = "0"
    @State private var selectedProvider: PaymentsManager.BNPLProvider = .tabby
    @State private var venueId: String = ""
    @State private var userId: String = ""
    @State private var selectedDate: Date = {
        var components = DateComponents()
        components.year = 2025
        components.month = 11
        components.day = 29
        components.hour = 20
        return Calendar.current.date(from: components) ?? Date()
    }()
    
    @State private var adjustedPrice: Double?
    @State private var depositResult: String = ""
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Inputs")) {
                    HStack {
                        Text("Base Price:")
                        Spacer()
                        TextField("Base Price", value: $basePrice, formatter: NumberFormatter.currencyFormatter)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    TextField("Amount AED", text: $amountAED)
                        .keyboardType(.decimalPad)
                    Picker("BNPL Provider", selection: $selectedProvider) {
                        ForEach(PaymentsManager.BNPLProvider.allCases, id: \.self) { provider in
                            Text(provider.rawValue.capitalized).tag(provider)
                        }
                    }
                    TextField("Venue ID", text: $venueId)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    TextField("User ID", text: $userId)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    DatePicker("Booking Date", selection: $selectedDate, displayedComponents: .date)
                }
                
                Section {
                    Button("Adjust Price for F1") {
                        Task {
                            adjustedPrice = await PaymentsManager.shared.adjustedPriceForF1(basePrice: basePrice, date: selectedDate)
                        }
                    }
                    if let adjustedPrice = adjustedPrice {
                        Text("Adjusted Price: AED \(adjustedPrice, specifier: "%.2f")")
                    }
                }
                
                Section {
                    Button("Simulate BNPL Deposit") {
                        guard let amount = Double(amountAED), !venueId.isEmpty, !userId.isEmpty else {
                            alertMessage = "Please enter valid Amount AED, Venue ID and User ID."
                            showAlert = true
                            return
                        }
                        
                        Task {
                            do {
                                let request = PaymentsManager.DepositRequest(
                                    amountAED: Decimal(amount),
                                    userId: userId,
                                    venueId: venueId,
                                    tableId: nil,
                                    provider: selectedProvider
                                )
                                let (deposit, redirectUrl) = try await PaymentsManager.shared.initiateBNPLDeposit(request: request)
                                try await PaymentsManager.shared.recordDeposit(deposit)
                                await MainActor.run {
                                    let idText = deposit.id ?? "new deposit"
                                    var resultText = "Deposit Success: \(idText)"
                                    if let url = redirectUrl {
                                        resultText += "\nRedirect URL: \(url.absoluteString)"
                                        // In a real app, you would open this URL
                                        UIApplication.shared.open(url)
                                    }
                                    depositResult = resultText
                                }
                        } catch {
                            await MainActor.run {
                                depositResult = "Deposit Failed: \(error.localizedDescription)"
                            }
                            }
                        }
                    }
                    if !depositResult.isEmpty {
                        Text(depositResult)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .navigationTitle("Debug Payments")
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
}

extension NumberFormatter {
    static var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter
    }
}

#Preview {
    DebugPaymentsView()
}
