import Foundation
import UnisightLib

// Test script to verify actual metrics are being sent
print("🧪 Testing Actual Metrics Export")

// Initialize telemetry
let config = UnisightConfiguration(
    serviceName: "ActualMetricsTest",
    version: "1.0.0",
    environment: "development",
    dispatcherEndpoint: "https://ref-tel-dis-dev.kbusw2a.shld.apple.com/otlp/v1/metrics",
    headers: [
        "Content-Type": "application/x-protobuf",
        "Accept": "application/x-protobuf"
    ],
    events: EventType.defaultEvents,
    scheme: .debug,
    verbosity: .verbose,
    processing: .consolidate,
    samplingRate: 1.0
)

do {
    try UnisightTelemetry.shared.initialize(with: config)
    print("✅ Telemetry initialized")
    
    // Start a session
    UnisightTelemetry.shared.startNewSession()
    print("✅ Session started")
    
    // Record some actual metrics
    print("📊 Recording actual metrics...")
    
    UnisightTelemetry.shared.recordMetric(name: "test_counter_actual", value: 1.0)
    UnisightTelemetry.shared.recordMetric(name: "test_gauge_actual", value: 42.5)
    UnisightTelemetry.shared.recordMetric(name: "test_histogram_actual", value: 100.0)
    UnisightTelemetry.shared.recordMetric(name: "user_interaction_count", value: 5.0)
    UnisightTelemetry.shared.recordMetric(name: "app_performance_score", value: 95.7)
    
    print("✅ Actual metrics recorded")
    
    // Log some events that should also generate metrics
    UnisightTelemetry.shared.logEvent(
        name: "test_event_with_metrics",
        category: .user,
        attributes: ["test_attribute": "test_value"]
    )
    
    print("✅ Event logged")
    
    // Force export
    UnisightTelemetry.shared.forceMetricExport()
    print("✅ Forced export triggered")
    
    print("\n🎯 Test completed! Check the logs above to see if actual metrics are being sent.")
    print("📝 Look for messages like:")
    print("   - 'Using actual metrics: X metrics'")
    print("   - 'Encoding actual metric: metric_name'")
    print("   - 'Export successful with status: 200'")
    
} catch {
    print("❌ Failed to initialize telemetry: \(error)")
}