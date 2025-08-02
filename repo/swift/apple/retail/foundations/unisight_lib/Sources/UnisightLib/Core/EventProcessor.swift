import Foundation
import OpenTelemetryApi

/// Processes telemetry events according to configuration settings
public class EventProcessor {
    
    // MARK: - Properties
    private let configuration: UnisightConfiguration
    private let consolidationQueue = DispatchQueue(label: "com.unisight.event-processor", qos: .utility)
    private var consolidatedEvents: [String: ConsolidatedEvent] = [:]
    private var consolidationTimer: Timer?
    
    // MARK: - Initialization
    
    public init(config: UnisightConfiguration) {
        self.configuration = config
        setupConsolidationTimer()
    }
    
    // MARK: - Event Processing
    
    public func process(event: TelemetryEvent) {
        // Apply sampling
        if !shouldSampleEvent() {
            return
        }
        
        // Apply scheme filtering
        if !shouldProcessEvent(event) {
            return
        }
        
        // Apply custom processing if configured
        configuration.customEventProcessor?(event)
        
        // Process based on configuration
        switch configuration.processing {
        case .consolidate:
            consolidateEvent(event)
        case .none:
            processEventImmediately(event)
        case .batch:
            consolidateEvent(event)
        }
    }
    
    // MARK: - Private Methods
    
    private func shouldSampleEvent() -> Bool {
        return Double.random(in: 0...1) <= configuration.samplingRate
    }
    
    private func shouldProcessEvent(_ event: TelemetryEvent) -> Bool {
        switch configuration.scheme {
        case .debug:
            return configuration.environment == "development" || configuration.environment == "debug"
        case .production:
            return configuration.environment == "production"
        case .all:
            return true
        }
    }
    
    private func processEventImmediately(_ event: TelemetryEvent) {
        // Create span for the event
        createSpanForEvent(event)
        
        // Log the event
        logEvent(event)
        
        // Record metrics
        recordMetricsForEvent(event)
    }
    
    private func consolidateEvent(_ event: TelemetryEvent) {
        consolidationQueue.async { [weak self] in
            guard let self = self else { return }
            
            let key = self.getConsolidationKey(for: event)
            
            if var existingEvent = self.consolidatedEvents[key] {
                existingEvent.addEvent(event)
                self.consolidatedEvents[key] = existingEvent
            } else {
                self.consolidatedEvents[key] = ConsolidatedEvent(baseEvent: event)
            }
        }
    }
    
    private func getConsolidationKey(for event: TelemetryEvent) -> String {
        var key = "\(event.category.rawValue)_\(event.name)"
        
        // Add view context to key if available
        if let viewContext = event.viewContext {
            key += "_\(viewContext.viewName)"
        }
        
        return key
    }
    
