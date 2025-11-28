import SwiftUI

struct AuthView: View {
    @StateObject private var authManager = AuthManager()
    @State private var isLogin = true
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var selectedRole: UserRole = .user
    @State private var referralCode = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var showVerificationAlert = false
    
    var body: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()
            
            // Background glow
            Circle()
                .fill(Color.theme.accent.opacity(0.1))
                .frame(width: 300, height: 300)
                .blur(radius: 100)
                .offset(y: -200)
            
            ScrollView {
                VStack(spacing: 32) {
                    Spacer()
                        .frame(height: 60)
                    
                    // Logo
                    VStack(spacing: 16) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.white)
                        
                        Text("LSTD")
                            .font(Theme.Fonts.display(size: 40))
                            .tracking(8)
                            .foregroundStyle(.white)
                        
                        Text(LocalizedStringKey("tagline"))
                            .font(Theme.Fonts.body(size: 12))
                            .tracking(4)
                            .foregroundStyle(Color.gray)
                    }
                    .padding(.bottom, 40)
                    
                    // Toggle Login/Signup
                    HStack(spacing: 0) {
                        Button {
                            withAnimation {
                                isLogin = true
                            }
                        } label: {
                            Text(LocalizedStringKey("login"))
                                .font(Theme.Fonts.body(size: 14))
                                .fontWeight(isLogin ? .bold : .regular)
                                .foregroundStyle(isLogin ? .white : .gray)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(isLogin ? Color.theme.surface : Color.clear)
                        }
                        
                        Button {
                            withAnimation {
                                isLogin = false
                            }
                        } label: {
                            Text(LocalizedStringKey("signup"))
                                .font(Theme.Fonts.body(size: 14))
                                .fontWeight(!isLogin ? .bold : .regular)
                                .foregroundStyle(!isLogin ? .white : .gray)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(!isLogin ? Color.theme.surface : Color.clear)
                        }
                    }
                    .background(Color.theme.surface.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.horizontal, 32)
                    
                    // Form
                    VStack(spacing: 16) {
                        if !isLogin {
                                CustomTextField(
                                    icon: "person",
                                    placeholder: LocalizedStringKey("full_name"),
                                    text: $name
                                )
                                
                                // Role Selection
                                HStack(spacing: 0) {
                                    Button {
                                        withAnimation { selectedRole = .user }
                                    } label: {
                                        HStack {
                                            Image(systemName: "person.fill")
                                            Text("User")
                                        }
                                        .font(Theme.Fonts.body(size: 14))
                                        .fontWeight(selectedRole == .user ? .bold : .regular)
                                        .foregroundStyle(selectedRole == .user ? .white : .gray)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(selectedRole == .user ? Color.theme.accent.opacity(0.6) : Color.theme.surface.opacity(0.5))
                                    }
                                    
                                    Button {
                                        withAnimation { selectedRole = .promoter }
                                    } label: {
                                        HStack {
                                            Image(systemName: "star.fill")
                                            Text("Promoter")
                                        }
                                        .font(Theme.Fonts.body(size: 14))
                                        .fontWeight(selectedRole == .promoter ? .bold : .regular)
                                        .foregroundStyle(selectedRole == .promoter ? .white : .gray)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(selectedRole == .promoter ? Color.theme.accent.opacity(0.6) : Color.theme.surface.opacity(0.5))
                                    }
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                                
                                CustomTextField(
                                    icon: "tag",
                                    placeholder: LocalizedStringKey("referral_optional"),
                                    text: $referralCode
                                )
                            }
                            
                            CustomTextField(
                                icon: "envelope",
                                placeholder: LocalizedStringKey("email"),
                                text: $email,
                                keyboardType: .emailAddress
                            )
                            
                            CustomTextField(
                                icon: "lock",
                                placeholder: LocalizedStringKey("password"),
                                text: $password,
                                isSecure: true
                            )
                        
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(Theme.Fonts.body(size: 12))
                                .foregroundStyle(.red)
                                .padding(.horizontal)
                        }
                        
                        Button {
                            handleAuth()
                        } label: {
                            if isLoading {
                                ProgressView()
                                    .tint(.black)
                            } else {
                                Text(isLogin ? LocalizedStringKey("login") : LocalizedStringKey("create_account"))
                                .font(Theme.Fonts.body(size: 14))
                                .fontWeight(.bold)
                                .tracking(2)
                            }
                        }
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .disabled(isLoading)
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 20)
                    
                    // Social Sign In
                    VStack(spacing: 20) {
                        HStack {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                            Text("OR")
                                .font(Theme.Fonts.caption())
                                .foregroundStyle(.gray)
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                        }
                        
                        HStack(spacing: 20) {
                            Button {
                                handleGoogleSignIn()
                            } label: {
                                HStack {
                                    Image(systemName: "g.circle.fill") // Placeholder for Google logo
                                        .font(.title2)
                                    Text("Google")
                                        .font(Theme.Fonts.body(size: 14))
                                        .fontWeight(.semibold)
                                }
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            
                            Button {
                                handleAppleSignIn()
                            } label: {
                                HStack {
                                    Image(systemName: "apple.logo")
                                        .font(.title2)
                                    Text("Apple")
                                        .font(Theme.Fonts.body(size: 14))
                                        .fontWeight(.semibold)
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.black)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 32)
                    
                    Spacer()
                }
            }
        }
        .alert("Check your email", isPresented: $showVerificationAlert) {
            Button("OK", role: .cancel) {
                withAnimation {
                    isLogin = true
                }
            }
        } message: {
            Text("We've sent a confirmation link to \(email). Please verify your email to log in.")
        }
    }
    
    private func handleAuth() {
        errorMessage = ""
        isLoading = true
        
        Task {
            do {
                if isLogin {
                    try await authManager.signIn(email: email, password: password)
                } else {
                    guard !name.isEmpty else {
                        errorMessage = NSLocalizedString("error_enter_name", comment: "")
                        isLoading = false
                        return
                    }
                    try await authManager.signUp(email: email, password: password, name: name, role: selectedRole, referralCode: referralCode)
                    
                    if !authManager.isAuthenticated {
                        showVerificationAlert = true
                    }
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
    private func handleGoogleSignIn() {
        isLoading = true
        Task {
            do {
                try await authManager.signInWithGoogle()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
    
    private func handleAppleSignIn() {
        isLoading = true
        Task {
            do {
                try await authManager.signInWithApple()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

struct CustomTextField: View {
    let icon: String
    let placeholder: LocalizedStringKey
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.theme.textSecondary)
                .frame(width: 20)
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .foregroundStyle(.white)
                    .tint(.white)
            } else {
                TextField(placeholder, text: $text)
                    .foregroundStyle(.white)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(.never)
                    .tint(.white)
            }
        }
        .padding(16)
        .background(Color.theme.surface.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

#Preview {
    AuthView()
}
