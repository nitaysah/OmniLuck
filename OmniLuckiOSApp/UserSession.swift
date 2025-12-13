import Foundation

struct UserProfile: Codable {
    let name: String?
    let dob: String? // "YYYY-MM-DD"
    let email: String?
    let username: String?
}

class UserSession: ObservableObject {
    @Published var isLoggedIn = false
    @Published var userProfile: UserProfile?
    
    func login(with profile: UserProfile) {
        self.userProfile = profile
        self.isLoggedIn = true
    }
    
    func logout() {
        self.userProfile = nil
        self.isLoggedIn = false
    }
}
