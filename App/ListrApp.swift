import SwiftUI
import FirebaseCore

@main
struct YourApp: App {
    @StateObject var authVM = AuthViewModel()
    @StateObject var coordinator = AccountSettingsCoordinator()
    
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(idealWidth: 1000, minHeight: 500, idealHeight: 750)
                .environmentObject(authVM)
                .environmentObject(coordinator)
        }
    }
}
