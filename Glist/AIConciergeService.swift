import Foundation
import FirebaseFirestore

/// AI-powered concierge service for intelligent chat responses
class AIConciergeService {
    static let shared = AIConciergeService()

    private let db = FirestoreManager.shared.db
    private var conversationContexts: [String: ConversationContext] = [:]

    // Common booking-related intents
    enum ChatIntent: String {
        case booking_inquiry = "booking_inquiry"
        case table_availability = "table_availability"
        case price_questions = "price_questions"
        case venue_recommendation = "venue_recommendation"
        case wait_time_questions = "wait_time_questions"
        case reservation_changes = "reservation_changes"
        case concierge_recommendations = "concierge_recommendations"
        case general_help = "general_help"
    }

    struct ConversationContext {
        var userId: String
        var currentVenueId: String?
        var mentionedVenues: [String]
        var discussedReservations: [String]
        var preferences: UserPreferences
        var lastActivity: Date
    }

    struct UserPreferences {
        var preferredPriceRange: String?
        var preferredVenueTypes: [String]
        var groupSizeTypical: Int?
        var timePreferences: [String]
    }

    // MARK: - AI Response Generation

    func generateAIResponse(for message: ChatMessage, in thread: ChatThread) async throws -> ChatMessage? {
        let intent = try await analyzeIntent(message.content, context: thread)
        let context = getOrCreateContext(threadId: thread.id, userId: message.senderId, venueId: thread.venueId)

        let (responseText, shouldRespond) = try await generateResponse(for: intent, message: message, context: context, thread: thread)

        if shouldRespond && !responseText.isEmpty {
            return ChatMessage(
                id: UUID().uuidString,
                threadId: thread.id,
                senderId: "ai_concierge",
                senderName: thread.venueName ?? "AI Concierge",
                senderRole: "system",
                content: responseText,
                messageType: .text,
                timestamp: Date(),
                isRead: false,
                metadata: ["ai_generated": "true", "intent": intent.rawValue]
            )
        }

        return nil
    }

    // MARK: - Intent Analysis

    private func analyzeIntent(_ text: String, context thread: ChatThread) async throws -> ChatIntent {
        let lowerText = text.lowercased()

        // Booking inquiries
        if lowerText.containsAny(of: ["book", "reservation", "table", "reserve", "schedule"]) {
            return .booking_inquiry
        }

        // Availability questions
        if lowerText.containsAny(of: ["available", "spots", "open", "free", "capacity"]) {
            return .table_availability
        }

        // Price questions
        if lowerText.containsAny(of: ["price", "cost", "amount", "fee", "deposit", "charge"]) {
            return .price_questions
        }

        // Wait time questions
        if lowerText.containsAny(of: ["wait", "time", "estimate", "queue", "long"]) {
            return .wait_time_questions
        }

        // Recommendations
        if lowerText.containsAny(of: ["suggest", "recommend", "best", "good", "favorite"]) {
            return .concierge_recommendations
        }

        // Cancellation/changes
        if lowerText.containsAny(of: ["cancel", "change", "modify", "update", "reschedule"]) {
            return .reservation_changes
        }

        // Venue recommendations (if no specific venue context)
        if thread.venueName == nil && lowerText.containsAny(of: ["venue", "club", "restaurant", "place"]) {
            return .venue_recommendation
        }

        // Default to general help
        return .general_help
    }

    // MARK: - Response Generation

    private func generateResponse(for intent: ChatIntent, message: ChatMessage, context userContext: ConversationContext, thread: ChatThread) async throws -> (String, Bool) {

        switch intent {
        case .booking_inquiry:
            return await generateBookingInquiryResponse(message, context: userContext, thread: thread)

        case .table_availability:
            return await generateAvailabilityResponse(message, context: userContext, thread: thread)

        case .price_questions:
            return await generatePriceResponse(message, context: userContext, thread: thread)

        case .wait_time_questions:
            return await generateWaitTimeResponse(message, context: userContext, thread: thread)

        case .concierge_recommendations:
            return await generateRecommendationsResponse(message, context: userContext, thread: thread)

        case .venue_recommendation:
            return await generateVenueRecommendationResponse(message, context: userContext)

        case .reservation_changes:
            return ("To modify or cancel your reservation, please contact the venue directly. You can also check your booking status in the app. 📱", true)

        case .general_help:
            return await generateGeneralHelpResponse(message, context: userContext, thread: thread)
        }
    }

    // MARK: - Specific Response Generators

    private func generateGeneralHelpResponse(_ message: ChatMessage, context: ConversationContext, thread: ChatThread) async -> (String, Bool) {
        let venueName = thread.venueName ?? "your venue"
        let responses = [
            "Hi! I'm here to help with your experience at \(venueName). You can ask me about bookings, availability, recommendations, or any questions about the venue. 🤖",
            "Hello! How can I assist you with your visit to \(venueName)? Whether it's table reservations, drink recommendations, or special requests, I'm here to help. 🎉",
            "Welcome to \(venueName)! I'm your AI concierge. Feel free to ask about anything - from booking tables to getting the best recommendations for your group. ⭐"
        ]

        return (responses.randomElement()!, true)
    }

