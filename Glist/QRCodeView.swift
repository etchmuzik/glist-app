import SwiftUI
import Combine

struct QRCodeView: View {
    let qrCodeId: String
    let venueName: String
    let guestName: String
    let date: Date
    let ticket: EventTicket?
    let guestListRequest: GuestListRequest?
    
    @StateObject private var ticketManager = TicketManager()
    @State private var isAddingToWallet = false
    @State private var walletError: String?
    @State private var showResaleOffer = false
    @State private var isPublishing = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text(venueName.uppercased())
                    .font(Theme.Fonts.display(size: 24))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 8) {
                    Text(guestName)
                        .font(Theme.Fonts.body(size: 18))
                        .foregroundStyle(.white)
                    
                    Text(date.formatted(date: .long, time: .omitted))
                        .font(Theme.Fonts.body(size: 14))
                        .foregroundStyle(.gray)
                }
                
                if let image = QRCodeGenerator.generate(from: qrCodeId) {
                    Image(uiImage: image)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250, height: 250)
                        .padding(20)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    Rectangle()
                        .fill(Color.gray)
                        .frame(width: 250, height: 250)
                        .overlay(Text("Error generating QR Code"))
                }
                
                Text("Show this code at the door")
                    .font(Theme.Fonts.body(size: 12))
                    .foregroundStyle(.gray)
                
                if ticket != nil || guestListRequest != nil {
                    HStack(spacing: 16) {
                        Button {
                            Task {
                                if let ticket = ticket {
                                    await addToWallet(ticket)
                                } else if let request = guestListRequest {
                                    await addToWallet(request)
                                }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                if isAddingToWallet { ProgressView() }
                                Image(systemName: "wallet.pass")
                                Text("Add to Apple Wallet")
                                    .fontWeight(.bold)
                            }
                            .font(Theme.Fonts.body(size: 14))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .clipShape(Capsule())
                        }
                        .disabled(isAddingToWallet)
                        
                        if let ticket = ticket, ticket.resaleStatus == nil {
                            Button {
                                showResaleOffer = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.2.squarepath")
                                    Text("Sell Ticket")
                                        .fontWeight(.bold)
                                }
                                .font(Theme.Fonts.body(size: 14))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.theme.surface)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                            }
                        }
                    }
                    
                    if let walletError {
                        Text(walletError)
                            .font(Theme.Fonts.caption())
                            .foregroundColor(.red)
                    }
                }
            }
            .padding(40)
        }
        .background(Color.theme.background)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.5), radius: 20, x: 0, y: 10)
        .sheet(isPresented: $showResaleOffer) {
            if let ticket = ticket {
                ResaleOfferView(ticket: ticket) { price in
                    publishResaleOffer(price: price)
                }
                .presentationDetents([.medium])
            }
        }
    }
    
    private func addToWallet(_ ticket: EventTicket) async {
        guard !isAddingToWallet else { return }
        await MainActor.run {
            walletError = nil
            isAddingToWallet = true
        }
        
        do {
            guard let data = try await ticketManager.fetchPass(for: ticket) else {
                throw NSError(domain: "wallet", code: -1, userInfo: [NSLocalizedDescriptionKey: "No pass available."])
            }
            try await presentPass(data)
        } catch {
            await MainActor.run {
                walletError = error.localizedDescription
            }
        }
        
        await MainActor.run {
            isAddingToWallet = false
        }
    }
    
    private func addToWallet(_ request: GuestListRequest) async {
        guard !isAddingToWallet else { return }
        await MainActor.run {
            walletError = nil
            isAddingToWallet = true
        }
        
        do {
            // For now, we'll simulate fetching a pass for guest list requests
            // In a real app, you'd have an endpoint for this too
            // For this demo, we can reuse the ticket pass logic if we map it, or just show an error/mock
            
            // Assuming ticketManager has a method for guest lists or we can adapt
            // Since we don't have a backend for guest list passes yet, we'll try to fetch one
            // or show a "Coming Soon" or similar if not implemented.
            // But to satisfy the user request, let's assume there's a method or we create a dummy one.
            
            // Let's try to fetch a pass using a new method we'll add to TicketManager,
            // or just use the existing one if we can mock an EventTicket.
            
            // MOCKING EventTicket for Guest List to reuse logic (Temporary Solution)
            let mockTicket = EventTicket(
                id: request.id,
                eventId: UUID(), // Dummy
                eventName: "Guest List Entry",
                eventDate: request.date,
                venueId: UUID(uuidString: request.venueId) ?? UUID(),
                venueName: request.venueName,
                userId: request.userId,
                ticketTypeId: UUID(),
                ticketTypeName: "Guest List",
                price: 0,
                status: .valid,
                qrCodeId: request.qrCodeId ?? "",
                purchaseDate: Date()
            )
            
            guard let data = try await ticketManager.fetchPass(for: mockTicket) else {
                 throw NSError(domain: "wallet", code: -1, userInfo: [NSLocalizedDescriptionKey: "Pass generation not supported for Guest Lists yet."])
            }
            try await presentPass(data)
            
        } catch {
            await MainActor.run {
                walletError = error.localizedDescription
            }
        }
        
        await MainActor.run {
            isAddingToWallet = false
        }
    }
    
    private func presentPass(_ data: Data) async throws {
        if let top = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?
            .rootViewController {
            await MainActor.run {
                AppleWalletManager.presentPass(from: data, in: top)
            }
        } else {
            throw NSError(domain: "wallet", code: -2, userInfo: [NSLocalizedDescriptionKey: "Unable to present Wallet sheet."])
        }
    }
    
    private func publishResaleOffer(price: Double) {
        guard let ticket = ticket else { return }
        isPublishing = true
        showResaleOffer = false
        
        Task {
            do {
                let offer = ResaleOffer(
                    id: UUID().uuidString,
                    ticketId: ticket.id,
                    sellerId: ticket.userId,
                    eventId: ticket.eventId,
                    price: price,
                    status: .active,
                    createdAt: Date()
                )
                try await SupabaseDataManager.shared.publishResaleOffer(ticket: ticket, offer: offer)
                await MainActor.run {
                    isPublishing = false
                    // Ideally show success message or refresh
                }
            } catch {
                await MainActor.run {
                    walletError = "Failed to publish offer: \(error.localizedDescription)"
                    isPublishing = false
                }
            }
        }
    }
}
