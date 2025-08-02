import Foundation
import UIKit

/// Main telemetry wrapper for iOS applications
/// Provides comprehensive journey tracking and observability features
public class UnisightTelemetry {
    
    // MARK: - Singleton
    public static let shared = UnisightTelemetry()
    
    // MARK: - Properties
    private var isInitialized = false
    private var tracer: Tracer!
    private var meterProvider: MeterProvider!
    private var meter: Meter!
    private var loggerProvider: LoggerProvider!
    private var logger: Logger!
    
    private var sessionId: String = UUID().uuidString
    private var configuration: UnisightConfiguration!
    private var journeyManager: JourneyManager!
    private var eventProcessor: EventProcessor!
    private var telemetryExporter: TelemetryExporter!
    
    // MARK: - Initialization
    private init() {}
    
    /// Initialize the telemetry system with configuration
    /// - Parameter config: Configuration for telemetry behavior
    public func initialize(with config: UnisightConfiguration) throws {
        guard !isInitialized else {
            print("UnisightTelemetry is already initialized")
            return
        }
        
        self.configuration = config
        
        // Initialize custom components first
        self.journeyManager = JourneyManager(config: config)
        self.eventProcessor = EventProcessor(config: config)
        self.telemetryExporter = TelemetryExporter(
            endpoint: config.dispatcherEndpoint,
            headers: config.headers
        )
        
        // Initialize OpenTelemetry components
        try setupOpenTelemetry()
        
        // Setup automatic instrumentation
        setupAutomaticInstrumentation()
        
        // Start system monitoring
        startSystemMonitoring()
        
        isInitialized = true
        
        // Log initialization
        logEvent(
            name: "telemetry_initialized",
            category: .system,
            attributes: [
                "session_id": sessionId,
                "service_name": config.serviceName,
                "version": config.version
            ]
        )
    }
    
    private func setupOpenTelemetry() throws {
        // Temporarily disable OpenTelemetry setup due to API compatibility issues
        // TODO: Re-enable when OpenTelemetry API is stable
        
        // Create mock instances for now
        self.tracer = MockTracer()
        self.meter = MockMeter()
        self.logger = MockLogger()
    }
    
    private func setupAutomaticInstrumentation() {
        // URLSession instrumentation temporarily disabled due to API compatibility issues
        // TODO: Re-enable when OpenTelemetry API is stable
        /*
        let urlSessionConfig = URLSessionInstrumentationConfiguration(
            shouldRecordPayload: { _ in self.configuration.shouldRecordPayloads },
            shouldInstrument: { request in
                // Don't instrument our own telemetry requests
                !(request.url?.absoluteString.contains(self.configuration.dispatcherEndpoint) ?? false)
            },
            nameSpan: { request in
                return "\(request.httpMethod ?? "GET") \(request.url?.path ?? "unknown")"
            }
        )
        
        // Initialize URLSession instrumentation
        _ = URLSessionInstrumentation(configuration: urlSessionConfig)
        */
    }
    
    private func startSystemMonitoring() {
        // Monitor app lifecycle events
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        // Monitor battery level changes
        if configuration.events.contains(.system(.battery(0.1))) {
            UIDevice.current.isBatteryMonitoringEnabled = true
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(batteryLevelChanged),
                name: UIDevice.batteryLevelDidChangeNotification,
                object: nil
            )
        }
        
