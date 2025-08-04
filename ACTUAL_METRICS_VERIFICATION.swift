import Foundation
import UnisightLib

/// Test script to verify actual metrics are being sent
/// This demonstrates the complete flow from event logging to metric export

// MARK: - Test Configuration
let testConfig = UnisightConfiguration(
    serviceName: "UnisightTestApp",
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
    processing: .immediate, // Use immediate processing for testing
    samplingRate: 1.0
)

// MARK: - Test Functions

func testInitialization() {
    print("🔧 Testing telemetry initialization...")
    
    do {
        try UnisightTelemetry.shared.initialize(with: testConfig)
        UnisightTelemetry.shared.startNewSession()
        print("✅ Telemetry initialized successfully")
    } catch {
        print("❌ Failed to initialize telemetry: \(error)")
        return
    }
}

func testEventLogging() {
    print("\n📝 Testing event logging...")
    
    // Log various events that should generate actual metrics
    TelemetryService.shared.logEvent(
        name: "screen_loaded",
        category: .user,
        attributes: ["screen_name": "home", "user_id": "test_user_123"]
    )
    
    TelemetryService.shared.logEvent(
        name: "product_viewed",
        category: .user,
        attributes: ["product_id": "prod_456", "category": "electronics"]
    )
    
    TelemetryService.shared.logEvent(
        name: "settings_accessed",
        category: .user,
        attributes: ["setting_type": "privacy", "action": "view"]
    )
    
    TelemetryService.shared.logEvent(
        name: "button_clicked",
        category: .user,
        attributes: ["button_id": "submit_order", "screen": "checkout"]
    )
    
    print("✅ Events logged successfully")
}

func testDirectMetricRecording() {
    print("\n📊 Testing direct metric recording...")
    
    // Record metrics directly
    TelemetryService.shared.recordMetric(name: "api_call_duration", value: 150.0)
    TelemetryService.shared.recordMetric(name: "memory_usage", value: 45.2)
    TelemetryService.shared.recordMetric(name: "battery_level", value: 0.75)
    TelemetryService.shared.recordMetric(name: "user_session_duration", value: 300.0)
    
    print("✅ Direct metrics recorded successfully")
}

func testTestMetrics() {
    print("\n🧪 Testing test metrics...")
    
    // Record test metrics using the dedicated method
    TelemetryService.shared.recordTestMetrics()
    
    print("✅ Test metrics recorded successfully")
}

func testMetricExport() {
    print("\n📤 Testing metric export...")
    
    // Force export to see actual metrics being sent
    TelemetryService.shared.forceMetricExport()
    
    print("✅ Metric export triggered")
}

func testConsolidatedEvents() {
    print("\n🔄 Testing consolidated events...")
    
    // Create a config with consolidation
    let consolidatedConfig = UnisightConfiguration(
        serviceName: "UnisightTestApp",
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
        processing: .consolidate(5.0), // 5 second consolidation window
        samplingRate: 1.0
    )
    
    // Reinitialize with consolidation
    do {
        try UnisightTelemetry.shared.initialize(with: consolidatedConfig)
        UnisightTelemetry.shared.startNewSession()
        
        // Log multiple rapid events that should be consolidated
        for i in 1...5 {
            TelemetryService.shared.logEvent(
                name: "screen_appeared",
                category: .user,
                attributes: ["screen_name": "product_detail", "iteration": i]
            )
        }
        
        print("✅ Consolidated events logged (will be processed in 5 seconds)")
        
        // Wait for consolidation
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
            print("🔄 Processing consolidated events...")
            TelemetryService.shared.forceMetricExport()
        }
        
    } catch {
        print("❌ Failed to initialize with consolidation: \(error)")
    }
}

// MARK: - Main Test Execution

func runAllTests() {
    print("🚀 Starting comprehensive actual metrics test...")
    print("=" * 60)
    
    testInitialization()
    testEventLogging()
    testDirectMetricRecording()
    testTestMetrics()
    testMetricExport()
    testConsolidatedEvents()
    
    print("\n" + "=" * 60)
    print("🎯 Test execution completed!")
    print("\n📋 Expected Results:")
    print("1. ✅ Telemetry should initialize successfully")
    print("2. ✅ Events should be logged and processed")
    print("3. ✅ Actual metrics should be recorded (not test_metric)")
    print("4. ✅ Metric export should show actual metric names in logs")
    print("5. ✅ Consolidated events should generate additional metrics")
    print("\n🔍 Check the logs for:")
    print("- '[ManualTelemetryExporter] Using actual metrics for export'")
    print("- '[ManualTelemetryExporter] Exported X actual metrics'")
    print("- Actual metric names like 'screen_loaded_count', 'product_viewed_count', etc.")
    print("- No more 'test_metric' in the exported data")
}

// MARK: - Helper Extension

extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}

// MARK: - Run Tests

// Uncomment the line below to run the tests
// runAllTests()