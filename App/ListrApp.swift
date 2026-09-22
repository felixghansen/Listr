import SwiftUI
import FirebaseCore

@main
struct YourApp: App {
    @StateObject var authService = AuthService.shared
    @StateObject var authVM = AuthViewModel()
    @StateObject var coordinator = AccountSettingsCoordinator()
    
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            if let user = authService.user, user.isEmailVerified {
                ContentView()
                    .frame(idealWidth: 1000, minHeight: 500, idealHeight: 750)
                    .environmentObject(authVM)
                    .environmentObject(authService) // for features like signing out and changing name, email, maybe password
                    .environmentObject(coordinator)
            } else {
                AuthEntry()
                    .frame(idealWidth: 1000, minHeight: 500, idealHeight: 750)
                    .environmentObject(authVM)
                    .environmentObject(authService)
            }
        }
    }
}
