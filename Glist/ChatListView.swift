import SwiftUI

struct ChatListView: View {
    @StateObject private var chatManager = ConciergeChatManager.shared
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedThread: ChatThread?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Messages")
                            .font(Theme.Fonts.display(size: 28))
                            .foregroundStyle(.white)
                        Spacer()

                        if !chatManager.chatThreads.isEmpty {
                            Text("\(chatManager.chatThreads.count) chats")
                                .font(Theme.Fonts.body(size: 14))
                                .foregroundStyle(.gray)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    // Chat Threads List
                    ScrollView {
                        if chatManager.isLoading {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity, maxHeight: 200)
                        } else if chatManager.chatThreads.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "bubble.left.and.bubble.right")
                                    .font(.system(size: 60))
                                    .foregroundStyle(.gray.opacity(0.5))

                                VStack(spacing: 8) {
                                    Text("No conversations yet")
                                        .font(Theme.Fonts.body(size: 18))
                                        .foregroundStyle(.gray)

                                    Text("Start chatting with hosts about your bookings and experiences")
                                        .font(Theme.Fonts.body(size: 14))
                                        .foregroundStyle(.gray.opacity(0.7))
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 40)
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.top, 80)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(chatManager.chatThreads) { thread in
                                    ChatThreadRow(thread: thread) {
                                        selectedThread = thread
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                            .padding(.vertical, 20)
                        }
                    }
                }
            }
            .onAppear {
                if let userId = authManager.user?.id {
                    chatManager.initialize(for: userId)
                }
            }
            .navigationDestination(item: $selectedThread) { thread in
                ChatThreadView(thread: thread)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ChatThreadRow: View {
    let thread: ChatThread
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(Color.theme.accent.opacity(0.2))
                        .frame(width: 56, height: 56)

                    Image(systemName: thread.threadType == .concierge ? "building.2" : "person.circle")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.theme.accent)
                }

                VStack(alignment: .leading, spacing: 6) {
                    // Venue/Title
                    HStack {
                        Text(thread.venueName ?? "Support Chat")
                            .font(Theme.Fonts.display(size: 16))
                            .foregroundStyle(.white)
                            .lineLimit(1)

                        Spacer()

                        // Timestamp and unread badge
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(thread.updatedAt.relativeFormatted())
                                .font(Theme.Fonts.body(size: 12))
                                .foregroundStyle(.gray)

                            if thread.unreadCount > 0 {
                                Text("\(thread.unreadCount)")
                                    .font(Theme.Fonts.body(size: 10))
                                    .fontWeight(.bold)
                                    .foregroundStyle(.black)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.theme.accent)
                                    .clipShape(Capsule())
                            }
                        }
                    }

                    // Last message preview
                    HStack {
                        Text(thread.lastMessagePreview)
                            .font(Theme.Fonts.body(size: 14))
                            .foregroundStyle(.gray.opacity(0.8))
                            .lineLimit(1)

                        Spacer()

                        // Booking indicator
                        if thread.bookingReferenceId != nil {
                            Image(systemName: "calendar")
                                .font(.caption)
                                .foregroundStyle(.gray.opacity(0.5))
                        }
                    }
                }
            }
            .padding(16)
            .background(Color.theme.surface.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
        }
    }
}

extension Date {
    func relativeFormatted() -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day], from: self, to: now)

        if let day = components.day, day >= 1 {
            return day == 1 ? "1d" : "\(day)d"
        } else if let hour = components.hour, hour >= 1 {
            return "\(hour)h"
        } else if let minute = components.minute, minute >= 1 {
            return "\(minute)m"
        } else {
            return "now"
        }
    }
}

#Preview {
    ChatListView()
        .environmentObject(AuthManager())
}
