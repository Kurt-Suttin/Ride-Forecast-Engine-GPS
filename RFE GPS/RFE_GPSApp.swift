import SwiftUI

@main
struct RFE_GPSApp: App {
    @StateObject private var locationManager = LocationManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(locationManager) // ← Inject into the app
        }
    }
}
