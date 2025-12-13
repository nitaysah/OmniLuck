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
    
    // Floating Animation State
    @State private var floatOffset: CGFloat = 0
    
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
            
            // Shared Galaxy Animation (Nebula & AI Overlay included)
            GalaxyView(accentPurple: accentPurple, accentGold: accentGold)
                .opacity(0.9) // Increased opacity for nebula visibility
            
            // Floating Cosmic Particles
            ZStack {
                Image(systemName: "sparkle")
                    .foregroundColor(accentGold)
                    .position(x: 60, y: 150)
                    .font(.system(size: 20))
                    .opacity(0.6)
                    .offset(y: floatOffset)
                
                Image(systemName: "moon.stars.fill")
                    .foregroundColor(accentPurple)
                    .position(x: 340, y: 220)
                    .font(.system(size: 24))
                    .opacity(0.5)
                    .offset(y: -floatOffset)
                
                Image(systemName: "star.fill")
                    .foregroundColor(accentGold)
                    .position(x: 200, y: 80)
                    .font(.system(size: 14))
                    .opacity(0.4)
                    .offset(y: floatOffset * 0.5)
            }
            .allowsHitTesting(false)
            
            VStack(spacing: 15) {
                // Logo & Title
                VStack(spacing: 15) {
                    ZStack {
                        Circle()
                            .fill(accentPurple.opacity(0.2))
                            .frame(width: 80, height: 80)
                            .blur(radius: 10)
                            .background(Circle().stroke(accentGold.opacity(0.5), lineWidth: 1))
                        Text("✨")
                            .font(.system(size: 40))
                            .shadow(color: accentGold.opacity(0.8), radius: 10)
                    }
                    
                    Text("OmniLuck")
                        .font(.system(size: 42, weight: .heavy, design: .serif))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(
                            LinearGradient(colors: [deepPurple, deepPurple.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .shadow(color: accentPurple.opacity(0.5), radius: 15, x: 0, y: 5)
                    
                    Text("Your daily luck, decoded by Personalized AI, Astrology and the cosmic signals")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .foregroundColor(deepPurple.opacity(0.9))
                        .padding(.horizontal, 35)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 30)
                
                // Form Fields (Glassmorphism)
                VStack(spacing: 20) {
                    ZStack(alignment: .leading) {
                        if email.isEmpty {
                            Text("Email or Username")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(deepPurple.opacity(0.7))
                                .padding(.leading, 16)
                        }
                        TextField("", text: $email)
                            .padding(12)
                            .background(Color.white.opacity(0.7)) // More transparent
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(accentPurple.opacity(0.5), lineWidth: 1)
                            )
                            .foregroundColor(deepPurple)
                            .tint(deepPurple)
                            .submitLabel(.next)
                            .focused($focusedField, equals: .email)
                            .onSubmit { focusedField = .password }
                    }
                    
                    ZStack(alignment: .leading) {
                        if password.isEmpty {
                            Text("Password")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(deepPurple.opacity(0.7))
                                .padding(.leading, 16)
                        }
                        SecureField("", text: $password)
                            .padding(12)
                            .background(Color.white.opacity(0.7))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(accentPurple.opacity(0.5), lineWidth: 1)
                            )
                            .foregroundColor(deepPurple)
                            .tint(deepPurple)
                            .submitLabel(.done)
                            .focused($focusedField, equals: .password)
                            .onSubmit {
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            }
                    }
                    
                    // Sign In Button (Cosmic Glow)
                    Button(action: {
                        isLoading = true
                        Task {
                            do {
                                let response = try await NetworkService.shared.login(email: email, password: password)
                                await MainActor.run {
                                    isLoading = false
                                    let profile = UserProfile(name: response.profile.name, dob: response.profile.dob, email: response.email, username: nil)
                                    userSession.login(with: profile)
                                }
                            } catch {
                                await MainActor.run { isLoading = false }
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
                        .background(
                            LinearGradient(colors: [deepPurple, accentPurple], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(24)
                        .shadow(color: accentPurple.opacity(0.6), radius: 10, x: 0, y: 5) // Glowing shadow
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .disabled(email.isEmpty || password.isEmpty)
                    .opacity((email.isEmpty || password.isEmpty) ? 0.6 : 1)
                    
                    
                    // Create Account Button
                    VStack(spacing: 10) {
                        Text("Don't have an account?")
                            .font(.subheadline)
                            .foregroundColor(deepPurple)
                        
                        Button(action: { showSignup = true }) {
                            Text("Create Account")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(Material.thinMaterial) // Glass effect
                                .foregroundColor(deepPurple)
                                .cornerRadius(24)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(deepPurple.opacity(0.5), lineWidth: 1)
                                )
                        }
                    }
                    
                    Button(action: { showForgotPassword = true }) {
                        Text("Forgot Password?")
                            .font(.footnote)
                            .foregroundColor(deepPurple)
                            .fontWeight(.medium)
                    }
                    .padding(.top, 0)
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .fill(Material.ultraThinMaterial) // Premium Glass
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
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
                .padding(.bottom, 20)
            }
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .sheet(isPresented: $showSignup) {
            SignupView(userSession: userSession)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                floatOffset = 15
            }
        }
    }
}
