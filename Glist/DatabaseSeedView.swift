import SwiftUI

struct DatabaseSeedView: View {
    @EnvironmentObject var venueManager: VenueManager
    @State private var isSeeding = false
    @State private var seedComplete = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.background.ignoresSafeArea()
                
                VStack(spacing: 32) {
                    Image(systemName: "cylinder.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.white)
                    
                    Text("DATABASE SETUP")
                        .font(Theme.Fonts.display(size: 24))
                        .foregroundStyle(.white)
                    
                    if seedComplete {
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(.green)
                            
                            Text("Database Seeded!")
                                .font(Theme.Fonts.body(size: 16))
                                .foregroundStyle(.white)
                            
                            Text("All Dubai venues have been added to Firestore.")
                                .font(Theme.Fonts.body(size: 14))
                                .foregroundStyle(.gray)
                                .multilineTextAlignment(.center)
                        }
                    } else {
                        VStack(spacing: 16) {
                            Text("Your Firestore database is empty. Seed it with Dubai venues to get started.")
                                .font(Theme.Fonts.body(size: 14))
                                .foregroundStyle(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                            
                            if let error = errorMessage {
                                Text(error)
                                    .font(Theme.Fonts.body(size: 12))
                                    .foregroundStyle(.red)
                                    .padding(.horizontal, 32)
                            }
                            
                            Button {
                                seedDatabase()
                            } label: {
                                if isSeeding {
                                    ProgressView()
                                        .tint(.black)
                                } else {
                                    Text("SEED DATABASE")
                                        .font(Theme.Fonts.body(size: 14))
                                        .fontWeight(.bold)
                                        .tracking(2)
                                }
                            }
                            .foregroundStyle(.black)
                            .frame(width: 200, height: 50)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .disabled(isSeeding)
                        }
                    }
                }
            }
            .navigationTitle("Setup")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func seedDatabase() {
        isSeeding = true
        errorMessage = nil
        
        Task {
            do {
                try await venueManager.seedDatabase()
                await MainActor.run {
                    isSeeding = false
                    seedComplete = true
                }
            } catch {
                await MainActor.run {
                    isSeeding = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    DatabaseSeedView()
        .environmentObject(VenueManager())
}
