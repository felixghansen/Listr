import SwiftUI
import FirebaseCore

@main
struct YourApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(idealWidth: 1000, minHeight: 500, idealHeight: 750)
        }
    }
}
