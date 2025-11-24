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
                        if name != authManager.user?.name {
                            Task {
                                try? await authManager.updateName(name)
                            }
                        }
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
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var localeManager: LocalizationManager
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var guestListUpdates = true
    @State private var newVenues = false
    @State private var promotions = false
    @State private var selectedLanguage: AppLanguage = .english
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.background.ignoresSafeArea()
                
                Form {
                    Section("STATUS") {
                        HStack {
                            Text("push_notifications")
                            Spacer()
                            Text(notificationManager.isAuthorized ? "On" : "Off")
                                .foregroundStyle(notificationManager.isAuthorized ? .green : .red)
                        }
                        
                        if !notificationManager.isAuthorized {
                            Button("enable_notifications") {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }
                        }
                    }
                    
                    Section("LANGUAGE") {
                        Picker("Language", selection: $selectedLanguage) {
                            Text("English").tag(AppLanguage.english)
                            Text("العربية").tag(AppLanguage.arabic)
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    Section("PREFERENCES") {
                        Toggle("Guest List Updates", isOn: $guestListUpdates)
                        Toggle("New Venues", isOn: $newVenues)
                        Toggle("Promotions", isOn: $promotions)
                    }
                    
                    Section {
                        Text("Manage what notifications you receive from LSTD.")
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
            .onAppear {
                notificationManager.getNotificationSettings()
                if let prefs = authManager.user?.notificationPreferences {
                    guestListUpdates = prefs.guestListUpdates
                    newVenues = prefs.newVenues
                    promotions = prefs.promotions
                }
                selectedLanguage = localeManager.language
            }
            .onChange(of: guestListUpdates) { _ in updatePreferences() }
            .onChange(of: newVenues) { _ in updatePreferences() }
            .onChange(of: promotions) { _ in updatePreferences() }
            .onChange(of: selectedLanguage) { language in
                localeManager.setLanguage(language)
            }
        }
    }
    
    private func updatePreferences() {
        let prefs = NotificationPreferences(
            guestListUpdates: guestListUpdates,
            newVenues: newVenues,
            promotions: promotions
        )
        Task {
            try? await authManager.updateNotificationPreferences(prefs)
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
                            
                            Text("To delete your account and all associated data, please contact support@lstd.com")
                                .font(Theme.Fonts.body(size: 14))
                                .foregroundStyle(.white)
                        }
                        
                        Button {
                            if let url = URL(string: "https://lstd.com/privacy") {
                                UIApplication.shared.open(url)
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

// MARK: - KYC Submission

struct KYCSubmissionView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    @State private var fullName: String = ""
    @State private var documentType: String = "Passport"
    @State private var documentNumber: String = ""
    @State private var documentFrontURL: String = ""
    @State private var documentBackURL: String = ""
    @State private var selfieURL: String = ""
    @State private var addressProofURL: String = ""
    @State private var notes: String = ""
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @State private var errorMessage: String?
    
    private let documentTypes = ["Passport", "National ID", "Driver License"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.background.ignoresSafeArea()
                
                Form {
                    Section("STATUS") {
                        HStack {
                            Text("Current Status")
                            Spacer()
                            StatusPill(status: authManager.user?.kycStatus ?? .notSubmitted)
                        }
                        if let status = authManager.user?.kycStatus, status == .failed {
                            Text("Your previous submission was rejected. Please re-submit with clear photos and matching details.")
                                .font(Theme.Fonts.caption())
                                .foregroundColor(.red)
                        }
                    }
                    
                    Section("IDENTITY") {
                        TextField("Full Name", text: $fullName)
                        Picker("Document Type", selection: $documentType) {
                            ForEach(documentTypes, id: \.self) { type in
                                Text(type).tag(type)
                            }
                        }
                        TextField("Document Number", text: $documentNumber)
                    }
                    
                    Section("UPLOAD LINKS") {
                        TextField("Front of ID (URL)", text: $documentFrontURL)
                            .textInputAutocapitalization(.never)
                        TextField("Back of ID (URL)", text: $documentBackURL)
                            .textInputAutocapitalization(.never)
                        TextField("Selfie / Live Photo (URL)", text: $selfieURL)
                            .textInputAutocapitalization(.never)
                        TextField("Address Proof (Utility Bill, URL)", text: $addressProofURL)
                            .textInputAutocapitalization(.never)
                    }
                    
                    Section("NOTES") {
                        TextEditor(text: $notes)
                            .frame(height: 80)
                    }
                    
                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(Theme.Fonts.caption())
                    }
                    
                    Button {
                        Task { await submit() }
                    } label: {
                        HStack {
                            if isSubmitting { ProgressView() }
                            Text(showSuccess ? "Submitted" : "Submit for Review")
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .disabled(isSubmitting || authManager.user == nil || documentNumber.isEmpty || fullName.isEmpty)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Identity Verification")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear {
                fullName = authManager.user?.name ?? ""
            }
        }
    }
    
    private func submit() async {
        guard let user = authManager.user else {
            errorMessage = "You must be signed in."
            return
        }
        isSubmitting = true
        errorMessage = nil
        showSuccess = false
        
        let submission = KYCSubmission(
            userId: user.id,
            fullName: fullName,
            documentType: documentType,
            documentNumber: documentNumber,
            documentFrontURL: documentFrontURL.isEmpty ? nil : documentFrontURL,
            documentBackURL: documentBackURL.isEmpty ? nil : documentBackURL,
            selfieURL: selfieURL.isEmpty ? nil : selfieURL,
            addressProofURL: addressProofURL.isEmpty ? nil : addressProofURL,
            status: .pending,
            notes: notes.isEmpty ? nil : notes
        )
        
        do {
            try await FirestoreManager.shared.submitKYC(submission)
            await authManager.fetchUserRole(userId: user.id)
            showSuccess = true
        } catch {
            errorMessage = "Failed to submit: \(error.localizedDescription)"
        }
        
        isSubmitting = false
    }
}

struct StatusPill: View {
    let status: KYCStatus
    
    var body: some View {
        Text(status.badgeText)
            .font(Theme.Fonts.body(size: 12))
            .fontWeight(.bold)
            .foregroundStyle(status.badgeColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(status.badgeColor.opacity(0.15))
            .clipShape(Capsule())
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
                            subtitle: "support@lstd.com"
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
