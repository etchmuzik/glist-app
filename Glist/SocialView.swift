import SwiftUI

struct SocialView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var socialManager = SocialManager.shared
    @State private var selectedTab = 0
    @State private var searchText = ""
    @State private var activityFeed: [ActivityItem] = []
    @State private var pendingRequests: [FriendRequest] = []
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.background.ignoresSafeArea()
                
                if let user = authManager.user, user.isBanned {
                    VStack(spacing: 16) {
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.red)
                        
                        Text(LocalizedStringKey("account_restricted"))
                            .font(Theme.Fonts.display(size: 24))
                            .foregroundStyle(.white)
                        
                        Text(LocalizedStringKey("social_restricted"))
                            .font(Theme.Fonts.body(size: 16))
                            .foregroundStyle(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    VStack(spacing: 0) {
                        // Custom Segmented Control
                        HStack(spacing: 0) {
                            SocialTabButton(title: NSLocalizedString("tab_feed", comment: ""), isSelected: selectedTab == 0) { selectedTab = 0 }
                            SocialTabButton(title: NSLocalizedString("tab_search", comment: ""), isSelected: selectedTab == 1) { selectedTab = 1 }
                            SocialTabButton(title: NSLocalizedString("tab_requests", comment: ""), isSelected: selectedTab == 2) { selectedTab = 2 }
                        }
                        .padding()
                        
                        if selectedTab == 0 {
                            FeedView(activities: activityFeed)
                        } else if selectedTab == 1 {
                            UserSearchView(searchText: $searchText)
                        } else {
                            RequestsView(requests: pendingRequests) { request in
                                Task {
                                    try? await socialManager.acceptRequest(request)
                                    await refreshData()
                                }
                            } onDecline: { request in
                                Task {
                                    try? await socialManager.declineRequest(request)
                                    await refreshData()
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("SOCIAL")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                Task {
                    await refreshData()
                }
            }
        }
    }
    
    private func refreshData() async {
        guard let user = authManager.user else { return }
        
        do {
            // Fetch Feed
            if !user.following.isEmpty {
                activityFeed = try await socialManager.fetchActivityFeed(followingUserIds: user.following)
            }
            
            // Fetch Requests
            pendingRequests = try await socialManager.fetchPendingRequests(for: user.id)
        } catch {
            print("Error refreshing social data: \(error)")
        }
    }
}

struct SocialTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(Theme.Fonts.body(size: 14))
                    .fontWeight(.bold)
                    .foregroundStyle(isSelected ? Color.theme.accent : Color.theme.textSecondary)
                
                Rectangle()
                    .fill(isSelected ? Color.theme.accent : Color.clear)
                    .frame(height: 2)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct FeedView: View {
    let activities: [ActivityItem]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if activities.isEmpty {
                    Text(LocalizedStringKey("no_activity"))
                        .font(Theme.Fonts.body(size: 14))
                        .foregroundStyle(Color.theme.textSecondary)
                        .padding(.top, 40)
                } else {
                    ForEach(activities) { activity in
                        ActivityCard(activity: activity)
                    }
                }
            }
            .padding()
        }
    }
}

struct ActivityCard: View {
    let activity: ActivityItem
    @State private var user: User?
    
    var body: some View {
        HStack(spacing: 16) {
            // User Avatar
            if let imageUrl = user?.profileImage, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color.gray
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user?.name ?? "Unknown User")
                    .font(Theme.Fonts.body(size: 14))
                    .fontWeight(.bold)
                    .foregroundStyle(Color.theme.textPrimary)
                
                Text("\(activity.title) \(activity.subtitle)")
                    .font(Theme.Fonts.body(size: 14))
                    .foregroundStyle(Color.theme.textSecondary)
                
                Text(activity.timestamp.formatted(.relative(presentation: .named)))
                    .font(Theme.Fonts.body(size: 12))
                    .foregroundStyle(.gray)
            }
            
            Spacer()
            