    private func generateBookingInquiryResponse(_ message: ChatMessage, context: ConversationContext, thread: ChatThread) async -> (String, Bool) {
        let venueName = thread.venueName ?? "the venue"

        // Check if they already have bookings
        do {
            let userBookings = try await FirestoreManager.shared.fetchUserBookings(userId: message.senderId)
            let upcomingBookings = userBookings.filter { $0.date > Date() && $0.status != .cancelled }

            if let existingBooking = upcomingBookings.first(where: { $0.venueId == thread.venueId }) {
                return ("Great! I see you already have a booking at \(venueName) on \(existingBooking.date.formatted(.dateTime.month(.twoDigits).day(.twoDigits))). Would you like to modify it or make a new reservation? 📅", true)
            }
        } catch {
            print("Error checking existing bookings: \(error)")
        }

        let responses = [
            "I'd be happy to help you book a table at \(venueName)! To get started, could you tell me when you'd like to visit and how many people are in your group? 🎯",
            "Let's get you booked at \(venueName)! What date and time were you thinking, and how many guests will be joining you? 👥",
            "Perfect! To create your reservation at \(venueName), I'll need your preferred date/time and party size. Let me know those details and I'll guide you through it. 🌟"
        ]

        return (responses.randomElement()!, true)
    }

    private func generateAvailabilityResponse(_ message: ChatMessage, context: ConversationContext, thread: ChatThread) async -> (String, Bool) {
        guard let venueId = thread.venueId else {
            return ("I need more specific information about your preferred date and time to check availability. Could you share those details? ⏰", true)
        }

        do {
            let recentBookings = try await db.collection("bookings")
                .whereField("venueId", isEqualTo: venueId)
                .order(by: "date", descending: true)
                .limit(10)
                .getDocuments()

            let venueName = thread.venueName ?? "the venue"

            return ("I'd be happy to check availability at \(venueName)! Could you tell me your preferred date and time, and how many people will be in your group? That way I can give you the most accurate information. 📅", true)

        } catch {
            return ("I can help check availability for \(thread.venueName ?? "your venue")! What date and time were you looking for, and how many people will be in your group? 📅", true)
        }
    }

    private func generatePriceResponse(_ message: ChatMessage, context: ConversationContext, thread: ChatThread) async -> (String, Bool) {
        let venueName = thread.venueName ?? "the venue"

        return ("Prices at \(venueName) vary by table type and time - ranging from AED 500 for standard tables up to AED 5000+ for VIP areas. What type of experience are you looking for? 💳", true)
    }

    private func generateWaitTimeResponse(_ message: ChatMessage, context: ConversationContext, thread: ChatThread) async -> (String, Bool) {
        let currentHour = Calendar.current.component(.hour, from: Date())
        let dayOfWeek = Calendar.current.component(.weekday, from: Date())

        var estimatedWait = "30-45 minutes"
        var advice = ""

        if dayOfWeek >= 6 { // Weekend
            if currentHour >= 22 {
                estimatedWait = "60-90 minutes"
                advice = "It can get quite busy on weekend nights!"
            } else if currentHour >= 20 {
                estimatedWait = "45-75 minutes"
                advice = "Weekend evenings pick up quickly."
            } else {
                estimatedWait = "20-40 minutes"
                advice = "Early weekend nights usually have shorter waits."
            }
        } else { // Weekday
            if currentHour >= 23 {
                estimatedWait = "30-60 minutes"
                advice = "Even weekdays can have lines late at night."
            } else {
                estimatedWait = "15-30 minutes"
                advice = "Weekdays are generally quicker!"
            }
        }

        return ("Based on current trends, the wait time right now is approximately \(estimatedWait). \(advice) 📱", true)
    }

    private func generateRecommendationsResponse(_ message: ChatMessage, context: ConversationContext, thread: ChatThread) async -> (String, Bool) {
        let venueName = thread.venueName ?? "the venue"
        let preferences = context.preferences

        return ("\(venueName) is fantastic! Our signature experience includes amazing music, premium drinks, and excellent service. The atmosphere is truly special after sunset. 🌟", true)
    }

    private func generateVenueRecommendationResponse(_ message: ChatMessage, context: ConversationContext) async -> (String, Bool) {
        return ("Depending on what you're looking for - LSTD for nightlife, BOCA for Italian dining, or ROOFTOP at Burj Al Arab for luxury views! 🌟", true)
    }

    // MARK: - Context Management

    private func getOrCreateContext(threadId: String, userId: String, venueId: String?) -> ConversationContext {
        if let existing = conversationContexts[threadId] {
            return existing
        }

        let context = ConversationContext(
            userId: userId,
            currentVenueId: venueId,
            mentionedVenues: venueId != nil ? [venueId!] : [],
            discussedReservations: [],
            preferences: getUserPreferences(userId: userId),
            lastActivity: Date()
        )

        conversationContexts[threadId] = context
        return context
    }

    private func getUserPreferences(userId: String) -> UserPreferences {
        return UserPreferences(
            preferredPriceRange: "premium",
            preferredVenueTypes: ["nightclub", "lounge"],
            groupSizeTypical: 4,
            timePreferences: ["evening", "late_night"]
        )
    }
}

// MARK: - String Extensions

extension String {
    func containsAny(of keywords: [String]) -> Bool {
        let lowerSelf = self.lowercased()
        return keywords.contains { lowerSelf.contains($0.lowercased()) }
    }
}
