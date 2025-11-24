import SwiftUI
import Combine

struct QRCodeView: View {
    let qrCodeId: String
    let venueName: String
    let guestName: String
    let date: Date
    let ticket: EventTicket?
    
    @StateObject private var ticketManager = TicketManager()
    @State private var isAddingToWallet = false
    @State private var walletError: String?
    
    var body: some View {
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
            
            if let ticket {
                Button {
                    Task { await addToWallet(ticket) }
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
                
                if let walletError {
                    Text(walletError)
                        .font(Theme.Fonts.caption())
                        .foregroundColor(.red)
                }
            }
        }
        .padding(40)
        .background(Color.theme.background)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.5), radius: 20, x: 0, y: 10)
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
        } catch {
            await MainActor.run {
                walletError = error.localizedDescription
            }
        }
        
        await MainActor.run {
            isAddingToWallet = false
        }
    }
}
