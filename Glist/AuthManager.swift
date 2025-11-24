import Foundation
import FirebaseAuth
import Combine
import SwiftUI

class AuthManager: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var userRole: UserRole = .user
    
    private var authStateHandler: AuthStateDidChangeListenerHandle?
    
    init() {
        registerAuthStateHandler()
    }
    
    private func registerAuthStateHandler() {
        authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user.map { User(firebaseUser: $0) }
            self?.isAuthenticated = user != nil
            
            // Fetch user role from Firestore
            if let userId = user?.uid {
                self?.fetchUserRole(userId: userId)
                Task {
                    await NotificationManager.shared.syncFCMTokenIfNeeded(userId: userId, preferences: self?.user?.notificationPreferences)
                }
            }
        }
    }
    
    func fetchUserRole(userId: String) {
        Task {
            do {
                if let user = try await FirestoreManager.shared.fetchUser(userId: userId) {
                    await MainActor.run {
                        self.userRole = user.role
                        self.user = user
                    }
                    await NotificationManager.shared.syncFCMTokenIfNeeded(userId: userId, preferences: user.notificationPreferences)
                }
            } catch {
                print("Error fetching user role: \(error)")
                // Default to user role on error
                await MainActor.run {
                    self.userRole = .user
                }
            }
        }
    }
    
    func signIn(email: String, password: String) async throws {
        try await Auth.auth().signIn(withEmail: email, password: password)
    }
    
    func signUp(email: String, password: String, name: String, referralCode: String? = nil) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        
        // Check referral code if provided
        var referredBy: String?
        if let code = referralCode, !code.isEmpty {
            referredBy = try await FirestoreManager.shared.checkReferralCode(code: code)
        }
        
        // Create user document in Firestore
        let newUser = User(
            id: result.user.uid,
            email: email,
            name: name,
            role: .user,
            tier: .standard,
            createdAt: Date(),
            favoriteVenueIds: [],
            profileImage: nil,
            following: [],
            followers: [],
            isPrivate: false,
            fcmToken: nil,
            notificationPreferences: NotificationPreferences(),
            rewardPoints: referredBy != nil ? LoyaltyManager.pointsPerReferralSignup : 0,
            noShowCount: 0,
            isBanned: false,
            softBanUntil: nil,
            kycStatus: .notSubmitted,
            dateOfBirth: nil,
            referralCode: nil,
            referredBy: referredBy,
            currentStreak: 0,
            lastVisitDate: nil,
            lifetimePoints: referredBy != nil ? LoyaltyManager.pointsPerReferralSignup : 0
        )
        
        try await FirestoreManager.shared.createUser(newUser)
        
        // Process referral reward for the referrer
        if let referrerId = referredBy {
            try await FirestoreManager.shared.processReferral(newUserId: newUser.id, referrerId: referrerId)
        }
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
        self.user = nil
        self.isAuthenticated = false
        self.userRole = .user
    }
    
    func updateName(_ name: String) async throws {
        guard var currentUser = user else { return }
        currentUser.name = name // Update local model temporarily
        
        // Update in Firestore
        try await FirestoreManager.shared.updateUser(userId: currentUser.id, data: ["name": name])
        
        // Update local state
        await MainActor.run {
            self.user?.name = name
        }
    }
    
    func updateNotificationPreferences(_ preferences: NotificationPreferences) async throws {
        guard let userId = user?.id else { return }
        
        let data: [String: Any] = [
            "guestListUpdates": preferences.guestListUpdates,
            "newVenues": preferences.newVenues,
            "promotions": preferences.promotions
        ]
        
        try await FirestoreManager.shared.updateNotificationPreferences(userId: userId, data: data)
        
        await MainActor.run {
            self.user?.notificationPreferences = preferences
        }
        await NotificationManager.shared.updateTopicSubscriptions(preferences: preferences)
    }
    
    func updateRole(to role: UserRole) async throws {
        guard let userId = user?.id else { return }
        
        // Update in Firestore
        try await FirestoreManager.shared.updateUser(userId: userId, data: ["role": role.rawValue])
        
        // Update local state
        await MainActor.run {
            self.userRole = role
            // Also update the user object if needed, though userRole is the main driver for UI
        }
    }
    
    deinit {
        if let handler = authStateHandler {
            Auth.auth().removeStateDidChangeListener(handler)
        }
    }
}

