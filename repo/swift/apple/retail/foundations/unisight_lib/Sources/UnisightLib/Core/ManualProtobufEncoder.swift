import Foundation
import OpenTelemetryApi
import OpenTelemetrySdk
#if os(iOS)
import UIKit
#endif

/// Manual protobuf encoder for OTLP data without generated files
/// This creates the binary protobuf format by manually encoding fields
public class ManualProtobufEncoder {
    
    // MARK: - Wire Types
    private enum WireType: UInt8 {
        case varint = 0
        case fixed64 = 1
        case lengthDelimited = 2
        case startGroup = 3
        case endGroup = 4
        case fixed32 = 5
    }
    
    // MARK: - Public Encoding Methods
    public static func encodeSpans(_ spans: [SpanData]) -> Data {
        var data = Data()
        
        // ExportTraceServiceRequest message
        for span in spans {
            let resourceSpansData = encodeResourceSpans(span)
            // Field 1: repeated ResourceSpans resource_spans
            writeField(1, wireType: .lengthDelimited, data: resourceSpansData, to: &data)
        }
        
        return data
    }
    
    public static func encodeMetrics(_ metrics: [StableMetricData]) -> Data {
        var data = Data()
        
        print("[UnisightLib] Encoding \(metrics.count) metrics into protobuf")
        
        // ExportMetricsServiceRequest message
        if !metrics.isEmpty {
            // Create a single ResourceMetrics that contains all metrics
            let resourceMetricsData = encodeResourceMetricsCollection(metrics)
            print("[UnisightLib] ResourceMetrics data size: \(resourceMetricsData.count) bytes")
            // Field 1: repeated ResourceMetrics resource_metrics
            writeField(1, wireType: .lengthDelimited, data: resourceMetricsData, to: &data)
        } else {
            print("[UnisightLib] No metrics to encode, returning empty request")
        }
        
        print("[UnisightLib] Final protobuf data size: \(data.count) bytes")
        return data
    }
    
    // MARK: - Private Encoding Methods
    private static func encodeResourceSpans(_ span: SpanData) -> Data {
        var data = Data()
        
        // Field 1: Resource resource
        let resourceData = encodeResource()
        writeField(1, wireType: .lengthDelimited, data: resourceData, to: &data)
        
        // Field 2: repeated ScopeSpans scope_spans
        let scopeSpansData = encodeScopeSpans(span)
        writeField(2, wireType: .lengthDelimited, data: scopeSpansData, to: &data)
        
        return data
    }
    
    private static func encodeResourceMetricsCollection(_ metrics: [StableMetricData]) -> Data {
        var data = Data()
        
        // Field 1: Resource resource
        let resourceData = encodeResource()
        writeField(1, wireType: .lengthDelimited, data: resourceData, to: &data)
        
        // Field 2: repeated ScopeMetrics scope_metrics
        // Create a single ScopeMetrics containing all metrics
        let scopeMetricsData = encodeScopeMetricsCollection(metrics)
        writeField(2, wireType: .lengthDelimited, data: scopeMetricsData, to: &data)
        
        return data
    }
    
    private static func encodeResourceMetrics(_ metric: StableMetricData) -> Data {
        var data = Data()
        
        // Field 1: Resource resource
        let resourceData = encodeResource()
        writeField(1, wireType: .lengthDelimited, data: resourceData, to: &data)
        
        // Field 2: repeated ScopeMetrics scope_metrics
        let scopeMetricsData = encodeScopeMetrics(metric)
        writeField(2, wireType: .lengthDelimited, data: scopeMetricsData, to: &data)
        
        return data
    }
    
    private static func encodeResource() -> Data {
        var data = Data()

        // Field 1: repeated KeyValue attributes
        let keyValueData = encodeKeyValue(key: "service.name", value: "UnisightTelemetry")
        writeField(1, wireType: .lengthDelimited, data: keyValueData, to: &data)

        return data
    }
    
