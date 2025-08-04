import SwiftUI
import UnisightLib

@main
struct UnisightSampleAppApp: App {
    
    init() {
        // Initialize telemetry early in app lifecycle
        TelemetryService.shared.initialize()

        // Set up user context (in a real app, this would come from your auth system)
        TelemetryService.shared.setUserContext(
            userId: UUID().uuidString,
            segment: "sample_user"
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Log app launch with device info
                    let attributes: [String: Any] = [
                        "device_model": DeviceInfo.model,
                        "os_version": DeviceInfo.osVersion,
                        "app_version": DeviceInfo.appVersion,
                        "first_launch": UserDefaults.standard.bool(forKey: "hasLaunchedBefore") == false
                    ]

                    TelemetryService.shared.logEvent(
                        name: "app_launch",
                        category: .system,
                        attributes: attributes
                    )
                    
                    // Record app launch metrics
                    UnisightTelemetry.shared.recordMetric(name: "app_launch_count", value: 1.0)
                    UnisightTelemetry.shared.recordMetric(name: "app_launch_timestamp", value: Date().timeIntervalSince1970)

                    UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
                }
        }
    }
}