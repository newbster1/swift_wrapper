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
    
    // Create a single mock metric
    let metrics = [
        MockStableMetricData(name: "test_metric", description: "Test metric", unit: "count")
    ]
    
    print("Created \(metrics.count) mock metrics")
    
    // Test encoding
    let protobufData = ManualProtobufEncoder.encodeMetrics(metrics)
    
    print("Encoded protobuf data size: \(protobufData.count) bytes")
    print("Protobuf hex: \(protobufData.map { String(format: "%02x", $0) }.joined())")
    
    // Decode and verify the structure
    print("\n=== Protobuf Structure Analysis ===")
    analyzeProtobufStructure(protobufData)
    
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

// Analyze protobuf structure
func analyzeProtobufStructure(_ data: Data) {
    var offset = 0
    var depth = 0
    
    while offset < data.count {
        guard offset < data.count else { break }
        
        let byte = data[offset]
        let fieldNumber = Int(byte >> 3)
        let wireType = Int(byte & 0x07)
        
        print("\(String(repeating: "  ", count: depth))Field \(fieldNumber), WireType \(wireType)")
        
        offset += 1
        
        switch wireType {
        case 0: // varint
            var value: UInt64 = 0
            var shift: UInt64 = 0
            while offset < data.count {
                let byte = data[offset]
                value |= UInt64(byte & 0x7F) << shift
                offset += 1
                if (byte & 0x80) == 0 { break }
                shift += 7
            }
            print("\(String(repeating: "  ", count: depth + 1))Value: \(value)")
            
        case 1: // fixed64
            if offset + 8 <= data.count {
                let value = data[offset..<offset+8].withUnsafeBytes { $0.load(as: UInt64.self).littleEndian }
                print("\(String(repeating: "  ", count: depth + 1))Value: \(value)")
                offset += 8
            }
            
        case 2: // length-delimited
            var length: UInt64 = 0
            var shift: UInt64 = 0
            while offset < data.count {
                let byte = data[offset]
                length |= UInt64(byte & 0x7F) << shift
                offset += 1
                if (byte & 0x80) == 0 { break }
                shift += 7
            }
            print("\(String(repeating: "  ", count: depth + 1))Length: \(length)")
            
            if length > 0 && offset + Int(length) <= data.count {
                let subData = data[offset..<offset+Int(length)]
                if let string = String(data: subData, encoding: .utf8) {
                    print("\(String(repeating: "  ", count: depth + 1))String: \(string)")
                } else {
                    print("\(String(repeating: "  ", count: depth + 1))Binary data: \(subData.map { String(format: "%02x", $0) }.joined())")
                }
                offset += Int(length)
            }
            
        default:
            print("\(String(repeating: "  ", count: depth + 1))Unknown wire type")
            offset += 1
        }
    }
}

// Run the test
testProtobufEncoding()