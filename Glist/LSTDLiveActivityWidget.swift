import SwiftUI
import WidgetKit

/// Live Activity widget for displaying nightclub experiences on lock screen
@available(iOS 16.1, *)
struct LSTDLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveActivitiesManager.LSTDLiveActivityAttributes.self) { context in
            // Lock screen/banner UI
            LSTDLockScreenActivityView(context: context)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded
                DynamicIslandExpandedRegion(.leading) {
                    Text("🎵")
                        .font(.title2)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .leading) {
                        Text(context.state.currentSong)
                            .font(.caption)
                            .lineLimit(1)
                        Text("DJ \(context.state.djName)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    HStack(spacing: 8) {
                        VStack(spacing: 2) {
                            Image(systemName: "figure.walk")
                                .font(.caption)
                            Text("\(context.state.stepsDanced)")
                                .font(.caption2)
                        }
                        if !context.state.vipAlerts.isEmpty {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                        }
                        if context.state.currentOffer != nil {
                            Image(systemName: "tag.fill")
                                .foregroundStyle(.green)
                        }
                    }
                }
            } compactLeading: {
                Text("🎵")
            } compactTrailing: {
                Text("\(context.state.stepsDanced)")
            } minimal: {
                Text("🎵")
            }
        }
    }
}

// MARK: - Lock Screen Activity View

@available(iOS 16.1, *)
struct LSTDLockScreenActivityView: View {
    let context: ActivityViewContext<LiveActivitiesManager.LSTDLiveActivityAttributes>

