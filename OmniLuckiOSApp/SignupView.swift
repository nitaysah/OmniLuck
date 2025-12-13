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
    @State private var dob = Date()
    @State private var useManualDate = false
    @State private var manualDateText = ""
    @State private var birthPlace = ""
    @State private var birthTime = Date()
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    enum Field {
        case username, firstName, middleName, lastName, email, password, confirmPassword, birthPlace
    }
    @FocusState private var focusedField: Field?
    @FocusState private var isDateFieldFocused: Bool
    
    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.string(from: date)
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
                    .onSubmit { focusedField = .email }
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
                SecureField("", text: $password)
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
                SecureField("", text: $confirmPassword)
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
                HStack {
                    Text("Date of Birth").font(.caption).fontWeight(.medium).foregroundColor(deepPurple)
                    Spacer()
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { useManualDate.toggle() }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: useManualDate ? "slider.horizontal.3" : "keyboard")
                            Text(useManualDate ? "Picker" : "Manual")
                        }
                        .font(.caption).foregroundColor(deepPurple)
                    }
                }
                
                if useManualDate {
                    ZStack(alignment: .leading) {
                        if manualDateText.isEmpty {
                            Text("MM/DD/YYYY").font(.subheadline).fontWeight(.bold).foregroundColor(deepPurple).padding(.leading, 16)
                        }
                        TextField("", text: $manualDateText)
                            .padding(14)
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(12)
                            .foregroundColor(deepPurple)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(accentPurple.opacity(0.5), lineWidth: 1))
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
                    }
                } else {
                    DatePicker("", selection: $dob, displayedComponents: .date)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .tint(accentPurple)
                        .frame(height: 140)
                        .clipped()
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
            VStack(alignment: .leading, spacing: 6) {
                Text("Time of Birth").font(.caption).fontWeight(.medium).foregroundColor(deepPurple)
                DatePicker("", selection: $birthTime, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .frame(maxWidth: .infinity, alignment: .leading)
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
                            email: email,
                            password: password,
                            dob: formatDate(dob),
                            birthPlace: birthPlace,
                            birthTime: birthTime
                        )
                        
                        await MainActor.run {
                            isLoading = false
                            let fullName = "\(firstName) \(middleName.isEmpty ? "" : middleName + " ")\(lastName)"
                            let profile = UserProfile(name: fullName, dob: formatDate(dob), email: email, username: username)
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
            .disabled(username.isEmpty || firstName.isEmpty || lastName.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty || birthPlace.isEmpty)
            .opacity((username.isEmpty || firstName.isEmpty || lastName.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty || birthPlace.isEmpty) ? 0.6 : 1)
            .padding(.top, 8)
            
            Button("Wait, I have an account") { dismiss() }
            .font(.footnote)
            .foregroundColor(deepPurple.opacity(0.7))
            .padding(.top, 8)
        }
    }
}
