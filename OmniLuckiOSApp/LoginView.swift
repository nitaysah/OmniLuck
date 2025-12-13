import SwiftUI

struct LoginView: View {
    @ObservedObject var userSession: UserSession
    
    // Light Celestial Color Palette
    let accentPurple = Color(red: 0.75, green: 0.6, blue: 0.95)
    let accentGold = Color(red: 1.0, green: 0.9, blue: 0.5)
    let deepPurple = Color(red: 0.5, green: 0.3, blue: 0.7)
    
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showSignup = false
    @State private var showForgotPassword = false
    @State private var errorMessage = ""
    
    enum Field {
        case email, password
    }
    @FocusState private var focusedField: Field?
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(colors: [
                Color(red: 1.0, green: 0.98, blue: 0.9),
                Color(red: 0.95, green: 0.9, blue: 1.0),
                Color(red: 0.98, green: 0.95, blue: 1.0)
            ], startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
            
            // Shared Galaxy Animation
            GalaxyView(accentPurple: accentPurple, accentGold: accentGold)
                .opacity(0.8)
            
            VStack(spacing: 15) { // Reduced from 30
                // Logo & Title
                VStack(spacing: 15) {
                    ZStack {
                        Circle().fill(accentPurple.opacity(0.2)).frame(width: 80, height: 80).blur(radius: 10)
                        Text("✨").font(.system(size: 40))
                    }
                    
                    Text("OmniLuck")
                        .font(.system(size: 42, weight: .heavy, design: .serif))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(
                            LinearGradient(colors: [deepPurple, deepPurple.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .shadow(color: accentPurple.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    Text("Your daily luck, decoded by Personalized AI, Astrology and the cosmic signals")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .foregroundColor(deepPurple.opacity(0.8))
                        .padding(.horizontal, 35)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 30) // Reduced from 60
                
                // Form Fields
                VStack(spacing: 20) {
                    ZStack(alignment: .leading) {
                        if email.isEmpty {
                            Text("Email or Username")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(deepPurple)
                                .padding(.leading, 16)
                        }
                        TextField("", text: $email)
                            .padding(12)
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(accentPurple.opacity(0.5), lineWidth: 1)
                            )
                            .foregroundColor(deepPurple)
                            .tint(deepPurple)
                            .accentColor(deepPurple)
                            .submitLabel(.next)
                            .focused($focusedField, equals: .email)
                            .onSubmit {
                                focusedField = .password
                            }
                    }
                    
                    ZStack(alignment: .leading) {
                        if password.isEmpty {
                            Text("Password")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(deepPurple)
                                .padding(.leading, 16)
                        }
                        SecureField("", text: $password)
                            .padding(12)
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(accentPurple.opacity(0.5), lineWidth: 1)
                            )
                            .foregroundColor(deepPurple)
                            .tint(deepPurple)
                            .accentColor(deepPurple)
                            .submitLabel(.done)
                            .focused($focusedField, equals: .password)
                            .onSubmit {
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            }
                    }
                    
                    // Sign In Button
                    Button(action: {
                        isLoading = true
                        
                        Task {
                            do {
                                let response = try await NetworkService.shared.login(email: email, password: password)
                                
                                await MainActor.run {
                                    isLoading = false
                                    // Save profile to session
                                    let profile = UserProfile(
                                        name: response.profile.name,
                                        dob: response.profile.dob,
                                        email: response.email,
                                        username: nil
                                    )
                                    userSession.login(with: profile)
                                    print("Login Success: \(response.email)")
                                }
                            } catch {
                                await MainActor.run {
                                    isLoading = false
                                    print("Login Failed: \(error.localizedDescription)")
                                }
                            }
                        }
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Sign In").fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(deepPurple)
                        .foregroundColor(.white)
                        .cornerRadius(24)
                        .shadow(color: deepPurple.opacity(0.4), radius: 8, x: 0, y: 4)
                    }
                    .disabled(email.isEmpty || password.isEmpty)
                    .opacity((email.isEmpty || password.isEmpty) ? 0.6 : 1)
                    
                    
                    // Create Account Button (Web App Style)
                    VStack(spacing: 10) {
                        Text("Don't have an account?")
                            .font(.subheadline)
                            .foregroundColor(deepPurple)
                        
                        Button(action: {
                            showSignup = true
                        }) {
                            Text("Create Account")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(Color.white)
                                .foregroundColor(deepPurple)
                                .cornerRadius(24)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(deepPurple, lineWidth: 1)
                                )
                        }
                    }
                    
                    // Forgot Password Link
                    Button(action: {
                        showForgotPassword = true
                    }) {
                        Text("Forgot Password?")
                            .font(.footnote)
                            .foregroundColor(deepPurple)
                            .fontWeight(.medium)
                    }
                    .padding(.top, 0) // Reduced
                }
                .padding(24) // Reduced from 30
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .fill(Color.white.opacity(0.4))
                        .blur(radius: 0)
                        .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.white.opacity(0.5), lineWidth: 1))
                )
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Guest Button
                VStack(spacing: 15) {
                    HStack {
                        Rectangle().frame(height: 1).foregroundColor(deepPurple.opacity(0.2))
                        Text("or continue as guest").font(.caption).foregroundColor(deepPurple.opacity(0.6)).fixedSize()
                        Rectangle().frame(height: 1).foregroundColor(deepPurple.opacity(0.2))
                    }
                    .padding(.horizontal, 60)
                    
                    Button("Skip for now") {
                        userSession.isLoggedIn = true
                    }
                    .font(.headline)
                    .foregroundColor(deepPurple)
                }
                .padding(.bottom, 20) // Reduced from 40
            }
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .sheet(isPresented: $showSignup) {
            SignupView(userSession: userSession)
        }
        .alert("Reset Password", isPresented: $showForgotPassword) {
            TextField("Email or Username", text: $email)
                .textInputAutocapitalization(.never)
            Button("Cancel", role: .cancel) { }
            Button("Send Reset Email") {
                Task {
                    // TODO: Implement password reset via backend/Firebase
                    // For now, show a placeholder message
                    errorMessage = "Password reset email sent to \(email.isEmpty ? "your email" : email). Please check your inbox."
                }
            }
        } message: {
            Text("Enter your email or username to receive a password reset link.")
        }
        .alert("Notice", isPresented: .constant(!errorMessage.isEmpty)) {
            Button("OK") {
                errorMessage = ""
            }
        } message: {
            Text(errorMessage)
        }
    }
}
