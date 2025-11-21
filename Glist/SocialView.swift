import SwiftUI

struct SocialView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var socialManager = SocialManager()
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.background.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.gray)
                        
                        TextField("Find friends...", text: $searchText)
                            .foregroundStyle(.white)
                            .autocorrectionDisabled()
                            .onChange(of: searchText) { newValue in
                                socialManager.searchUsers(query: newValue)
                            }
                    }
                    .padding()
                    .background(Color.theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                    
                    // Content
                    if searchText.isEmpty {
                        // Show Following/Followers lists
                        List {
                            Section("FOLLOWING") {
                                if socialManager.followingUsers.isEmpty {
                                    Text("You aren't following anyone yet.")
                                        .foregroundStyle(.gray)
                                } else {
                                    ForEach(socialManager.followingUsers) { user in
                                        UserRow(user: user, isFollowing: true)
                                    }
                                }
                            }
                            .listRowBackground(Color.theme.surface)
                            
                            Section("FOLLOWERS") {
                                if socialManager.followerUsers.isEmpty {
                                    Text("No followers yet.")
                                        .foregroundStyle(.gray)
                                } else {
                                    ForEach(socialManager.followerUsers) { user in
                                        UserRow(user: user, isFollowing: false) // Logic needed to check if also following back
                                    }
                                }
                            }
                            .listRowBackground(Color.theme.surface)
                        }
                        .scrollContentBackground(.hidden)
                    } else {
                        // Search Results
                        if socialManager.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else if socialManager.searchResults.isEmpty {
                            Text("No users found.")
                                .foregroundStyle(.gray)
                                .padding(.top, 40)
                        } else {
                            List {
                                ForEach(socialManager.searchResults) { user in
                                    UserRow(user: user, isFollowing: authManager.user?.following.contains(user.id) ?? false)
                                }
                            }
                            .scrollContentBackground(.hidden)
                        }
                    }
                }
            }
            .navigationTitle("Find Friends")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct UserRow: View {
    let user: User
    let isFollowing: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
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
            
            VStack(alignment: .leading, spacing: 2) {
                Text(user.name)
                    .font(Theme.Fonts.body(size: 16))
                    .foregroundStyle(.white)
                
                if user.tier != .standard {
                    Text(user.tier.rawValue)
                        .font(Theme.Fonts.body(size: 10))
                        .foregroundStyle(Color(hex: user.tier.color))
                }
            }
            
            Spacer()
            
            Button {
                // Action to follow/unfollow
            } label: {
                Text(isFollowing ? "Following" : "Follow")
                    .font(Theme.Fonts.body(size: 12))
                    .fontWeight(.bold)
                    .foregroundStyle(isFollowing ? .white : .black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(isFollowing ? Color.gray.opacity(0.3) : Color.white)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
    }
}
