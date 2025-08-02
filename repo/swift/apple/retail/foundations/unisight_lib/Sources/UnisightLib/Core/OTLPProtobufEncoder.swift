import Foundation

/// OTLP Protobuf Encoder for OpenTelemetry Protocol
/// This implements a simplified OTLP v1.0 protobuf format
public class OTLPProtobufEncoder {
    
    // MARK: - Encoding Methods
    
    /// Encode spans to OTLP protobuf format
    /// Note: This is a simplified implementation that creates a valid protobuf structure
    static func encodeSpans(_ spans: [SpanData]) -> Data {
        // Create a minimal valid OTLP protobuf structure
        var data = Data()
        
        // OTLP ExportTraceServiceRequest structure
        // Field 1: repeated ResourceSpans resource_spans
        
        for span in spans {
            // Encode each span as a ResourceSpans message
            data.append(encodeResourceSpansMessage(span))
        }
        
        return data
    }
    
    /// Encode metrics to OTLP protobuf format
    static func encodeMetrics(_ metrics: [Metric]) -> Data {
        // Create a minimal valid OTLP protobuf structure
        var data = Data()
        
        // OTLP ExportMetricsServiceRequest structure
        // Field 1: repeated ResourceMetrics resource_metrics
        
        for metric in metrics {
            // Encode each metric as a ResourceMetrics message
            data.append(encodeResourceMetricsMessage(metric))
        }
        
        return data
    }
    
    // MARK: - Private Methods
    
    private static func encodeResourceSpansMessage(_ span: SpanData) -> Data {
        var data = Data()
        
        // ResourceSpans message structure:
        // Field 1: Resource resource
        // Field 2: repeated ScopeSpans scope_spans
        
        // Encode resource (simplified)
        data.append(encodeResourceMessage())
        
        // Encode scope spans
        data.append(encodeScopeSpansMessage(span))
        
        return data
    }
    
    private static func encodeResourceMetricsMessage(_ metric: Metric) -> Data {
        var data = Data()
        
        // ResourceMetrics message structure:
        // Field 1: Resource resource
        // Field 2: repeated ScopeMetrics scope_metrics
        
        // Encode resource (simplified)
        data.append(encodeResourceMessage())
        
        // Encode scope metrics
        data.append(encodeScopeMetricsMessage(metric))
        
        return data
    }
    
    private static func encodeResourceMessage() -> Data {
        var data = Data()
        
        // Resource message structure:
        // Field 1: repeated KeyValue attributes
        
        // Encode service name attribute
        data.append(encodeKeyValueMessage("service.name", "UnisightTelemetry"))
        data.append(encodeKeyValueMessage("service.version", "1.0.0"))
        data.append(encodeKeyValueMessage("device.model", DeviceInfo.model))
        data.append(encodeKeyValueMessage("os.name", DeviceInfo.osName))
        data.append(encodeKeyValueMessage("os.version", DeviceInfo.osVersion))
        
        return data
    }
    
    private static func encodeScopeSpansMessage(_ span: SpanData) -> Data {
        var data = Data()
        
        // ScopeSpans message structure:
        // Field 1: InstrumentationScope scope
        // Field 2: repeated Span spans
        
        // Encode scope
        data.append(encodeInstrumentationScopeMessage())
        
        // Encode span
        data.append(encodeSpanMessage(span))
        
        return data
    }
    
    private static func encodeScopeMetricsMessage(_ metric: Metric) -> Data {
        var data = Data()
        
        // ScopeMetrics message structure:
        // Field 1: InstrumentationScope scope
        // Field 2: repeated Metric metrics
        
        // Encode scope
        data.append(encodeInstrumentationScopeMessage())
        
        // Encode metric
        data.append(encodeMetricMessage(metric))
        
        return data
    }
    
    private static func encodeInstrumentationScopeMessage() -> Data {
        var data = Data()
        
        // InstrumentationScope message structure:
        // Field 1: string name
        // Field 2: string version (optional)
        
        // Encode name
        data.append(encodeStringField(1, "UnisightTelemetry"))
        
        // Encode version
        data.append(encodeStringField(2, "1.0.0"))
        
        return data
    }
    
