import Foundation
import ActivityKit
import CoreMotion
import SwiftUI

/// Manager for Live Activities on lock screen showing real-time nightlife experiences
@available(iOS 16.1, *)
@MainActor
class LiveActivitiesManager {
    static let shared = LiveActivitiesManager()
    private let pedometer = CMPedometer()
    private var currentActivity: Activity<LSTDLiveActivityAttributes>?

    func isActivityActive() -> Bool {
        return currentActivity != nil
    }

    private init() {
        setupActivityTracking()
    }

    // MARK: - Live Activity Attributes & Content State

    /// Attributes for LSTD nightlife Live Activities
    struct LSTDLiveActivityAttributes: ActivityAttributes, Sendable {
        public struct ContentState: Codable, Hashable, Sendable {
            // Venue & Entertainment
            var currentSong: String
            var currentArtist: String
            var djName: String
            var crowdLevel: Int // 1-5 (ghost town to raging)
            var vipAlerts: [String]

            // User Activity Tracking
            var stepsDanced: Int
            var timeSpentDancing: TimeInterval
            var staminaScore: Double // 0-100 based on steps/time

            // The Experience
            var waitTimeMinutes: Int
            var queuePosition: Int?
            var tableReadyTime: Date?

            // Dynamic Offers (FOMO creation)
            var currentOffer: String?
            var offerValidUntil: Date?
            var celebritiesPresent: [String]
        }

        // Activity Identity
        let venueName: String
        let venueId: String
        let userName: String
    }

    /// Current state of the live activity
    private var currentContentState: LSTDLiveActivityAttributes.ContentState = .init(
        currentSong: "Loading...",
        currentArtist: "Loading...",
        djName: "DJ Loading...",
        crowdLevel: 3,
        vipAlerts: [],
        stepsDanced: 0,
        timeSpentDancing: 0,
        staminaScore: 0,
        waitTimeMinutes: 0,
        celebritiesPresent: []
    )

    // MARK: - Activity Lifecycle

    /// Start live activity when user enters venue
    func startVenueActivity(venueName: String, venueId: String, userName: String, checkInTime: Date = Date()) async throws {
        let attributes = LSTDLiveActivityAttributes(
            venueName: venueName,
            venueId: venueId,
            userName: userName
        )

        let initialContent = ActivityContent(
            state: currentContentState,
            staleDate: Date().addingTimeInterval(3600) // 1 hour
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: initialContent,
                pushType: .token
            )

            currentActivity = activity
            print("🎵 Live Activity started: \(venueName)")

            // Setup push token handling for real-time updates
            Task {
                for await tokenData in activity.pushTokenUpdates {
                    let token = tokenData.map { String(format: "%02x", $0) }.joined()
                    await sendPushTokenToVenue(venueId: venueId, token: token)
                }
            }

        } catch {
            print("❌ Failed to start Live Activity: \(error.localizedDescription)")
            throw error
        }
    }

    /// Update activity with new nightclub data
    func updateActivity(
        song: String? = nil,
        artist: String? = nil,
        dj: String? = nil,
        crowdLevel: Int? = nil,
        vipAlert: String? = nil,
        waitTime: Int? = nil,
        offer: String? = nil,
        celebrity: String? = nil
    ) async {
        guard let activity = currentActivity else { return }

        // Update state atomically
        if let song = song { currentContentState.currentSong = song }
        if let artist = artist { currentContentState.currentArtist = artist }
        if let dj = dj { currentContentState.djName = dj }
        if let crowdLevel = crowdLevel { currentContentState.crowdLevel = crowdLevel }
        if let vipAlert = vipAlert { currentContentState.vipAlerts.append(vipAlert) }
        if let waitTime = waitTime { currentContentState.waitTimeMinutes = waitTime }
        if let offer = offer {
            currentContentState.currentOffer = offer
            currentContentState.offerValidUntil = Date().addingTimeInterval(1800) // 30 min
        }
        if let celebrity = celebrity { currentContentState.celebritiesPresent.append(celebrity) }

        let updatedContent = ActivityContent(
            state: currentContentState,
            staleDate: Date().addingTimeInterval(1800) // 30 min
        )

        await activity.update(updatedContent)
        print("🔄 Live Activity updated with nightlife data")
    }

    /// End activity when user leaves venue
    func endActivity(summary: String? = nil) async {
        guard let activity = currentActivity else { return }

        let finalState = currentContentState
        let finalContent = ActivityContent(state: finalState, staleDate: nil)

        await activity.end(finalContent, dismissalPolicy: .immediate)
        currentActivity = nil
        stopActivityTracking()

        print("🏁 Live Activity ended - Night out complete! 🎉")
    }

    // MARK: - Core Motion Activity Tracking

    private func setupActivityTracking() {
        guard CMPedometer.isStepCountingAvailable() else {
            print("⚠️ Pedometer not available on this device")
            return
        }

        pedometer.startUpdates(from: Date()) { [weak self] pedometerData, error in
            guard let self = self, let pedometerData = pedometerData else { return }

            let steps = pedometerData.numberOfSteps.intValue
            let timeSpent = Date().timeIntervalSince(pedometerData.startDate)

            // Calculate stamina score (simplified algorithm)
            let staminaScore = min(100.0, Double(steps) / 10.0 + timeSpent / 360.0)

            Task {
                await self.updateActivity(steps: steps, timeSpent: timeSpent, stamina: staminaScore)
            }
        }

        print("🏃‍♂️ Started nightclub activity tracking")
    }

    private func updateActivity(steps: Int, timeSpent: TimeInterval, stamina: Double) async {
        guard let activity = currentActivity else { return }

        currentContentState.stepsDanced = steps
        currentContentState.timeSpentDancing = timeSpent
        currentContentState.staminaScore = stamina

        let content = ActivityContent(state: currentContentState, staleDate: nil)
        await activity.update(content)
    }

    private func stopActivityTracking() {
        pedometer.stopUpdates()
        print("⏹️ Stopped activity tracking")
    }

    // MARK: - Server Integration

    /// Send push token to venue's server for live updates
    private func sendPushTokenToVenue(venueId: String, token: String) async {
        // In production: Send to LSTD backend to enable push-to-activity updates
        // Venue can push: song changes, VIP alerts, offers, celebrity arrivals

        print("📡 Push token registered with venue: \(venueId)")
        // TODO: POST to /venues/{id}/liveActivityTokens
    }

    /// Handle push notifications that update the activity
    func handlePushUpdate(_ userInfo: [AnyHashable: Any]) async {
        guard let updateType = userInfo["type"] as? String else { return }

        switch updateType {
        case "song_change":
            if let songData = userInfo["songData"] as? [String: Any],
               let song = songData["title"] as? String,
               let artist = songData["artist"] as? String {
                await updateActivity(song: song, artist: artist)
            }

        case "dj_change":
            if let dj = userInfo["djName"] as? String {
                await updateActivity(dj: dj)
            }

        case "crowd_level":
            if let level = userInfo["level"] as? Int {
                await updateActivity(crowdLevel: level)
            }

        case "vip_alert":
            if let alert = userInfo["message"] as? String {
                await updateActivity(vipAlert: alert)
            }

        case "celebrity_alert":
            if let celebrity = userInfo["name"] as? String {
                await updateActivity(celebrity: celebrity)
            }

        case "special_offer":
            if let offer = userInfo["offer"] as? String {
                await updateActivity(offer: offer)
            }

        case "queue_update":
            // TODO: Handle queue position updates by adding queuePosition to content state and updating activity
            break

        default:
            print("🔔 Unknown push update type: \(updateType)")
        }
    }
}
