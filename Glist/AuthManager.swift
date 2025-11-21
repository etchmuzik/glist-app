import Foundation
import FirebaseAuth
import Combine

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
    
    func signUp(email: String, password: String, name: String) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        
        // Create user document in Firestore
        let newUser = User(
            id: result.user.uid,
            email: email,
            name: name,
            role: .user,
            createdAt: Date(),
            favoriteVenueIds: []
        )
        
        try await FirestoreManager.shared.createUser(newUser)
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
        self.user = nil
        self.isAuthenticated = false
        self.userRole = .user
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
    let name: String
    let role: UserRole
    var tier: UserTier = .standard
    let createdAt: Date
    var favoriteVenueIds: [String]
    var profileImage: String?
    var following: [String] = []
    var followers: [String] = []
    var isPrivate: Bool = false
    
    init(id: String, email: String, name: String, role: UserRole, tier: UserTier = .standard, createdAt: Date, favoriteVenueIds: [String], profileImage: String? = nil, following: [String] = [], followers: [String] = [], isPrivate: Bool = false) {
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
    }
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
