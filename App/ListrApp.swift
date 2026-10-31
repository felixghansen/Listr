import SwiftUI
import FirebaseCore
import FirebaseAppCheck

@main
struct ListrApp: App {
    @StateObject var authService = AuthService.shared
    @StateObject var authVM = AuthViewModel()
    
    init() {
        let providerFactory = AppCheckDebugProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)
        FirebaseApp.configure()
      }

    var body: some Scene {
        WindowGroup {
            if let user = authService.user, user.isEmailVerified {
                ContentView()
                    .frame(idealWidth: 1000, minHeight: 500, idealHeight: 750)
                    .environmentObject(authVM)
                    .environmentObject(authService) // for features like signing out and changing name, email, maybe password
            } else {
                AuthEntry()
                    .frame(idealWidth: 1000, minHeight: 500, idealHeight: 750)
                    .environmentObject(authVM)
                    .environmentObject(authService)
            }
        }
    }
}
