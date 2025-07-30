import Foundation

/// Simple telemetry service wrapper for the sample app
/// This demonstrates how to integrate UnisightLib in a real application
class TelemetryService {
    static let shared = TelemetryService()
    
    private var isInitialized = false
    
    private init() {}
    
    func initialize() {
        guard !isInitialized else {
            print("TelemetryService is already initialized")
            return
        }
        
        do {
            // For this sample, we'll create a simple configuration
            // In a real app, you would load these from configuration files or environment
            let config = createSampleConfiguration()
            
            // Initialize UnisightLib with the configuration
            // try UnisightLib.initialize(with: config)
            
            print("✅ Telemetry initialized successfully")
            print("📊 Dispatcher endpoint: \(config.dispatcherEndpoint)")
            print("🔧 Environment: \(config.environment)")
            
            isInitialized = true
            
        } catch {
            print("❌ Failed to initialize telemetry: \(error)")
        }
    }
    
    private func createSampleConfiguration() -> SampleConfiguration {
        return SampleConfiguration(
            serviceName: "UnisightSampleApp",
            version: "1.0.0",
            environment: "development",
            dispatcherEndpoint: "https://ref-tel-dis-dev.kbusw2a.shld.apple.com/otlp/v1/metrics"
        )
    }
    
    // MARK: - Event Logging Methods
    
    func logEvent(name: String, category: EventCategory, attributes: [String: Any] = [:]) {
        guard isInitialized else {
            print("⚠️ Telemetry not initialized. Event '\(name)' not logged.")
            return
        }
        
        // For demo purposes, we'll just print the events
        // In the real implementation, this would call UnisightTelemetry.shared.logEvent
        print("📝 Event: \(name)")
        print("   Category: \(category.rawValue)")
        if !attributes.isEmpty {
            print("   Attributes: \(attributes)")
        }
        
        // UnisightTelemetry.shared.logEvent(name: name, category: category, attributes: attributes)
    }
    
    func logUserInteraction(_ interaction: String, viewName: String, elementId: String? = nil) {
        var attributes: [String: Any] = [
            "interaction_type": interaction,
            "view_name": viewName
        ]
        
        if let elementId = elementId {
            attributes["element_id"] = elementId
        }
        
        logEvent(name: "user_interaction", category: .user, attributes: attributes)
    }
    
    func logNavigation(from: String?, to: String) {
        logEvent(
            name: "navigation",
            category: .navigation,
            attributes: [
                "from_screen": from ?? "unknown",
                "to_screen": to
            ]
        )
    }
    
    func logNetworkRequest(url: String, method: String, statusCode: Int? = nil) {
        var attributes: [String: Any] = [
            "url": url,
            "method": method
        ]
        
        if let statusCode = statusCode {
            attributes["status_code"] = statusCode
        }
        
        logEvent(name: "network_request", category: .functional, attributes: attributes)
    }
    
    func logError(_ error: Error, context: String? = nil) {
        var attributes: [String: Any] = [
            "error_description": error.localizedDescription
        ]
        
        if let context = context {
            attributes["context"] = context
        }
        
        logEvent(name: "error", category: .system, attributes: attributes)
    }
}

// MARK: - Sample Configuration

/// Sample configuration structure for demo purposes
/// In the real implementation, this would use UnisightConfiguration
struct SampleConfiguration {
    let serviceName: String
    let version: String
    let environment: String
    let dispatcherEndpoint: String
}

// MARK: - Event Categories

enum EventCategory: String, CaseIterable {
    case user = "user"
    case navigation = "navigation"
    case system = "system"
    case functional = "functional"
    case custom = "custom"
}