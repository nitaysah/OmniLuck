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
    @State private var notificationsEnabled = true
    @State private var soundEnabled = false
    
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
                                // Logout handled in parent usually, or we pass session?
                                // For now just UI
                            }) {
                                Text("Sign Out")
                                    .foregroundColor(.red)
                            }
                            
                            Divider()
                            
                            Button(action: {}) {
                                Text("Delete Account")
                                    .foregroundColor(.red.opacity(0.6))
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
    }
}
