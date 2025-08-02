import Foundation

/// UnisightLib - Comprehensive iOS Telemetry Wrapper
/// 
/// A Swift telemetry library that provides comprehensive journey tracking and observability
/// features for iOS applications. Built on top of OpenTelemetry, it sends data in OTLP
/// format to configurable dispatcher endpoints.
///
/// Features:
/// - User interaction tracking (taps, swipes, gestures)
/// - Navigation and screen transition tracking
/// - System event monitoring (app lifecycle, battery, accessibility)
/// - Network request instrumentation
/// - Custom event logging with rich context
/// - OTLP-compliant data export
/// - Privacy-focused with PII redaction
/// - Configurable sampling and processing
///
/// Usage:
/// ```swift
/// import UnisightLib
/// 
/// let config = UnisightConfiguration(
///     serviceName: "MyApp",
///     version: "1.0.0",
///     dispatcherEndpoint: "https://your-dispatcher.com/otlp/v1/metrics"
/// )
/// 
/// try UnisightTelemetry.shared.initialize(with: config)
/// 
/// // Track custom events
/// UnisightTelemetry.shared.logEvent(
///     name: "user_action",
///     category: .user,
///     attributes: ["action": "button_press"]
/// )
/// 
/// // Use SwiftUI modifiers for automatic tracking
/// Button("Click me") { }
///     .trackTapGesture(viewName: "MainView", elementId: "clickButton")
/// ```

// MARK: - Public API Exports

// Note: All types are defined within this module, so no @_exported imports are needed
// The types are automatically available when importing UnisightLib

// MARK: - SwiftUI Extensions (iOS 13.0+)
#if canImport(SwiftUI)
import SwiftUI
#endif

// MARK: - Library Information

public struct UnisightLib {
    public static let version = "1.0.0"
    public static let name = "UnisightLib"
    
    /// Initialize the telemetry library with a simple configuration
    /// - Parameters:
    ///   - serviceName: Name of your service/app
    ///   - version: Version of your app
    ///   - dispatcherEndpoint: OTLP endpoint URL
    ///   - environment: Environment name (development, staging, production)
    /// - Throws: Configuration or initialization errors
    public static func initialize(
        serviceName: String,
        version: String,
        dispatcherEndpoint: String,
        environment: String = "development"
    ) throws {
        let config = UnisightConfiguration(
            serviceName: serviceName,
            version: version,
            environment: environment,
            dispatcherEndpoint: dispatcherEndpoint
        )
        
        try UnisightTelemetry.shared.initialize(with: config)
    }
    
    /// Initialize with a custom configuration
    /// - Parameter configuration: Custom UnisightConfiguration
    /// - Throws: Configuration or initialization errors
    public static func initialize(with configuration: UnisightConfiguration) throws {
        try UnisightTelemetry.shared.initialize(with: configuration)
    }
    
    /// Get the shared telemetry instance
    public static var shared: UnisightTelemetry {
        return UnisightTelemetry.shared
    }
    
    /// Create a pre-configured setup for retail applications
    /// - Parameters:
    ///   - appName: Name of the retail app
    ///   - version: App version
    ///   - dispatcherEndpoint: OTLP endpoint
    ///   - userId: Anonymous user identifier
    /// - Returns: Configured UnisightConfiguration
    public static func retailConfiguration(
        appName: String,
        version: String,
        dispatcherEndpoint: String,
        userId: String? = nil
    ) -> UnisightConfiguration {
        return UnisightConfiguration(
            serviceName: appName,
            version: version,
            environment: "production",
            dispatcherEndpoint: dispatcherEndpoint,
            events: [
                // User interactions
                .user(.tap),
                .user(.swipe(.left)),
                .user(.swipe(.right)),
                .user(.selection),
                .user(.entry),
                
                // Navigation
                .screen(.navigated),
                .screen(.appeared),
                .screen(.disappeared),
                
                // Network
                .functional(.network(.request(.foreground))),
                .functional(.network(.response(.foreground))),
                
                // System
                            .system(.foreground),
            .system(.background),
            .system(.battery(0.1)),
            .system(.accessibilityChange)
            ],
            scheme: .production,
            verbosity: .discrete,
            processing: .consolidate,
            usesBatchProcessor: true,
            metricsExportInterval: 30,
            samplingRate: 1.0,
            enablePIIRedaction: true
        )
    }
    
