import SwiftUI

@main
struct UnisightSampleAppApp: App {
    
    init() {
        // Initialize telemetry system
        TelemetryService.shared.initialize()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Log app launch
                    TelemetryService.shared.logEvent(
                        name: "app_launched",
                        category: .system,
                        attributes: [
                            "launch_time": Date().timeIntervalSince1970,
                            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
                        ]
                    )
                }
        }
    }
}