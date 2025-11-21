import SwiftUI

struct AuthView: View {
    @StateObject private var authManager = AuthManager()
    @State private var isLogin = true
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    
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
                        
                        Text("GLIST")
                            .font(Theme.Fonts.display(size: 40))
                            .tracking(8)
                            .foregroundStyle(.white)
                        
                        Text("DUBAI NIGHTLIFE GUIDE")
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
                            Text("LOGIN")
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
                            Text("SIGN UP")
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
                                placeholder: "Full Name",
                                text: $name
                            )
                        }
                        
                        CustomTextField(
                            icon: "envelope",
                            placeholder: "Email",
                            text: $email,
                            keyboardType: .emailAddress
                        )
                        
                        CustomTextField(
                            icon: "lock",
                            placeholder: "Password",
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
                                Text(isLogin ? "LOGIN" : "CREATE ACCOUNT")
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
                    
                    Spacer()
                }
            }
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
                        errorMessage = "Please enter your name"
                        isLoading = false
                        return
                    }
                    try await authManager.signUp(email: email, password: password, name: name)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

struct CustomTextField: View {
    let icon: String
    let placeholder: String
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