    private static func encodeScopeSpans(_ span: SpanData) -> Data {
        var data = Data()
        
        // Field 1: InstrumentationScope scope
        let scopeData = encodeInstrumentationScope()
        writeField(1, wireType: .lengthDelimited, data: scopeData, to: &data)
        
        // Field 2: repeated Span spans
        let spanData = encodeSpan(span)
        writeField(2, wireType: .lengthDelimited, data: spanData, to: &data)
        
        return data
    }
    
    private static func encodeScopeMetricsCollection(_ metrics: [StableMetricData]) -> Data {
        var data = Data()
        
        // Create a single ScopeMetrics message containing all metrics
        // Field 1: InstrumentationScope scope
        let scopeData = encodeInstrumentationScope()
        writeField(1, wireType: .lengthDelimited, data: scopeData, to: &data)
        
        // Field 2: repeated Metric metrics - encode all metrics here
        for metric in metrics {
            let metricData = encodeMetric(metric)
            writeField(2, wireType: .lengthDelimited, data: metricData, to: &data)
        }
        
        return data
    }
    
    private static func encodeScopeMetrics(_ metric: StableMetricData) -> Data {
        var data = Data()
        
        // Field 1: InstrumentationScope scope
        let scopeData = encodeInstrumentationScope()
        writeField(1, wireType: .lengthDelimited, data: scopeData, to: &data)
        
        // Field 2: repeated Metric metrics
        let metricData = encodeMetric(metric)
        writeField(2, wireType: .lengthDelimited, data: metricData, to: &data)
        
        return data
    }
    
    private static func encodeInstrumentationScope() -> Data {
        var data = Data()

        // Field 1: string name
        writeStringField(1, value: "UnisightTelemetry", to: &data)

        return data
    }
    
    private static func encodeSpan(_ span: SpanData) -> Data {
        var data = Data()

        // Field 1: bytes trace_id
        let traceIdData = Data(hexString: span.traceId.hexString) ?? Data()
        if traceIdData.isEmpty {
            print("[UnisightLib] Warning: Invalid trace ID: \(span.traceId.hexString)")
        }
        writeField(1, wireType: .lengthDelimited, data: traceIdData, to: &data)

        // Field 2: bytes span_id
        let spanIdData = Data(hexString: span.spanId.hexString) ?? Data()
        if spanIdData.isEmpty {
            print("[UnisightLib] Warning: Invalid span ID: \(span.spanId.hexString)")
        }
        writeField(2, wireType: .lengthDelimited, data: spanIdData, to: &data)

        // Field 3: bytes parent_span_id (optional)
        if let parentSpanId = span.parentSpanId {
            let parentSpanIdData = Data(hexString: parentSpanId.hexString) ?? Data()
            if parentSpanIdData.isEmpty {
                print("[UnisightLib] Warning: Invalid parent span ID: \(parentSpanId.hexString)")
            }
            writeField(3, wireType: .lengthDelimited, data: parentSpanIdData, to: &data)
        }

        // Field 4: string name
        writeStringField(4, value: span.name, to: &data)

        // Field 5: SpanKind kind
        writeVarintField(5, value: UInt64(convertSpanKind(span.kind)), to: &data)

        // Field 6: fixed64 start_time_unix_nano
        writeFixed64Field(6, value: UInt64(span.startTime.timeIntervalSince1970 * 1_000_000_000), to: &data)

        // Field 7: fixed64 end_time_unix_nano
        writeFixed64Field(7, value: UInt64(span.endTime.timeIntervalSince1970 * 1_000_000_000), to: &data)

        // Field 8: repeated KeyValue attributes
        for attribute in span.attributes {
            let attributeData = encodeKeyValue(key: attribute.key, attributeValue: attribute.value)
            writeField(8, wireType: .lengthDelimited, data: attributeData, to: &data)
        }

        // Field 11: Status status
        let statusData = encodeStatus(span.status)
        writeField(11, wireType: .lengthDelimited, data: statusData, to: &data)

        return data
    }
    
