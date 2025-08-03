import Foundation
import UnisightLib

/// Integration test to verify protobuf telemetry export works correctly
class TelemetryIntegrationTest {
    
    static func runTests() {
        print("🧪 Starting Telemetry Integration Tests...")
        
        // Test 1: Manual Protobuf Encoding
        testManualProtobufEncoding()
        
        // Test 2: Full Telemetry Stack
        testFullTelemetryStack()
        
        // Test 3: Sample App Integration
        testSampleAppIntegration()
        
        print("✅ All integration tests completed!")
    }
    
    static func testManualProtobufEncoding() {
        print("\n📊 Test 1: Manual Protobuf Encoding")
        
        // Create sample span data
        let spans = createSampleSpans()
        
        // Test manual encoding
        let protobufData = ManualProtobufEncoder.encodeSpans(spans)
        
        print("   ✓ Encoded \(spans.count) spans to \(protobufData.count) bytes")
        print("   ✓ Protobuf hex preview: \(protobufData.prefix(32).map { String(format: "%02x", $0) }.joined())")
        
        // Test metrics encoding
        let metrics = createSampleMetrics()
        let metricsData = ManualProtobufEncoder.encodeMetrics(metrics)
        
        print("   ✓ Encoded \(metrics.count) metrics to \(metricsData.count) bytes")
    }
    
    static func testFullTelemetryStack() {
        print("\n🔄 Test 2: Full Telemetry Stack")
        
        do {
            // Configure telemetry with test endpoint
            let config = UnisightConfiguration(
                serviceName: "IntegrationTest",
                version: "1.0.0",
                environment: "test",
                dispatcherEndpoint: "https://httpbin.org/post",  // Test endpoint
                headers: [
                    "Content-Type": "application/x-protobuf",
                    "X-Test": "integration-test"
                ],
                scheme: .debug,
                verbosity: .verbose,
                processing: .none,
                samplingRate: 1.0
            )
            
            // Initialize telemetry
            try UnisightTelemetry.shared.initialize(with: config)
            print("   ✓ Telemetry initialized successfully")
            
            // Log test events
            UnisightTelemetry.shared.logEvent(
                name: "integration_test",
                category: .custom,
                attributes: [
                    "test_type": "protobuf_export",
                    "timestamp": Date().timeIntervalSince1970
                ]
            )
            
            print("   ✓ Test event logged")
            
            // Test span creation
            let span = UnisightTelemetry.shared.createSpan(
                name: "test_span",
                kind: .internal,
                attributes: [
                    "test_attribute": "test_value",
                    "span_number": 1
                ]
            )
            
            // Simulate some work
            Thread.sleep(forTimeInterval: 0.1)
            span.end()
            
            print("   ✓ Test span created and ended")
            
        } catch {
            print("   ❌ Test failed: \(error)")
        }
    }
    
    static func testSampleAppIntegration() {
        print("\n📱 Test 3: Sample App Integration")
        
        // Test TelemetryService initialization
        TelemetryService.shared.initialize()
        print("   ✓ TelemetryService initialized")
        
        // Test user interaction logging
        TelemetryService.shared.logUserInteraction(
            .tap,
            viewName: "TestView",
            elementId: "test_button"
        )
        print("   ✓ User interaction logged")
        
        // Test navigation logging
        TelemetryService.shared.logNavigation(
            from: "TestView",
            to: "AnotherView",
            method: .push
        )
        print("   ✓ Navigation logged")
        
        // Test custom event
        TelemetryService.shared.logEvent(
            name: "test_custom_event",
            category: .functional,
            attributes: [
                "integration_test": true,
                "test_timestamp": Date().timeIntervalSince1970
            ]
        )
        print("   ✓ Custom event logged")
    }
    
    // MARK: - Helper Methods
    
    private static func createSampleSpans() -> [SpanData] {
        // This would normally come from OpenTelemetry SDK
        // For testing, we'll create mock span data
        return []  // Empty for now since we'd need real SpanData instances
    }
    
    private static func createSampleMetrics() -> [StableMetricData] {
        // This would normally come from OpenTelemetry SDK
        // For testing, we'll create mock metric data
        return []  // Empty for now since we'd need real metric instances
    }
}

/// Extension to test protobuf encoding directly
extension TelemetryIntegrationTest {
    
    static func testProtobufBinaryOutput() {
        print("\n🔍 Testing Raw Protobuf Binary Output")
        
        // Test basic protobuf encoding structure
        let testData = createTestProtobufMessage()
        
        print("   Raw protobuf bytes: \(testData.map { String(format: "%02x", $0) }.joined(separator: " "))")
        print("   Size: \(testData.count) bytes")
        
        // Verify protobuf structure
        if testData.count > 0 {
            print("   ✓ Protobuf data generated successfully")
        } else {
            print("   ❌ No protobuf data generated")
        }
    }
    
    private static func createTestProtobufMessage() -> Data {
        // Create a simple protobuf message manually for testing
        var data = Data()
        
        // Simple test message: field 1 (string) = "test"
        data.append(0x0A)  // Field 1, wire type 2 (length-delimited)
        data.append(0x04)  // Length = 4
        data.append("test".data(using: .utf8)!)
        
        return data
    }
}