            // Icon based on type
            Image(systemName: iconName(for: activity.type))
                .font(.title2)
                .foregroundStyle(Color.theme.accent)
        }
        .padding()
        .background(Color.theme.surface.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .task {
            user = try? await FirestoreManager.shared.fetchUser(userId: activity.userId)
        }
    }
    
    func iconName(for type: ActivityType) -> String {
        switch type {
        case .booking: return "calendar.badge.clock"
        case .guestList: return "list.bullet.clipboard"
        case .review: return "star.bubble"
        case .follow: return "person.badge.plus"
        }
    }
}

struct UserSearchView: View {
    @Binding var searchText: String
    @StateObject private var socialManager = SocialManager.shared
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        VStack {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.theme.textSecondary)
                TextField(LocalizedStringKey("search_users_placeholder"), text: $searchText)
                    .foregroundStyle(Color.theme.textPrimary)
                    .onChange(of: searchText) { newValue in
                        socialManager.searchUsers(query: newValue)
                    }
            }
            .padding(12)
            .background(Color.theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding()
            
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(socialManager.searchResults) { user in
                        if user.id != authManager.user?.id {
                            UserRow(user: user)
                        }
                    }
                }
                .padding()
            }
        }
    }
}

struct UserRow: View {
    let user: User
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var socialManager = SocialManager.shared
    @State private var isFollowing = false
    @State private var isRequested = false
    
    var body: some View {
        HStack {
            if let imageUrl = user.profileImage, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color.gray
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.gray)
            }
            
            Text(user.name)
                .font(Theme.Fonts.body(size: 16))
                .foregroundStyle(Color.theme.textPrimary)
            
            Spacer()
            
            Button {
                Task {
                    if isFollowing {
                        try? await socialManager.unfollowUser(currentUserId: authManager.user?.id ?? "", targetUserId: user.id)
                        isFollowing = false
                    } else {
                        try? await socialManager.sendFriendRequest(currentUserId: authManager.user?.id ?? "", targetUser: user)
                        if user.isPrivate {
                            isRequested = true
                        } else {
                            isFollowing = true
                        }
                    }
                }
            } label: {
                Text(isFollowing ? NSLocalizedString("following", comment: "") : (isRequested ? NSLocalizedString("requested", comment: "") : NSLocalizedString("follow", comment: "")))
                    .font(Theme.Fonts.body(size: 12))
                    .fontWeight(.bold)
                    .foregroundStyle(isFollowing || isRequested ? Color.theme.textPrimary : .black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(isFollowing || isRequested ? Color.clear : Color.white)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.white, lineWidth: isFollowing || isRequested ? 1 : 0)
                    )
            }
        }
        .padding()
        .background(Color.theme.surface.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear {
            if let currentUser = authManager.user {
                isFollowing = currentUser.following.contains(user.id)
            }
        }
    }
}

struct RequestsView: View {
    let requests: [FriendRequest]
    let onAccept: (FriendRequest) -> Void
    let onDecline: (FriendRequest) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if requests.isEmpty {
                    Text(LocalizedStringKey("no_pending_requests"))
                        .font(Theme.Fonts.body(size: 14))
                        .foregroundStyle(Color.theme.textSecondary)
                        .padding(.top, 40)
                } else {
                    ForEach(requests) { request in
                        RequestRow(request: request, onAccept: onAccept, onDecline: onDecline)
                    }
                }
            }
            .padding()
        }
    }
}

struct RequestRow: View {
    let request: FriendRequest
    let onAccept: (FriendRequest) -> Void
    let onDecline: (FriendRequest) -> Void
    @State private var fromUser: User?
    
    var body: some View {
        HStack {
            if let user = fromUser {
                if let imageUrl = user.profileImage, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Color.gray
                    }
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.gray)
                }
                
                Text(user.name)
                    .font(Theme.Fonts.body(size: 16))
                    .foregroundStyle(Color.theme.textPrimary)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button {
                    onDecline(request)
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.red)
                        .padding(8)
                        .background(Color.theme.surface)
                        .clipShape(Circle())
                }
                
                Button {
                    onAccept(request)
                } label: {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.green)
                        .padding(8)
                        .background(Color.theme.surface)
                        .clipShape(Circle())
                }
            }
        }
        .padding()
        .background(Color.theme.surface.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .task {
            fromUser = try? await FirestoreManager.shared.fetchUser(userId: request.fromUserId)
        }
    }
}
