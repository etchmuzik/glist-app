import SwiftUI

// MARK: - Account Settings
struct AccountSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    @State private var name = ""
    @State private var email = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.background.ignoresSafeArea()
                
                Form {
                    Section("ACCOUNT INFO") {
                        TextField("Name", text: $name)
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .disabled(true)
                    }
                    
                    Section("ROLE") {
                        HStack {
                            Text("Current Role")
                            Spacer()
                            Text(authManager.userRole.rawValue.uppercased())
                                .foregroundStyle(.gray)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Account Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                name = authManager.user?.name ?? ""
                email = authManager.user?.email ?? ""
            }
        }
    }
}

// MARK: - Notifications
struct NotificationsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var guestListUpdates = true
    @State private var newVenues = false
    @State private var promotions = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.background.ignoresSafeArea()
                
                Form {
                    Section("PUSH NOTIFICATIONS") {
                        Toggle("Guest List Updates", isOn: $guestListUpdates)
                        Toggle("New Venues", isOn: $newVenues)
                        Toggle("Promotions", isOn: $promotions)
                    }
                    
                    Section {
                        Text("Push notifications are not yet configured. This feature will be available soon.")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Privacy & Security
struct PrivacyView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("DATA COLLECTION")
                                .font(Theme.Fonts.body(size: 12))
                                .fontWeight(.bold)
                                .foregroundStyle(.gray)
                            
                            Text("LSTD stores your guest list requests and favorites in the cloud using Firebase. Your data is encrypted and secure.")
                                .font(Theme.Fonts.body(size: 14))
                                .foregroundStyle(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ACCOUNT DELETION")
                                .font(Theme.Fonts.body(size: 12))
                                .fontWeight(.bold)
                                .foregroundStyle(.gray)
                            
                            Text("To delete your account and all associated data, please contact support@glist.com")
                                .font(Theme.Fonts.body(size: 14))
                                .foregroundStyle(.white)
                        }
                        
                        Button {
                            if let url = URL(string: "https://glist.com/privacy") {
                                // Open privacy policy
                            }
                        } label: {
                            HStack {
                                Text("View Full Privacy Policy")
                                    .font(Theme.Fonts.body(size: 14))
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                            }
                            .foregroundStyle(.white)
                            .padding(16)
                            .background(Color.theme.surface.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Privacy & Security")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Help & Support
struct HelpView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        HelpItem(
                            icon: "envelope.fill",
                            title: "Email Support",
                            subtitle: "support@glist.com"
                        )
                        
                        HelpItem(
                            icon: "message.fill",
                            title: "Live Chat",
                            subtitle: "Coming soon"
                        )
                        
                        HelpItem(
                            icon: "book.fill",
                            title: "FAQ",
                            subtitle: "Common questions"
                        )
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("APP VERSION")
                                .font(Theme.Fonts.body(size: 12))
                                .fontWeight(.bold)
                                .foregroundStyle(.gray)
                            
                            Text("Version 1.0.0")
                                .font(Theme.Fonts.body(size: 14))
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 20)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Help & Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct HelpItem: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(Color.theme.accent)
                .frame(width: 40, height: 40)
                .background(Color.theme.surface)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Theme.Fonts.body(size: 16))
                    .foregroundStyle(.white)
                
                Text(subtitle)
                    .font(Theme.Fonts.body(size: 14))
                    .foregroundStyle(.gray)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.gray)
        }
        .padding(16)
        .background(Color.theme.surface.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

#Preview {
    AccountSettingsView()
        .environmentObject(AuthManager())
}
