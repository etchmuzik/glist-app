import SwiftUI
import Combine

struct QRCodeView: View {
    let qrCodeId: String
    let venueName: String
    let guestName: String
    let date: Date
    
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
}
