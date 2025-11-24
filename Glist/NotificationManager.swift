import UserNotifications
import FirebaseMessaging
import UIKit
import Combine

class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    @Published var latestFCMToken: String?
    
    private let topicMap: [KeyPath<NotificationPreferences, Bool>: String] = [
        \NotificationPreferences.guestListUpdates: "guest-list",
        \NotificationPreferences.newVenues: "new-venues",
        \NotificationPreferences.promotions: "promotions"
    ]
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
    }
    
    func requestPermission() {
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { granted, error in
                DispatchQueue.main.async {
                    self.isAuthorized = granted
                    if granted {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                }
                if let error = error {
                    print("Error requesting notification permission: \(error)")
                }
            }
        )
    }
    
    func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // Store token for current user and subscribe to topics matching preferences.
    func syncFCMTokenIfNeeded(userId: String?, preferences: NotificationPreferences? = nil) async {
        guard let userId, let token = latestFCMToken else { return }
        try? await FirestoreManager.shared.updateFCMToken(userId: userId, token: token)
        if let preferences {
            await updateTopicSubscriptions(preferences: preferences)
        }
    }
    
    func updateTopicSubscriptions(preferences: NotificationPreferences) async {
        for (keyPath, topic) in topicMap {
            if preferences[keyPath: keyPath] {
                try? await Messaging.messaging().subscribe(toTopic: topic)
            } else {
                try? await Messaging.messaging().unsubscribe(fromTopic: topic)
            }
        }
    }

    
    // MARK: - Local Notifications
    
    func scheduleLocalNotification(title: String, body: String, timeInterval: TimeInterval, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    func scheduleBookingReminder(for booking: Booking) {
        // Schedule reminder 2 hours before booking
        let timeInterval = booking.date.timeIntervalSinceNow - (2 * 60 * 60)
        
        if timeInterval > 0 {
            scheduleLocalNotification(
                title: "Upcoming Booking",
                body: "Your table at \(booking.venueName) is ready in 2 hours. Running late? Tap to notify.",
                timeInterval: timeInterval,
                identifier: "booking-\(booking.id)"
            )
        }
    }
    
    func sendValetNotification(status: String) {
        // Simulate a valet notification
        scheduleLocalNotification(
            title: "Valet Update",
            body: "Your car is \(status). Please proceed to the valet desk.",
            timeInterval: 5, // 5 seconds delay for demo
            identifier: "valet-\(UUID().uuidString)"
        )
    }
    
    func sendTableUpgradeNotification(venueName: String) {
        // Simulate a table upgrade offer
        scheduleLocalNotification(
            title: "Table Upgrade Available! 🥂",
            body: "A VIP table just opened up at \(venueName). Upgrade now for 2500 points?",
            timeInterval: 10, // 10 seconds delay for demo
            identifier: "upgrade-\(UUID().uuidString)"
        )
    }
}

extension NotificationManager: UNUserNotificationCenterDelegate {
    // Receive displayed notifications for iOS 10 devices.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        print("Will present notification: \(userInfo)")
        
        // Change this to your preferred presentation option
        completionHandler([[.banner, .sound]])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        print("Did receive response: \(userInfo)")
        
        completionHandler()
    }
}

extension NotificationManager: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(String(describing: fcmToken))")
        
        guard let token = fcmToken else { return }
        latestFCMToken = token
    }
}
