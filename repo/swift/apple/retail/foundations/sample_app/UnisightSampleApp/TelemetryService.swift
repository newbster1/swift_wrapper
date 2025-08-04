import Foundation
import UnisightLib

/// Simplified telemetry service for the sample app
/// Provides easy-to-use methods for logging events and metrics
public class TelemetryService {
    
    public static let shared = TelemetryService()
    
    private init() {}
    
    /// Log an event
    /// - Parameters:
    ///   - name: Event name
    ///   - category: Event category
    ///   - attributes: Additional attributes
    public func logEvent(
        name: String,
        category: EventCategory = .user,
        attributes: [String: Any] = [:]
    ) {
        UnisightTelemetry.shared.logEvent(
            name: name,
            category: category,
            attributes: attributes
        )
    }
    
    /// Record a metric
    /// - Parameters:
    ///   - name: Metric name
    ///   - value: Metric value
    ///   - labels: Additional labels
    public func recordMetric(
        name: String,
        value: Double,
        labels: [String: String] = [:]
    ) {
        UnisightTelemetry.shared.recordMetric(
            name: name,
            value: value,
            labels: labels
        )
    }
    
    /// Record test metrics for demonstration
    public func recordTestMetrics() {
        print("[TelemetryService] Recording test metrics")
        
        // Record various types of metrics
        recordMetric(name: "screen_loaded", value: 1.0)
        recordMetric(name: "product_viewed", value: 1.0)
        recordMetric(name: "settings_accessed", value: 1.0)
        recordMetric(name: "button_clicked", value: 1.0)
        recordMetric(name: "api_call_duration", value: 150.0)
        recordMetric(name: "memory_usage", value: 45.2)
        recordMetric(name: "battery_level", value: 0.75)
        
        print("[TelemetryService] Test metrics recorded")
    }
    
    /// Force export of current metrics
    public func forceMetricExport() {
        print("[TelemetryService] Forcing metric export")
        UnisightTelemetry.shared.forceMetricExport()
    }
}