    private func setupConsolidationTimer() {
        guard configuration.processing == .consolidate else { return }
        
        consolidationTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.flushConsolidatedEvents()
        }
    }
    
    private func flushConsolidatedEvents() {
        consolidationQueue.async { [weak self] in
            guard let self = self else { return }
            
            let eventsToFlush = self.consolidatedEvents
            self.consolidatedEvents.removeAll()
            
            DispatchQueue.main.async {
                for (_, consolidatedEvent) in eventsToFlush {
                    self.processConsolidatedEvent(consolidatedEvent)
                }
            }
        }
    }
    
    private func processConsolidatedEvent(_ consolidatedEvent: ConsolidatedEvent) {
        let span = UnisightTelemetry.shared.createSpan(
            name: "consolidated_\(consolidatedEvent.baseEvent.name)",
            kind: .internal,
            attributes: [
                "event_count": consolidatedEvent.eventCount,
                "time_span": consolidatedEvent.timeSpan,
                "category": consolidatedEvent.baseEvent.category.rawValue
            ]
        )
        
        // Add consolidated attributes
        for (key, value) in consolidatedEvent.consolidatedAttributes {
            span.setAttribute(key: "consolidated_\(key)", value: AttributeValue.fromAny(value))
        }
        
        // Add event timestamps
        span.setAttribute(key: "event_timestamps", value: AttributeValue.string(
            consolidatedEvent.timestamps.map { "\($0.timeIntervalSince1970)" }.joined(separator: ",")
        ))
        
        span.end()
        
        // Log consolidated event
        let logRecord = LogRecord(
            timestamp: Date(),
            observedTimestamp: Date(),
            traceId: nil,
            spanId: nil,
            traceFlags: TraceFlags(),
            severityText: "INFO",
            severityNumber: SeverityNumber.info,
            body: AttributeValue.string("Consolidated event: \(consolidatedEvent.baseEvent.name)"),
            attributes: [
                "event_count": AttributeValue.int(consolidatedEvent.eventCount),
                "category": AttributeValue.string(consolidatedEvent.baseEvent.category.rawValue),
                "time_span": AttributeValue.double(consolidatedEvent.timeSpan)
            ]
        )
        UnisightTelemetry.shared.getLogger().emit(logRecord: logRecord)
    }
    
    private func createSpanForEvent(_ event: TelemetryEvent) {
        let spanName = "\(event.category.rawValue)_\(event.name)"
        let span = UnisightTelemetry.shared.createSpan(
            name: spanName,
            kind: .internal,
            attributes: [
                "event_id": event.id,
                "category": event.category.rawValue,
                "session_id": event.sessionId
            ]
        )
        
        // Add event attributes
        for (key, value) in event.attributes {
            span.setAttribute(key: key, value: AttributeValue.fromAny(value.value))
        }
        
        // Add view context if available
        if let viewContext = event.viewContext {
            addViewContextToSpan(span, viewContext: viewContext)
        }
        
        // Add user context if available
        if let userContext = event.userContext {
            addUserContextToSpan(span, userContext: userContext)
        }
        
        // Add device context
        addDeviceContextToSpan(span, deviceContext: event.deviceContext)
        
        span.end()
    }
    
    private func logEvent(_ event: TelemetryEvent) {
        let logger = UnisightTelemetry.shared.getLogger()
        
        var logAttributes: [String: AttributeValue] = [
            "event_id": AttributeValue.string(event.id),
            "category": AttributeValue.string(event.category.rawValue),
            "session_id": AttributeValue.string(event.sessionId)
        ]
        
        // Add event attributes
        for (key, value) in event.attributes {
            logAttributes[key] = AttributeValue.fromAny(value.value)
        }
        
        // Determine log severity based on event category
        let (severityText, severityNumber): (String, SeverityNumber) = {
            switch event.category {
            case .system:
                return ("INFO", SeverityNumber.info)
            case .user, .navigation:
                return ("DEBUG", SeverityNumber.debug)
            case .functional:
                return ("INFO", SeverityNumber.info)
            case .custom:
                return ("DEBUG", SeverityNumber.debug)
            }
        }()
        
        let logRecord = LogRecord(
            timestamp: Date(),
            observedTimestamp: Date(),
            traceId: nil,
            spanId: nil,
            traceFlags: TraceFlags(),
            severityText: severityText,
            severityNumber: severityNumber,
            body: AttributeValue.string("Event: \(event.name)"),
            attributes: logAttributes
        )
        logger.emit(logRecord: logRecord)
    }
    
    private func recordMetricsForEvent(_ event: TelemetryEvent) {
        let meter = UnisightTelemetry.shared.getMeter()
        
        // Record event counter
        let eventCounter = meter.createIntCounter(name: "events_total")
        eventCounter.add(
            value: 1,
            labels: [
                "category": event.category.rawValue,
                "event_name": event.name
            ]
        )
        
        // Record session metrics
        let sessionDuration = meter.createDoubleHistogram(name: "session_duration", explicitBoundaries: nil, absolute: false)
        if let journeyManager = JourneyManager.shared {
            sessionDuration.record(
                value: journeyManager.getSessionDuration(),
                labels: ["session_id": event.sessionId]
            )
        }
        
        // Record screen time metrics if available
        if event.category == .navigation, let timeOnScreen = event.timeOnScreen {
            let screenTimeHistogram = meter.createDoubleHistogram(name: "screen_time", explicitBoundaries: nil, absolute: false)
            screenTimeHistogram.record(
                value: timeOnScreen,
                labels: [
                    "screen_name": event.previousScreen ?? "unknown"
                ]
            )
        }
    }
    
    private func addViewContextToSpan(_ span: Span, viewContext: ViewContext) {
        span.setAttribute(key: "view.name", value: viewContext.viewName)
        
        if let elementId = viewContext.elementIdentifier {
            span.setAttribute(key: "view.element.id", value: elementId)
        }
        
        if let elementType = viewContext.elementType {
            span.setAttribute(key: "view.element.type", value: elementType)
        }
        
        if let elementLabel = viewContext.elementLabel {
            span.setAttribute(key: "view.element.label", value: elementLabel)
        }
        
        if !viewContext.viewHierarchy.isEmpty {
            span.setAttribute(key: "view.hierarchy", value: viewContext.viewHierarchy.joined(separator: " > "))
        }
        
        if let coordinates = viewContext.coordinates {
            span.setAttribute(key: "view.coordinates", value: "(\(coordinates.x), \(coordinates.y))")
        }
    }
    
    private func addUserContextToSpan(_ span: Span, userContext: UserContext) {
        span.setAttribute(key: "user.id", value: userContext.anonymousUserId)
        
        if let segment = userContext.userSegment {
            span.setAttribute(key: "user.segment", value: segment)
        }
        
        for (key, value) in userContext.abTestVariants {
            span.setAttribute(key: "user.ab_test.\(key)", value: value)
        }
        
        for (key, value) in userContext.featureFlags {
            span.setAttribute(key: "user.feature_flag.\(key)", value: value)
        }
    }
    
    private func addDeviceContextToSpan(_ span: Span, deviceContext: DeviceContext) {
        span.setAttribute(key: "device.model", value: deviceContext.deviceModel)
        span.setAttribute(key: "device.os.version", value: deviceContext.osVersion)
        span.setAttribute(key: "device.app.version", value: deviceContext.appVersion)
        span.setAttribute(key: "device.network.status", value: deviceContext.networkStatus)
        span.setAttribute(key: "device.battery.level", value: Double(deviceContext.batteryLevel))
        span.setAttribute(key: "device.memory.usage", value: Int(deviceContext.memoryUsage))
    }
    
    deinit {
        consolidationTimer?.invalidate()
        flushConsolidatedEvents()
    }
}

