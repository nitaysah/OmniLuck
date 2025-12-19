import SwiftUI

// Shared Colors
private let accentPurple = Color(red: 0.75, green: 0.6, blue: 0.95)
private let accentGold = Color(red: 1.0, green: 0.9, blue: 0.5)
private let deepPurple = Color(red: 0.5, green: 0.3, blue: 0.7)

struct AboutView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(colors: [
                Color(red: 1.0, green: 0.98, blue: 0.9),
                Color(red: 0.95, green: 0.9, blue: 1.0),
                Color(red: 0.98, green: 0.95, blue: 1.0)
            ], startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(deepPurple)
                        .padding(10)
                        .background(Color.white.opacity(0.5))
                        .cornerRadius(10)
                    }
                    Spacer()
                    Text("About Us")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(deepPurple)
                    Spacer()
                    // Phantom for alignment
                    Color.clear.frame(width: 70, height: 40)
                }
                .padding()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("OmniLuck is your daily celestial companion, fusing ancient astrological wisdom with modern predictive AI.")
                            .foregroundColor(deepPurple)
                            .lineSpacing(6)
                        
                        Text("We calculate your unique luck score by analyzing planetary transits, numerology, and cosmic weather patterns in real-time.")
                            .foregroundColor(deepPurple)
                            .lineSpacing(6)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("✨").font(.title)
                                Text("Our Mission").font(.headline).foregroundColor(deepPurple)
                            }
                            Text("To help you navigate life's tides with confidence and cosmic insight.")
                                .font(.subheadline).foregroundColor(deepPurple.opacity(0.8))
                        }
                        .padding()
                        .background(accentGold.opacity(0.2))
                        .cornerRadius(16)
                        
                        Spacer()
                    }
                    .padding(20)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

struct ContactView: View {
    @Environment(\.dismiss) var dismiss
    @State private var message = ""
    @State private var topic = "General Inquiry"
    let topics = ["General Inquiry", "Bug Report", "Feature Request", "Account Support"]
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(colors: [
                Color(red: 1.0, green: 0.98, blue: 0.9),
                Color(red: 0.95, green: 0.9, blue: 1.0),
                Color(red: 0.98, green: 0.95, blue: 1.0)
            ], startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(deepPurple)
                        .padding(10)
                        .background(Color.white.opacity(0.5))
                        .cornerRadius(10)
                    }
                    Spacer()
                    Text("Contact Us")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(deepPurple)
                    Spacer()
                    Color.clear.frame(width: 70, height: 40)
                }
                .padding()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Have questions or cosmic feedback? We'd love to hear from you.")
                            .foregroundColor(deepPurple)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("TOPIC").font(.caption).fontWeight(.bold).foregroundColor(deepPurple.opacity(0.7))
                            Menu {
                                ForEach(topics, id: \.self) { t in
                                    Button(t) { topic = t }
                                }
                            } label: {
                                HStack {
                                    Text(topic).foregroundColor(deepPurple)
                                    Spacer()
                                    Image(systemName: "chevron.down").foregroundColor(deepPurple)
                                }
                                .padding()
                                .background(Color.white.opacity(0.7))
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(accentPurple.opacity(0.5), lineWidth: 1))
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("MESSAGE").font(.caption).fontWeight(.bold).foregroundColor(deepPurple.opacity(0.7))
                            TextEditor(text: $message)
                                .frame(height: 150)
                                .padding(8)
                                .background(Color.white.opacity(0.7)) // TextEditor background quirks in iOS 16+
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(accentPurple.opacity(0.5), lineWidth: 1))
                                .foregroundColor(deepPurple)
                        }
                        
                        Button(action: {
                            // Mock Send
                            message = ""
                        }) {
                            HStack {
                                Image(systemName: "paperplane.fill")
                                Text("Send Message")
                            }
                            .fontWeight(.bold)
                            .foregroundColor(deepPurple)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(LinearGradient(colors: [accentGold, accentGold.opacity(0.8)], startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(16)
                            .shadow(radius: 5)
                        }
                        
                        Text("Or email us at support@omniluck.app")
                            .font(.caption)
                            .foregroundColor(accentPurple)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(20)
                }
            }
        }
        .navigationBarHidden(true)
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var userSession: UserSession
    @State private var notificationsEnabled = true
    @State private var soundEnabled = false
    @State private var showDeleteAlert = false
    @State private var showSuccessAlert = false
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(colors: [
                Color(red: 1.0, green: 0.98, blue: 0.9),
                Color(red: 0.95, green: 0.9, blue: 1.0),
                Color(red: 0.98, green: 0.95, blue: 1.0)
            ], startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(deepPurple)
                        .padding(10)
                        .background(Color.white.opacity(0.5))
                        .cornerRadius(10)
                    }
                    Spacer()
                    Text("Settings")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(deepPurple)
                    Spacer()
                    Color.clear.frame(width: 70, height: 40)
                }
                .padding()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 30) {
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("PREFERENCES").font(.caption).fontWeight(.bold).foregroundColor(deepPurple.opacity(0.6))
                            
                            Toggle("Daily Notifications", isOn: $notificationsEnabled)
                                .toggleStyle(SwitchToggleStyle(tint: accentPurple))
                                .foregroundColor(deepPurple)
                            
                            Toggle("Sound Effects", isOn: $soundEnabled)
                                .toggleStyle(SwitchToggleStyle(tint: accentPurple))
                                .foregroundColor(deepPurple)
                        }
                        .padding()
                        .background(Color.white.opacity(0.6))
                        .cornerRadius(16)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("ACCOUNT").font(.caption).fontWeight(.bold).foregroundColor(deepPurple.opacity(0.6))
                            
                            Button(action: {
                                userSession.logout()
                                dismiss()
                            }) {
                                Text("Sign Out")
                                    .fontWeight(.medium)
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            Divider()
                            
                            Button(action: {
                                showDeleteAlert = true
                            }) {
                                Text("Delete Account")
                                    .fontWeight(.medium)
                                    .foregroundColor(.red.opacity(0.8))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.6))
                        .cornerRadius(16)
                        
                    }
                    .padding(20)
                }
            }
        }
        .navigationBarHidden(true)
        .alert("Delete Account", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    // Check for valid token
                    guard let token = userSession.userProfile?.idToken else {
                        await MainActor.run {
                            userSession.logout()
                            dismiss()
                        }
                        return
                    }
                    
                    // Attempt Server-Side Deletion
                    do {
                       _ = try await NetworkService.shared.deleteAccount(idToken: token)
                       // Success: Show Confirmation
                       await MainActor.run {
                           showSuccessAlert = true
                       }
                    } catch {
                       print("Server deletion failed: \(error)")
                       // Proceed to local logout anyway on failure
                        await MainActor.run {
                            userSession.logout()
                            dismiss()
                        }
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete your account? This action cannot be undone and will permanently remove your personal data.")
        }
        .alert("Account Deleted", isPresented: $showSuccessAlert) {
            Button("OK", role: .cancel) {
                userSession.logout()
                dismiss()
            }
        } message: {
            Text("Your account has been successfully deleted.")
        }
    }
}

