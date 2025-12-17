import SwiftUI

struct ContentView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var userSession: UserSession
    
    @State private var name = ""
    @State private var dob = Date()
    @State private var birthTime = Date()
    @State private var birthPlace = ""
    @State private var showResult = false
    @State private var apiResult: LuckResponse? // New
    @State private var showDatePicker = false
    @State private var manualDateText = ""
    @State private var isButtonPressed = false
    @FocusState private var isNameFieldFocused: Bool
    @FocusState private var isDateFieldFocused: Bool
    @FocusState private var isBirthPlaceFocused: Bool
    @State private var useNAForTime = false // N/A toggle for birth time
    @State private var showTimeInfo = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showLogoutAlert = false
    @State private var showAbout = false
    @State private var showContact = false
    @State private var showSettings = false
    
    // Light Celestial Color Palette
    let accentPurple = Color(red: 0.75, green: 0.6, blue: 0.95)  // Light purple
    let accentGold = Color(red: 1.0, green: 0.9, blue: 0.5)      // Light yellow/gold
    let deepPurple = Color(red: 0.5, green: 0.3, blue: 0.7)      // Medium purple for text
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundView
                
                if let profile = userSession.userProfile {
                    // === LOGGED IN DASHBOARD ===
                    dashboardView(profile: profile)
                } else {
                    // === GUEST / INPUT MODE ===
                    ScrollView {
                        VStack(spacing: 25) {
                            guestHeaderView
                            formView
                            Spacer(minLength: 20)
                            footerView
                        }
                    }
                }
            }
            .alert("Time of Birth", isPresented: $showTimeInfo) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Add your exact local time of birth for full precision. This data acts as your cosmic GPS, identifying the precise degrees of your Rising Sign and the 12 Life Houses that shift every few minutes. These details are vital for accurate daily insights and a truly personalized Luck Score. If unknown, we apply the 12:00 PM Astrology standard to maximize planetary accuracy and provide reliable guidance.")
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
                // Pre-fill logic can remain for internal state, 
                // but UI now diverges.
                if let profile = userSession.userProfile {
                     initializeStateFrom(profile: profile)
                }
            }
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .navigationDestination(isPresented: $showResult) {
                // Navigation Logic remains same
                if let result = apiResult {
                    ResultView(
                        percentage: result.luck_score,
                        explanation: OmniLuckLogic.LuckExplanation(
                             text: result.explanation,
                             traits: ["Cosmic", "Aligned", "Lucky"]
                        ),
                        caption: result.caption,
                        summary: result.summary,
                        birthInfo: (dob: dob, time: birthTime, place: birthPlace, timeIsNA: useNAForTime),
                        strategicAdvice: result.strategic_advice,
                        luckyTimeSlots: result.lucky_time_slots
                    )
                } else {
                    // Fallback
                    let pct = OmniLuckLogic.calculateLuckyPercentage(name: name, dob: dob)
                    let expl = OmniLuckLogic.generateLuckExplanation(percentage: pct, name: name, dob: dob)
                    ResultView(
                        percentage: pct,
                        explanation: expl,
                        birthInfo: (dob: dob, time: birthTime, place: birthPlace, timeIsNA: useNAForTime)
                    )
                }
            }
            .navigationDestination(isPresented: $showAbout) { AboutView() }
            .navigationDestination(isPresented: $showContact) { ContactView() }
            .navigationDestination(isPresented: $showSettings) { SettingsView() }
            #if os(iOS)
            .navigationBarHidden(true)
            #endif
        }
        .preferredColorScheme(.light)
    }
    
    // MARK: - Helpers
    private func initializeStateFrom(profile: UserProfile) {
        if let profileName = profile.name, !profileName.isEmpty {
            name = profileName
        }
        if let profileDOB = profile.dob, !profileDOB.isEmpty {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.timeZone = TimeZone(secondsFromGMT: 0) // Treat as distinct date
            // Note: If we don't set timezone, Local midnight might be previous day in UTC or vice versa depending on input.
            // Backend sends "YYYY-MM-DD".
            // If we parse that in Local Time, it's fine.
            formatter.timeZone = TimeZone.current 
            
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

    // MARK: - Dashboard View (New)
    private func dashboardView(profile: UserProfile) -> some View {
        VStack {
            // Top Bar
            HStack {
                Spacer()
                Menu {
                    Button(action: { showLogoutAlert = true }) {
                        Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.title2)
                        .foregroundColor(deepPurple)
                        .padding()
                }
            }
            
            // Welcome Section
            Spacer()
            
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(accentPurple.opacity(0.2))
                        .frame(width: 120, height: 120)
                        .blur(radius: 20)
                    Image(systemName: "sparkles")
                        .font(.system(size: 60))
                        .foregroundStyle(LinearGradient(colors: [accentGold, accentPurple], startPoint: .topLeading, endPoint: .bottomTrailing))
                }
                
                VStack(spacing: 8) {
                    Text("Welcome back,")
                         .font(.title3)
                         .foregroundColor(deepPurple.opacity(0.7))
                    
                    Text(profile.name?.components(separatedBy: " ").first ?? "Traveler")
                        .font(.system(size: 42, weight: .bold, design: .serif))
                        .foregroundColor(deepPurple)
                }
                
                // Profile Card
                VStack(spacing: 15) {
                    Text("YOUR COSMIC PROFILE")
                        .font(.caption)
                        .fontWeight(.bold)
                        .tracking(2)
                        .foregroundColor(deepPurple.opacity(0.6))
                    
                    HStack(spacing: 20) {
                        // Zodiac / DOB
                        VStack {
                            if let d = profile.dob {
                                Text(formatDateForDisplay(d))
                                    .font(.headline)
                                    .foregroundColor(deepPurple)
                            }
                        }
                        
                        Divider().frame(height: 30)
                        
                        // Place
                        VStack {
                            if let p = profile.birth_place {
                                Text(p)
                                    .font(.subheadline)
                                    .foregroundColor(deepPurple)
                            }
                        }
                    }
                }
                .padding(25)
                .background(Material.thinMaterial)
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(accentPurple.opacity(0.3), lineWidth: 1))
                .padding(.horizontal, 30)
                .padding(.top, 10)
                
                
                // Forecast Button
                Button(action: {
                    // Trigger Forecast using existing state (already populated)
                    triggerForecast()
                }) {
                    HStack(spacing: 10) {
                        if isButtonPressed {
                            ProgressView().tint(deepPurple)
                        } else {
                            Text("Forecast my Luck")
                                .fontWeight(.bold)
                            Image(systemName: "wand.and.stars")
                        }
                    }
                    .font(.title3)
                    .foregroundColor(deepPurple)
                    .padding(.vertical, 18)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(colors: [accentGold, accentGold.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(20)
                    .shadow(color: accentGold.opacity(0.4), radius: 10, x: 0, y: 5)
                    .padding(.horizontal, 40)
                    .padding(.top, 20)
                }
                .disabled(isButtonPressed)
            }
            
            Spacer()
            Spacer()
        }
    }
    
    // Helper to format string YYYY-MM-DD to "Dec 14, 1990"
    private func formatDateForDisplay(_ dateStr: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        // Force GMT for input to avoid shifting if the string is just a date
        // Actually, best to just use the components manually to be safe like Web
        let components = dateStr.split(separator: "-")
        if components.count == 3 {
            // Basic mapping
            let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
            if let m = Int(components[1]), let d = Int(components[2]), let y = Int(components[0]) {
                if m >= 1 && m <= 12 {
                    return "\(months[m-1]) \(d), \(y)"
                }
            }
        }
        return dateStr // Fallback
    }

    private func triggerForecast() {
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

    private var guestHeaderView: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { userSession.logout() }) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(deepPurple)
                        .padding(10)
                        .background(Color.white.opacity(0.6))
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom, 10)
            
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
                Menu {
                    Button(action: { showAbout = true }) {
                        Label("About Us", systemImage: "info.circle")
                    }
                    Button(action: { showContact = true }) {
                        Label("Contact Us", systemImage: "envelope")
                    }
                    Button(action: { showSettings = true }) {
                        Label("Settings", systemImage: "gearshape")
                    }
                    Divider()
                    Button(role: .destructive, action: { showLogoutAlert = true }) {
                        Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text("Hi, \(userName.components(separatedBy: " ").first ?? userName)")
                            .font(.system(size: 14, weight: .semibold))
                        Image(systemName: "chevron.down") // Changed to chevron for menu indication
                            .font(.system(size: 10, weight: .bold)) // Smaller chevron
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
                Label("DATE OF BIRTH", systemImage: "calendar")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(deepPurple.opacity(0.8))
                
                VStack(spacing: 0) {
                    // Manual Input with Calendar Icon
                    ZStack(alignment: .leading) {
                        if manualDateText.isEmpty {
                            Text("MM/DD/YYYY")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(deepPurple)
                                .padding(.leading, 16)
                        }
                        HStack {
                            TextField("", text: $manualDateText)
                                .padding()
                                .foregroundColor(deepPurple)
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
                            
                            Button(action: {
                                withAnimation {
                                    showDatePicker.toggle()
                                    // If text is valid, ensure picker matches (via dob binding).
                                    // If text is empty/partial, dob is kept.
                                    // If opening picker, maybe dismiss keyboard?
                                    if showDatePicker {
                                        isDateFieldFocused = false
                                        isNameFieldFocused = false
                                    }
                                }
                            }) {
                                Image(systemName: "calendar")
                                    .font(.title2)
                                    .foregroundColor(deepPurple)
                                    .padding(.trailing, 16)
                            }
                        }
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(accentPurple.opacity(showDatePicker ? 1.0 : 0.5), lineWidth: 1)
                        )
                    }
                    
                    // Conditional Picker
                    if showDatePicker {
                        DatePicker("", selection: $dob, displayedComponents: .date)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .frame(height: 140)
                            .clipped()
                            .colorScheme(.light)
                            .background(Color.white.opacity(0.5))
                            .cornerRadius(12)
                            .padding(.top, 8)
                            .onChange(of: dob) { _, newDate in
                                // Update manual text match picker selection
                                let f = DateFormatter()
                                f.dateFormat = "MM/dd/yyyy"
                                manualDateText = f.string(from: newDate)
                            }
                    }
                }
            }
            
            // Place Field
            VStack(alignment: .leading, spacing: 8) {
                Label("PLACE OF BIRTH", systemImage: "mappin.and.ellipse")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(deepPurple.opacity(0.8))
                
                TextField("City, Country (e.g. Dallas, USA)", text: $birthPlace)
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(12)
                    .foregroundColor(deepPurple)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(accentPurple.opacity(0.5), lineWidth: 1)
                    )
                    .submitLabel(.done)
                    .focused($isBirthPlaceFocused)
                    .onSubmit {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
            }
            .onChange(of: isNameFieldFocused) { _, focused in if focused { showDatePicker = false } }
            .onChange(of: isBirthPlaceFocused) { _, focused in if focused { showDatePicker = false } }
            .onChange(of: isDateFieldFocused) { _, focused in if focused { showDatePicker = false } }
            
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
                    Text("Midday Alignment Active: Following the Astrology standard for unknown birth times, your chart is anchored to 12:00 PM to maximize planetary accuracy and ensure a reliable luck forecast.")
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
                            birthTime: useNAForTime ? Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())! : birthTime,
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
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(colors: (name.isEmpty || birthPlace.isEmpty) ? [Color.gray.opacity(0.5)] : [accentGold, accentGold.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(16)
                .shadow(color: (name.isEmpty || birthPlace.isEmpty) ? .clear : accentGold.opacity(0.4), radius: 10, x: 0, y: 5)
                .scaleEffect(isButtonPressed ? 0.95 : 1.0)
            }
            .disabled(name.isEmpty || birthPlace.isEmpty)
            .padding(.horizontal)
            .padding(.bottom, 10)
            
            Button(action: {
                userSession.logout()
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "house")
                    Text("Back to Home")
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
