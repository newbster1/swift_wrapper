import Foundation

// Minimal OTLP protobuf encoder test
struct MinimalOTLPTest {
    
    enum WireType: UInt8 {
        case varint = 0
        case fixed64 = 1
        case lengthDelimited = 2
    }
    
    static func writeField(_ fieldNumber: Int, wireType: WireType, data: Data, to output: inout Data) {
        let tag = (fieldNumber << 3) | Int(wireType.rawValue)
        writeVarint(UInt64(tag), to: &output)
        
        if wireType == .lengthDelimited {
            writeVarint(UInt64(data.count), to: &output)
        }
        
        output.append(data)
    }
    
    static func writeStringField(_ fieldNumber: Int, value: String, to output: inout Data) {
        let stringData = value.data(using: .utf8) ?? Data()
        writeField(fieldNumber, wireType: .lengthDelimited, data: stringData, to: &output)
    }
    
    static func writeVarint(_ value: UInt64, to output: inout Data) {
        var value = value
        while value >= 0x80 {
            output.append(UInt8((value & 0x7F) | 0x80))
            value >>= 7
        }
        output.append(UInt8(value & 0x7F))
    }
    
    static func writeFixed64Field(_ fieldNumber: Int, value: UInt64, to output: inout Data) {
        let tag = (fieldNumber << 3) | Int(WireType.fixed64.rawValue)
        writeVarint(UInt64(tag), to: &output)
        var littleEndianValue = value.littleEndian
        let data = Data(bytes: &littleEndianValue, count: 8)
        output.append(data)
    }
    
    static func writeDoubleField(_ fieldNumber: Int, value: Double, to output: inout Data) {
        let tag = (fieldNumber << 3) | Int(WireType.fixed64.rawValue)
        writeVarint(UInt64(tag), to: &output)
        var bits = value.bitPattern.littleEndian
        let data = Data(bytes: &bits, count: 8)
        output.append(data)
    }
    
    // Create minimal OTLP ExportMetricsServiceRequest
    static func createMinimalOTLPRequest() -> Data {
        var data = Data()
        
        // ExportMetricsServiceRequest
        // Field 1: repeated ResourceMetrics resource_metrics
        let resourceMetricsData = createResourceMetrics()
        writeField(1, wireType: .lengthDelimited, data: resourceMetricsData, to: &data)
        
        return data
    }
    
    static func createResourceMetrics() -> Data {
        var data = Data()
        
        // ResourceMetrics
        // Field 1: Resource resource
        let resourceData = createResource()
        writeField(1, wireType: .lengthDelimited, data: resourceData, to: &data)
        
        // Field 2: repeated ScopeMetrics scope_metrics
        let scopeMetricsData = createScopeMetrics()
        writeField(2, wireType: .lengthDelimited, data: scopeMetricsData, to: &data)
        
        return data
    }
    
    static func createResource() -> Data {
        var data = Data()
        
        // Resource
        // Field 1: repeated KeyValue attributes
        let keyValueData = createKeyValue(key: "service.name", value: "test-service")
        writeField(1, wireType: .lengthDelimited, data: keyValueData, to: &data)
        
        return data
    }
    
    static func createKeyValue(key: String, value: String) -> Data {
        var data = Data()
        
        // KeyValue
        // Field 1: string key
        writeStringField(1, value: key, to: &data)
        
        // Field 2: AnyValue value
        let anyValueData = createAnyValue(stringValue: value)
        writeField(2, wireType: .lengthDelimited, data: anyValueData, to: &data)
        
        return data
    }
    
    static func createAnyValue(stringValue: String) -> Data {
        var data = Data()
        
        // AnyValue
        // Field 1: string string_value
        writeStringField(1, value: stringValue, to: &data)
        
        return data
    }
    
    static func createScopeMetrics() -> Data {
        var data = Data()
        
        // ScopeMetrics
        // Field 1: InstrumentationScope scope
        let scopeData = createInstrumentationScope()
        writeField(1, wireType: .lengthDelimited, data: scopeData, to: &data)
        
        // Field 2: repeated Metric metrics
        let metricData = createMetric()
        writeField(2, wireType: .lengthDelimited, data: metricData, to: &data)
        
        return data
    }
    
    static func createInstrumentationScope() -> Data {
        var data = Data()
        
        // InstrumentationScope
        // Field 1: string name
        writeStringField(1, value: "test-scope", to: &data)
        
        return data
    }
    
    static func createMetric() -> Data {
        var data = Data()
        
        // Metric
        // Field 1: string name
        writeStringField(1, value: "test_metric", to: &data)
        
        // Field 5: Gauge gauge
        let gaugeData = createGauge()
        writeField(5, wireType: .lengthDelimited, data: gaugeData, to: &data)
        
        return data
    }
    
    static func createGauge() -> Data {
        var data = Data()
        
        // Gauge
        // Field 1: repeated NumberDataPoint data_points
        let pointData = createNumberDataPoint()
        writeField(1, wireType: .lengthDelimited, data: pointData, to: &data)
        
        return data
    }
    
    static func createNumberDataPoint() -> Data {
        var data = Data()
        
        // NumberDataPoint
        // Field 2: fixed64 start_time_unix_nano
        let currentTime = UInt64(Date().timeIntervalSince1970 * 1_000_000_000)
        writeFixed64Field(2, value: currentTime, to: &data)
        
        // Field 4: fixed64 time_unix_nano
        writeFixed64Field(4, value: currentTime, to: &data)
        
        // Field 6: double as_double
        writeDoubleField(6, value: 1.0, to: &data)
        
        return data
    }
}

// Test the minimal OTLP implementation
func testMinimalOTLP() {
    print("=== Testing Minimal OTLP Implementation ===")
    
    let protobufData = MinimalOTLPTest.createMinimalOTLPRequest()
    
    print("Minimal OTLP protobuf data size: \(protobufData.count) bytes")
    print("Minimal OTLP protobuf hex: \(protobufData.map { String(format: "%02x", $0) }.joined())")
    
    // Analyze the structure
    print("\n=== Minimal OTLP Structure Analysis ===")
    analyzeProtobufStructure(protobufData)
    
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
testMinimalOTLP()