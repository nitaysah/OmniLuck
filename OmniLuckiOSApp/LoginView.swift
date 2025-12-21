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
    @State private var forgotEmail = ""
    @State private var showResetSuccess = false
    
    // Forgot Username Flow
    @State private var showForgotUsername = false
    @State private var forgotUsernameEmail = ""
    @State private var showUsernameSuccess = false
    @State private var usernameSuccessMessage = ""
    
    @State private var isRotating = false
    @State private var showPassword = false
    @State private var showPrivacy = false
    
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
                    Image("Logo")
                        .resizable()
                        .scaledToFill()
                         .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .rotationEffect(.degrees(isRotating ? 360 : 0))
                    
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
                            .textInputAutocapitalization(.never) // Disable Caps
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
                        
                        HStack {
                            if showPassword {
                                TextField("", text: $password)
                                    .textInputAutocapitalization(.never)
                            } else {
                                SecureField("", text: $password)
                            }
                            
                            Button(action: { showPassword.toggle() }) {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .foregroundColor(deepPurple.opacity(0.7))
                                    .font(.system(size: 16))
                            }
                        }
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
                    
                    // Error Message
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.caption).fontWeight(.semibold)
                            .foregroundColor(.red)
                            .padding(.top, 4)
                            .transition(.opacity)
                    }

                    // Sign In Button (Cosmic Glow)
                    Button(action: {
                        focusedField = nil // Dismiss keyboard
                        isLoading = true
                        errorMessage = ""
                        Task {
                            do {
                                // Cache the email for faster future logins
                                UserDefaults.standard.set(email, forKey: "lastLoginEmail")
                                
                                let response = try await NetworkService.shared.login(email: email, password: password)
                                await MainActor.run {
                                    isLoading = false
                                    let profile = UserProfile(
                                        name: response.profile.name,
                                        dob: response.profile.dob,
                                        email: response.email,
                                        username: nil,
                                        birth_place: response.profile.birth_place,
                                        birth_time: response.profile.birth_time,
                                        uid: response.uid,
                                        idToken: response.idToken
                                    )
                                    userSession.login(with: profile)
                                }
                            } catch {
                                await MainActor.run {
                                    isLoading = false
                                    errorMessage = "Invalid login ID or password."
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
                    
                    HStack(spacing: 8) {
                        Button(action: { showForgotPassword = true; forgotEmail = "" }) {
                            Text("Forgot Password?")
                                .font(.footnote)
                                .foregroundColor(deepPurple)
                                .fontWeight(.medium)
                        }
                        
                        Text("|").font(.footnote).foregroundColor(deepPurple.opacity(0.5))
                        
                        Button(action: { showForgotUsername = true; forgotUsernameEmail = "" }) {
                            Text("Forgot Username?")
                                .font(.footnote)
                                .foregroundColor(deepPurple)
                                .fontWeight(.medium)
                        }
                    }
                    .padding(.top, 5)
                    
                    
                    // Create Account Button
                    VStack(spacing: 10) {
                        Text("Don't have an account?")
                            .font(.subheadline)
                            .foregroundColor(deepPurple)
                        
                        Button(action: { showSignup = true }) {
                            Text("Get Started")
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
                        Text("or skip for now").font(.caption).foregroundColor(deepPurple.opacity(0.6)).fixedSize()
                        Rectangle().frame(height: 1).foregroundColor(deepPurple.opacity(0.2))
                    }
                    .padding(.horizontal, 60)
                    
                    Button(action: {
                        userSession.isLoggedIn = true
                    }) {
                        Text("Continue as Guest")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 24)
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(20)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(deepPurple, lineWidth: 1))
                            .foregroundColor(deepPurple)
                    }
                    
                    // Privacy Policy
                    Button(action: { showPrivacy = true }) {
                        Text("Privacy Policy")
                            .font(.caption)
                            .foregroundColor(deepPurple.opacity(0.7))
                            .underline()
                    }
                    .padding(.top, 10)
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
        .sheet(isPresented: $showPrivacy) {
            PrivacyView()
        }
        .alert("Reset Password", isPresented: $showForgotPassword) {
            TextField("Enter your email", text: $forgotEmail)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
            Button("Send Reset Link") {
                Task {
                    do {
                        _ = try await NetworkService.shared.resetPassword(email: forgotEmail)
                        await MainActor.run { showResetSuccess = true }
                    } catch {
                       print("Reset Password Error: \(error)")
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Enter your email address to receive a password reset link.")
        }
        .alert("Link Sent", isPresented: $showResetSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("If an account exists for \(forgotEmail), a reset link has been sent.")
        }
        // Forgot Username Alerts
        .alert("Recover Username", isPresented: $showForgotUsername) {
            TextField("Enter your email", text: $forgotUsernameEmail)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
            Button("Send Username") {
                Task {
                    do {
                        let resp = try await NetworkService.shared.forgotUsername(email: forgotUsernameEmail)
                        await MainActor.run {
                            usernameSuccessMessage = resp.message
                            showUsernameSuccess = true
                        }
                    } catch {
                       await MainActor.run {
                           // Show error logic or just print for now, maybe set error message in another alert?
                           // Re-using showUsernameSuccess for error display simplicy or just reusing the main errorMessage if I wasn't inside an alert flow
                           // Actually, let's just trigger a separate alert or modify message
                            usernameSuccessMessage = "Email address not exist or error occurred." // As requested: "email address not exist"
                            showUsernameSuccess = true
                       }
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Enter your email address to receive your username.")
        }
        .alert("Usage Recovery", isPresented: $showUsernameSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(usernameSuccessMessage)
        }
        .onAppear {
            // Pre-fill email from cache for faster login
            if let cachedEmail = UserDefaults.standard.string(forKey: "lastLoginEmail") {
                email = cachedEmail
            }
            
            withAnimation(.linear(duration: 60).repeatForever(autoreverses: false)) {
                isRotating = true
            }
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                floatOffset = 15
            }
        }
    }
}

