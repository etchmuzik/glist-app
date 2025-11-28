import Foundation
import Supabase
import Combine
import SwiftUI
import AuthenticationServices
import GoogleSignIn
import CryptoKit

@MainActor
class AuthManager: NSObject, ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var userRole: UserRole = .user
    
    // private var authStateHandler: AuthStateDidChangeListenerHandle?
    
    override init() {
        super.init()
        registerAuthStateHandler()
    }
    
    private func registerAuthStateHandler() {
        Task {
            for await (event, session) in SupabaseManager.shared.client.auth.authStateChanges {
                switch event {
                case AuthChangeEvent.signedIn:
                    if let session {
                        self.user = User(supabaseUser: session.user)
                        self.isAuthenticated = true
                        self.fetchUserRole(userId: session.user.id.uuidString)
                    }
                case .tokenRefreshed:
                    if let session {
                        self.user = User(supabaseUser: session.user)
                        self.isAuthenticated = true
                    }
                case .signedOut, .userDeleted, .passwordRecovery:
                    self.user = nil
                    self.isAuthenticated = false
                    self.userRole = .user
                default:
                    break
                }
            }
        }
    }
    
    func fetchUserRole(userId: String) {
        Task {
            do {
                let fetched = try await SupabaseDataManager.shared.fetchUser(userId: userId)
                if let user = fetched {
                    await MainActor.run {
                        self.user = user
                        
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
        try await SupabaseManager.shared.client.auth.signIn(email: email, password: password)
    }
    
    func signUp(email: String, password: String, name: String, role: UserRole = .user, referralCode: String? = nil) async throws {
        // Check referral code if provided
        var referredBy: String?
        if let code = referralCode, !code.isEmpty {
            print("DEBUG: Checking referral code: \(code)")
            do {
                referredBy = try await SupabaseDataManager.shared.checkReferralCode(code: code)
                print("DEBUG: Referral code check result: \(String(describing: referredBy))")
            } catch {
                print("DEBUG: Referral code check failed: \(error)")
                throw error
            }
        }
        

        
        var metadata: [String: AnyJSON] = [
            "name": .string(name),
            "role": .string(role.rawValue)
        ]
        
        if let referrerId = referredBy {
            metadata["referred_by"] = .string(referrerId)
        }
        
        print("DEBUG: Starting signUp for \(email)")
        
        let response: AuthResponse
        do {
            response = try await SupabaseManager.shared.client.auth.signUp(
                email: email,
                password: password,
                data: metadata
            )
            print("DEBUG: Supabase auth.signUp success. Session: \(String(describing: response.session))")
        } catch {
            print("DEBUG: Supabase auth.signUp failed: \(error)")
            throw error
        }
        
        if let session = response.session {
            await MainActor.run {
                self.user = User(supabaseUser: session.user)
                self.isAuthenticated = true
                self.fetchUserRole(userId: session.user.id.uuidString)
            }
        }
        
        // User document is created automatically by database trigger on auth.users
        // Referral rewards are also handled by the trigger
    }
    
    func signInWithGoogle() async throws {
        guard let topViewController = await MainActor.run(body: {
            return UIApplication.shared.connectedScenes
                .filter { $0.activationState == .foregroundActive }
                .compactMap { $0 as? UIWindowScene }
                .first?.windows
                .filter { $0.isKeyWindow }.first?.rootViewController
        }) else {
            throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not find root view controller"])
        }
        
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: topViewController)
        
        guard let idToken = result.user.idToken?.tokenString else {
            throw NSError(domain: "Auth", code: -2, userInfo: [NSLocalizedDescriptionKey: "Could not get ID token"])
        }
        
        // Remove GoogleAuthProvider usage as it is Firebase specific
        // let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: result.user.accessToken.tokenString)
        
        let session = try await SupabaseManager.shared.client.auth.signInWithIdToken(credentials: .init(provider: .google, idToken: idToken, accessToken: result.user.accessToken.tokenString, nonce: nil))
        try await handleSocialLoginSuccess(user: session.user)
    }
    
    func signInWithApple() async throws {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let nonce = randomNonceString()
        currentNonce = nonce
        request.nonce = sha256(nonce)
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
    
    // Helper for handling successful social login (creating user doc if needed)
    private func handleSocialLoginSuccess(user: Supabase.User) async throws {
        // User document is created automatically by database trigger
        // We can optionally fetch it to ensure it exists or update last login
        if try await SupabaseDataManager.shared.fetchUser(userId: user.id.uuidString) == nil {
            print("Warning: User document not found after social login. Trigger might have failed.")
        }
    }

    // Helpers for Apple Sign In
    private var currentNonce: String?
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        
        return String(nonce)
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            return String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    func signOut() throws {
        Task {
            try await SupabaseManager.shared.client.auth.signOut()
        }
        self.user = nil
        self.isAuthenticated = false
        self.userRole = .user
    }
    
    func updateName(_ name: String) async throws {
        guard var currentUser = user else { return }
        currentUser.name = name // Update local model temporarily
        
        // Update in Firestore
        try await SupabaseDataManager.shared.updateUser(userId: currentUser.id, data: ["name": GlistAnyEncodable(name)])
        
        // Update local state
        await MainActor.run {
            self.user?.name = name
        }
    }
    
    func updateNotificationPreferences(_ preferences: NotificationPreferences) async throws {
        guard let userId = user?.id else { return }
        
        let data: [String: GlistAnyEncodable] = [
            "guestListUpdates": GlistAnyEncodable(preferences.guestListUpdates),
            "newVenues": GlistAnyEncodable(preferences.newVenues),
            "promotions": GlistAnyEncodable(preferences.promotions)
        ]
        
        try await SupabaseDataManager.shared.updateNotificationPreferences(userId: userId, data: data)
        
        await MainActor.run {
            self.user?.notificationPreferences = preferences
        }
        await NotificationManager.shared.updateTopicSubscriptions(preferences: preferences)
    }
    
    func updateRole(to role: UserRole) async throws {
        guard let userId = user?.id else { return }
        
        // Update in Firestore
        try await SupabaseDataManager.shared.updateUser(userId: userId, data: ["role": GlistAnyEncodable(role.rawValue)])
        
        // Update local state
        await MainActor.run {
            self.userRole = role
            // Also update the user object if needed, though userRole is the main driver for UI
        }
    }
    
    func deleteAccount() async throws {
        guard let userId = user?.id else { return }
        
        // Delete from Database
        try await SupabaseDataManager.shared.deleteUser(userId: userId)
        
        // Delete from Supabase Auth (Requires Admin or Server Function usually)
        // For now, we just sign out locally as client-side delete is restricted
        // try await SupabaseManager.shared.client.functions.invoke("delete-user")
        try await SupabaseManager.shared.client.auth.signOut()
        
        await MainActor.run {
            self.user = nil
            self.isAuthenticated = false
            self.userRole = .user
        }
    }
    
    func updateProfileImage(_ imageData: Data) async throws {
        guard let userId = user?.id else { return }
        
        let filename = "\(userId)-\(Int(Date().timeIntervalSince1970)).jpg"
        let path = "profile-images/\(filename)"
        
        do {
            let url = try await SupabaseManager.shared.uploadImage(data: imageData, bucket: "profile-images", path: path)
            let urlString = url.absoluteString
            
            try await SupabaseDataManager.shared.updateProfileImage(userId: userId, imageUrl: urlString)
            
            await MainActor.run {
                self.user?.profileImage = urlString
            }
        } catch {
            print("Error uploading profile image: \(error)")
            throw error
        }
    }
    
    // deinit {
    //     if let handler = authStateHandler {
    //         Auth.auth().removeStateDidChangeListener(handler)
    //     }
    // }
}

// User model
struct User: Identifiable, Codable, Sendable {
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
    var referralCode: String?
    var referredBy: String?
    var currentStreak: Int
    var lastVisitDate: Date?
    var lifetimePoints: Int
    
    enum CodingKeys: String, CodingKey {
        case id, email, name, role, tier, createdAt
        case favoriteVenueIds, profileImage, following, followers
        case isPrivate, fcmToken, notificationPreferences
        case rewardPoints, noShowCount, isBanned, softBanUntil
        case kycStatus, dateOfBirth, referralCode, referredBy
        case currentStreak, lastVisitDate, lifetimePoints
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        name = try container.decode(String.self, forKey: .name)
        
        // Robust Role Decoding
        if let roleString = try? container.decode(String.self, forKey: .role) {
            // Try exact match first, then lowercase
            if let role = UserRole(rawValue: roleString) {
                self.role = role
            } else if let role = UserRole(rawValue: roleString.lowercased()) {
                self.role = role
            } else {
                self.role = .user
            }
        } else {
            self.role = .user
        }
        
        // Robust Tier Decoding
        if let tierString = try? container.decode(String.self, forKey: .tier) {
            if let tier = UserTier(rawValue: tierString) {
                self.tier = tier
            } else if let tier = UserTier(rawValue: tierString.lowercased()) {
                self.tier = tier
            } else {
                self.tier = .standard
            }
        } else {
            self.tier = .standard
        }
        
        // Handle missing createdAt by defaulting to now
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        
        // Handle potential NULLs for arrays and booleans
        favoriteVenueIds = try container.decodeIfPresent([String].self, forKey: .favoriteVenueIds) ?? []
        profileImage = try container.decodeIfPresent(String.self, forKey: .profileImage)
        following = try container.decodeIfPresent([String].self, forKey: .following) ?? []
        followers = try container.decodeIfPresent([String].self, forKey: .followers) ?? []
        isPrivate = try container.decodeIfPresent(Bool.self, forKey: .isPrivate) ?? false
        fcmToken = try container.decodeIfPresent(String.self, forKey: .fcmToken)
        notificationPreferences = try container.decodeIfPresent(NotificationPreferences.self, forKey: .notificationPreferences) ?? NotificationPreferences()
        rewardPoints = try container.decodeIfPresent(Int.self, forKey: .rewardPoints) ?? 0
        noShowCount = try container.decodeIfPresent(Int.self, forKey: .noShowCount) ?? 0
        isBanned = try container.decodeIfPresent(Bool.self, forKey: .isBanned) ?? false
        softBanUntil = try container.decodeIfPresent(Date.self, forKey: .softBanUntil)
        kycStatus = try container.decodeIfPresent(KYCStatus.self, forKey: .kycStatus) ?? .notSubmitted
        dateOfBirth = try container.decodeIfPresent(Date.self, forKey: .dateOfBirth)
        referralCode = try container.decodeIfPresent(String.self, forKey: .referralCode)
        referredBy = try container.decodeIfPresent(String.self, forKey: .referredBy)
        currentStreak = try container.decodeIfPresent(Int.self, forKey: .currentStreak) ?? 0
        lastVisitDate = try container.decodeIfPresent(Date.self, forKey: .lastVisitDate)
        lifetimePoints = try container.decodeIfPresent(Int.self, forKey: .lifetimePoints) ?? 0
    }
    
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
    
    init(supabaseUser: Supabase.User) {
        self.id = supabaseUser.id.uuidString
        self.email = supabaseUser.email ?? ""
        self.name = supabaseUser.userMetadata["name"] as? String ?? "User"
        
        self.role = .user
        
        self.tier = .standard
        self.createdAt = Date()
        self.favoriteVenueIds = []
        self.profileImage = supabaseUser.userMetadata["avatar_url"] as? String
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

enum KYCStatus: String, Codable, Sendable {
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

struct NotificationPreferences: Codable, Sendable {
    var guestListUpdates: Bool = true
    var newVenues: Bool = false
    var promotions: Bool = false
}

enum UserRole: String, Codable, Sendable {
    case user
    case promoter
    case venueManager = "venue_manager"
    case admin
}

enum UserTier: String, Codable, CaseIterable, Sendable {
    case standard = "standard"
    case vip = "vip"
    case member = "member"
    
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

// MARK: - Apple Sign In Delegate
extension AuthManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }
            
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                return
            }
            
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
            }
            
            guard let authorizationCode = appleIDCredential.authorizationCode,
                  let codeString = String(data: authorizationCode, encoding: .utf8) else {
                print("Unable to serialize authorization code")
                return
            }

            Task {
                do {
                    let session = try await SupabaseManager.shared.client.auth.signInWithIdToken(credentials: .init(provider: .apple, idToken: idTokenString, accessToken: nil, nonce: nonce))
                        // If name is provided (first sign in), update it
                        if let fullName = appleIDCredential.fullName {
                            let formatter = PersonNameComponentsFormatter()
                            var name = formatter.string(from: fullName)
                            if name.isEmpty { name = "User" }
                            
                            // Trigger created the user with default name "User"
                            // We need to update it with the real name
                            try await SupabaseDataManager.shared.updateUser(userId: session.user.id.uuidString, data: ["name": GlistAnyEncodable(name)])
                        } else {
                            try await handleSocialLoginSuccess(user: session.user)
                        }
                } catch {
                    print("Error signing in with Apple: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Sign in with Apple errored: \(error)")
    }
}

extension AuthManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .compactMap { $0 as? UIWindowScene }
            .first?.windows
            .filter { $0.isKeyWindow }.first ?? UIWindow()
    }
}