    private static func encodeMetric(_ metric: StableMetricData) -> Data {
        var data = Data()
        
        print("[UnisightLib] Encoding metric: \(metric.name)")
        
        writeStringField(1, value: metric.name, to: &data)

        if !metric.description.isEmpty {
            writeStringField(2, value: metric.description, to: &data)
        }

        if !metric.unit.isEmpty {
            writeStringField(3, value: metric.unit, to: &data)
        }

        // Create a simple gauge metric with a single data point
        let gaugeData = encodeGauge(metric)
        writeField(5, wireType: .lengthDelimited, data: gaugeData, to: &data)

        print("[UnisightLib] Metric data size: \(data.count) bytes")
        return data
    }

    private static func encodeGauge(_ metric: StableMetricData) -> Data {
        var data = Data()
        
        // Field 1: repeated NumberDataPoint data_points
        let pointData = encodeNumberDataPoint(metric)
        writeField(1, wireType: .lengthDelimited, data: pointData, to: &data)
        
        return data
    }

    private static func encodeNumberDataPoint(_ metric: StableMetricData) -> Data {
        var data = Data()
        
        // Field 2: fixed64 start_time_unix_nano
        let currentTime = UInt64(Date().timeIntervalSince1970 * 1_000_000_000)
        writeFixed64Field(2, value: currentTime, to: &data)
        
        // Field 4: fixed64 time_unix_nano
        writeFixed64Field(4, value: currentTime, to: &data)
        
        // Field 6: double as_double - use a default value of 1.0
        // In a real implementation, you would extract the actual metric value
        let metricValue = 1.0
        writeDoubleField(6, value: metricValue, to: &data)
        
        return data
    }
    
    private static func encodeKeyValue(key: String, value: String) -> Data {
        var data = Data()
        
        // Field 1: string key
        writeStringField(1, value: key, to: &data)
        
        // Field 2: AnyValue value
        let anyValueData = encodeAnyValue(stringValue: value)
        writeField(2, wireType: .lengthDelimited, data: anyValueData, to: &data)
        
        return data
    }
    
    private static func encodeKeyValue(key: String, attributeValue: AttributeValue) -> Data {
        var data = Data()
        
        // Field 1: string key
        writeStringField(1, value: key, to: &data)
        
        // Field 2: AnyValue value
        let anyValueData = encodeAnyValue(attributeValue: attributeValue)
        writeField(2, wireType: .lengthDelimited, data: anyValueData, to: &data)
        
        return data
    }
    
    private static func encodeAnyValue(stringValue: String) -> Data {
        var data = Data()
        
        // Field 1: string string_value
        writeStringField(1, value: stringValue, to: &data)
        
        return data
    }
    
    private static func encodeAnyValue(attributeValue: AttributeValue) -> Data {
        var data = Data()
        
        switch attributeValue {
        case .string(let stringValue):
            // Field 1: string string_value
            writeStringField(1, value: stringValue, to: &data)
            
        case .bool(let boolValue):
            // Field 2: bool bool_value
            writeBoolField(2, value: boolValue, to: &data)
            
        case .int(let intValue):
            // Field 3: int64 int_value
            writeVarintField(3, value: UInt64(intValue), to: &data)
            
        case .double(let doubleValue):
            // Field 4: double double_value
            writeDoubleField(4, value: doubleValue, to: &data)
            
        case .stringArray(let array):
            // Field 5: ArrayValue array_value
            let arrayData = encodeArrayValue(stringArray: array)
            writeField(5, wireType: .lengthDelimited, data: arrayData, to: &data)
            
        default:
            // Default to string representation
            writeStringField(1, value: String(describing: attributeValue), to: &data)
        }
        
        return data
    }
    
    private static func encodeArrayValue(stringArray: [String]) -> Data {
        var data = Data()
        
        // Field 1: repeated AnyValue values
        for string in stringArray {
            let anyValueData = encodeAnyValue(stringValue: string)
            writeField(1, wireType: .lengthDelimited, data: anyValueData, to: &data)
        }
        
        return data
    }
    