    /// Create a debug configuration for development
    /// - Parameters:
    ///   - appName: Name of the app
    ///   - version: App version
    ///   - dispatcherEndpoint: OTLP endpoint
    /// - Returns: Configured UnisightConfiguration for debugging
    public static func debugConfiguration(
        appName: String,
        version: String,
        dispatcherEndpoint: String
    ) -> UnisightConfiguration {
        return UnisightConfiguration(
            serviceName: appName,
            version: version,
            environment: "development",
            dispatcherEndpoint: dispatcherEndpoint,
            events: EventType.defaultEvents,
            scheme: .debug,
            verbosity: .verbose,
            processing: .none,
            usesBatchProcessor: false,
            metricsExportInterval: 5,
            samplingRate: 1.0,
            enablePIIRedaction: false
        )
    }
}

// MARK: - Convenience Extensions

public extension UnisightTelemetry {
    
    /// Quick event logging with minimal parameters
    /// - Parameters:
    ///   - name: Event name
    ///   - category: Event category
    ///   - attributes: Optional attributes dictionary
    func log(_ name: String, category: EventCategory = .custom, attributes: [String: Any] = [:]) {
        logEvent(name: name, category: category, attributes: attributes)
    }
    
    /// Log a user interaction event
    /// - Parameters:
    ///   - interaction: Type of interaction
    ///   - viewName: Name of the view
    ///   - elementId: Optional element identifier
    ///   - attributes: Additional attributes
    func logUserInteraction(
        _ interaction: UserEventType,
        viewName: String,
        elementId: String? = nil,
        attributes: [String: Any] = [:]
    ) {
        var eventAttributes = attributes
        eventAttributes["interaction_type"] = interaction.userEventName
        eventAttributes["view_name"] = viewName
        if let elementId = elementId {
            eventAttributes["element_id"] = elementId
        }
        
        logEvent(
            name: "user_\(interaction.userEventName)",
            category: .user,
            attributes: eventAttributes
        )
    }
    
    /// Log a navigation event
    /// - Parameters:
    ///   - from: Source screen
    ///   - to: Destination screen
    ///   - method: Navigation method
    func logNavigation(from: String?, to: String, method: NavigationMethod = .unknown) {
        logEvent(
            name: "navigation",
            category: .navigation,
            attributes: [
                "from_screen": from ?? "unknown",
                "to_screen": to,
                "method": method.rawValue
            ]
        )
    }
    
    /// Log a system event
    /// - Parameters:
    ///   - event: System event type
    ///   - attributes: Additional attributes
    func logSystemEvent(_ event: SystemEventType, attributes: [String: Any] = [:]) {
        var eventAttributes = attributes
        
        switch event {
        case .battery(let threshold):
            eventAttributes["threshold"] = threshold
        default:
            break
        }
        
        logEvent(
            name: "system_\(event.systemEventName)",
            category: .system,
            attributes: eventAttributes
        )
    }
}

// MARK: - Error Types

public enum UnisightError: Error, LocalizedError {
    case configurationError(String)
    case initializationError(String)
    case exportError(String)
    case networkError(String)
    
    public var errorDescription: String? {
        switch self {
        case .configurationError(let message):
            return "Configuration Error: \(message)"
        case .initializationError(let message):
            return "Initialization Error: \(message)"
        case .exportError(let message):
            return "Export Error: \(message)"
        case .networkError(let message):
            return "Network Error: \(message)"
        }
    }
}