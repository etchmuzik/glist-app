import Foundation
import Supabase
import Combine

// MARK: - Chat Data Models

enum MessageType: String, Codable, Sendable {
    case text = "text"
    case image = "image"
    case bookingUpdate = "booking_update"
    case system = "system"
}

enum ChatThreadType: String, Codable, Sendable {
    case concierge = "concierge"  // User ↔ Venue Host
    case promoter = "promoter"   // User ↔ Promoter
    case support = "support"     // User ↔ App Support
}

struct ChatMessage: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let threadId: String
    let senderId: String
    let senderName: String
    let senderRole: String  // "user", "host", "promoter", "system"
    let content: String
    let messageType: MessageType
    let timestamp: Date
    let isRead: Bool
    let metadata: [String: String]?  // For booking IDs, table names, etc.

    enum CodingKeys: String, CodingKey {
        case id
        case threadId = "thread_id"
        case senderId = "sender_id"
        case senderName = "sender_name"
        case senderRole = "sender_role"
        case content
        case messageType = "message_type"
        case timestamp
        case isRead = "is_read"
        case metadata
    }

    var isFromUser: Bool {
        senderRole == "user"
    }

    var isFromConcierge: Bool {
        ["host", "promoter", "system"].contains(senderRole)
    }
}

struct ChatThread: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let participants: [String]  // User IDs
    let venueId: String?
    let venueName: String?
    let threadType: ChatThreadType
    let bookingReferenceId: String?  // UUID of related booking
    let createdAt: Date
    let updatedAt: Date
    let lastMessagePreview: String
    let unreadCount: Int
    let status: String  // "active", "closed", "archived"

    enum CodingKeys: String, CodingKey {
        case id
        case participants
        case venueId = "venue_id"
        case venueName = "venue_name"
        case threadType = "thread_type"
        case bookingReferenceId = "booking_reference_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case lastMessagePreview = "last_message_preview"
        case unreadCount = "unread_count"
        case status
    }

    var isActive: Bool {
        status == "active"
    }
}

// MARK: - Concierge Chat Manager

@MainActor
class ConciergeChatManager: ObservableObject {
    static let shared = ConciergeChatManager()

    private let client = SupabaseManager.shared.client
    private var channels: [RealtimeChannelV2] = []

    // Published properties
    @Published var chatThreads: [ChatThread] = []
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Current chat state
    private var currentThreadId: String?
    private var currentUserId: String?

    // Initialize with user context
    func initialize(for userId: String) {
        // Avoid duplicate listeners for the same user
        if currentUserId == userId && !channels.isEmpty { return }
        
        resetListeners()
        currentUserId = userId
        observeUserThreads()
    }
    
    private func resetListeners() {
        let channelsToUnsubscribe = channels
        channels.removeAll()
        Task {
            for channel in channelsToUnsubscribe {
                await channel.unsubscribe()
            }
        }
    }

    func tearDown() {
        resetListeners()
        chatThreads = []
        messages = []
        currentThreadId = nil
        currentUserId = nil
    }

    // MARK: - Thread Management

