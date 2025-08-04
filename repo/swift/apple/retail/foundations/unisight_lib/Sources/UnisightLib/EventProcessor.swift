import Foundation

/// Processes telemetry events based on configuration
/// Handles event consolidation and immediate processing
public class EventProcessor {
    
    private let config: UnisightConfiguration
    private var consolidatedEvents: [String: [TelemetryEvent]] = [:]
    private var consolidationTimers: [String: Timer] = [:]
    
    public init(config: UnisightConfiguration) {
        self.config = config
    }
    
    /// Process a telemetry event
    /// - Parameter event: The event to process
    public func process(event: TelemetryEvent) {
        switch config.eventProcessing {
        case .immediate:
            processImmediate(event: event)
        case .consolidate(let window):
            processConsolidated(event: event, window: window)
        case .none:
            // Do nothing
            break
        }
    }
    
    // MARK: - Private Methods
    
    private func processImmediate(event: TelemetryEvent) {
        // Send event immediately
        sendEvent(event)
        
        // Record corresponding metric
        recordMetricForEvent(event)
    }
    
    private func processConsolidated(event: TelemetryEvent, window: TimeInterval) {
        let key = event.name
        
        // Add event to consolidation buffer
        if consolidatedEvents[key] == nil {
            consolidatedEvents[key] = []
        }
        consolidatedEvents[key]?.append(event)
        
        // Cancel existing timer if any
        consolidationTimers[key]?.invalidate()
        
        // Create new timer
        let timer = Timer.scheduledTimer(withTimeInterval: window, repeats: false) { [weak self] _ in
            self?.processConsolidatedEvent(key: key)
        }
        consolidationTimers[key] = timer
    }
    
    private func processConsolidatedEvent(key: String) {
        guard let events = consolidatedEvents[key], !events.isEmpty else {
            return
        }
        
        // Create consolidated event
        let consolidatedEvent = TelemetryEvent(
            name: "consolidated_\(key)",
            category: events.first?.category ?? .user,
            attributes: [
                "original_event_count": events.count,
                "original_event_name": key,
                "consolidation_window": config.eventProcessing.consolidationWindow ?? 0,
                "first_event_time": events.first?.timestamp.timeIntervalSince1970 ?? 0,
                "last_event_time": events.last?.timestamp.timeIntervalSince1970 ?? 0
            ],
            timestamp: Date(),
            sessionId: events.first?.sessionId ?? ""
        )
        
        // Send consolidated event
        sendEvent(consolidatedEvent)
        
        // Record metrics for consolidated events
        recordMetricForConsolidatedEvent(consolidatedEvent, originalEvents: events)
        
        // Clear consolidation buffer
        consolidatedEvents[key] = nil
        consolidationTimers[key] = nil
    }
    
    private func sendEvent(_ event: TelemetryEvent) {
        // In a real implementation, this would send the event to your backend
        print("[EventProcessor] Sending event: \(event.name) with \(event.attributes.count) attributes")
        
        // For now, just log the event
        // You could integrate with your actual event sending mechanism here
    }
    
    private func recordMetricForEvent(_ event: TelemetryEvent) {
        // Record a metric for the event
        let metricName = "\(event.name)_count"
        UnisightTelemetry.shared.recordMetric(name: metricName, value: 1.0)
        
        // Record event-specific metrics based on category
        switch event.category {
        case .user:
            UnisightTelemetry.shared.recordMetric(name: "user_event_count", value: 1.0)
        case .system:
            UnisightTelemetry.shared.recordMetric(name: "system_event_count", value: 1.0)
        case .performance:
            UnisightTelemetry.shared.recordMetric(name: "performance_event_count", value: 1.0)
        case .error:
            UnisightTelemetry.shared.recordMetric(name: "error_event_count", value: 1.0)
        }
    }
    
    private func recordMetricForConsolidatedEvent(_ consolidatedEvent: TelemetryEvent, originalEvents: [TelemetryEvent]) {
        // Record metrics for consolidated events
        UnisightTelemetry.shared.recordMetric(
            name: "consolidated_event_screen_appeared_count", 
            value: Double(originalEvents.count)
        )
        
        // Record time span of consolidation
        if let firstTime = originalEvents.first?.timestamp.timeIntervalSince1970,
           let lastTime = originalEvents.last?.timestamp.timeIntervalSince1970 {
            let timeSpan = lastTime - firstTime
            UnisightTelemetry.shared.recordMetric(
                name: "consolidated_event_screen_appeared_time_span", 
                value: timeSpan
            )
        }
        
        // Record consolidation efficiency
        UnisightTelemetry.shared.recordMetric(
            name: "consolidation_efficiency_ratio", 
            value: Double(originalEvents.count) / max(1.0, consolidatedEvent.attributes["consolidation_window"] as? Double ?? 1.0)
        )
    }
}