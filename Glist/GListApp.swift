import SwiftUI
import GoogleSignIn
import Supabase

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Initialize NotificationManager and request permission
        NotificationManager.shared.requestPermission()
        application.registerForRemoteNotifications()
        
        return true
    }
    
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
      return GIDSignIn.sharedInstance.handle(url)
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        NotificationManager.shared.latestFCMToken = token
        
        Task {
            if let session = try? await SupabaseManager.shared.client.auth.session {
                await NotificationManager.shared.syncFCMTokenIfNeeded(userId: session.user.id.uuidString)
            }
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }
}

@main
struct GListApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // Centralized Dependency Injection
    @StateObject private var authManager = AuthManager()
    @StateObject private var bookingManager = BookingManager()
    @StateObject private var socialManager = SocialManager()
    @StateObject private var localeManager = LocalizationManager()
    @StateObject private var favoritesManager = FavoritesManager()
    @StateObject private var guestListManager = GuestListManager()
    @StateObject private var venueManager = VenueManager()
    @StateObject private var loyaltyManager = LoyaltyManager.shared
    @StateObject private var conciergeChatManager = ConciergeChatManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(bookingManager)
                .environmentObject(socialManager)
                .environmentObject(localeManager)
                .environmentObject(favoritesManager)
                .environmentObject(guestListManager)
                .environmentObject(venueManager)
                .environmentObject(loyaltyManager)
                .environmentObject(conciergeChatManager)
                .environment(\.layoutDirection, localeManager.usesRTL ? .rightToLeft : .leftToRight)
                .environment(\.locale, localeManager.locale)
                .onOpenURL { url in
                    Task {
                        do {
                            try await SupabaseManager.shared.client.auth.session(from: url)
                        } catch {
                            print("Fail to handle deep link: \(error)")
                        }
                    }
                }
        }
    }
}