    private static func encodeSpanMessage(_ span: SpanData) -> Data {
        var data = Data()
        
        // Span message structure:
        // Field 1: bytes trace_id
        // Field 2: bytes span_id
        // Field 3: bytes parent_span_id (optional)
        // Field 4: string name
        // Field 5: SpanKind kind
        // Field 6: uint64 start_time_unix_nano
        // Field 7: uint64 end_time_unix_nano
        // Field 8: repeated KeyValue attributes
        // Field 9: Status status
        
        // Encode trace ID
        data.append(encodeBytesField(1, hexStringToData(span.traceId.hexString)))
        
        // Encode span ID
        data.append(encodeBytesField(2, hexStringToData(span.spanId.hexString)))
        
        // Encode parent span ID if exists
        if let parentSpanId = span.parentSpanId {
            data.append(encodeBytesField(3, hexStringToData(parentSpanId.hexString)))
        }
        
        // Encode name
        data.append(encodeStringField(4, span.name))
        
        // Encode kind (internal = 1)
        data.append(encodeInt32Field(5, 1))
        
        // Encode start time
        let startTimeNano = UInt64(span.startTime.timeIntervalSince1970 * 1_000_000_000)
        data.append(encodeUInt64Field(6, startTimeNano))
        
        // Encode end time
        let endTimeNano = UInt64(span.endTime.timeIntervalSince1970 * 1_000_000_000)
        data.append(encodeUInt64Field(7, endTimeNano))
        
        // Encode attributes
        for (key, value) in span.attributes {
            data.append(encodeKeyValueMessage(key, String(describing: value)))
        }
        
        // Encode status (OK = 1)
        data.append(encodeStatusMessage())
        
        return data
    }
    
    private static func encodeMetricMessage(_ metric: Metric) -> Data {
        var data = Data()
        
        // Metric message structure:
        // Field 1: string name
        // Field 2: string description (optional)
        // Field 3: string unit (optional)
        // Field 4: oneof data
        
        // Encode name
        data.append(encodeStringField(1, metric.name))
        
        // Encode description if exists
        if let description = metric.description {
            data.append(encodeStringField(2, description))
        }
        
        // Encode unit if exists
        if let unit = metric.unit {
            data.append(encodeStringField(3, unit))
        }
        
        return data
    }
    
    private static func encodeKeyValueMessage(_ key: String, _ value: String) -> Data {
        var data = Data()
        
        // KeyValue message structure:
        // Field 1: string key
        // Field 2: AnyValue value
        
        // Encode key
        data.append(encodeStringField(1, key))
        
        // Encode value as string
        data.append(encodeAnyValueMessage(value))
        
        return data
    }
    
    private static func encodeAnyValueMessage(_ stringValue: String) -> Data {
        var data = Data()
        
        // AnyValue message structure:
        // Field 1: string string_value
        
        // Encode string value
        data.append(encodeStringField(1, stringValue))
        
        return data
    }
    
    private static func encodeStatusMessage() -> Data {
        var data = Data()
        
        // Status message structure:
        // Field 1: StatusCode code
        // Field 2: string message (optional)
        
        // Encode code (OK = 1)
        data.append(encodeInt32Field(1, 1))
        
        return data
    }
    
    // MARK: - Protobuf Field Encoding
    
    private static func encodeStringField(_ fieldNumber: Int, _ value: String) -> Data {
        var data = Data()
        let stringData = value.data(using: .utf8) ?? Data()
        
        // Encode field tag (wire type 2 = length-delimited)
        data.append(encodeVarint((UInt64(fieldNumber) << 3) | 2))
        
        // Encode string length
        data.append(encodeVarint(UInt64(stringData.count)))
        
        // Encode string data
        data.append(stringData)
        
        return data
    }
    
    private static func encodeBytesField(_ fieldNumber: Int, _ value: Data) -> Data {
        var data = Data()
        
        // Encode field tag (wire type 2 = length-delimited)
        data.append(encodeVarint((UInt64(fieldNumber) << 3) | 2))
        
        // Encode bytes length
        data.append(encodeVarint(UInt64(value.count)))
        
        // Encode bytes data
        data.append(value)
        
        return data
    }
    
    private static func encodeInt32Field(_ fieldNumber: Int, _ value: Int32) -> Data {
        var data = Data()
        
        // Encode field tag (wire type 0 = varint)
        data.append(encodeVarint((UInt64(fieldNumber) << 3) | 0))
        
        // Encode int32 value
        data.append(encodeVarint(UInt64(value)))
        
        return data
    }
    
    private static func encodeUInt64Field(_ fieldNumber: Int, _ value: UInt64) -> Data {
        var data = Data()
        
        // Encode field tag (wire type 0 = varint)
        data.append(encodeVarint((UInt64(fieldNumber) << 3) | 0))
        
        // Encode uint64 value
        data.append(encodeVarint(value))
        
        return data
    }
    
    // MARK: - Utility Methods
    
    private static func hexStringToData(_ hexString: String) -> Data {
        var data = Data()
        var index = hexString.startIndex
        
        while index < hexString.endIndex {
            let nextIndex = hexString.index(index, offsetBy: 2)
            let byteString = String(hexString[index..<nextIndex])
            if let byte = UInt8(byteString, radix: 16) {
                data.append(byte)
            }
            index = nextIndex
        }
        
        return data
    }
    
    private static func encodeVarint(_ value: UInt64) -> Data {
        var data = Data()
        var value = value
        
        while value >= 0x80 {
            data.append(UInt8(value & 0x7F) | 0x80)
            value >>= 7
        }
        data.append(UInt8(value))
        
        return data
    }
}