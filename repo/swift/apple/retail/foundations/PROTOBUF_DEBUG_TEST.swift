import Foundation
import UnisightLib

/// Debug test for protobuf generation
class ProtobufDebugTest {
    
    static func testEmptyMetricsProtobuf() {
        print("🔍 Debug: Testing empty metrics protobuf generation")
        
        let emptyMetrics: [StableMetricData] = []
        let protobufData = ManualProtobufEncoder.encodeMetrics(emptyMetrics)
        
        print("Generated \(protobufData.count) bytes")
        if protobufData.count > 0 {
            let hexString = protobufData.map { String(format: "%02x", $0) }.joined()
            print("Hex: \(hexString)")
        }
        
        // Test with httpbin to see if the protobuf structure is valid
        testProtobufWithHttpbin(protobufData)
    }
    
    static func testBasicProtobufStructure() {
        print("🔍 Debug: Testing basic protobuf structure")
        
        // Create a minimal valid ExportMetricsServiceRequest manually
        var data = Data()
        
        // Empty ExportMetricsServiceRequest (should be valid)
        print("Empty request: \(data.count) bytes")
        
        // Minimal ResourceMetrics structure
        var resourceMetrics = Data()
        
        // Field 1: Resource (minimal)
        var resource = Data()
        // Empty resource is valid
        writeField(1, wireType: .lengthDelimited, data: resource, to: &resourceMetrics)
        
        // Field 2: ScopeMetrics (minimal)  
        var scopeMetrics = Data()
        // Empty scope metrics is valid
        writeField(2, wireType: .lengthDelimited, data: scopeMetrics, to: &resourceMetrics)
        
        // Add ResourceMetrics to request
        writeField(1, wireType: .lengthDelimited, data: resourceMetrics, to: &data)
        
        print("Minimal request: \(data.count) bytes")
        let hexString = data.map { String(format: "%02x", $0) }.joined()
        print("Hex: \(hexString)")
        
        testProtobufWithHttpbin(data)
    }
    
    static func testProtobufWithHttpbin(_ data: Data) {
        print("🧪 Testing protobuf with httpbin.org...")
        
        guard let url = URL(string: "https://httpbin.org/post") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = data
        request.setValue("application/x-protobuf", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: request) { responseData, response, error in
            if let error = error {
                print("❌ Error: \(error)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("✅ httpbin.org response: \(httpResponse.statusCode)")
                if let responseData = responseData,
                   let responseString = String(data: responseData, encoding: .utf8) {
                    print("Response preview: \(String(responseString.prefix(200)))...")
                }
            }
        }
        
        task.resume()
    }
    
    static func compareWithRealOTLP() {
        print("📋 Expected OTLP structure reference:")
        print("ExportMetricsServiceRequest {")
        print("  field 1: repeated ResourceMetrics resource_metrics")
        print("}")
        print("")
        print("ResourceMetrics {")
        print("  field 1: Resource resource")
        print("  field 2: repeated ScopeMetrics scope_metrics")
        print("}")
        print("")
        print("ScopeMetrics {")
        print("  field 1: InstrumentationScope scope") 
        print("  field 2: repeated Metric metrics")
        print("}")
        print("")
        print("Expected minimal hex: 0a00 (field 1, length 0)")
        print("Our empty request should be 0 bytes (valid empty message)")
    }
}

// Helper functions for manual protobuf encoding
private enum WireType: UInt8 {
    case varint = 0
    case fixed64 = 1
    case lengthDelimited = 2
    case fixed32 = 5
}

private func writeField(_ fieldNumber: UInt32, wireType: WireType, data: Data, to output: inout Data) {
    let tag = (fieldNumber << 3) | UInt32(wireType.rawValue)
    writeVarint(UInt64(tag), to: &output)
    writeVarint(UInt64(data.count), to: &output)
    output.append(data)
}

private func writeVarint(_ value: UInt64, to output: inout Data) {
    var value = value
    while value >= 0x80 {
        output.append(UInt8((value & 0x7F) | 0x80))
        value >>= 7
    }
    output.append(UInt8(value & 0x7F))
}

/*
Usage in your app:

ProtobufDebugTest.testEmptyMetricsProtobuf()
ProtobufDebugTest.testBasicProtobufStructure()
ProtobufDebugTest.compareWithRealOTLP()

*/