import SwiftUI

struct ContentView: View {
    @ObservedObject var userSession: UserSession
    
    @State private var name = ""
    @State private var dob = Date()
    @State private var birthTime = Date()
    @State private var birthPlace = ""
    @State private var showResult = false
    @State private var apiResult: LuckResponse? // New
    @State private var useManualDate = false
    @State private var manualDateText = ""
    @State private var isButtonPressed = false
    @FocusState private var isNameFieldFocused: Bool
    @FocusState private var isDateFieldFocused: Bool
    @State private var useNAForTime = false // N/A toggle for birth time
    @State private var showTimeInfo = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showLogoutAlert = false
    
    // Light Celestial Color Palette
    let accentPurple = Color(red: 0.75, green: 0.6, blue: 0.95)  // Light purple
    let accentGold = Color(red: 1.0, green: 0.9, blue: 0.5)      // Light yellow/gold
    let deepPurple = Color(red: 0.5, green: 0.3, blue: 0.7)      // Medium purple for text
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundView
                
                ScrollView {
                    VStack(spacing: 25) {
                        headerView
                        formView
                        Spacer(minLength: 20)
                        footerView
                    }
                }
            }
            .alert("Time of Birth", isPresented: $showTimeInfo) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Add exact time of birth (local time at place of birth) to get your daily Astrology insights.")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("Log Out", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Log Out", role: .destructive) {
                    userSession.logout()
                }
            } message: {
                Text("Are you sure you want to log out?")
            }
            .onAppear {
                // Auto-populate fields from authenticated profile
                if let profile = userSession.userProfile {
                    if let profileName = profile.name, !profileName.isEmpty {
                        name = profileName
                    }
                    if let profileDOB = profile.dob, !profileDOB.isEmpty {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd"
                        if let date = formatter.date(from: profileDOB) {
                            dob = date
                        }
                    }
                    if let place = profile.birth_place, !place.isEmpty {
                        birthPlace = place
                    }
                    if let timeStr = profile.birth_time, !timeStr.isEmpty {
                        let tFormatter = DateFormatter()
                        tFormatter.dateFormat = "HH:mm"
                        if let tDate = tFormatter.date(from: timeStr) {
                            birthTime = tDate
                            useNAForTime = false
                        }
                    }
                }
            }
            .onTapGesture {
                // Dismiss all keyboards
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .navigationDestination(isPresented: $showResult) {
                if let result = apiResult {
                    // Use LIVE API result
                    ResultView(
                        percentage: result.luck_score,
                        explanation: OmniLuckLogic.LuckExplanation(
                             text: result.explanation,
                             traits: ["Cosmic", "Aligned", "Lucky"]
                        ),
                        birthInfo: (dob: dob, time: birthTime, place: birthPlace)
                    )
                } else {
                    // Fallback to Offline
                    let pct = OmniLuckLogic.calculateLuckyPercentage(name: name, dob: dob)
                    let expl = OmniLuckLogic.generateLuckExplanation(percentage: pct, name: name, dob: dob)
                    ResultView(
                        percentage: pct,
                        explanation: expl,
                        birthInfo: (dob: dob, time: birthTime, place: birthPlace)
                    )
                }
            }
            #if os(iOS)
            .navigationBarHidden(true)
            #endif
        }
        .preferredColorScheme(.light)
    }

    // MARK: - Subviews
    private var backgroundView: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.98, blue: 0.9),   // Soft cream/yellow
                    Color(red: 0.95, green: 0.9, blue: 1.0),   // Very light purple
                    Color(red: 0.98, green: 0.95, blue: 1.0)   // Lavender white
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            GalaxyView(accentPurple: accentPurple, accentGold: accentGold)
        }
    }

    private var headerView: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(accentPurple.opacity(0.3))
                        .frame(width: 100, height: 100)
                        .blur(radius: 20)
                    
                    Image(systemName: "sparkles")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                        .foregroundStyle(
                            LinearGradient(colors: [accentGold, accentGold.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                }
                
                Text("Discover Your Luck")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(deepPurple)
                
                Text("A Fusion of Astrology, Physics & Predictive AI")
                    .font(.subheadline)
                    .foregroundColor(deepPurple.opacity(0.7))
            }
            .padding(.top, 40)
            
            if let profile = userSession.userProfile, let userName = profile.name {
                Button(action: {
                    showLogoutAlert = true
                }) {
                    HStack(spacing: 6) {
                        Text("Hi, \(userName.components(separatedBy: " ").first ?? userName)")
                            .font(.system(size: 14, weight: .semibold))
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(deepPurple)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.4))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
                            )
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                }
                .padding(.top, 0)
                .padding(.trailing, 20)
            }
        }
    }
    
    private var formView: some View {
        VStack(alignment: .leading, spacing: 22) {
            
            // Name Field
            VStack(alignment: .leading, spacing: 8) {
                Label("YOUR NAME", systemImage: "person.fill")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(deepPurple.opacity(0.8))
                
                ZStack(alignment: .leading) {
                    if name.isEmpty {
                        Text("Enter your full name")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(deepPurple)
                            .padding(.leading, 16)
                    }
                    TextField("", text: $name)
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(12)
                        .foregroundColor(deepPurple)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(accentPurple.opacity(0.5), lineWidth: 1)
                        )
                        .focused($isNameFieldFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            isNameFieldFocused = false
                        }
                }
            }
            
            // Date Field
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("DATE OF BIRTH", systemImage: "calendar")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(deepPurple.opacity(0.8))
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            useManualDate.toggle()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: useManualDate ? "slider.horizontal.3" : "keyboard")
                            Text(useManualDate ? "Picker" : "Manual")
                        }
                        .font(.caption)
                        .foregroundColor(deepPurple)
                    }
                }
                
                if useManualDate {
                    ZStack(alignment: .leading) {
                        if manualDateText.isEmpty {
                            Text("MM/DD/YYYY")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(deepPurple)
                                .padding(.leading, 16)
                        }
                        TextField("", text: $manualDateText)
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(12)
                            .foregroundColor(deepPurple)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(accentPurple.opacity(0.5), lineWidth: 1)
                            )
                            .keyboardType(.numbersAndPunctuation)
                            .focused($isDateFieldFocused)
                            .onChange(of: manualDateText) { _, newValue in
                                let filtered = newValue.filter { "0123456789/".contains($0) }
                                if filtered.count <= 10 {
                                    manualDateText = filtered
                                }
                                if filtered.count == 10 {
                                    let formatter = DateFormatter()
                                    formatter.dateFormat = "MM/dd/yyyy"
                                    if let date = formatter.date(from: filtered) {
                                        dob = date
                                    }
                                }
                            }
                    }
                } else {
                    DatePicker("", selection: $dob, displayedComponents: .date)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(height: 140)
                        .clipped()
                        .colorScheme(.light)
                }
            }
            
            // Place Field
            VStack(alignment: .leading, spacing: 8) {
                Label("PLACE OF BIRTH", systemImage: "mappin.and.ellipse")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(deepPurple.opacity(0.8))
                
                ZStack(alignment: .leading) {
                    if birthPlace.isEmpty {
                        Text("City, Country (e.g. Dallas, USA)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(deepPurple)
                            .padding(.leading, 16)
                    }
                    TextField("", text: $birthPlace)
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(12)
                        .foregroundColor(deepPurple)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(accentPurple.opacity(0.5), lineWidth: 1)
                        )
                        .submitLabel(.done)
                        .onSubmit {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                }
            }
            
            // Time Field
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("TIME OF BIRTH", systemImage: "clock")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(deepPurple.opacity(0.8))
                    
                    Button(action: {
                        showTimeInfo = true
                    }) {
                        Image(systemName: "info.circle")
                            .font(.caption)
                            .foregroundColor(deepPurple.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        useNAForTime.toggle()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: useNAForTime ? "checkmark.square.fill" : "square")
                            Text("Don't know")
                        }
                        .font(.caption)
                        .foregroundColor(deepPurple)
                    }
                }
                
                if !useNAForTime {
                    DatePicker("", selection: $birthTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(accentPurple.opacity(0.5), lineWidth: 1)
                        )
                } else {
                    Text("Time not provided - Daily Astrology insight will not be generated")
                        .font(.caption)
                        .foregroundColor(deepPurple.opacity(0.6))
                        .italic()
                        .padding(.top, 4)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(accentPurple.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }

    private var footerView: some View {
        VStack(spacing: 25) {
            Button(action: {
                isButtonPressed = true
                Task {
                    do {
                        let result = try await NetworkService.shared.fetchLuck(
                            name: name,
                            dob: dob,
                            birthTime: useNAForTime ? Date() : birthTime,
                            birthPlace: birthPlace,
                            timeIsNA: useNAForTime
                        )
                        await MainActor.run {
                            isButtonPressed = false
                            self.apiResult = result
                            self.showResult = true
                        }
                    } catch {
                        print("API Error: \(error)")
                        await MainActor.run {
                            isButtonPressed = false
                            errorMessage = error.localizedDescription
                            showError = true
                        }
                    }
                }
            }) {
                HStack(spacing: 10) {
                    Text("Forecast my Luck")
                        .fontWeight(.bold)
                    Image(systemName: "wand.and.stars")
                }
                .font(.title3)
                .foregroundColor(deepPurple)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(colors: name.isEmpty ? [Color.gray.opacity(0.5)] : [accentGold, accentGold.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(16)
                .shadow(color: name.isEmpty ? .clear : accentGold.opacity(0.4), radius: 10, x: 0, y: 5)
                .scaleEffect(isButtonPressed ? 0.95 : 1.0)
            }
            .disabled(name.isEmpty)
            .padding(.horizontal)
            .padding(.bottom, 10)
            
            Button(action: {
                showLogoutAlert = true
            }) {
                HStack(spacing: 10) {
                    Text("🚪")
                    Text("Logout")
                        .fontWeight(.medium)
                }
                .font(.subheadline)
                .foregroundColor(deepPurple)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.6))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(accentPurple.opacity(0.3), lineWidth: 1))
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(userSession: UserSession())
    }
}


// Galaxy Animation moved to GalaxyView.swift
