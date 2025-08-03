import Foundation
import OpenTelemetryApi
import OpenTelemetrySdk

/// JSON-based telemetry exporter that mimics protobuf format
/// This sends JSON data with protobuf headers for compatibility
public class JSONToProtobufExporter: SpanExporter, MetricExporter {
    
    // MARK: - Properties
    private let endpoint: String
    private let headers: [String: String]
    private let session: URLSession
    
    // MARK: - Initialization
    public init(endpoint: String, headers: [String: String] = [:], bypassSSL: Bool = false) {
        self.endpoint = endpoint
        self.headers = headers
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        
        self.session = bypassSSL ?
            URLSession(configuration: config, delegate: BypassSSLCertificateURLSessionDelegate(), delegateQueue: nil) :
            URLSession(configuration: config)
    }
    
    // MARK: - SpanExporter Protocol
    public func export(spans: [SpanData]) -> SpanExporterResultCode {
        let jsonData = encodeSpansAsJSON(spans)
        let success = sendJSONRequest(jsonData, to: "\(endpoint)/v1/traces")
        return success ? .success : .failure
    }
    
    public func flush() -> SpanExporterResultCode {
        return .success
    }
    
    public func shutdown() {
        session.invalidateAndCancel()
    }
    
    // MARK: - MetricExporter Protocol
    public func export(metrics: [Metric]) -> MetricExporterResultCode {
        let metricData = metrics.compactMap { $0 as? StableMetricData }
        let jsonData = encodeMetricsAsJSON(metricData)
        let success = sendJSONRequest(jsonData, to: "\(endpoint)/v1/metrics")
        return success ? .success : .failure
    }
    
    // MARK: - JSON Encoding Methods
    private func encodeSpansAsJSON(_ spans: [SpanData]) -> Data {
        let exportRequest: [String: Any] = [
            "resourceSpans": spans.map { span in
                [
                    "resource": createResourceJSON(),
                    "scopeSpans": [[
                        "scope": createInstrumentationScopeJSON(),
                        "spans": [createSpanJSON(span)]
                    ]]
                ]
            }
        ]
        
        return try! JSONSerialization.data(withJSONObject: exportRequest, options: [])
    }
    
    private func encodeMetricsAsJSON(_ metrics: [StableMetricData]) -> Data {
        let exportRequest: [String: Any] = [
            "resourceMetrics": metrics.map { metric in
                [
                    "resource": createResourceJSON(),
                    "scopeMetrics": [[
                        "scope": createInstrumentationScopeJSON(),
                        "metrics": [createMetricJSON(metric)]
                    ]]
                ]
            }
        ]
        
        return try! JSONSerialization.data(withJSONObject: exportRequest, options: [])
    }
    
    private func createResourceJSON() -> [String: Any] {
        return [
            "attributes": [
                createKeyValueJSON(key: "service.name", value: "UnisightTelemetry"),
                createKeyValueJSON(key: "service.version", value: "1.0.0"),
                createKeyValueJSON(key: "device.model", value: DeviceInfo.model),
                createKeyValueJSON(key: "os.name", value: DeviceInfo.osName),
                createKeyValueJSON(key: "os.version", value: DeviceInfo.osVersion)
            ]
        ]
    }
    
    private func createInstrumentationScopeJSON() -> [String: Any] {
        return [
            "name": "UnisightTelemetry",
            "version": "1.0.0"
        ]
    }
    
    private func createSpanJSON(_ span: SpanData) -> [String: Any] {
        var spanJSON: [String: Any] = [
            "traceId": span.traceId.hexString,
            "spanId": span.spanId.hexString,
            "name": span.name,
            "kind": convertSpanKindToJSON(span.kind),
            "startTimeUnixNano": String(UInt64(span.startTime.timeIntervalSince1970 * 1_000_000_000)),
            "endTimeUnixNano": String(UInt64(span.endTime.timeIntervalSince1970 * 1_000_000_000)),
            "attributes": span.attributes.map { createKeyValueJSON(key: $0.key, attributeValue: $0.value) },
            "status": createStatusJSON(span.status)
        ]
        
        if let parentSpanId = span.parentSpanId {
            spanJSON["parentSpanId"] = parentSpanId.hexString
        }
        
        return spanJSON
    }
    