    func observeUserThreads() {
        guard let userId = currentUserId else { return }

        isLoading = true
        
        Task {
            do {
                // Initial fetch
                let threads: [ChatThread] = try await client.database.from("chat_threads")
                    .select()
                    .contains("participants", value: [userId])
                    .eq("status", value: "active")
                    .order("updated_at", ascending: false)
                    .execute()
                    .value
                
                await MainActor.run {
                    self.chatThreads = threads
                    self.isLoading = false
                }
                
                // Realtime subscription
                let channel: RealtimeChannelV2 = client.channel("public:chat_threads")
                let changeStream = channel.postgresChange(
                    AnyAction.self,
                    schema: "public",
                    table: "chat_threads",
                    filter: "participants=cs.{\(userId)}" // cs = contains
                )
                
                await channel.subscribe()
                
                for await _ in changeStream {
                    // Refresh threads on any change
                    let updatedThreads: [ChatThread] = try await client.database.from("chat_threads")
                        .select()
                        .contains("participants", value: [userId])
                        .eq("status", value: "active")
                        .order("updated_at", ascending: false)
                        .execute()
                        .value
                    
                    await MainActor.run {
                        self.chatThreads = updatedThreads
                    }
                }
                
                channels.append(channel)
                
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load chat threads: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }

    func openChatThread(venueId: String, venueName: String, bookingId: String? = nil) async throws -> String {
        guard let userId = currentUserId else {
            throw NSError(domain: "ConciergeChatManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
        }

        // Check if thread already exists locally
        if let existingThread = chatThreads.first(where: {
            $0.venueId == venueId && $0.bookingReferenceId == bookingId
        }) {
            return existingThread.id
        }

        // Create new thread
        let threadId = UUID().uuidString
        let thread = ChatThread(
            id: threadId,
            participants: [userId], // Start with user, venue host will be added when they respond
            venueId: venueId,
            venueName: venueName,
            threadType: .concierge,
            bookingReferenceId: bookingId,
            createdAt: Date(),
            updatedAt: Date(),
            lastMessagePreview: "Started a conversation",
            unreadCount: 0,
            status: "active"
        )

        // Add system message
        let systemMessage = ChatMessage(
            id: UUID().uuidString,
            threadId: threadId,
            senderId: "system",
            senderName: "LSTD",
            senderRole: "system",
            content: "Hi! I'm connecting you with \(venueName)'s concierge. They'll be with you shortly to help with your experience.",
            messageType: .system,
            timestamp: Date(),
            isRead: false,
            metadata: nil
        )

        // Save to Supabase
        try await client.database.from("chat_threads").insert(thread).execute()
        try await client.database.from("messages").insert(systemMessage).execute()

        return threadId
    }

    // MARK: - Message Management

    func observeMessages(for threadId: String) {
        currentThreadId = threadId

        Task {
            do {
                // Initial fetch
                let fetchedMessages: [ChatMessage] = try await client.database.from("messages")
                    .select()
                    .eq("thread_id", value: threadId)
                    .order("timestamp", ascending: true)
                    .execute()
                    .value
                
                await MainActor.run {
                    self.messages = fetchedMessages
                }
                
                // Realtime subscription
                let channel: RealtimeChannelV2 = client.channel("public:messages:\(threadId)")
                let changeStream = channel.postgresChange(
                    AnyAction.self,
                    schema: "public",
                    table: "messages",
                    filter: "thread_id=eq.\(threadId)"
                )
                
                await channel.subscribe()
                
                for await _ in changeStream {
                    // Refresh messages on any change (simple approach, can be optimized to append)
                    let updatedMessages: [ChatMessage] = try await client.database.from("messages")
                        .select()
                        .eq("thread_id", value: threadId)
                        .order("timestamp", ascending: true)
                        .execute()
                        .value
                    
                    await MainActor.run {
                        self.messages = updatedMessages
                    }
                }
                
                channels.append(channel)
                
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load messages: \(error.localizedDescription)"
                }
            }
        }
    }

    func sendMessage(threadId: String, content: String, messageType: MessageType = .text) async throws {
        guard let userId = currentUserId else { return }

        let message = ChatMessage(
            id: UUID().uuidString,
            threadId: threadId,
            senderId: userId,
            senderName: "You", // Would be replaced with actual user name
            senderRole: "user",
            content: content,
            messageType: messageType,
            timestamp: Date(),
            isRead: false,
            metadata: nil
        )

        // Save user message
        try await client.database.from("messages").insert(message).execute()

        // Update thread's last message and timestamp
        try await client.database.from("chat_threads").update([
            "last_message_preview": content,
            "updated_at": Date().ISO8601Format()
        ]).eq("id", value: threadId).execute()

        // Generate AI response if this is a user message
        if messageType == .text && !content.isEmpty {
            try await generateAIResponse(for: message, inThread: threadId)
        }
    }

    private func generateAIResponse(for userMessage: ChatMessage, inThread threadId: String) async throws {
        // Find the thread
        guard let thread = chatThreads.first(where: { $0.id == threadId }) else { return }

        // Generate AI response
        if let aiResponse = try await AIConciergeService.shared.generateAIResponse(for: userMessage, in: thread) {
            // Save AI response to database
            try await client.database.from("messages").insert(aiResponse).execute()

            // Update thread with AI response as last message
            try await client.database.from("chat_threads").update([
                "last_message_preview": aiResponse.content,
                "updated_at": Date().ISO8601Format()
            ]).eq("id", value: threadId).execute()
        }
    }

    func markMessagesAsRead(threadId: String) async throws {
        // Update all unread messages in this thread that are NOT from the user
        try await client.database.from("messages")
            .update(["is_read": true])
            .eq("thread_id", value: threadId)
            .eq("is_read", value: false)
            .neq("sender_role", value: "user") // Don't mark own messages as read (logic check)
            .execute()

        // Reset unread count on thread
        try await client.database.from("chat_threads")
            .update(["unread_count": 0])
            .eq("id", value: threadId)
            .execute()
    }

    // MARK: - Cleanup

    func stopObserving() {
        resetListeners()
        chatThreads.removeAll()
        messages.removeAll()
    }
}

// MARK: - Legacy WhatsApp Integration

struct MessagingContext: Sendable {
    let bookingId: UUID
    let venueName: String
    let date: Date
    let partySize: Int
    let tableName: String?
    let promoterCode: String?
    let userDisplayName: String?
}

struct MessagingTemplate: Sendable {
    let name: String
    let makeBody: @Sendable (MessagingContext) -> String
}

enum LegacyConciergeChatManager {
    static let defaultTemplates: [MessagingTemplate] = [
        MessagingTemplate(name: "Instant Confirm") { context in
            "Hi \(context.userDisplayName ?? "there"), your booking at \(context.venueName) is confirmed for \(formattedDate(context.date)). Reply if you want upgrades or bottle menu recommendations."
        },
        MessagingTemplate(name: "Waitlist Promote") { context in
            "Good news! A spot opened up at \(context.venueName). Reply YES to confirm your booking for \(formattedDate(context.date))."
        },
        MessagingTemplate(name: "Cancellation Window") { context in
            "Reminder: you can cancel \(context.venueName) \(formattedDate(context.date)) booking without fees up to 6 hours prior. Need changes? Just reply here."
        }
    ]

    static func whatsappURL(
        phoneNumber: String,
        context: MessagingContext,
        template: MessagingTemplate? = nil
    ) -> URL? {
        let base = "https://wa.me/\(phoneNumber)"
        let message = template?.makeBody(context) ?? defaultTemplates.first?.makeBody(context) ?? ""
        let encoded = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "\(base)?text=\(encoded)")
    }

    static func threadMetadata(from context: MessagingContext) -> [String: String] {
        var metadata: [String: String] = [
            "bookingId": context.bookingId.uuidString,
            "venueName": context.venueName,
            "date": ISO8601DateFormatter().string(from: context.date),
            "partySize": "\(context.partySize)"
        ]

        if let tableName = context.tableName {
            metadata["tableName"] = tableName
        }
        if let promoterCode = context.promoterCode {
            metadata["promoterCode"] = promoterCode
        }
        if let name = context.userDisplayName {
            metadata["guestName"] = name
        }

        return metadata
    }

    private static func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