struct PrivacyView: View {
    @Environment(\.dismiss) var dismiss
    
    // Shared Colors (Local copies since they are private in file scope)
    private let deepPurple = Color(red: 0.5, green: 0.3, blue: 0.7)
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(colors: [
                Color(red: 1.0, green: 0.98, blue: 0.9),
                Color(red: 0.95, green: 0.9, blue: 1.0),
                Color(red: 0.98, green: 0.95, blue: 1.0)
            ], startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(deepPurple)
                        .padding(10)
                        .background(Color.white.opacity(0.5))
                        .cornerRadius(10)
                    }
                    Spacer()
                    Text("Privacy Policy")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(deepPurple)
                    Spacer()
                    Color.clear.frame(width: 70, height: 40)
                }
                .padding()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 25) {
                        Text("Last Updated: December 18, 2024")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.bottom, 10)
                        
                        Group {
                            Text("1. Introduction")
                                .font(.headline)
                                .foregroundColor(deepPurple)
                            Text("Welcome to OmniLuck. We value your privacy and are committed to protecting your personal data. This Privacy Policy explains how we collect, use, and safeguard your information when you use our mobile application.")
                                .font(.body)
                                .foregroundColor(deepPurple.opacity(0.9))
                        }
                        
                        Group {
                            Text("2. Information We Collect")
                                .font(.headline)
                                .foregroundColor(deepPurple)
                            Text("We collect only the information necessary to provide you with accurate astrological insights:")
                            
                            VStack(alignment: .leading, spacing: 8) {
                                BulletPoint(text: "Personal Identity: Name, Email (for secure account management).")
                                BulletPoint(text: "Astrological Data: Date, Time, and Place of Birth. Used strictly for natal chart calculations.")
                                BulletPoint(text: "Device Usage: Basic interaction metrics to improve performance.")
                            }
                        }
                        
                        Group {
                            Text("3. How We Use Your Data")
                                .font(.headline)
                                .foregroundColor(deepPurple)
                            VStack(alignment: .leading, spacing: 8) {
                                BulletPoint(text: "To perform astronomical calculations for your personal luck score.")
                                BulletPoint(text: "To authenticate your identity and secure your account.")
                                BulletPoint(text: "To maintain your preferences across devices.")
                            }
                            Text("We do NOT sell, trade, or rent your personal data to third parties.")
                                .fontWeight(.bold)
                                .padding(.top, 5)
                        }
                        
                        Group {
                            Text("4. Data Storage")
                                .font(.headline)
                                .foregroundColor(deepPurple)
                            Text("We use trusted third-party services like Google Firebase for secure authentication and database storage. Your data is processed in accordance with industry security standards.")
                        }
                        
                        Group {
                            Text("5. Your Rights")
                                .font(.headline)
                                .foregroundColor(deepPurple)
                            Text("You have full control. You can access your data, request corrections, or request full deletion of your account at any time via the Settings menu.")
                        }
                        
                        Group {
                            Text("6. Contact Us")
                                .font(.headline)
                                .foregroundColor(deepPurple)
                            Text("If you have questions, please contact us via our support channels within the app.")
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(24)
                    .foregroundColor(deepPurple.opacity(0.9))
                }
            }
        }
    }
}

// Helper for Privacy List items
private struct BulletPoint: View {
    let text: String
    var body: some View {
        HStack(alignment: .top) {
            Text("•").bold()
            Text(text)
        }
    }
}
