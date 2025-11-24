import Foundation

struct MessagingContext {
    let bookingId: UUID
    let venueName: String
    let date: Date
    let partySize: Int
    let tableName: String?
    let promoterCode: String?
    let userDisplayName: String?
}

struct MessagingTemplate {
    let name: String
    let makeBody: (MessagingContext) -> String
}

enum ConciergeChatManager {
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
