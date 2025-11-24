import SwiftUI
import FirebaseCore
import FirebaseMessaging

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        // Initialize NotificationManager and request permission
        NotificationManager.shared.requestPermission()
        application.registerForRemoteNotifications()
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }
}

@main
struct GListApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @StateObject private var bookingManager = BookingManager()
    @StateObject private var socialManager = SocialManager()
    @StateObject private var localeManager = LocalizationManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(bookingManager)
                .environmentObject(socialManager)
                .environmentObject(localeManager)
                .environment(\.layoutDirection, localeManager.usesRTL ? .rightToLeft : .leftToRight)
                .environment(\.locale, localeManager.locale)
        }
    }
}
