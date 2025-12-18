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
    @State private var activeSheet: SheetType?
    @State private var timeSelected = false

    enum SheetType: Identifiable {
        case about, contact, settings
        var id: Int { hashValue }
    }
    
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
                    dashboardViewV3(profile: profile)
                } else {
                    // === GUEST / INPUT MODE ===
                    VStack(spacing: 16) {
                        guestHeaderView
                        formView
                        Spacer(minLength: 0)
                        footerView
                    }
                    .padding(.bottom, 20)
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
                        luckyTimeSlots: result.lucky_time_slots,
                        personalPowerball: result.personal_powerball,
                        dailyPowerballs: result.daily_powerballs
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
            .sheet(item: $activeSheet) { item in
                switch item {
                case .about: AboutView()
                case .contact: ContactView()
                case .settings: SettingsView()
                }
            }
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
                    Button(action: { activeSheet = .about }) { Label("About Us", systemImage: "info.circle") }
                    Button(action: { activeSheet = .contact }) { Label("Contact Us", systemImage: "envelope") }
                    Button(action: { activeSheet = .settings }) { Label("Settings", systemImage: "gearshape") }
                    Divider()
                    Button(action: { showLogoutAlert = true }) {
                        Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text("Hi, \(profile.name?.components(separatedBy: " ").first ?? "User")")
                            .font(.system(size: 16, weight: .semibold))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(deepPurple)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.white.opacity(0.4))
                            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.5), lineWidth: 1))
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                }
                .padding(.top, 55)
                .padding(.trailing, 20)
            }
            
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text("Welcome back,")
                         .font(.title3)
                         .foregroundColor(deepPurple.opacity(0.7))
                    
                    Text(profile.name?.components(separatedBy: " ").first ?? "Traveler")
                        .font(.system(size: 38, weight: .bold, design: .serif))
                        .foregroundColor(deepPurple)
                }
                
                // Profile Card
                VStack(spacing: 15) {
                    Text("YOUR COSMIC PROFILE")
                        .font(.caption)
                        .fontWeight(.bold)
                        .tracking(2)
                        .foregroundColor(deepPurple.opacity(0.6))
                    
                    VStack(alignment: .leading, spacing: 15) {
                        // Name
                        VStack(alignment: .leading, spacing: 3) {
                            Text("My Full Name:").font(.caption).fontWeight(.bold).opacity(0.6).textCase(.uppercase).foregroundColor(deepPurple)
                            Text(profile.name ?? "--").font(.title3).fontWeight(.bold).foregroundColor(deepPurple)
                        }
                        
                        // Zodiac
                        if let d = profile.dob {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("My Zodiac Sign:").font(.caption).fontWeight(.bold).opacity(0.6).textCase(.uppercase).foregroundColor(deepPurple)
                                Text(getZodiacSign(from: d)).font(.title3).fontWeight(.bold).foregroundColor(deepPurple)
                            }
                        }

                        // DOB
                        if let d = profile.dob {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("My Date of Birth:").font(.caption).fontWeight(.bold).opacity(0.6).textCase(.uppercase).foregroundColor(deepPurple)
                                Text(formatDateForDisplay(d)).font(.title3).fontWeight(.bold).foregroundColor(deepPurple)
                            }
                        }
                        
                        // Place
                        VStack(alignment: .leading, spacing: 3) {
                            Text("My Place of Birth:").font(.caption).fontWeight(.bold).opacity(0.6).textCase(.uppercase).foregroundColor(deepPurple)
                            Text(profile.birth_place ?? "--").font(.title3).fontWeight(.bold).foregroundColor(deepPurple)
                        }
                        
                        // Time
                        VStack(alignment: .leading, spacing: 3) {
                            Text("My Time of Birth:").font(.caption).fontWeight(.bold).opacity(0.6).textCase(.uppercase).foregroundColor(deepPurple)
                            Text(formatTime(profile.birth_time)).font(.title3).fontWeight(.bold).foregroundColor(deepPurple)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 5)
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
                
                // Log Out Button
                Button(action: {
                    showLogoutAlert = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "door.left.hand.open")
                        Text("Log Out")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(deepPurple)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.4))
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.6), lineWidth: 1))
                    .padding(.horizontal, 50)
                    .padding(.top, 5)
                }
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

    private func formatTime(_ timeStr: String?) -> String {
        guard let timeStr = timeStr, !timeStr.isEmpty else { return "Unknown (12:00 PM)" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        if let date = formatter.date(from: timeStr) {
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: date)
        }
        return timeStr
    }

    private func getZodiacSign(from dateStr: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateStr) else { return "--" }
        
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        let month = calendar.component(.month, from: date)
        
        switch month {
        case 1:  return day >= 20 ? "♒️ Aquarius" : "♑️ Capricorn"
        case 2:  return day >= 19 ? "♓️ Pisces" : "♒️ Aquarius"
        case 3:  return day >= 21 ? "♈️ Aries" : "♓️ Pisces"
        case 4:  return day >= 20 ? "♉️ Taurus" : "♈️ Aries"
        case 5:  return day >= 21 ? "♊️ Gemini" : "♉️ Taurus"
        case 6:  return day >= 21 ? "♋️ Cancer" : "♊️ Gemini"
        case 7:  return day >= 23 ? "♌️ Leo" : "♋️ Cancer"
        case 8:  return day >= 23 ? "♍️ Virgo" : "♌️ Leo"
        case 9:  return day >= 23 ? "♎️ Libra" : "♍️ Virgo"
        case 10: return day >= 23 ? "♏️ Scorpio" : "♎️ Libra"
        case 11: return day >= 22 ? "♐️ Sagittarius" : "♏️ Scorpio"
        case 12: return day >= 22 ? "♑️ Capricorn" : "♐️ Sagittarius"
        default: return "✨ Star Child"
        }
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
            .padding(.bottom, 8)
            
            VStack(spacing: 8) {
                Text("Discover Your Luck")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(deepPurple)
                
                Text("A Fusion of Astrology, Physics & Predictive AI")
                    .font(.caption)
                    .foregroundColor(deepPurple.opacity(0.7))
            }
            .padding(.top, 10)
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
                    ZStack(alignment: .leading) {
                        // Background placeholder pill to show "-- : --"
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(deepPurple.opacity(0.4))
                            Text(timeSelected ? birthTime.formatted(date: .omitted, time: .shortened) : "-- : --")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(deepPurple.opacity(timeSelected ? 1.0 : 0.7))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(accentPurple.opacity(0.1))
                        .cornerRadius(10)
                        
                        // The actual picker layered on top
                        DatePicker("", selection: $birthTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .colorScheme(.light)
                            // When not selected, we keep it nearly transparent so the placeholder shows
                            // but it still captures the tap to open the system picker popover.
                            .opacity(timeSelected ? 1 : 0.015)
                            .onChange(of: birthTime) { _, _ in
                                withAnimation {
                                    timeSelected = true
                                }
                            }
                    }
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
            .disabled(name.isEmpty || birthPlace.isEmpty || (!useNAForTime && !timeSelected) || manualDateText.isEmpty)
            .opacity((name.isEmpty || birthPlace.isEmpty || (!useNAForTime && !timeSelected) || manualDateText.isEmpty) ? 0.6 : 1)
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
    // MARK: - Dashboard Layout V3 (Responsive, Non-Scrolling)
    private func dashboardViewV3(profile: UserProfile) -> some View {
        ZStack(alignment: .top) {
            
            // Top Menu Overlay (ZIndex Higher)
            HStack {
                Spacer()
                Menu {
                    Button(action: { activeSheet = .about }) { Label("About Us", systemImage: "info.circle") }
                    Button(action: { activeSheet = .contact }) { Label("Contact Us", systemImage: "envelope") }
                    Button(action: { activeSheet = .settings }) { Label("Settings", systemImage: "gearshape") }
                    Divider()
                    Button(action: { showLogoutAlert = true }) { Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right") }
                } label: {
                    HStack(spacing: 8) {
                        Text("Hi, \(profile.name?.components(separatedBy: " ").first ?? "User")")
                            .font(.system(size: 16, weight: .semibold))
                            .minimumScaleFactor(0.8)
                            .lineLimit(1)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(deepPurple)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.white.opacity(0.4))
                            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.5), lineWidth: 1))
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                }
                .padding(.top, 50)
                .padding(.trailing, 20)
            }
            .zIndex(10)
            
            // Main Content Layer
            VStack(spacing: 0) {
                // Header Region (Max 15-20% height)
                VStack(spacing: 2) {
                    Text("Welcome back,")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(deepPurple)
                        .minimumScaleFactor(0.8)
                    
                    Text(profile.name?.components(separatedBy: " ").first ?? "Traveler")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.85, green: 0.8, blue: 1.0))
                        .shadow(color: Color.white.opacity(0.8), radius: 2, x: 0, y: 0)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    
                    Text("The cosmos awaits your query.")
                        .font(.caption)
                        .foregroundColor(deepPurple.opacity(0.6))
                        .padding(.top, 4)
                }
                .padding(.top, 100) // Spacing to clear the Menu
                .padding(.bottom, 10)
                
                Spacer(minLength: 10)
                
                // Content Card (Flexible Height)
                VStack(spacing: 0) {
                    Text("YOUR COSMIC PROFILE")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(2)
                        .foregroundColor(deepPurple.opacity(0.5))
                        .padding(.bottom, 20)
                    
                    // Vertical Stacked Data Points (Tight Spacing)
                    VStack(alignment: .leading, spacing: 14) {
                        
                        // Name
                        VStack(alignment: .leading, spacing: 2) {
                            Text("MY FULL NAME:")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(deepPurple.opacity(0.5))
                            Text(profile.name ?? "--")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(deepPurple)
                                .minimumScaleFactor(0.8)
                                .lineLimit(1)
                        }
                        
                        // Zodiac
                        if let d = profile.dob {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("MY ZODIAC SIGN:")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(deepPurple.opacity(0.5))
                                Text(getZodiacSign(from: d))
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(deepPurple)
                            }
                        }
                        
                        // DOB
                        if let d = profile.dob {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("MY DATE OF BIRTH:")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(deepPurple.opacity(0.5))
                                Text(formatDateForDisplay(d))
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(deepPurple)
                            }
                        }
                        
                        // Place
                        VStack(alignment: .leading, spacing: 2) {
                            Text("MY PLACE OF BIRTH:")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(deepPurple.opacity(0.5))
                            Text(profile.birth_place ?? "--")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(deepPurple)
                                .minimumScaleFactor(0.8)
                                .lineLimit(1)
                        }
                        
                        // Time
                        VStack(alignment: .leading, spacing: 2) {
                            Text("MY TIME OF BIRTH:")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(deepPurple.opacity(0.5))
                            Text(formatTime(profile.birth_time))
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(deepPurple)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(25)
                .background(Color.white.opacity(0.95))
                .cornerRadius(30)
                .shadow(color: accentPurple.opacity(0.15), radius: 10, x: 0, y: 8)
                .padding(.horizontal, 30)
                
                Spacer(minLength: 20)
                
                // Footer Buttons (Pinned Bottom)
                VStack(spacing: 12) {
                    Button(action: {
                        triggerForecast()
                    }) {
                        HStack(spacing: 8) {
                            Text("Forecast my Luck")
                                .fontWeight(.bold)
                            Image(systemName: "wand.and.stars")
                        }
                        .font(.title3)
                        .foregroundColor(deepPurple)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(accentGold)
                        .cornerRadius(22)
                        .shadow(color: accentGold.opacity(0.5), radius: 8, x: 0, y: 4)
                    }
                    .disabled(isButtonPressed)
                    .scaleEffect(isButtonPressed ? 0.98 : 1.0)
                    
                    Button(action: {
                        showLogoutAlert = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "door.left.hand.open")
                            Text("Logout")
                        }
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(deepPurple)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .cornerRadius(22)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 20) // Base padding
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom) // Avoid keyboard shift if any
    }
    
    // Helper View for Compact Row
    private func profileRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(deepPurple.opacity(0.5))
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(deepPurple)
                .multilineTextAlignment(.trailing)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(userSession: UserSession())
    }
}

// MARK: - Placeholder Views Removed (Using SideMenuViews.swift)

// (Views defined in SideMenuViews.swift)


// Galaxy Animation moved to GalaxyView.swift
