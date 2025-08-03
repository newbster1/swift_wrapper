import Foundation
import OpenTelemetryApi
import OpenTelemetrySdk

// Mock StableMetricData for testing
struct MockStableMetricData: StableMetricData {
    let name: String
    let description: String
    let unit: String
}

// Test the protobuf encoding
func testProtobufEncoding() {
    print("=== Testing Protobuf Encoding ===")
    
    // Create mock metrics
    let metrics = [
        MockStableMetricData(name: "test_metric_1", description: "Test metric 1", unit: "count"),
        MockStableMetricData(name: "test_metric_2", description: "Test metric 2", unit: "bytes")
    ]
    
    print("Created \(metrics.count) mock metrics")
    
    // Test encoding
    let protobufData = ManualProtobufEncoder.encodeMetrics(metrics)
    
    print("Encoded protobuf data size: \(protobufData.count) bytes")
    print("Protobuf hex: \(protobufData.map { String(format: "%02x", $0) }.joined())")
    
    // Test hex string parsing
    let testHex = "1234567890abcdef"
    if let parsedData = Data(hexString: testHex) {
        print("Hex parsing test passed: \(testHex) -> \(parsedData.count) bytes")
    } else {
        print("Hex parsing test failed for: \(testHex)")
    }
    
    // Test invalid hex string
    let invalidHex = "1234567890abcdeg"
    if let parsedData = Data(hexString: invalidHex) {
        print("Invalid hex parsing test failed: should have returned nil")
    } else {
        print("Invalid hex parsing test passed: correctly returned nil")
    }
    
    print("=== Test Complete ===")
}

// Run the test
testProtobufEncoding()