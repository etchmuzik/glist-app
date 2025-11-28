import Foundation
import ShazamKit
import AVFoundation
import SwiftUI
import Combine

class MusicRecognitionManager: NSObject, ObservableObject, SHSessionDelegate {
    @Published var isRecording = false
    @Published var matchedMediaItem: SHMediaItem?
    @Published var error: Error?
    
    private var session: SHSession?
    private let audioEngine = AVAudioEngine()
    
    override init() {
        super.init()
        // Initialize session
        session = SHSession()
        session?.delegate = self
    }
    
    func startRecognition() {
        guard !audioEngine.isRunning else { return }
        
        // Request permission
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            guard granted else {
                DispatchQueue.main.async {
                    self?.error = NSError(domain: "MusicRecognition", code: 1, userInfo: [NSLocalizedDescriptionKey: "Microphone permission denied"])
                }
                return
            }
            
            self?.startAudioEngine()
        }
    }
    
    private func startAudioEngine() {
        do {
            // Setup Audio Session
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            // Setup Input Node
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
                self?.session?.matchStreamingBuffer(buffer, at: when)
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            
            DispatchQueue.main.async {
                self.isRecording = true
                self.matchedMediaItem = nil
                self.error = nil
            }
        } catch {
            DispatchQueue.main.async {
                self.error = error
            }
        }
    }
    
    func stopRecognition() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        DispatchQueue.main.async {
            self.isRecording = false
        }
    }
    
    // MARK: - SHSessionDelegate
    
    func session(_ session: SHSession, didFind match: SHMatch) {
        DispatchQueue.main.async {
            if let mediaItem = match.mediaItems.first {
                print("🎵 Shazam Match Found: \(mediaItem.title ?? "Unknown") by \(mediaItem.artist ?? "Unknown")")
                self.matchedMediaItem = mediaItem
                self.stopRecognition() // Stop after finding a match
            }
        }
    }
    
    func session(_ session: SHSession, didNotFindMatchFor signature: SHSignature, error: Error?) {
        DispatchQueue.main.async {
            if let error = error {
                // Ignore "Signature not found" errors as they happen frequently while listening
                // Only report actual errors or if we want to show "No match found" after a timeout
                print("❌ Shazam match error: \(error.localizedDescription)")
                // Only set self.error for non-signature errors or specific cases
                // self.error = error 
            } else {
                print("⚠️ Shazam: No match found for current signature")
            }
        }
    }
}