// User model
struct User: Identifiable, Codable {
    let id: String
    let email: String
    var name: String
    let role: UserRole
    var tier: UserTier = .standard
    let createdAt: Date
    var favoriteVenueIds: [String]
    var profileImage: String?
    var following: [String] = []
    var followers: [String] = []
    var isPrivate: Bool = false
    var fcmToken: String?
    var notificationPreferences: NotificationPreferences = NotificationPreferences()
    var rewardPoints: Int = 0
    var noShowCount: Int = 0
    var isBanned: Bool = false
    var softBanUntil: Date?
    var kycStatus: KYCStatus = .notSubmitted
    var dateOfBirth: Date?
    var referralCode: String
    var referredBy: String?
    var currentStreak: Int
    var lastVisitDate: Date?
    var lifetimePoints: Int
    
    init(id: String, email: String, name: String, role: UserRole, tier: UserTier = .standard, createdAt: Date, favoriteVenueIds: [String], profileImage: String? = nil, following: [String] = [], followers: [String] = [], isPrivate: Bool = false, fcmToken: String? = nil, notificationPreferences: NotificationPreferences = NotificationPreferences(), rewardPoints: Int = 0, noShowCount: Int = 0, isBanned: Bool = false, softBanUntil: Date? = nil, kycStatus: KYCStatus = .notSubmitted, dateOfBirth: Date? = nil, referralCode: String? = nil, referredBy: String? = nil, currentStreak: Int = 0, lastVisitDate: Date? = nil, lifetimePoints: Int = 0) {
        self.id = id
        self.email = email
        self.name = name
        self.role = role
        self.tier = tier
        self.createdAt = createdAt
        self.favoriteVenueIds = favoriteVenueIds
        self.profileImage = profileImage
        self.following = following
        self.followers = followers
        self.isPrivate = isPrivate
        self.fcmToken = fcmToken
        self.notificationPreferences = notificationPreferences
        self.rewardPoints = rewardPoints
        self.noShowCount = noShowCount
        self.isBanned = isBanned
        self.softBanUntil = softBanUntil
        self.kycStatus = kycStatus
        self.dateOfBirth = dateOfBirth
        self.referralCode = referralCode ?? String(UUID().uuidString.prefix(8)).uppercased()
        self.referredBy = referredBy
        self.currentStreak = currentStreak
        self.lastVisitDate = lastVisitDate
        self.lifetimePoints = lifetimePoints
    }
    
    init(firebaseUser: FirebaseAuth.User) {
        self.id = firebaseUser.uid
        self.email = firebaseUser.email ?? ""
        self.name = firebaseUser.displayName ?? "User"
        self.role = .user
        self.tier = .standard
        self.createdAt = Date()
        self.favoriteVenueIds = []
        self.profileImage = firebaseUser.photoURL?.absoluteString
        self.following = []
        self.followers = []
        self.isPrivate = false
        self.fcmToken = nil
        self.notificationPreferences = NotificationPreferences()
        self.rewardPoints = 0
        self.noShowCount = 0
        self.isBanned = false
        self.softBanUntil = nil
        self.kycStatus = .notSubmitted
        self.dateOfBirth = nil
        self.referralCode = String(UUID().uuidString.prefix(8)).uppercased()
        self.referredBy = nil
        self.currentStreak = 0
        self.lastVisitDate = nil
        self.lifetimePoints = 0
    }
    
    var isSoftBanned: Bool {
        guard let softBanUntil else { return false }
        return softBanUntil > Date()
    }
}

enum KYCStatus: String, Codable {
    case notSubmitted = "Not Submitted"
    case pending = "Pending Review"
    case verified = "Verified"
    case failed = "Failed"
    
    var badgeText: String { rawValue }
    
    var badgeColor: Color {
        switch self {
        case .verified: return .green
        case .pending: return .orange
        case .failed: return .red
        case .notSubmitted: return .gray
        }
    }
}

struct NotificationPreferences: Codable {
    var guestListUpdates: Bool = true
    var newVenues: Bool = false
    var promotions: Bool = false
}

enum UserRole: String, Codable {
    case user
    case promoter
    case venueManager = "venue_manager"
    case admin
}

enum UserTier: String, Codable, CaseIterable {
    case standard = "Standard"
    case vip = "VIP"
    case member = "Member"
    
    var color: String {
        switch self {
        case .standard: return "gray"
        case .vip: return "gold"
        case .member: return "purple"
        }
    }
    
    var price: Double {
        switch self {
        case .standard: return 0
        case .vip: return 29.99
        case .member: return 99.99
        }
    }
    
    var features: [String] {
        switch self {
        case .standard:
            return ["Basic Access", "Standard Booking"]
        case .vip:
            return ["Priority Booking", "Skip the Line", "5% Discount"]
        case .member:
            return ["Exclusive Events", "Concierge Service", "15% Discount", "Free VIP Entry"]
        }
    }
}
