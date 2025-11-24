import Foundation
import FirebaseFirestore
import Combine

// MARK: - Chat Data Models

enum MessageType: String, Codable {
    case text = "text"
    case image = "image"
    case bookingUpdate = "booking_update"
    case system = "system"
}

enum ChatThreadType: String, Codable {
    case concierge = "concierge"  // User ↔ Venue Host
    case promoter = "promoter"   // User ↔ Promoter
    case support = "support"     // User ↔ App Support
}

struct ChatMessage: Identifiable, Codable, Hashable {
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

    var isFromUser: Bool {
        senderRole == "user"
    }

    var isFromConcierge: Bool {
        ["host", "promoter", "system"].contains(senderRole)
    }
}

struct ChatThread: Identifiable, Codable, Hashable {
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

    var isActive: Bool {
        status == "active"
    }
}

// MARK: - Concierge Chat Manager

class ConciergeChatManager: ObservableObject {
    static let shared = ConciergeChatManager()

    private let db = FirestoreManager.shared.db
    private var listeners: [ListenerRegistration] = []

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
        currentUserId = userId
        observeUserThreads()
    }

    // MARK: - Thread Management

    func observeUserThreads() {
        guard let userId = currentUserId else { return }

        isLoading = true
        let listener = db.collection("chatThreads")
            .whereField("participants", arrayContains: userId)
            .whereField("status", isEqualTo: "active")
            .order(by: "updatedAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    self.errorMessage = "Failed to load chat threads: \(error.localizedDescription)"
                    self.isLoading = false
                    return
                }

                self.chatThreads = snapshot?.documents.compactMap { document in
                    try? document.data(as: ChatThread.self)
                } ?? []

                self.isLoading = false
            }

        listeners.append(listener)
    }

    func openChatThread(venueId: String, venueName: String, bookingId: String? = nil) async throws -> String {
        guard let userId = currentUserId else {
            throw NSError(domain: "ConciergeChatManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
        }

        // Check if thread already exists
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

        // Save to Firestore
        try await db.collection("chatThreads").document(threadId).setData([
            "id": threadId,
            "participants": [userId],
            "venueId": venueId,
            "venueName": venueName,
            "threadType": thread.threadType.rawValue,
            "bookingReferenceId": bookingId as Any,
            "createdAt": Timestamp(date: thread.createdAt),
            "updatedAt": Timestamp(date: thread.updatedAt),
            "lastMessagePreview": thread.lastMessagePreview,
            "unreadCount": thread.unreadCount,
            "status": thread.status
        ])

        // Add system message
        try await db.collection("messages").addDocument(data: [
            "id": systemMessage.id,
            "threadId": threadId,
            "senderId": systemMessage.senderId,
            "senderName": systemMessage.senderName,
            "senderRole": systemMessage.senderRole,
            "content": systemMessage.content,
            "messageType": systemMessage.messageType.rawValue,
            "timestamp": Timestamp(date: systemMessage.timestamp),
            "isRead": systemMessage.isRead
        ])

        return threadId
    }

    // MARK: - Message Management

    func observeMessages(for threadId: String) {
        currentThreadId = threadId

        let listener = db.collection("messages")
            .whereField("threadId", isEqualTo: threadId)
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    self.errorMessage = "Failed to load messages: \(error.localizedDescription)"
                    return
                }

                self.messages = snapshot?.documents.compactMap { document in
                    try? document.data(as: ChatMessage.self)
                } ?? []
            }

        listeners.append(listener)
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
        try await db.collection("messages").addDocument(data: [
            "id": message.id,
            "threadId": threadId,
            "senderId": message.senderId,
            "senderName": message.senderName,
            "senderRole": message.senderRole,
            "content": message.content,
            "messageType": message.messageType.rawValue,
            "timestamp": Timestamp(date: message.timestamp),
            "isRead": message.isRead
        ])

        // Update thread's last message and timestamp
        try await db.collection("chatThreads").document(threadId).updateData([
            "lastMessagePreview": content,
            "updatedAt": Timestamp(date: Date())
        ])

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
            try await db.collection("messages").addDocument(data: [
                "id": aiResponse.id,
                "threadId": threadId,
                "senderId": aiResponse.senderId,
                "senderName": aiResponse.senderName,
                "senderRole": aiResponse.senderRole,
                "content": aiResponse.content,
                "messageType": aiResponse.messageType.rawValue,
                "timestamp": Timestamp(date: aiResponse.timestamp),
                "isRead": aiResponse.isRead,
                "metadata": aiResponse.metadata as Any
            ])

            // Update thread with AI response as last message
            try await db.collection("chatThreads").document(threadId).updateData([
                "lastMessagePreview": aiResponse.content,
                "updatedAt": Timestamp(date: Date())
            ])
        }
    }
+++++++ REPLACE</parameter>

    func markMessagesAsRead(threadId: String) async throws {
        let unreadMessages = messages.filter { !$0.isRead && !$0.isFromUser }

        for message in unreadMessages {
            try await db.collection("messages").document(message.id).updateData([
                "isRead": true
            ])
        }

        // Update unread count
        if !unreadMessages.isEmpty {
            let currentUnreadCount = unreadMessages.count
            try await db.collection("chatThreads").document(threadId).updateData([
                "unreadCount": FieldValue.increment(Int64(-currentUnreadCount))
            ])
        }
    }

    // MARK: - Cleanup

    func stopObserving() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
        chatThreads.removeAll()
        messages.removeAll()
    }

    deinit {
        stopObserving()
    }
}

// MARK: - Legacy WhatsApp Integration

struct MessagingContext {
    let bookingId: UUID
    let venueName: String
    let date: Date
    let partySize: Int
    let tableName: String?
    let promoterCode: String?
    let userDisplayName: String?
}
+++++++ REPLACE</parameter>

struct MessagingTemplate {
    let name: String
    let makeBody: (MessagingContext) -> String
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
+++++++ REPLACE</parameter>