        // Monitor accessibility changes
        if configuration.events.contains(.system(.accessibility)) {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(accessibilityChanged),
                name: UIAccessibility.voiceOverStatusDidChangeNotification,
                object: nil
            )
        }
    }
    
    // MARK: - Public API
    
    /// Start a new session
    public func startNewSession() {
        sessionId = UUID().uuidString
        journeyManager.startNewSession(sessionId: sessionId)
        
        logEvent(
            name: "session_started",
            category: .system,
            attributes: ["session_id": sessionId]
        )
    }
    
    /// Log a custom event
    public func logEvent(
        name: String,
        category: EventCategory,
        attributes: [String: Any] = [:],
        timestamp: Date = Date()
    ) {
        let event = TelemetryEvent(
            name: name,
            category: category,
            attributes: attributes,
            timestamp: timestamp,
            sessionId: sessionId
        )
        
        eventProcessor.process(event: event)
    }
    
    /// Create a span for tracing
    public func createSpan(
        name: String,
        kind: SpanKind = .internal,
        attributes: [String: Any] = [:]
    ) -> Span {
        let spanBuilder = tracer.spanBuilder(spanName: name)
            .setSpanKind(spanKind: kind)
        
        // Add common attributes
        spanBuilder.setAttribute(key: "session.id", value: sessionId)
        
        // Add custom attributes
        for (key, value) in attributes {
            spanBuilder.setAttribute(key: key, value: AttributeValue.fromAny(value))
        }
        
        return spanBuilder.startSpan()
    }
    
    /// Record a metric
    public func recordMetric(
        name: String,
        value: Double,
        labels: [String: String] = [:]
    ) {
        let counter = meter.createDoubleCounter(name: name)
        counter.add(value: value, labels: labels)
    }
    
    /// Get the current tracer
    public func getTracer() -> Tracer {
        return tracer
    }
    
    /// Get the current meter
    public func getMeter() -> Meter {
        return meter
    }
    
    /// Get the current logger
    public func getLogger() -> Logger {
        return logger
    }
    
    /// Get the journey manager for advanced journey tracking
    public func getJourneyManager() -> JourneyManager {
        return journeyManager
    }
    
    // MARK: - System Event Handlers
    
    @objc private func appDidEnterBackground() {
        logEvent(
            name: "app_background",
            category: .system,
            attributes: ["previous_state": "foreground"]
        )
    }
    
    @objc private func appWillEnterForeground() {
        logEvent(
            name: "app_foreground",
            category: .system,
            attributes: ["previous_state": "background"]
        )
    }
    
    @objc private func batteryLevelChanged() {
        let batteryLevel = UIDevice.current.batteryLevel
        logEvent(
            name: "battery_level_changed",
            category: .system,
            attributes: ["battery_level": batteryLevel]
        )
    }
    
    @objc private func accessibilityChanged() {
        logEvent(
            name: "accessibility_changed",
            category: .system,
            attributes: [
                "voice_over_enabled": UIAccessibility.isVoiceOverRunning,
                "switch_control_enabled": UIAccessibility.isSwitchControlRunning,
                "reduce_motion_enabled": UIAccessibility.isReduceMotionEnabled
            ]
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - OpenTelemetry Type Definitions (Temporary)

public protocol Tracer {
    func spanBuilder(spanName: String) -> SpanBuilder
}

public protocol SpanBuilder {
    func setSpanKind(spanKind: SpanKind) -> SpanBuilder
    func setAttribute(key: String, value: AttributeValue) -> SpanBuilder
    func startSpan() -> Span
}

public protocol Span {
    func setAttribute(key: String, value: AttributeValue)
    func end()
}

public protocol Meter {
    func createDoubleCounter(name: String) -> DoubleCounter
    func createIntCounter(name: String) -> IntCounter
    func createDoubleHistogram(name: String) -> DoubleHistogram
}

public protocol DoubleCounter {
    func add(value: Double, labels: [String: String])
}

public protocol IntCounter {
    func add(value: Int, labels: [String: String])
}

public protocol DoubleHistogram {
    func record(value: Double, labels: [String: String])
}

public protocol Logger {
    func log(text: String, severity: LogSeverity, attributes: [String: AttributeValue])
}

public enum SpanKind {
    case internal
    case server
    case client
    case producer
    case consumer
}

public enum LogSeverity {
    case trace
    case debug
    case info
    case warn
    case error
    case fatal
}

public enum AttributeValue {
    case string(String)
    case bool(Bool)
    case int(Int)
    case double(Double)
    case stringArray([String])
    case boolArray([Bool])
    case intArray([Int])
    case doubleArray([Double])
}

// MARK: - Mock Classes for OpenTelemetry Compatibility

private class MockTracer: Tracer {
    func spanBuilder(spanName: String) -> SpanBuilder {
        return MockSpanBuilder()
    }
}

private class MockSpanBuilder: SpanBuilder {
    func setSpanKind(spanKind: SpanKind) -> SpanBuilder {
        return self
    }
    
    func setAttribute(key: String, value: AttributeValue) -> SpanBuilder {
        return self
    }
    
    func startSpan() -> Span {
        return MockSpan()
    }
}

private class MockSpan: Span {
    func setAttribute(key: String, value: AttributeValue) {
        // Mock implementation
    }
    
    func end() {
        // Mock implementation
    }
}

private class MockMeter: Meter {
    func createDoubleCounter(name: String) -> DoubleCounter {
        return MockDoubleCounter()
    }
    
    func createIntCounter(name: String) -> IntCounter {
        return MockIntCounter()
    }
    
    func createDoubleHistogram(name: String) -> DoubleHistogram {
        return MockDoubleHistogram()
    }
}

private class MockDoubleCounter: DoubleCounter {
    func add(value: Double, labels: [String: String]) {
        // Mock implementation
    }
}

private class MockIntCounter: IntCounter {
    func add(value: Int, labels: [String: String]) {
        // Mock implementation
    }
}

private class MockDoubleHistogram: DoubleHistogram {
    func record(value: Double, labels: [String: String]) {
        // Mock implementation
    }
}

private class MockLogger: Logger {
    func log(text: String, severity: LogSeverity, attributes: [String: AttributeValue]) {
        // Mock implementation
    }
}

// MARK: - AttributeValue Extension
extension AttributeValue {
    static func fromAny(_ value: Any) -> AttributeValue {
        switch value {
        case let stringValue as String:
            return .string(stringValue)
        case let intValue as Int:
            return .int(intValue)
        case let doubleValue as Double:
            return .double(doubleValue)
        case let boolValue as Bool:
            return .bool(boolValue)
        default:
            return .string(String(describing: value))
        }
    }
}