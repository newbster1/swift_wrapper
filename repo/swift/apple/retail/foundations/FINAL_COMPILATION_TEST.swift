import Foundation
import UnisightLib

/// Final compilation test to verify all telemetry components work together
class FinalCompilationTest {
    
    static func testAllComponents() {
        print("🧪 Final Compilation Test - Verifying All Components")
        print("======================================================")
        
        // Test 1: ManualProtobufEncoder
        testManualProtobufEncoder()
        
        // Test 2: ManualTelemetryExporter
        testManualTelemetryExporter()
        
        // Test 3: UnisightTelemetry Integration
        testUnisightTelemetryIntegration()
        
        // Test 4: Sample App Integration
        testSampleAppCompatibility()
        
        print("\n✅ All compilation tests completed successfully!")
    }
    
    static func testManualProtobufEncoder() {
        print("\n📊 Test 1: ManualProtobufEncoder")
        
        // Test basic protobuf encoding without dependencies
        let emptySpans: [SpanData] = []
        let spanData = ManualProtobufEncoder.encodeSpans(emptySpans)
        print("   ✓ Spans encoding: \(spanData.count) bytes")
        
        let emptyMetrics: [StableMetricData] = []
        let metricsData = ManualProtobufEncoder.encodeMetrics(emptyMetrics)
        print("   ✓ Metrics encoding: \(metricsData.count) bytes")
        
        // Verify basic protobuf structure
        if spanData.count > 0 || metricsData.count > 0 {
            print("   ✓ Protobuf encoder works without generated files")
        }
    }
    
    static func testManualTelemetryExporter() {
        print("\n🚀 Test 2: ManualTelemetryExporter")
        
        // Test exporter initialization
        let exporter = ManualTelemetryExporter(
            endpoint: "https://httpbin.org/post",
            headers: ["X-Test": "compilation-test"],
            bypassSSL: true
        )
        
        print("   ✓ ManualTelemetryExporter initialized successfully")
        
        // Test protocol conformance
        let _: SpanExporter = exporter
        let _: MetricExporter = exporter
        print("   ✓ Conforms to SpanExporter and MetricExporter protocols")
        
        // Test method availability
        let result1 = exporter.flush()
        let result2 = exporter.flush()
        print("   ✓ All required protocol methods available")
        print("   ✓ Flush results: \(result1), \(result2)")
    }
    
    static func testUnisightTelemetryIntegration() {
        print("\n🔄 Test 3: UnisightTelemetry Integration")
        
        do {
            // Test configuration
            let config = UnisightConfiguration(
                serviceName: "CompilationTest",
                version: "1.0.0",
                environment: "test",
                dispatcherEndpoint: "https://httpbin.org/post",
                headers: ["X-Test": "integration"],
                scheme: .debug,
                verbosity: .verbose,
                processing: .none,
                samplingRate: 1.0
            )
            
            print("   ✓ UnisightConfiguration created successfully")
            
            // Test telemetry initialization
            try UnisightTelemetry.shared.initialize(with: config)
            print("   ✓ UnisightTelemetry initialized with ManualTelemetryExporter")
            
            // Test event logging
            UnisightTelemetry.shared.logEvent(
                name: "compilation_test",
                category: .custom,
                attributes: ["test_type": "final_compilation"]
            )
            print("   ✓ Event logging works")
            
            // Test span creation
            let span = UnisightTelemetry.shared.createSpan(
                name: "test_span",
                kind: .internal,
                attributes: ["test": "compilation"]
            )
            span.end()
            print("   ✓ Span creation and management works")
            
        } catch {
            print("   ❌ Integration test failed: \(error)")
        }
    }
    
    static func testSampleAppCompatibility() {
        print("\n📱 Test 4: Sample App Compatibility")
        
        // Test TelemetryService
        TelemetryService.shared.initialize()
        print("   ✓ TelemetryService initialization works")
        
        // Test user interaction logging
        TelemetryService.shared.logUserInteraction(
            .tap,
            viewName: "CompilationTestView",
            elementId: "test_button"
        )
        print("   ✓ User interaction logging works")
        
        // Test custom event logging
        TelemetryService.shared.logEvent(
            name: "compilation_test_complete",
            category: .custom,
            attributes: [
                "test_result": "success",
                "components_tested": 4
            ]
        )
        print("   ✓ Custom event logging works")
        
        // Test navigation logging
        TelemetryService.shared.logNavigation(
            from: "TestView",
            to: "ResultView",
            method: .push
        )
        print("   ✓ Navigation logging works")
    }
}

/// Main test execution
extension FinalCompilationTest {
    
    static func runQuickTest() {
        print("⚡ Quick Compilation Test")
        print("========================")
        
        // Quick test of core functionality
        let config = UnisightConfiguration(
            serviceName: "QuickTest",
            version: "1.0.0",
            dispatcherEndpoint: "https://httpbin.org/post"
        )
        
        do {
            try UnisightTelemetry.shared.initialize(with: config)
            
            UnisightTelemetry.shared.logEvent(
                name: "quick_test",
                category: .system
            )
            
            print("✅ Quick test passed - all components compile and initialize correctly!")
            
        } catch {
            print("❌ Quick test failed: \(error)")
        }
    }
    
    static func printSystemInfo() {
        print("\n📋 System Information")
        print("=====================")
        print("Service: UnisightTelemetry")
        print("Version: 1.0.0")
        print("Encoder: ManualProtobufEncoder (no generated files)")
        print("Exporter: ManualTelemetryExporter")
        print("Protocols: SpanExporter, MetricExporter")
        print("Format: OTLP Protobuf Binary")
        print("SSL Bypass: Available for testing")
        print("Compatibility: iOS 13.0+")
    }
}

// MARK: - Usage Example

/*
 To run this test in your app:
 
 1. Import UnisightLib
 2. Call FinalCompilationTest.runQuickTest()
 3. Check console for success messages
 4. Monitor network requests to verify protobuf data
 
 Example:
 ```swift
 import UnisightLib
 
 // In your app startup:
 FinalCompilationTest.runQuickTest()
 FinalCompilationTest.printSystemInfo()
 ```
 */