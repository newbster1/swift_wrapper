import Foundation
import UnisightLib

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
            let config = UnisightConfiguration(
                serviceName: "UnisightSampleApp",
                version: "1.0.0",
                environment: "development",
                dispatcherEndpoint: "https://your-telemetry-endpoint.com/otlp/v1/metrics",
                events: EventType.defaultEvents,
                scheme: .debug,
                verbosity: .complete,
                processing: .consolidate,
                samplingRate: 1.0
            )

            try UnisightTelemetry.shared.initialize(with: config)
            isInitialized = true

            // Start a new session
            UnisightTelemetry.shared.startNewSession()

            print("✅ Telemetry initialized successfully")

        } catch {
            print("❌ Failed to initialize telemetry: \(error)")
        }
    }

    // MARK: - Event Logging Methods

    func logEvent(
        name: String,
        category: EventCategory,
        attributes: [String: Any] = [:],
        viewContext: ViewContext? = nil,
        userContext: UserContext? = nil
    ) {
        guard isInitialized else {
            print("⚠️ Telemetry not initialized. Event '\(name)' not logged.")
            return
        }

        UnisightTelemetry.shared.logEvent(
            name: name,
            category: category,
            attributes: attributes
        )
    }

    func logUserInteraction(
        _ interaction: UserEventType,
        viewName: String,
        elementId: String? = nil,
        elementType: String? = nil,
        elementLabel: String? = nil,
        coordinates: CGPoint? = nil
    ) {
        let viewContext = ViewContext(
            viewName: viewName,
            elementIdentifier: elementId,
            elementType: elementType,
            elementLabel: elementLabel,
            coordinates: coordinates
        )

        logEvent(
            name: "user_\(interaction.userEventName)",
            category: .user,
            viewContext: viewContext
        )
    }
    
    // Backward compatibility method for string-based interactions
    func logUserInteraction(
        _ interaction: String,
        viewName: String,
        elementId: String? = nil,
        elementType: String? = nil,
        elementLabel: String? = nil,
        coordinates: CGPoint? = nil
    ) {
        let viewContext = ViewContext(
            viewName: viewName,
            elementIdentifier: elementId,
            elementType: elementType,
            elementLabel: elementLabel,
            coordinates: coordinates
        )

        logEvent(
            name: "user_\(interaction)",
            category: .user,
            viewContext: viewContext
        )
    }

    func logNavigation(
        from: String?,
        to: String,
        method: NavigationMethod = .unknown,
        deepLink: String? = nil
    ) {
        JourneyManager.shared?.trackScreenTransition(
            from: from,
            to: to,
            method: method,
            deepLink: deepLink
        )
    }

    func logScreenAppeared(_ screenName: String) {
        JourneyManager.shared?.trackScreenAppeared(screenName)
    }

    func logScreenDisappeared(_ screenName: String) {
        JourneyManager.shared?.trackScreenDisappeared(screenName)
    }

    func logNetworkRequest(
        url: String,
        method: String,
        statusCode: Int? = nil,
        duration: TimeInterval? = nil,
        payloadSize: Int? = nil
    ) {
        var attributes: [String: Any] = [
            "url": url,
            "method": method
        ]

        if let statusCode = statusCode {
            attributes["status_code"] = statusCode
        }
        if let duration = duration {
            attributes["duration"] = duration
        }
        if let payloadSize = payloadSize {
            attributes["payload_size"] = payloadSize
        }

        logEvent(name: "network_request", category: .functional, attributes: attributes)
    }

    func logError(_ error: Error, context: String? = nil) {
        var attributes: [String: Any] = [
            "error_description": error.localizedDescription,
            "error_type": String(describing: type(of: error))
        ]

        if let context = context {
            attributes["context"] = context
        }

        logEvent(name: "error", category: .system, attributes: attributes)
    }

    // MARK: - User Context

    func setUserContext(userId: String, segment: String? = nil) {
        // Log user identification event with user context
        UnisightTelemetry.shared.logEvent(
            name: "user_identified",
            category: .user,
            attributes: [
                "user_id": userId,
                "user_segment": segment ?? "unknown"
            ]
        )
    }
}