// MARK: - Consolidated Event

private struct ConsolidatedEvent {
    let baseEvent: TelemetryEvent
    private(set) var eventCount: Int = 1
    private(set) var timestamps: [Date]
    private(set) var consolidatedAttributes: [String: Any] = [:]
    
    init(baseEvent: TelemetryEvent) {
        self.baseEvent = baseEvent
        self.timestamps = [baseEvent.timestamp]
        self.consolidatedAttributes = baseEvent.attributes.mapValues { $0.value }
    }
    
    mutating func addEvent(_ event: TelemetryEvent) {
        eventCount += 1
        timestamps.append(event.timestamp)
        
        // Merge attributes (simple strategy - could be more sophisticated)
        for (key, value) in event.attributes {
            if consolidatedAttributes[key] == nil {
                consolidatedAttributes[key] = [value.value]
            } else if var existingArray = consolidatedAttributes[key] as? [Any] {
                existingArray.append(value.value)
                consolidatedAttributes[key] = existingArray
            } else {
                consolidatedAttributes[key] = [consolidatedAttributes[key]!, value.value]
            }
        }
    }
    
    var timeSpan: TimeInterval {
        guard let first = timestamps.first, let last = timestamps.last else { return 0 }
        return last.timeIntervalSince(first)
    }
}