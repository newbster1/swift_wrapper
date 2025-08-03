import Foundation
import OpenTelemetryApi
import OpenTelemetrySdk

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
        
        // ExportMetricsServiceRequest message
        for metric in metrics {
            let resourceMetricsData = encodeResourceMetrics(metric)
            // Field 1: repeated ResourceMetrics resource_metrics
            writeField(1, wireType: .lengthDelimited, data: resourceMetricsData, to: &data)
        }
        
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
        let attributes = [
            ("service.name", "UnisightTelemetry"),
            ("service.version", "1.0.0"),
            ("device.model", DeviceInfo.model),
            ("os.name", DeviceInfo.osName),
            ("os.version", DeviceInfo.osVersion)
        ]
        
        for (key, value) in attributes {
            let keyValueData = encodeKeyValue(key: key, value: value)
            writeField(1, wireType: .lengthDelimited, data: keyValueData, to: &data)
        }
        
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
        
        // Field 2: string version
        writeStringField(2, value: "1.0.0", to: &data)
        
        return data
    }
    
    private static func encodeSpan(_ span: SpanData) -> Data {
        var data = Data()
        
        // Field 1: bytes trace_id
        let traceIdData = Data(hexString: span.traceId.hexString) ?? Data()
        writeField(1, wireType: .lengthDelimited, data: traceIdData, to: &data)
        
        // Field 2: bytes span_id
        let spanIdData = Data(hexString: span.spanId.hexString) ?? Data()
        writeField(2, wireType: .lengthDelimited, data: spanIdData, to: &data)
        
        // Field 3: bytes parent_span_id (optional)
        if let parentSpanId = span.parentSpanId {
            let parentSpanIdData = Data(hexString: parentSpanId.hexString) ?? Data()
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
        
        // Field 1: string name
        writeStringField(1, value: metric.name, to: &data)
        
        // Field 2: string description
        writeStringField(2, value: metric.description, to: &data)
        
        // Field 3: string unit
        writeStringField(3, value: metric.unit, to: &data)
        
        // Field 5-11: metric data (gauge, sum, histogram, etc.)
        switch metric.data {
        case let gauge as GaugeMetricData:
            let gaugeData = encodeGauge(gauge)
            writeField(5, wireType: .lengthDelimited, data: gaugeData, to: &data)
            
        case let sum as SumMetricData:
            let sumData = encodeSum(sum)
            writeField(7, wireType: .lengthDelimited, data: sumData, to: &data)
            
        case let histogram as HistogramMetricData:
            let histogramData = encodeHistogram(histogram)
            writeField(9, wireType: .lengthDelimited, data: histogramData, to: &data)
            
        default:
            break
        }
        
        return data
    }
    
    private static func encodeGauge(_ gauge: GaugeMetricData) -> Data {
        var data = Data()
        
        // Field 1: repeated NumberDataPoint data_points
        for point in gauge.points {
            let pointData = encodeNumberDataPoint(point)
            writeField(1, wireType: .lengthDelimited, data: pointData, to: &data)
        }
        
        return data
    }
    
    private static func encodeSum(_ sum: SumMetricData) -> Data {
        var data = Data()
        
        // Field 1: repeated NumberDataPoint data_points
        for point in sum.points {
            let pointData = encodeNumberDataPoint(point)
            writeField(1, wireType: .lengthDelimited, data: pointData, to: &data)
        }
        
        // Field 2: bool is_monotonic
        writeBoolField(2, value: sum.isMonotonic, to: &data)
        
        // Field 3: AggregationTemporality aggregation_temporality
        let temporality = sum.aggregationTemporality == .cumulative ? 2 : 1
        writeVarintField(3, value: UInt64(temporality), to: &data)
        
        return data
    }
    
    private static func encodeHistogram(_ histogram: HistogramMetricData) -> Data {
        var data = Data()
        
        // Field 1: repeated HistogramDataPoint data_points
        for point in histogram.points {
            let pointData = encodeHistogramDataPoint(point)
            writeField(1, wireType: .lengthDelimited, data: pointData, to: &data)
        }
        
        // Field 2: AggregationTemporality aggregation_temporality
        let temporality = histogram.aggregationTemporality == .cumulative ? 2 : 1
        writeVarintField(2, value: UInt64(temporality), to: &data)
        
        return data
    }
    
    private static func encodeNumberDataPoint(_ point: MetricPointData) -> Data {
        var data = Data()
        
        // Field 2: fixed64 start_time_unix_nano
        writeFixed64Field(2, value: point.startEpochNanos, to: &data)
        
        // Field 4: fixed64 time_unix_nano
        writeFixed64Field(4, value: point.endEpochNanos, to: &data)
        
        // Field 3 or 6: value (as_int or as_double)
        switch point.value {
        case .int(let value):
            writeVarintField(3, value: UInt64(value), to: &data)
        case .double(let value):
            writeDoubleField(6, value: value, to: &data)
        }
        
        // Field 7: repeated KeyValue attributes
        for label in point.labels {
            let labelData = encodeKeyValue(key: label.key, attributeValue: label.value)
            writeField(7, wireType: .lengthDelimited, data: labelData, to: &data)
        }
        
        return data
    }
    
    private static func encodeHistogramDataPoint(_ point: HistogramPointData) -> Data {
        var data = Data()
        
        // Field 2: fixed64 start_time_unix_nano
        writeFixed64Field(2, value: point.startEpochNanos, to: &data)
        
        // Field 3: fixed64 time_unix_nano
        writeFixed64Field(3, value: point.endEpochNanos, to: &data)
        
        // Field 4: fixed64 count
        writeVarintField(4, value: UInt64(point.count), to: &data)
        
        // Field 5: double sum
        writeDoubleField(5, value: point.sum, to: &data)
        
        // Field 6: repeated fixed64 bucket_counts
        for count in point.buckets.counts {
            writeVarintField(6, value: UInt64(count), to: &data)
        }
        
        // Field 7: repeated double explicit_bounds
        for bound in point.buckets.boundaries {
            writeDoubleField(7, value: bound, to: &data)
        }
        
        // Field 9: repeated KeyValue attributes
        for label in point.labels {
            let labelData = encodeKeyValue(key: label.key, attributeValue: label.value)
            writeField(9, wireType: .lengthDelimited, data: labelData, to: &data)
        }
        
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
        writeVarint(UInt64(data.count), to: &output)
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

// MARK: - Device Info Helper
private struct DeviceInfo {
    static var model: String {
        #if os(iOS)
        return UIDevice.current.model
        #elseif os(macOS)
        return "Mac"
        #else
        return "Unknown"
        #endif
    }
    
    static var osName: String {
        #if os(iOS)
        return "iOS"
        #elseif os(macOS)
        return "macOS"
        #else
        return "Unknown"
        #endif
    }
    
    static var osVersion: String {
        #if os(iOS)
        return UIDevice.current.systemVersion
        #elseif os(macOS)
        return ProcessInfo.processInfo.operatingSystemVersionString
        #else
        return "Unknown"
        #endif
    }
}

// MARK: - Data Extension for Hex String
extension Data {
    init?(hexString: String) {
        var data = Data()
        var index = hexString.startIndex
        
        while index < hexString.endIndex {
            let nextIndex = hexString.index(index, offsetBy: 2, limitedBy: hexString.endIndex) ?? hexString.endIndex
            let byteString = String(hexString[index..<nextIndex])
            if let byte = UInt8(byteString, radix: 16) {
                data.append(byte)
            }
            index = nextIndex
        }
        
        self = data
    }
}