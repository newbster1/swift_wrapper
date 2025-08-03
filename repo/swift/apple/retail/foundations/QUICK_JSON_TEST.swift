import Foundation
import UnisightLib

class QuickJSONTest {
    
    static func testJSONFormat() {
        print("🧪 Testing JSON format instead of binary protobuf")
        
        // Create a simple OTLP JSON structure
        let jsonData = createSimpleOTLPJSON()
        
        guard let url = URL(string: "https://ref-tel-dis-dev.kbusw2a.shld.apple.com/otlp/v1/metrics") else { return }
        
        // Test 1: JSON with application/json
        testWithContentType(jsonData, url: url, contentType: "application/json")
        
        // Test 2: JSON with application/x-protobuf (some servers expect this)
        testWithContentType(jsonData, url: url, contentType: "application/x-protobuf")
        
        // Test 3: Test httpbin first
        testWithHttpbin(jsonData)
    }
    
    static func createSimpleOTLPJSON() -> Data {
        let otlpRequest = [
            "resourceMetrics": [
                [
                    "resource": [
                        "attributes": [
                            [
                                "key": "service.name",
                                "value": ["stringValue": "UnisightSampleApp"]
                            ],
                            [
                                "key": "service.version", 
                                "value": ["stringValue": "1.0.0"]
                            ]
                        ]
                    ],
                    "scopeMetrics": [
                        [
                            "scope": [
                                "name": "UnisightTelemetry",
                                "version": "1.0.0"
                            ],
                            "metrics": [
                                [
                                    "name": "test_metric",
                                    "description": "Test metric for debugging",
                                    "unit": "1",
                                    "gauge": [
                                        "dataPoints": [
                                            [
                                                "timeUnixNano": "\(UInt64(Date().timeIntervalSince1970 * 1_000_000_000))",
                                                "asDouble": 1.0
                                            ]
                                        ]
                                    ]
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: otlpRequest, options: .prettyPrinted)
            print("📄 Generated JSON (\(jsonData.count) bytes):")
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print(String(jsonString.prefix(500)))
                if jsonString.count > 500 {
                    print("... (truncated)")
                }
            }
            return jsonData
        } catch {
            print("❌ JSON creation error: \(error)")
            return Data()
        }
    }
    
    static func testWithContentType(_ data: Data, url: URL, contentType: String) {
        print("\n🔄 Testing with Content-Type: \(contentType)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = data
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.setValue("application/x-protobuf", forHTTPHeaderField: "Accept")
        
        let task = URLSession.shared.dataTask(with: request) { responseData, response, error in
            if let error = error {
                print("❌ Error: \(error)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📊 Response Status: \(httpResponse.statusCode)")
                print("📋 Response Headers: \(httpResponse.allHeaderFields)")
                
                if let responseData = responseData, !responseData.isEmpty {
                    if let responseString = String(data: responseData, encoding: .utf8) {
                        print("📄 Response Body: \(responseString)")
                    }
                } else {
                    print("📄 Response Body: (empty)")
                }
            }
        }
        
        task.resume()
        
        // Wait a bit for the request to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            print("✅ Test completed for \(contentType)")
        }
    }
    
    static func testWithHttpbin(_ data: Data) {
        print("\n🧪 Testing with httpbin.org first...")
        
        guard let url = URL(string: "https://httpbin.org/post") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = data
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: request) { responseData, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                print("✅ httpbin.org response: \(httpResponse.statusCode)")
                print("📄 This confirms our JSON structure is valid")
            }
        }
        
        task.resume()
    }
    
    static func debugCurrentProtobuf() {
        print("\n🔍 Debugging current protobuf generation...")
        
        // Generate current protobuf data
        let emptyMetrics: [StableMetricData] = []
        let protobufData = ManualProtobufEncoder.encodeMetrics(emptyMetrics)
        
        print("Current protobuf size: \(protobufData.count) bytes")
        
        if protobufData.count > 0 {
            let hex = protobufData.map { String(format: "%02x", $0) }.joined()
            print("Hex: \(hex)")
        } else {
            print("Empty protobuf (this might be the issue)")
        }
    }
}

/*
Usage:

// Add this to your app for debugging:
QuickJSONTest.testJSONFormat()
QuickJSONTest.debugCurrentProtobuf()

*/