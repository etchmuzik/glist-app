import SwiftUI

struct UserManagementView: View {
    @State private var users: [User] = []
    @State private var isLoading = false
    @State private var searchText = ""
    @State private var filter: UserFilter = .all
    
    enum UserFilter {
        case all
        case banned
    }
    
    var filteredUsers: [User] {
        var result = users
        
        if filter == .banned {
            result = result.filter { $0.isBanned }
        }
        
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.email.localizedCaseInsensitiveContains(searchText) }
        }
        
        return result
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search and Filter
            VStack(spacing: 12) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Color.theme.textSecondary)
                    TextField("Search users...", text: $searchText)
                        .foregroundStyle(Color.theme.textPrimary)
                        .onChange(of: searchText) { oldValue, newValue in
                            if newValue.count > 2 {
                                searchUsers(query: newValue)
                            } else if newValue.isEmpty {
                                loadUsers()
                            }
                        }
                }
                .padding(12)
                .background(Color.theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                // Filter Chips
                HStack(spacing: 12) {
                    FilterChip(title: "All Users", isSelected: filter == .all) {
                        filter = .all
                    }
                    FilterChip(title: "Banned", isSelected: filter == .banned) {
                        filter = .banned
                    }
                    Spacer()
                }
            }
            .padding(20)
            
            if isLoading {
                ProgressView()
                    .tint(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredUsers.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.slash")
                        .font(.system(size: 40))
                        .foregroundStyle(.gray)
                    Text("No users found")
                        .foregroundStyle(.gray)
                        .font(Theme.Fonts.body(size: 14))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredUsers) { user in
                            AdminUserRow(user: user) {
                                // Refresh list after action
                                if searchText.isEmpty {
                                    loadUsers()
                                } else {
                                    searchUsers(query: searchText)
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
        }
        .onAppear {
            loadUsers()
        }
    }
    
    private func loadUsers() {
        isLoading = true
        Task {
            do {
                users = try await SupabaseDataManager.shared.fetchAllUsers()
            } catch {
                print("Error loading users: \(error)")
            }
            isLoading = false
        }
    }
    
    private func searchUsers(query: String) {
        isLoading = true
        Task {
            do {
                users = try await SupabaseDataManager.shared.searchUsers(query: query)
            } catch {
                print("Error searching users: \(error)")
            }
            isLoading = false
        }
    }
}

struct AdminUserRow: View {
    let user: User
    let onUpdate: () -> Void
    @State private var isProcessing = false
    @State private var showBanAlert = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            if let imageUrl = user.profileImage, let url = URL(string: imageUrl) {
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
                HStack {
                    Text(user.name)
                        .font(Theme.Fonts.body(size: 16))
                        .fontWeight(.bold)
                        .foregroundStyle(Color.theme.textPrimary)
                    
                    if user.isBanned {
                        Text("BANNED")
                            .font(Theme.Fonts.body(size: 10))
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .clipShape(Capsule())
                    }
                }
                
                Text(user.email)
                    .font(Theme.Fonts.body(size: 14))
                    .foregroundStyle(Color.theme.textSecondary)
                
                HStack(spacing: 8) {
                    Text(user.role.rawValue.capitalized)
                        .font(Theme.Fonts.body(size: 12))
                        .foregroundStyle(Color.theme.accent)
                    
                    Text("•")
                        .foregroundStyle(.gray)
                    
                    Text("Joined \(user.createdAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(Theme.Fonts.body(size: 12))
                        .foregroundStyle(.gray)
                }
            }
            
            Spacer()
            
            Menu {
                if user.isBanned {
                    Button {
                        unbanUser()
                    } label: {
                        Label("Unban User", systemImage: "lock.open")
                    }
                } else {
                    Button(role: .destructive) {
                        showBanAlert = true
                    } label: {
                        Label("Ban User", systemImage: "lock")
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.title3)
                    .foregroundStyle(Color.theme.textSecondary)
                    .padding(8)
                    .background(Color.theme.surface)
                    .clipShape(Circle())
            }
        }
        .padding(16)
        .background(Color.theme.surface.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
        .alert("Ban User", isPresented: $showBanAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Ban", role: .destructive) {
                banUser()
            }
        } message: {
            Text("Are you sure you want to ban \(user.name)? They will lose access to social features.")
        }
        .disabled(isProcessing)
    }
    
    private func banUser() {
        isProcessing = true
        Task {
            do {
                try await SupabaseDataManager.shared.banUser(userId: user.id)
                await MainActor.run {
                    isProcessing = false
                    onUpdate()
                }
            } catch {
                print("Error banning user: \(error)")
                isProcessing = false
            }
        }
    }
    
    private func unbanUser() {
        isProcessing = true
        Task {
            do {
                try await SupabaseDataManager.shared.unbanUser(userId: user.id)
                await MainActor.run {
                    isProcessing = false
                    onUpdate()
                }
            } catch {
                print("Error unbanning user: \(error)")
                isProcessing = false
            }
        }
    }
}