    var body: some View {
        ZStack {
            // Background gradient based on crowd level
            LinearGradient(
                gradient: crowdLevelGradient(),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            HStack(spacing: 16) {
                // Left side - Music info
                VStack(alignment: .leading, spacing: 4) {
                    Text("🎵 \(context.state.currentSong)")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text("by \(context.state.currentArtist)")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(1)

                    HStack(spacing: 12) {
                        Text("DJ \(context.state.djName)")
                            .font(.caption)
                            .foregroundStyle(Color.theme.accent)

                        // Crowd indicator
                        HStack(spacing: 2) {
                            ForEach(1..<6) { level in
                                RoundedRectangle(cornerRadius: 1)
                                    .frame(width: 6, height: 2)
                                    .foregroundStyle(
                                        level <= context.state.crowdLevel ?
                                        Color.theme.accent : .white.opacity(0.3)
                                    )
                            }
                        }
                    }
                }

                Spacer()

                // Right side - User activity & VIP alerts
                VStack(alignment: .trailing, spacing: 6) {
                    // Activity tracking
                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: 4) {
                            Image(systemName: "figure.walk")
                                .foregroundStyle(Color.theme.accent)
                            Text("\(context.state.stepsDanced)")
                                .foregroundStyle(.white)
                                .font(.subheadline)
                        }

                        HStack(spacing: 4) {
                            Image(systemName: "bolt.fill")
                                .foregroundStyle(Color.theme.accent)
                            Text("\(Int(context.state.staminaScore))%")
                                .foregroundStyle(.white)
                                .font(.caption)
                        }
                    }

                    // VIP Alerts (show latest if any)
                    if !context.state.vipAlerts.isEmpty {
                        Text("⭐ \(context.state.vipAlerts.last!)")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                            .lineLimit(1)
                    }

                    // Current offer (if active)
                    if let offer = context.state.currentOffer,
                       let validUntil = context.state.offerValidUntil,
                       validUntil > Date() {
                        Text(offer)
                            .font(.caption)
                            .foregroundStyle(.green)
                            .lineLimit(1)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .activityBackgroundTint(.clear)
        .activitySystemActionForegroundColor(.white)
    }

    private func crowdLevelGradient() -> Gradient {
        switch context.state.crowdLevel {
        case 1: return Gradient(colors: [.purple.opacity(0.6), .blue.opacity(0.6)]) // Empty
        case 2: return Gradient(colors: [.blue.opacity(0.6), .green.opacity(0.6)]) // Light
        case 3: return Gradient(colors: [.green.opacity(0.6), .yellow.opacity(0.6)]) // Moderate
        case 4: return Gradient(colors: [.yellow.opacity(0.6), .orange.opacity(0.6)]) // Busy
        case 5: return Gradient(colors: [.orange.opacity(0.6), .red.opacity(0.6)]) // Packed
        default: return Gradient(colors: [.gray.opacity(0.6), .black.opacity(0.6)])
        }
    }
}

// MARK: - Dynamic Island Activity View

@available(iOS 16.1, *)
struct LSTDDynamicIslandActivityView: View {
    let context: ActivityViewContext<LiveActivitiesManager.LSTDLiveActivityAttributes>

    var body: some View {
        HStack {
            // Leading content
            HStack {
                Text("🎵")
                    .font(.title2)
                VStack(alignment: .leading) {
                    Text(context.state.currentSong)
                        .font(.caption)
                        .lineLimit(1)
                    Text("DJ \(context.state.djName)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Compact indicators
            HStack(spacing: 8) {
                // Steps indicator
                VStack(spacing: 2) {
                    Image(systemName: "figure.walk")
                        .font(.caption)
                    Text("\(context.state.stepsDanced)")
                        .font(.caption2)
                }

                // VIP alert if any
                if !context.state.vipAlerts.isEmpty {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                }

                // Offer indicator
                if context.state.currentOffer != nil {
                    Image(systemName: "tag.fill")
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Activity Button Component

/// Button to start/end Live Activities in the main app
struct LiveActivityButton: View {
    let venue: Venue?
    let isActive: Bool

    @State private var showingStartConfirmation = false

    var body: some View {
        Button(action: {
            if isActive {
                stopActivity()
            } else {
                showingStartConfirmation = true
            }
        }) {
            HStack {
                Image(systemName: isActive ? "stop.circle.fill" : "play.circle.fill")
                    .font(.title2)

                VStack(alignment: .leading) {
                    Text(isActive ? "End Live Activity" : "Start Live Activity")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(isActive ? "Hide from lock screen" : "Show nightclub vibes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isActive ? Color.red.opacity(0.1) : Color.theme.accent.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isActive ? Color.red.opacity(0.3) : Color.theme.accent.opacity(0.3), lineWidth: 1)
            )
        }
        .confirmationDialog(
            "Start Live Activity?",
            isPresented: $showingStartConfirmation,
            titleVisibility: .visible
        ) {
            Button("Start Now") {
                startActivity()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will show real-time nightclub activity on your lock screen, including current songs, VIP alerts, and your dance tracking.")
        }
    }

    private func startActivity() {
        Task {
            do {
                guard let venue = venue else { return }
                try await LiveActivitiesManager.shared.startVenueActivity(
                    venueName: venue.name,
                    venueId: venue.id.uuidString,
                    userName: "Club Goer" // TODO: Get from auth
                )
            } catch {
                print("Failed to start Live Activity: \(error)")
            }
        }
    }

    private func stopActivity() {
        Task {
            await LiveActivitiesManager.shared.endActivity()
        }
    }
}

// MARK: - Activity Status Card

/// Card showing current Live Activity status
struct LiveActivityStatusCard: View {
    @State private var isLiveActivityActive = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lock.square.stack.fill")
                    .foregroundStyle(Color.theme.accent)
                    .font(.title2)

                Text("Live Activity Status")
                    .font(.headline)

                Spacer()

                Circle()
                    .fill(isLiveActivityActive ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
            }

            if isLiveActivityActive {
                Text("Your nightlife experience is live on lock screen! 🎉")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text("Start a Live Activity to see real-time nightclub updates on your lock screen.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Quick status indicators
            if isLiveActivityActive {
                HStack(spacing: 16) {
                    LiveActivityStatusIndicator(icon: "music.note", text: "Track songs")
                    LiveActivityStatusIndicator(icon: "figure.walk", text: "Count steps")
                    LiveActivityStatusIndicator(icon: "bell.badge", text: "VIP alerts")
                    LiveActivityStatusIndicator(icon: "tag", text: "Live offers")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color.theme.surface.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear {
            // Check if Live Activity is active
            isLiveActivityActive = LiveActivitiesManager.shared.isActivityActive()
        }
    }
}

struct LiveActivityStatusIndicator: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
        }
    }
}

// MARK: - Helper Extension

