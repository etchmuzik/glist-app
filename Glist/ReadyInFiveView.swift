import SwiftUI

struct ReadyInFiveInfo {
    let venueName: String
    let dressCode: String
    let parking: String
    let hostContact: String
    let mapURL: URL?
}

struct ReadyInFiveView: View {
    let info: ReadyInFiveInfo
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("You're up next")
                    .font(Theme.Fonts.display(size: 24))
                    .foregroundColor(Color.theme.accent)
                Text("Be at \(info.venueName) in 5 minutes to keep your spot.")
                    .font(Theme.Fonts.body(size: 14))
                    .foregroundColor(.theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Label(info.dressCode, systemImage: "checkmark.shield")
                    .font(Theme.Fonts.body(size: 14))
                    .foregroundColor(.theme.textPrimary)
                Label("Parking: \(info.parking)", systemImage: "car.fill")
                    .font(Theme.Fonts.body(size: 14))
                    .foregroundColor(.theme.textPrimary)
                Label("Host: \(info.hostContact)", systemImage: "person.fill")
                    .font(Theme.Fonts.body(size: 14))
                    .foregroundColor(.theme.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.theme.surface.opacity(0.6))
            .cornerRadius(12)
            
            if let mapURL = info.mapURL {
                Link("Open Map", destination: mapURL)
                    .font(Theme.Fonts.bodyBold(size: 14))
                    .foregroundColor(Color.theme.accent)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.theme.accent.opacity(0.1))
                    .cornerRadius(12)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.theme.background.ignoresSafeArea())
    }
}
