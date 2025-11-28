import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var localeManager: LocalizationManager
    
    private var kycStatusText: String {
        guard let status = authManager.user?.kycStatus else { return "Not set" }
        switch status {
        case .verified: return "Verified"
        case .pending: return "Pending"
        case .failed: return "Rejected"
        case .notSubmitted: return "Not submitted"
        }
    }
    
    private var notificationStatusText: String {
        guard let prefs = authManager.user?.notificationPreferences else { return "Off" }
        return (prefs.guestListUpdates || prefs.newVenues || prefs.promotions) ? "On" : "Off"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.background.ignoresSafeArea()
                
                List {
                    // Profile Snapshot
                    if let user = authManager.user {
                        Section {
                            HStack(spacing: 12) {
                                if let urlString = user.profileImage, let url = URL(string: urlString) {
                                    AsyncImage(url: url) { image in
                                        image.resizable().scaledToFill()
                                    } placeholder: {
                                        Color.gray
                                    }
                                    .frame(width: 52, height: 52)
                                    .clipShape(Circle())
                                } else if let urlString = user.profileImage, urlString.hasPrefix("data:image") {
                                    // Handle Base64 image
                                    if let data = Data(base64Encoded: urlString.components(separatedBy: ",").last ?? ""),
                                       let uiImage = UIImage(data: data) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 52, height: 52)
                                            .clipShape(Circle())
                                    } else {
                                        placeholderImage(name: user.name)
                                    }
                                } else {
                                    placeholderImage(name: user.name)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(user.name)
                                        .font(Theme.Fonts.display(size: 18))
                                        .foregroundStyle(.white)
                                    Text(user.email)
                                        .font(Theme.Fonts.body(size: 12))
                                        .foregroundStyle(.gray)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 6) {
                                    Text(user.role.rawValue.capitalized)
                                        .font(Theme.Fonts.body(size: 12))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color.theme.surface.opacity(0.6))
                                        .clipShape(Capsule())
                                    
                                    Text(user.tier.rawValue)
                                        .font(Theme.Fonts.body(size: 12))
                                        .foregroundStyle(.black)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color.theme.accent)
                                        .clipShape(Capsule())
                                }
                            }
                            
                            NavigationLink(destination: AccountSettingsView()) {
                                Text("Edit Profile")
                                    .font(Theme.Fonts.body(size: 12))
                                    .fontWeight(.bold)
                                    .foregroundStyle(.black)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(Color.white)
                                    .clipShape(Capsule())
                            }
                        }
                        .listRowBackground(Color.theme.surface)
                    }
                    
                    // Section: Account
                    Section {
                        NavigationLink(destination: AccountSettingsView()) {
                            SettingRow(icon: "person.circle", title: "Account Settings", subtitle: "Profile, password, privacy")
                        }
                        
                        NavigationLink(destination: KYCSubmissionView()) {
                            SettingRow(
                                icon: "checkmark.seal",
                                title: "Identity Verification",
                                subtitle: "KYC status",
                                trailing: kycStatusText
                            )
                        }
                    } header: {
                        Text("ACCOUNT")
                            .font(Theme.Fonts.caption())
                            .foregroundStyle(Color.theme.textSecondary)
                    }
                    .listRowBackground(Color.theme.surface)
                    
                    // Section: Preferences
                    Section {
                        NavigationLink(destination: NotificationsView()) {
                            SettingRow(
                                icon: "bell",
                                title: "Notifications",
                                subtitle: "Push, reminders",
                                trailing: notificationStatusText
                            )
                        }
                        
                        Picker(selection: Binding(
                            get: { localeManager.language },
                            set: { localeManager.setLanguage($0) }
                        )) {
                            Text("English").tag(AppLanguage.english)
                            Text("العربية").tag(AppLanguage.arabic)
                        } label: {
                            SettingRow(
                                icon: "globe",
                                title: "Language",
                                subtitle: localeManager.language == .english ? "English" : "العربية"
                            )
                        }
                        .pickerStyle(.menu)
                        .tint(.white) // Ensure picker text is visible
                        
                    } header: {
                        Text("PREFERENCES")
                            .font(Theme.Fonts.caption())
                            .foregroundStyle(Color.theme.textSecondary)
                    }
                    .listRowBackground(Color.theme.surface)
                    
                    // Section: Support & Legal
                    Section {
                        NavigationLink(destination: HelpView()) {
                            SettingRow(icon: "questionmark.circle", title: "Help & Support")
                        }
                        
                        NavigationLink(destination: PrivacyView()) {
                            SettingRow(icon: "lock", title: "Privacy & Security")
                        }
                        
                        Button {
                            if let mailto = URL(string: "mailto:support@glist.app") {
                                openURL(mailto)
                            }
                        } label: {
                            SettingRow(icon: "envelope", title: "Contact Support")
                        }
                    } header: {
                        Text("SUPPORT")
                            .font(Theme.Fonts.caption())
                            .foregroundStyle(Color.theme.textSecondary)
                    }
                    .listRowBackground(Color.theme.surface)
                    
                    // Section: Actions
                    Section {
                        Button {
                            Task {
                                try? authManager.signOut()
                                ConciergeChatManager.shared.tearDown()
                                dismiss()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "arrow.right.square")
                                    .foregroundStyle(.red)
                                    .frame(width: 24)
                                Text("Logout")
                                    .font(Theme.Fonts.body(size: 16))
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    .listRowBackground(Color.theme.surface)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func placeholderImage(name: String) -> some View {
        Circle()
            .fill(Color.theme.surface)
            .frame(width: 52, height: 52)
            .overlay(
                Text(name.prefix(1))
                    .font(Theme.Fonts.display(size: 22))
                    .foregroundStyle(.white)
            )
    }
}

// Reusing the SettingRow from ProfileView (we might need to move it here or make it public)
struct SettingRow: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    var trailing: String? = nil
    var color: Color = .white
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: subtitle == nil ? 0 : 2) {
                Text(title)
                    .font(Theme.Fonts.body(size: 16))
                    .foregroundStyle(color)
                if let subtitle {
                    Text(subtitle)
                        .font(Theme.Fonts.body(size: 12))
                        .foregroundStyle(color.opacity(0.6))
                }
            }
            
            Spacer()
            
            if let trailing {
                Text(trailing)
                    .font(Theme.Fonts.body(size: 12))
                    .foregroundStyle(Color.theme.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.theme.surface.opacity(0.5))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 6)
    }
}
