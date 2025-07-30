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

// Core telemetry functionality
@_exported import struct UnisightTelemetry
@_exported import struct UnisightConfiguration

// Models and data structures
@_exported import struct TelemetryEvent
@_exported import struct ViewContext
@_exported import struct UserContext
@_exported import struct DeviceContext
@_exported import struct AppContext
@_exported import struct AnyCodable

// Configuration enums and types
@_exported import enum EventType
@_exported import enum EventCategory
@_exported import enum EventScheme
@_exported import enum EventVerbosity
@_exported import enum EventProcessing
@_exported import enum UserEventType
@_exported import enum SwipeDirection
@_exported import enum ScreenEventType
@_exported import enum FunctionalEventType
@_exported import enum SystemEventType
@_exported import enum NetworkType
@_exported import enum RequestType

// Journey management
@_exported import class JourneyManager
@_exported import struct JourneySession
@_exported import struct ScreenTransition
@_exported import enum NavigationMethod
@_exported import enum SessionEvent

// Utility classes
@_exported import struct DeviceInfo
@_exported import struct NetworkInfo
@_exported import struct MemoryInfo
@_exported import struct DiskInfo
@_exported import struct AppStateManager
@_exported import struct InstallationManager

// SwiftUI extensions and modifiers (iOS 13.0+)
#if canImport(SwiftUI)
import SwiftUI

@available(iOS 13.0, *)
@_exported import extension View

@available(iOS 13.0, *)
@_exported import struct GestureTrackingWrapper
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
                .system(.accessibility)
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
            verbosity: .complete,
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
        eventAttributes["interaction_type"] = interaction.eventName
        eventAttributes["view_name"] = viewName
        if let elementId = elementId {
            eventAttributes["element_id"] = elementId
        }
        
        logEvent(
            name: "user_\(interaction.eventName)",
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
            name: "system_\(event)",
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