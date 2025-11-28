import SwiftUI
import ShazamKit

struct MusicScannerView: View {
    @StateObject private var recognitionManager = MusicRecognitionManager()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Background Ambient Glow
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 300, height: 300)
                .blur(radius: 100)
                .offset(x: -100, y: -200)
            
            Circle()
                .fill(Color.purple.opacity(0.2))
                .frame(width: 300, height: 300)
                .blur(radius: 100)
                .offset(x: 100, y: 200)
            
            VStack(spacing: 40) {
                // Header
                HStack {
                    Spacer()
                    Button {
                        recognitionManager.stopRecognition()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                .padding()
                
                Spacer()
                
                // Result or Status
                if let item = recognitionManager.matchedMediaItem {
                    VStack(spacing: 20) {
                        AsyncImage(url: item.artworkURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.gray.opacity(0.3)
                        }
                        .frame(width: 250, height: 250)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.5), radius: 30, x: 0, y: 10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        
                        VStack(spacing: 8) {
                            Text(item.title ?? "Unknown Track")
                                .font(Theme.Fonts.display(size: 28))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                            
                            Text(item.artist ?? "Unknown Artist")
                                .font(Theme.Fonts.body(size: 20))
                                .foregroundStyle(.gray)
                        }
                        .padding(.top, 10)
                        
                        if let appleMusicURL = item.appleMusicURL {
                            Link(destination: appleMusicURL) {
                                HStack {
                                    Image(systemName: "apple.logo")
                                    Text("Listen on Apple Music")
                                }
                                .font(Theme.Fonts.body(size: 16))
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 16)
                                .background(Color.red)
                                .clipShape(Capsule())
                            }
                        }
                        
                        Button {
                            recognitionManager.startRecognition()
                        } label: {
                            Text("Scan Again")
                                .font(Theme.Fonts.body(size: 16))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .padding(.top)
                    }
                    .transition(.opacity.combined(with: .scale))
                } else {
                    VStack(spacing: 40) {
                        // Pulse Animation
                        ZStack {
                            if recognitionManager.isRecording {
                                Circle()
                                    .stroke(Color.blue.opacity(0.5), lineWidth: 2)
                                    .frame(width: 200, height: 200)
                                    .scaleEffect(1.5)
                                    .opacity(0)
                                    .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false), value: recognitionManager.isRecording)
                                
                                Circle()
                                    .stroke(Color.purple.opacity(0.3), lineWidth: 2)
                                    .frame(width: 200, height: 200)
                                    .scaleEffect(2)
                                    .opacity(0)
                                    .animation(.easeOut(duration: 2).repeatForever(autoreverses: false).delay(0.5), value: recognitionManager.isRecording)
                            }
                            
                            Button {
                                if recognitionManager.isRecording {
                                    recognitionManager.stopRecognition()
                                } else {
                                    recognitionManager.startRecognition()
                                }
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.blue, Color.purple],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 140, height: 140)
                                        .shadow(color: Color.blue.opacity(0.5), radius: 30, x: 0, y: 0)
                                    
                                    Image(systemName: "shazam.logo.fill")
                                        .font(.system(size: 60))
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                        
                        VStack(spacing: 8) {
                            Text(recognitionManager.isRecording ? "Listening..." : "Tap to Shazam")
                                .font(Theme.Fonts.display(size: 24))
                                .foregroundStyle(.white)
                            
                            Text("Discover music playing around you")
                                .font(Theme.Fonts.body(size: 14))
                                .foregroundStyle(.gray)
                        }
                        
                        if let error = recognitionManager.error {
                            Text(error.localizedDescription)
                                .font(Theme.Fonts.body(size: 14))
                                .foregroundStyle(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                }
                
                Spacer()
            }
        }
        .onAppear {
            // Optionally auto-start
            // recognitionManager.startRecognition()
        }
        .onDisappear {
            recognitionManager.stopRecognition()
        }
    }
}
