import SwiftUI

struct ChatThreadView: View {
    let thread: ChatThread
    @StateObject private var chatManager = ConciergeChatManager.shared
    @EnvironmentObject var authManager: AuthManager
    @State private var messageText = ""
    @State private var isTyping = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header with venue info
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.theme.accent.opacity(0.2))
                                .frame(width: 36, height: 36)

                            Image(systemName: thread.threadType == .concierge ? "building.2" : "person.circle")
                                .font(.system(size: 16))
                                .foregroundStyle(Color.theme.accent)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(thread.venueName ?? "Support")
                                .font(Theme.Fonts.display(size: 16))
                                .foregroundStyle(.white)

                            if thread.threadType == .concierge {
                                Text("Concierge")
                                    .font(Theme.Fonts.body(size: 12))
                                    .foregroundStyle(.gray)
                            } else {
                                Text("Support")
                                    .font(Theme.Fonts.body(size: 12))
                                    .foregroundStyle(.gray)
                            }
                        }

                        Spacer()

                        // Status indicator
                        StatusIndicator(thread: thread)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.theme.surface.opacity(0.5))

                    // Messages View
                    MessagesView(thread: thread, chatManager: chatManager)

                    // Message Input
                    MessageInputBar(text: $messageText, isTyping: $isTyping) {
                        await sendMessage()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(thread.venueName ?? "Chat")
            .onAppear {
                chatManager.observeMessages(for: thread.id)
                Task {
                    try? await chatManager.markMessagesAsRead(threadId: thread.id)
                }
            }
        }
    }

    private func sendMessage() async {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let contentToSend = messageText
        messageText = ""

        do {
            try await chatManager.sendMessage(threadId: thread.id, content: contentToSend)
            isTyping = false
        } catch {
            print("Failed to send message: \(error)")
            // Could show an alert here
            messageText = contentToSend // Restore the text if sending failed
        }
    }
}

struct StatusIndicator: View {
    let thread: ChatThread

    var statusText: String {
        switch thread.status {
        case "active": return "Active"
        case "waiting": return "Connecting..."
        default: return "Offline"
        }
    }

    var statusColor: Color {
        switch thread.status {
        case "active": return .green
        case "waiting": return .orange
        default: return .gray
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            Text(statusText)
                .font(Theme.Fonts.body(size: 12))
                .foregroundStyle(.white.opacity(0.7))
        }
    }
}

struct MessagesView: View {
    let thread: ChatThread
    @ObservedObject var chatManager: ConciergeChatManager

    var body: some View {
        ScrollView {
            ScrollViewReader { scrollView in
                LazyVStack(spacing: 16) {
                    ForEach(chatManager.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .onChange(of: chatManager.messages.count) { _ in
                    if let lastMessage = chatManager.messages.last {
                        withAnimation {
                            scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(spacing: 0) {
            if message.isFromUser {
                Spacer(minLength: 60)
            }

            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
                // Message content
                Text(message.content)
                    .font(Theme.Fonts.body(size: 16))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(messageBubbleBackground)
                    .clipShape(ChatBubbleShape(isFromUser: message.isFromUser))

                // Timestamp
                Text(message.timestamp.formatted(.dateTime.hour().minute()))
                    .font(Theme.Fonts.body(size: 10))
                    .foregroundStyle(.gray.opacity(0.6))

                // Sender for system/host messages
                if !message.isFromUser && message.senderRole != "system" {
                    Text(message.senderName)
                        .font(Theme.Fonts.body(size: 10))
                        .foregroundStyle(.gray.opacity(0.6))
                        .fontWeight(.medium)
                }
            }

            if !message.isFromUser {
                Spacer(minLength: 60)
            }
        }
    }

    private var messageBubbleBackground: Color {
        if message.messageType == .system {
            return Color.theme.surface.opacity(0.3)
        } else if message.isFromUser {
            return Color.theme.accent
        } else {
            return Color.theme.surface.opacity(0.7)
        }
    }
}

struct ChatBubbleShape: Shape {
    let isFromUser: Bool

    func path(in rect: CGRect) -> Path {
        let cornerRadius: CGFloat = 18
        let tailSize: CGFloat = 8

        var path = Path()

        if isFromUser {
            // Right-aligned bubble with tail on the right
            path.addRoundedRect(in: CGRect(
                x: rect.minX,
                y: rect.minY,
                width: rect.width - tailSize,
                height: rect.height
            ), cornerSize: CGSize(width: cornerRadius, height: cornerRadius))

            // Tail pointing right
            path.move(to: CGPoint(x: rect.maxX - tailSize, y: rect.midY - tailSize))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX - tailSize, y: rect.midY + tailSize))
            path.closeSubpath()
        } else {
            // Left-aligned bubble with tail on the left
            path.addRoundedRect(in: CGRect(
                x: rect.minX + tailSize,
                y: rect.minY,
                width: rect.width - tailSize,
                height: rect.height
            ), cornerSize: CGSize(width: cornerRadius, height: cornerRadius))

            // Tail pointing left
            path.move(to: CGPoint(x: rect.minX + tailSize, y: rect.midY - tailSize))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.minX + tailSize, y: rect.midY + tailSize))
            path.closeSubpath()
        }

        return path
    }
}

struct MessageInputBar: View {
    @Binding var text: String
    @Binding var isTyping: Bool
    let onSend: () async -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Text field
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text("Type a message...")
                        .font(Theme.Fonts.body(size: 16))
                        .foregroundStyle(.gray.opacity(0.5))
                        .padding(.horizontal, 16)
                }

                TextField("", text: $text, axis: .vertical)
                    .font(Theme.Fonts.body(size: 16))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .lineLimit(1...5)
            }
            .background(Color.theme.surface.opacity(0.5))
            .clipShape(Capsule())

            // Send button
            Button {
                Task {
                    await onSend()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?
                              Color.theme.surface.opacity(0.3) : Color.theme.accent)
                        .frame(width: 44, height: 44)

                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.theme.surface.opacity(0.8))
    }
}

#Preview {
    ChatThreadView(thread: ChatThread(
        id: "sample",
        participants: ["user1"],
        venueId: "venue1",
        venueName: "Test Venue",
        threadType: .concierge,
        bookingReferenceId: "booking1",
        createdAt: Date(),
        updatedAt: Date(),
        lastMessagePreview: "Hello",
        unreadCount: 0,
        status: "active"
    ))
    .environmentObject(AuthManager())
}
