import SwiftUI

@main
struct OmniLuckApp: App {
    @StateObject private var userSession = UserSession()
    
    var body: some Scene {
        WindowGroup {
            if userSession.isLoggedIn {
                ContentView(userSession: userSession)
            } else {
                LoginView(userSession: userSession)
            }
        }
    }
}
