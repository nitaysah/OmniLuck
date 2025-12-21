import SwiftUI

struct SignupView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var userSession: UserSession
    
    // Light Celestial Color Palette
    let accentPurple = Color(red: 0.75, green: 0.6, blue: 0.95)
    let accentGold = Color(red: 1.0, green: 0.9, blue: 0.5)
    let deepPurple = Color(red: 0.5, green: 0.3, blue: 0.7)
    
    @State private var username = ""
    @State private var firstName = ""
    @State private var middleName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var phoneNumber = ""
    @State private var countryCode = "+1"
    @State private var dob = Date()
    @State private var showDatePicker = false
    @State private var manualDateText = ""
    @State private var birthPlace = ""
    @State private var birthTime = Date()
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var useNAForTime = false
    @State private var showTimeInfo = false
    @State private var showPassword = false
    @State private var showConfirmPassword = false

    
    enum Field {
        case username, firstName, middleName, lastName, phoneNumber, email, password, confirmPassword, birthPlace
    }
    @FocusState private var focusedField: Field?
    @FocusState private var isDateFieldFocused: Bool
    
    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.string(from: date)
    }

    private func formatPhoneNumber(_ source: String) -> String {
        // Mask: (XXX) XXX-XXXX
        var result = ""
        let mask = "(XXX) XXX-XXXX"
        var index = source.startIndex
        
        for ch in mask {
            if index == source.endIndex { break }
            if ch == "X" {
                result.append(source[index])
                index = source.index(after: index)
            } else {
                result.append(ch)
            }
        }
        return result
    }
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(colors: [
                Color(red: 1.0, green: 0.98, blue: 0.9),
                Color(red: 0.95, green: 0.9, blue: 1.0),
                Color(red: 0.98, green: 0.95, blue: 1.0)
            ], startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
            
            // Galaxy
            GalaxyView(accentPurple: accentPurple, accentGold: accentGold)
                .opacity(0.8)
            
            ScrollView {
                VStack(spacing: 25) {
                    // Title
                    Text("Create Account")
                        .font(.system(size: 36, weight: .heavy, design: .serif))
                        .foregroundStyle(
                            LinearGradient(colors: [deepPurple, deepPurple.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .padding(.top, 60)
                    
                    // Form Card
                    VStack(spacing: 16) {
                        personalInfoFields
                        birthInfoFields
                        actionButtons
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.95))
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
        .onChange(of: focusedField) { _, field in
            if field != nil { showDatePicker = false }
        }
        .onChange(of: isDateFieldFocused) { _, focused in
            if focused { showDatePicker = false }
        }
        .alert("Time of Birth", isPresented: $showTimeInfo) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Add your exact local time of birth for full precision. This data acts as your cosmic GPS, identifying the precise degrees of your Rising Sign and the 12 Life Houses that shift every few minutes. These details are vital for accurate daily insights and a truly personalized Luck Score. If unknown, we apply the 12:00 PM Astrology standard to maximize planetary accuracy and provide reliable guidance.")
        }
        .preferredColorScheme(.light)
    }
    
    // MARK: - Subviews
    
    private var personalInfoFields: some View {
        VStack(spacing: 16) {
            // Username
            VStack(alignment: .leading, spacing: 6) {
                Text("Username").font(.caption).fontWeight(.medium).foregroundColor(deepPurple)
                TextField("Choose a unique username", text: $username)
                    .padding(14)
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(accentPurple.opacity(0.5), lineWidth: 1))
                    .foregroundColor(deepPurple)
                    .textInputAutocapitalization(.never)
                    .submitLabel(.next)
                    .focused($focusedField, equals: .username)
                    .onSubmit { focusedField = .firstName }
            }
            
            // First Name
            VStack(alignment: .leading, spacing: 6) {
                Text("First Name").font(.caption).fontWeight(.medium).foregroundColor(deepPurple)
                TextField("", text: $firstName)
                    .padding(14)
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(accentPurple.opacity(0.5), lineWidth: 1))
                    .foregroundColor(deepPurple)
                    .submitLabel(.next)
                    .focused($focusedField, equals: .firstName)
                    .onSubmit { focusedField = .middleName }
            }
            
            // Middle Name
            VStack(alignment: .leading, spacing: 6) {
                Text("Middle Name (If Any)").font(.caption).fontWeight(.medium).foregroundColor(deepPurple)
                TextField("", text: $middleName)
                    .padding(14)
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(accentPurple.opacity(0.5), lineWidth: 1))
                    .foregroundColor(deepPurple)
                    .submitLabel(.next)
                    .focused($focusedField, equals: .middleName)
                    .onSubmit { focusedField = .lastName }
            }
            
            // Last Name
            VStack(alignment: .leading, spacing: 6) {
                Text("Last Name").font(.caption).fontWeight(.medium).foregroundColor(deepPurple)
                TextField("", text: $lastName)
                    .padding(14)
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(accentPurple.opacity(0.5), lineWidth: 1))
                    .foregroundColor(deepPurple)
                    .submitLabel(.next)
                    .focused($focusedField, equals: .lastName)
                    .onSubmit { focusedField = .phoneNumber }
            }
            
            // Phone Number
            VStack(alignment: .leading, spacing: 6) {
                Text("Phone Number").font(.caption).fontWeight(.medium).foregroundColor(deepPurple)
                HStack(spacing: 8) {
                    Menu {
                        Button("🇺🇸 +1 United States") { countryCode = "+1" }
                        Button("🇮🇳 +91 India") { countryCode = "+91" }
                        Button("🇬🇧 +44 UK") { countryCode = "+44" }
                        Button("🇦🇺 +61 Australia") { countryCode = "+61" }
                        Button("🇨🇦 +1 Canada") { countryCode = "+1" }
                    } label: {
                        Text(countryCode)
                            .frame(width: 60)
                            .padding(14)
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(accentPurple.opacity(0.5), lineWidth: 1))
                            .foregroundColor(deepPurple)
                    }

                    TextField("(555) 000-0000", text: $phoneNumber)
                        .padding(14)
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(accentPurple.opacity(0.5), lineWidth: 1))
                        .foregroundColor(deepPurple)
                        .keyboardType(.phonePad)
                        .submitLabel(.next)
                        .focused($focusedField, equals: .phoneNumber)
                        .onSubmit { focusedField = .email }
                        .onChange(of: phoneNumber) { _, newValue in
                            let filtered = newValue.filter { "0123456789".contains($0) }
                            if filtered.count > 10 {
                                phoneNumber = String(filtered.prefix(10))
                            } else {
                                phoneNumber = formatPhoneNumber(filtered)
                            }
                        }
                }
            }
            
            // Email
            VStack(alignment: .leading, spacing: 6) {
                Text("Email Address").font(.caption).fontWeight(.medium).foregroundColor(deepPurple)
                TextField("", text: $email)
                    .padding(14)
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(accentPurple.opacity(0.5), lineWidth: 1))
                    .foregroundColor(deepPurple)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .submitLabel(.next)
                    .focused($focusedField, equals: .email)
                    .onSubmit { focusedField = .password }
            }
            
            // Password
            VStack(alignment: .leading, spacing: 6) {
                Text("Password").font(.caption).fontWeight(.medium).foregroundColor(deepPurple)
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
                            .font(.system(size: 14))
                    }
                }
                .padding(14)
                .background(Color.white.opacity(0.9))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(accentPurple.opacity(0.5), lineWidth: 1))
                .foregroundColor(deepPurple)
                .submitLabel(.next)
                .focused($focusedField, equals: .password)
                .onSubmit { focusedField = .confirmPassword }
            }
            
            // Confirm Password
            VStack(alignment: .leading, spacing: 6) {
                Text("Confirm Password").font(.caption).fontWeight(.medium).foregroundColor(deepPurple)
                HStack {
                    if showConfirmPassword {
                        TextField("", text: $confirmPassword)
                            .textInputAutocapitalization(.never)
                    } else {
                        SecureField("", text: $confirmPassword)
                    }
                    
                    Button(action: { showConfirmPassword.toggle() }) {
                        Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                            .foregroundColor(deepPurple.opacity(0.7))
                            .font(.system(size: 14))
                    }
                }
                .padding(14)
                .background(Color.white.opacity(0.9))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(accentPurple.opacity(0.5), lineWidth: 1))
                .foregroundColor(deepPurple)
                .submitLabel(.done)
                .focused($focusedField, equals: .confirmPassword)
                .onSubmit { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
            }
        }
    }
    
    private var birthInfoFields: some View {
        VStack(spacing: 16) {
            // DOB
            VStack(alignment: .leading, spacing: 6) {
                Text("Date of Birth").font(.caption).fontWeight(.medium).foregroundColor(deepPurple)
                
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
                                .padding(14)
                                .foregroundColor(deepPurple)
                                .keyboardType(.numbersAndPunctuation)
                                .focused($isDateFieldFocused)
                                .onChange(of: manualDateText) { _, newValue in
                                    let filtered = newValue.filter { "0123456789/".contains($0) }
                                    if filtered.count <= 10 { manualDateText = filtered }
                                    if filtered.count == 10 {
                                        let formatter = DateFormatter()
                                        formatter.dateFormat = "MM/dd/yyyy"
                                        if let date = formatter.date(from: filtered) { dob = date }
                                    }
                                }
                            
                            Button(action: {
                                withAnimation {
                                    showDatePicker.toggle()
                                    if showDatePicker {
                                        isDateFieldFocused = false
                                        focusedField = nil
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
                            .tint(accentPurple)
                            .frame(height: 140)
                            .clipped()
                            .background(Color.white.opacity(0.5))
                            .cornerRadius(12)
                            .padding(.top, 8)
                            .onChange(of: dob) { _, newDate in
                                let f = DateFormatter(); f.dateFormat = "MM/dd/yyyy"
                                manualDateText = f.string(from: newDate)
                            }
                    }
                }
            }
            
            // Place of Birth
            VStack(alignment: .leading, spacing: 6) {
                Text("Place of Birth").font(.caption).fontWeight(.medium).foregroundColor(deepPurple)
                TextField("City, Country (e.g. Dallas, USA)", text: $birthPlace)
                    .padding(14)
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(accentPurple.opacity(0.5), lineWidth: 1))
                    .foregroundColor(deepPurple)
                    .submitLabel(.done)
                    .focused($focusedField, equals: .birthPlace)
                    .onSubmit { focusedField = nil }
            }
            
            // Time of Birth
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Time of Birth").font(.caption).fontWeight(.medium).foregroundColor(deepPurple)
                    
                    Button(action: { showTimeInfo = true }) {
                        Image(systemName: "info.circle")
                            .font(.caption)
                            .foregroundColor(deepPurple.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Button(action: { useNAForTime.toggle() }) {
                        HStack(spacing: 4) {
                            Image(systemName: useNAForTime ? "checkmark.square.fill" : "square")
                            Text("Don't know")
                        }
                        .font(.caption).foregroundColor(deepPurple)
                    }
                }
                
                if !useNAForTime {
                    DatePicker("", selection: $birthTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .colorScheme(.light)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(accentPurple.opacity(0.5), lineWidth: 1))
                } else {
                    Text("Midday Alignment Active: Following the Astrology standard for unknown birth times, your chart is anchored to 12:00 PM to maximize planetary accuracy and ensure a reliable luck forecast.")
                        .font(.caption)
                        .foregroundColor(deepPurple.opacity(0.6))
                        .italic()
                        .padding(.top, 4)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 16) {
            if !errorMessage.isEmpty {
                Text(errorMessage).font(.caption).foregroundColor(.red).padding(.top, 8)
            }
            
            Button(action: {
                guard password == confirmPassword else { errorMessage = "Passwords do not match"; return }
                isLoading = true; errorMessage = ""
                
                Task {
                    do {
                        let response = try await NetworkService.shared.signup(
                            username: username,
                            firstName: firstName,
                            middleName: middleName,
                            lastName: lastName,
                            phoneNumber: "\(countryCode) \(phoneNumber)",
                            email: email,
                            password: password,
                            dob: formatDate(dob),
                            birthPlace: birthPlace,
                            birthTime: useNAForTime ? Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())! : birthTime
                        )
                        
                        await MainActor.run {
                            isLoading = false
                            
                            let f = DateFormatter()
                            f.dateFormat = "HH:mm"
                            let finalTime = useNAForTime ? Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())! : birthTime
                            let timeStr = f.string(from: finalTime)
                            
                            let fullName = "\(firstName) \(middleName.isEmpty ? "" : middleName + " ")\(lastName)"
                            let profile = UserProfile(
                                name: fullName,
                                dob: formatDate(dob),
                                email: email,
                                username: username,
                                birth_place: birthPlace,
                                birth_time: timeStr,
                                uid: response.uid,
                                idToken: response.idToken
                            )
                            userSession.login(with: profile)
                            print("Signup Success: \(response.message)")
                        }
                    } catch {
                        await MainActor.run {
                            isLoading = false
                            errorMessage = error.localizedDescription
                            print("Signup Failed: \(error)")
                        }
                    }
                }
            }) {
                HStack {
                    if isLoading { ProgressView().tint(.white) } else { Text("Sign Up").fontWeight(.semibold) }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(deepPurple)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(username.isEmpty || firstName.isEmpty || lastName.isEmpty || phoneNumber.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty || birthPlace.isEmpty || manualDateText.isEmpty)
            .opacity((username.isEmpty || firstName.isEmpty || lastName.isEmpty || phoneNumber.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty || birthPlace.isEmpty || manualDateText.isEmpty) ? 0.6 : 1)
            .padding(.top, 8)
            
            Button("Wait, I have an account") { dismiss() }
            .font(.footnote)
            .foregroundColor(deepPurple.opacity(0.7))
            .padding(.top, 8)
        }
    }
}