    private static func encodeStatus(_ status: Status) -> Data {
        var data = Data()
        
        switch status {
        case .unset:
            // Field 2: StatusCode code = 0 (unset)
            writeVarintField(2, value: 0, to: &data)
            
        case .ok:
            // Field 2: StatusCode code = 1 (ok)
            writeVarintField(2, value: 1, to: &data)
            
        case .error(let description):
            // Field 2: StatusCode code = 2 (error)
            writeVarintField(2, value: 2, to: &data)
            // Field 3: string message
            writeStringField(3, value: description, to: &data)
        }
        
        return data
    }
    
    private static func convertSpanKind(_ kind: SpanKind) -> Int {
        switch kind {
        case .internal: return 1
        case .server: return 2
        case .client: return 3
        case .producer: return 4
        case .consumer: return 5
        }
    }
    
    // MARK: - Low-level encoding helpers
    private static func writeField(_ fieldNumber: Int, wireType: WireType, data: Data, to output: inout Data) {
        let tag = (fieldNumber << 3) | Int(wireType.rawValue)
        writeVarint(UInt64(tag), to: &output)
        
        if wireType == .lengthDelimited {
            writeVarint(UInt64(data.count), to: &output)
        }
        
        output.append(data)
    }
    
    private static func writeStringField(_ fieldNumber: Int, value: String, to output: inout Data) {
        guard !value.isEmpty else { return }
        let stringData = value.data(using: .utf8) ?? Data()
        writeField(fieldNumber, wireType: .lengthDelimited, data: stringData, to: &output)
    }
    
    private static func writeVarintField(_ fieldNumber: Int, value: UInt64, to output: inout Data) {
        let tag = (fieldNumber << 3) | Int(WireType.varint.rawValue)
        writeVarint(UInt64(tag), to: &output)
        writeVarint(value, to: &output)
    }
    
    private static func writeBoolField(_ fieldNumber: Int, value: Bool, to output: inout Data) {
        writeVarintField(fieldNumber, value: value ? 1 : 0, to: &output)
    }
    
    private static func writeFixed64Field(_ fieldNumber: Int, value: UInt64, to output: inout Data) {
        let tag = (fieldNumber << 3) | Int(WireType.fixed64.rawValue)
        writeVarint(UInt64(tag), to: &output)
        var littleEndianValue = value.littleEndian
        let data = Data(bytes: &littleEndianValue, count: 8)
        output.append(data)
    }
    
    private static func writeDoubleField(_ fieldNumber: Int, value: Double, to output: inout Data) {
        let tag = (fieldNumber << 3) | Int(WireType.fixed64.rawValue)
        writeVarint(UInt64(tag), to: &output)
        var bits = value.bitPattern.littleEndian
        let data = Data(bytes: &bits, count: 8)
        output.append(data)
    }
    
    private static func writeVarint(_ value: UInt64, to output: inout Data) {
        var value = value
        while value >= 0x80 {
            output.append(UInt8((value & 0x7F) | 0x80))
            value >>= 7
        }
        output.append(UInt8(value & 0x7F))
    }
}



// MARK: - Data Extension for Hex String
extension Data {
    init?(hexString: String) {
        var data = Data()
        var index = hexString.startIndex
        
        // Ensure the hex string has an even number of characters
        if hexString.count % 2 != 0 {
            print("[UnisightLib] Warning: Odd-length hex string: \(hexString)")
            return nil
        }
        
        while index < hexString.endIndex {
            let nextIndex = hexString.index(index, offsetBy: 2, limitedBy: hexString.endIndex) ?? hexString.endIndex
            let byteString = String(hexString[index..<nextIndex])
            if let byte = UInt8(byteString, radix: 16) {
                data.append(byte)
            } else {
                print("[UnisightLib] Warning: Invalid hex character in string: \(byteString)")
                return nil
            }
            index = nextIndex
        }
        
        self = data
    }
}