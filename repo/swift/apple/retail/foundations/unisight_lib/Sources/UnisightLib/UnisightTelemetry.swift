import Foundation
import OpenTelemetryApi
import OpenTelemetrySdk
import ResourceExtension
import URLSessionInstrumentation
import NetworkStatus

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
        
        // Initialize OpenTelemetry components
        try setupOpenTelemetry()
        
        // Initialize custom components
        self.journeyManager = JourneyManager(config: config)
        self.eventProcessor = EventProcessor(config: config)
        self.telemetryExporter = TelemetryExporter(
            endpoint: config.dispatcherEndpoint,
            headers: config.headers
        )
        
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
        // Create resource
        let resource = Resource(
            attributes: [
                ResourceAttributes.serviceName: AttributeValue.string(configuration.serviceName),
                ResourceAttributes.serviceVersion: AttributeValue.string(configuration.version),
                ResourceAttributes.deploymentEnvironment: AttributeValue.string(configuration.environment),
                "session.id": AttributeValue.string(sessionId),
                "device.model": AttributeValue.string(DeviceInfo.model),
                "os.name": AttributeValue.string(DeviceInfo.osName),
                "os.version": AttributeValue.string(DeviceInfo.osVersion),
                "app.version": AttributeValue.string(DeviceInfo.appVersion)
            ]
        )
        
        // Setup tracer provider
        let spanProcessor = configuration.usesBatchProcessor 
            ? BatchSpanProcessor(spanExporter: telemetryExporter)
            : SimpleSpanProcessor(spanExporter: telemetryExporter)
        
        let tracerProvider = TracerProviderBuilder()
            .add(spanProcessor: spanProcessor)
            .with(resource: resource)
            .build()
        
        OpenTelemetry.registerTracerProvider(tracerProvider: tracerProvider)
        
        self.tracer = OpenTelemetry.instance.tracerProvider.get(
            instrumentationName: "UnisightTelemetry",
            instrumentationVersion: "1.0.0"
        )
        
        // Setup meter provider
        let metricExporter = OTLPMetricExporter(endpoint: configuration.dispatcherEndpoint)
        let metricProcessor = PeriodicMetricReader(
            exporter: metricExporter,
            exportInterval: TimeInterval(configuration.metricsExportInterval)
        )
        
        self.meterProvider = MeterProviderBuilder()
            .with(resource: resource)
            .registerMetricReader(metricProcessor)
            .build()
        
        self.meter = meterProvider.get(instrumentationName: "UnisightTelemetry")
        
        // Setup logger provider
        let logExporter = OTLPLogExporter(endpoint: configuration.dispatcherEndpoint)
        let logProcessor = BatchLogRecordProcessor(exporter: logExporter)
        
        self.loggerProvider = LoggerProviderBuilder()
            .with(resource: resource)
            .add(processor: logProcessor)
            .build()
        
        self.logger = loggerProvider.get(instrumentationName: "UnisightTelemetry")
    }
    
    private func setupAutomaticInstrumentation() {
        // Setup URLSession instrumentation
        let urlSessionConfig = URLSessionInstrumentationConfiguration(
            shouldRecordPayload: { _ in configuration.shouldRecordPayloads },
            shouldInstrument: { request in
                // Don't instrument our own telemetry requests
                !request.url?.absoluteString.contains(configuration.dispatcherEndpoint) ?? true
            },
            nameSpan: { request in
                return "\(request.httpMethod ?? "GET") \(request.url?.path ?? "unknown")"
            }
        )
        
        URLSessionInstrumentation(configuration: urlSessionConfig)
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
                name: UIAccessibility.notificationName,
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
        attributes: [String: String] = [:]
    ) {
        let counter = meter.createDoubleCounter(name: name)
        counter.add(value: value, attributes: attributes)
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