    private func createMetricJSON(_ metric: StableMetricData) -> [String: Any] {
        var metricJSON: [String: Any] = [
            "name": metric.name,
            "description": metric.description,
            "unit": metric.unit
        ]
        
        switch metric.data {
        case let gauge as GaugeMetricData:
            metricJSON["gauge"] = [
                "dataPoints": gauge.points.map { createNumberDataPointJSON($0) }
            ]
            
        case let sum as SumMetricData:
            metricJSON["sum"] = [
                "dataPoints": sum.points.map { createNumberDataPointJSON($0) },
                "isMonotonic": sum.isMonotonic,
                "aggregationTemporality": sum.aggregationTemporality == .cumulative ? "AGGREGATION_TEMPORALITY_CUMULATIVE" : "AGGREGATION_TEMPORALITY_DELTA"
            ]
            
        case let histogram as HistogramMetricData:
            metricJSON["histogram"] = [
                "dataPoints": histogram.points.map { createHistogramDataPointJSON($0) },
                "aggregationTemporality": histogram.aggregationTemporality == .cumulative ? "AGGREGATION_TEMPORALITY_CUMULATIVE" : "AGGREGATION_TEMPORALITY_DELTA"
            ]
            
        default:
            break
        }
        
        return metricJSON
    }
    
    private func createNumberDataPointJSON(_ point: MetricPointData) -> [String: Any] {
        var pointJSON: [String: Any] = [
            "startTimeUnixNano": String(point.startEpochNanos),
            "timeUnixNano": String(point.endEpochNanos),
            "attributes": point.labels.map { createKeyValueJSON(key: $0.key, attributeValue: $0.value) }
        ]
        
        switch point.value {
        case .int(let value):
            pointJSON["asInt"] = String(value)
        case .double(let value):
            pointJSON["asDouble"] = value
        }
        
        return pointJSON
    }
    
    private func createHistogramDataPointJSON(_ point: HistogramPointData) -> [String: Any] {
        return [
            "startTimeUnixNano": String(point.startEpochNanos),
            "timeUnixNano": String(point.endEpochNanos),
            "count": String(point.count),
            "sum": point.sum,
            "bucketCounts": point.buckets.counts.map { String($0) },
            "explicitBounds": point.buckets.boundaries,
            "attributes": point.labels.map { createKeyValueJSON(key: $0.key, attributeValue: $0.value) }
        ]
    }
    
    private func createKeyValueJSON(key: String, value: String) -> [String: Any] {
        return [
            "key": key,
            "value": [
                "stringValue": value
            ]
        ]
    }
    
    private func createKeyValueJSON(key: String, attributeValue: AttributeValue) -> [String: Any] {
        var valueJSON: [String: Any] = [:]
        
        switch attributeValue {
        case .string(let stringValue):
            valueJSON["stringValue"] = stringValue
        case .bool(let boolValue):
            valueJSON["boolValue"] = boolValue
        case .int(let intValue):
            valueJSON["intValue"] = String(intValue)
        case .double(let doubleValue):
            valueJSON["doubleValue"] = doubleValue
        case .stringArray(let array):
            valueJSON["arrayValue"] = [
                "values": array.map { ["stringValue": $0] }
            ]
        default:
            valueJSON["stringValue"] = String(describing: attributeValue)
        }
        
        return [
            "key": key,
            "value": valueJSON
        ]
    }
    
    private func createStatusJSON(_ status: Status) -> [String: Any] {
        switch status {
        case .unset:
            return ["code": "STATUS_CODE_UNSET"]
        case .ok:
            return ["code": "STATUS_CODE_OK"]
        case .error(let description):
            return [
                "code": "STATUS_CODE_ERROR",
                "message": description
            ]
        }
    }
    
    private func convertSpanKindToJSON(_ kind: SpanKind) -> String {
        switch kind {
        case .internal: return "SPAN_KIND_INTERNAL"
        case .server: return "SPAN_KIND_SERVER"
        case .client: return "SPAN_KIND_CLIENT"
        case .producer: return "SPAN_KIND_PRODUCER"
        case .consumer: return "SPAN_KIND_CONSUMER"
        }
    }
    
    // MARK: - HTTP Request Methods
    private func sendJSONRequest(_ data: Data, to url: String) -> Bool {
        guard let url = URL(string: url) else {
            print("[UnisightLib] Invalid URL: \(url)")
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = data
        
        // Use application/json but some servers may accept this with protobuf endpoints
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Alternative: Some OTLP collectors accept JSON with protobuf content-type
        // request.setValue("application/x-protobuf", forHTTPHeaderField: "Content-Type")
        
        // Add custom headers
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let semaphore = DispatchSemaphore(value: 0)
        var success = false
        
        let task = session.dataTask(with: request) { data, response, error in
            defer { semaphore.signal() }
            
            if let error = error {
                print("[UnisightLib] Export error: \(error.localizedDescription)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("[UnisightLib] Invalid response type")
                return
            }
            
            success = (200...299).contains(httpResponse.statusCode)
            if !success {
                print("[UnisightLib] Export failed with status: \(httpResponse.statusCode)")
                if let data = data, let body = String(data: data, encoding: .utf8) {
                    print("[UnisightLib] Response body: \(body)")
                }
            }
        }
        
        task.resume()
        semaphore.wait()
        
        return success
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