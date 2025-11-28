import SwiftUI

// MARK: - App Clip Ticket Option & Selection View

public struct AppClipTicketOption: Identifiable, Equatable {
    public let id = UUID()
    public let name: String
    public let phase: String
    public let price: Double
    public init(name: String, phase: String, price: Double) {
        self.name = name
        self.phase = phase
        self.price = price
    }
}

public struct AppClipTicketSelectionView: View {
    @Binding var selectedTicket: AppClipTicketOption?
    let onContinue: (AppClipTicketOption) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var quantity: Int = 1
    private let serviceFeeRate: Double = 0.05
    private let processingFee: Double = 3.0

    private let ticketOptions: [AppClipTicketOption] = [
        AppClipTicketOption(name: "GA Early Bird", phase: "Early Bird", price: 150),
        AppClipTicketOption(name: "GA", phase: "General Admission", price: 200),
        AppClipTicketOption(name: "VIP Presale", phase: "Presale", price: 350),
        AppClipTicketOption(name: "VIP", phase: "General Admission", price: 450)
    ]

    private var subtotal: Double {
        (selectedTicket?.price ?? 0) * Double(quantity)
    }

    private var serviceFee: Double {
        subtotal * serviceFeeRate
    }

    private var total: Double {
        subtotal + serviceFee + processingFee
    }

    public init(selectedTicket: Binding<AppClipTicketOption?>, onContinue: @escaping (AppClipTicketOption) -> Void) {
        self._selectedTicket = selectedTicket
        self.onContinue = onContinue
    }

    public var body: some View {
        NavigationView {
            VStack {
                List(ticketOptions) { ticket in
                    Button {
                        selectedTicket = ticket
                        quantity = 1
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(ticket.name)
                                    .font(Theme.Fonts.body(size: 16, weight: .semibold))
                                    .foregroundStyle(.white)

                                Text(ticket.phase)
                                    .font(Theme.Fonts.body(size: 12))
                                    .foregroundStyle(Color.theme.accent.opacity(0.8))
                            }
                            Spacer()
                            Text(CurrencyFormatter.aed(ticket.price))
                                .font(Theme.Fonts.body(size: 14, weight: .semibold))
                                .foregroundStyle(Color.theme.accent)

                            if selectedTicket == ticket {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.theme.accent)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowBackground(Color.theme.surface.opacity(0.3))
                }
                .listStyle(.plain)
                .background(Color.theme.background)
                .scrollContentBackground(.hidden)

                if selectedTicket != nil {
                    // Quantity selector
                    HStack {
                        Text("Quantity")
                            .font(Theme.Fonts.body(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                        Spacer()
                        Stepper(value: $quantity, in: 1...10) {
                            Text("\(quantity)")
                                .font(Theme.Fonts.body(size: 16, weight: .semibold))
                                .foregroundStyle(Color.theme.accent)
                                .frame(minWidth: 24)
                        }
                        .labelsHidden()
                    }
                    .padding(16)
                    .background(Color.theme.surface.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                    // Fee breakdown
                    VStack(spacing: 8) {
                        HStack {
                            Text("Subtotal")
                                .font(Theme.Fonts.body(size: 14))
                                .foregroundStyle(.gray)
                            Spacer()
                            Text(CurrencyFormatter.aed(subtotal))
                                .font(Theme.Fonts.body(size: 14))
                                .foregroundStyle(.gray)
                        }
                        HStack {
                            Text("Service Fee (5%)")
                                .font(Theme.Fonts.body(size: 14))
                                .foregroundStyle(.gray)
                            Spacer()
                            Text(CurrencyFormatter.aed(serviceFee))
                                .font(Theme.Fonts.body(size: 14))
                                .foregroundStyle(.gray)
                        }
                        HStack {
                            Text("Processing")
                                .font(Theme.Fonts.body(size: 14))
                                .foregroundStyle(.gray)
                            Spacer()
                            Text(CurrencyFormatter.aed(processingFee))
                                .font(Theme.Fonts.body(size: 14))
                                .foregroundStyle(.gray)
                        }
                        Divider()
                            .background(Color.theme.accent)
                        HStack {
                            Text("Total")
                                .font(Theme.Fonts.body(size: 16, weight: .semibold))
                                .foregroundStyle(Color.theme.accent)
                            Spacer()
                            Text(CurrencyFormatter.aed(total))
                                .font(Theme.Fonts.body(size: 16, weight: .semibold))
                                .foregroundStyle(Color.theme.accent)
                        }
                    }
                    .padding(16)
                    .background(Color.theme.surface.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                }

                Button {
                    if let ticket = selectedTicket {
                        let confirmed = AppClipTicketOption(name: ticket.name, phase: ticket.phase, price: total)
                        onContinue(confirmed)
                        dismiss()
                    }
                } label: {
                    Text(selectedTicket != nil ? "Continue – \(CurrencyFormatter.aed(total))" : "Continue with Apple Pay")
                        .font(Theme.Fonts.body(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(selectedTicket != nil ? Color.theme.accent : Color.theme.accent.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                }
                .disabled(selectedTicket == nil)
            }
            .navigationTitle("Select Ticket")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.theme.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Color.theme.accent)
                }
            }
        }
    }
}

#Preview("App Clip Ticket Selection") {
    // Local wrapper to host @State for the binding
    struct PreviewHost: View {
        @State private var selected: AppClipTicketOption? = nil
        var body: some View {
            AppClipTicketSelectionView(selectedTicket: $selected) { _ in }
                .environment(\.colorScheme, .dark)
                .background(Color.theme.background)
        }
    }
    return PreviewHost()
}
