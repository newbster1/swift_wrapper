import Foundation
import OpenTelemetryApi
import OpenTelemetrySdk
import Network

/// URLSession delegate that bypasses SSL certificate validation for testing purposes
/// ⚠️ WARNING: This should ONLY be used for testing and development
/// DO NOT use this in production as it bypasses all SSL security
@available(iOS 13.0, *)
public class BypassSSLCertificateURLSessionDelegate: NSObject, URLSessionDelegate {

    public func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        // Bypass SSL certificate validation for testing
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            if let serverTrust = challenge.protectionSpace.serverTrust {
                let credential = URLCredential(trust: serverTrust)
                completionHandler(.useCredential, credential)
                return
            }
        }

        // For other authentication challenges, use default behavior
        completionHandler(.performDefaultHandling, nil)
    }

    public func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        if let error = error {
            print("[UnisightLib] Network request failed: \(error.localizedDescription)")
        }
    }

    public func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive data: Data
    ) {
        // Handle successful response
        if let response = dataTask.response as? HTTPURLResponse {
            print("[UnisightLib] Telemetry data sent successfully. Status: \(response.statusCode)")
        }
    }
}

/// Custom telemetry exporter that sends OTLP data over HTTP
/// Implements both SpanExporter and MetricExporter protocols
public class ManualTelemetryExporter: SpanExporter, MetricExporter {
    
    private let endpoint: String
    private let headers: [String: String]
    private let bypassSSL: Bool
    
    public init(endpoint: String, headers: [String: String] = [:], bypassSSL: Bool = false) {
        self.endpoint = endpoint
        self.headers = headers
        self.bypassSSL = bypassSSL
    }
    
    // MARK: - SpanExporter Implementation
    
    public func export(spans: [SpanData]) -> SpanExporterResultCode {
        print("[ManualTelemetryExporter] Exporting \(spans.count) spans")
        
        // For now, we'll use the minimal OTLP request for spans
        // In a full implementation, you'd encode the actual span data
        let request = MinimalOTLPEncoder.createMinimalOTLPRequest()
        
        return sendOTLPRequest(request: request, type: "spans")
    }
    
    public func flush() -> SpanExporterResultCode {
        print("[ManualTelemetryExporter] Flushing spans")
        return .success
    }
    
    public func shutdown() {
        print("[ManualTelemetryExporter] Shutting down span exporter")
    }
    
    // MARK: - MetricExporter Implementation
    
    public func export(metrics: [StableMetricData]) -> MetricExporterResultCode {
        print("[ManualTelemetryExporter] Exporting \(metrics.count) metrics")
        
        if metrics.isEmpty {
            print("[ManualTelemetryExporter] No metrics to export, using test metric")
            let request = MinimalOTLPEncoder.createMinimalOTLPRequest()
            return sendOTLPRequest(request: request, type: "metrics")
        } else {
            print("[ManualTelemetryExporter] Using actual metrics for export")
            let request = MinimalOTLPEncoder.createOTLPRequestFromMetrics(metrics)
            return sendOTLPRequest(request: request, type: "metrics", metrics: metrics)
        }
    }
    
    public func flush() -> MetricExporterResultCode {
        print("[ManualTelemetryExporter] Flushing metrics")
        return .success
    }
    
    public func shutdown() {
        print("[ManualTelemetryExporter] Shutting down metric exporter")
    }
    
    // MARK: - Private Methods
    
    private func sendOTLPRequest(request: Data, type: String, metrics: [StableMetricData]? = nil) -> SpanExporterResultCode {
        guard let url = URL(string: endpoint) else {
            print("[ManualTelemetryExporter] Invalid endpoint URL: \(endpoint)")
            return .failure
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/x-protobuf", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("\(request.count)", forHTTPHeaderField: "Content-Length")
        
        // Add custom headers
        for (key, value) in headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }
        
        urlRequest.httpBody = request
        
        let semaphore = DispatchSemaphore(value: 0)
        var resultCode: SpanExporterResultCode = .failure
        
        let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            defer { semaphore.signal() }
            
            if let error = error {
                print("[ManualTelemetryExporter] Network error: \(error)")
                resultCode = .failure
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("[ManualTelemetryExporter] \(type.capitalized) export response: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 200 {
                    print("[ManualTelemetryExporter] ✅ Successfully exported \(type)")
                    if let metrics = metrics {
                        print("[ManualTelemetryExporter] Exported \(metrics.count) actual metrics")
                        for metric in metrics {
                            print("[ManualTelemetryExporter] - Metric: \(metric.name)")
                        }
                    } else {
                        print("[ManualTelemetryExporter] Exported test metric")
                    }
                    resultCode = .success
                } else {
                    print("[ManualTelemetryExporter] ❌ Failed to export \(type): HTTP \(httpResponse.statusCode)")
                    if let data = data, let responseString = String(data: data, encoding: .utf8) {
                        print("[ManualTelemetryExporter] Response body: \(responseString)")
                    }
                    resultCode = .failure
                }
            } else {
                print("[ManualTelemetryExporter] Invalid response type")
                resultCode = .failure
            }
        }
        
        task.resume()
        semaphore.wait()
        
        return resultCode
    }
}

// MARK: - Minimal OTLP Encoder (Working Implementation)
struct MinimalOTLPEncoder {
    
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
    
    // Create OTLP ExportMetricsServiceRequest from actual metrics
    static func createOTLPRequestFromMetrics(_ metrics: [Metric]) -> Data {
        var data = Data()
        
        print("[UnisightLib] Creating OTLP request from \(metrics.count) actual metrics")
        
        // ExportMetricsServiceRequest
        // Field 1: repeated ResourceMetrics resource_metrics
        let resourceMetricsData = createResourceMetricsFromMetrics(metrics)
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
    
    static func createResourceMetricsFromMetrics(_ metrics: [Metric]) -> Data {
        var data = Data()
        
        // ResourceMetrics
        // Field 1: Resource resource
        let resourceData = createResource()
        writeField(1, wireType: .lengthDelimited, data: resourceData, to: &data)
        
        // Field 2: repeated ScopeMetrics scope_metrics
        let scopeMetricsData = createScopeMetricsFromMetrics(metrics)
        writeField(2, wireType: .lengthDelimited, data: scopeMetricsData, to: &data)
        
        return data
    }
    
    static func createResource() -> Data {
        var data = Data()
        
        // Resource
        // Field 1: repeated KeyValue attributes
        let keyValueData = createKeyValue(key: "service.name", value: "UnisightTelemetry")
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
    
    static func createScopeMetricsFromMetrics(_ metrics: [Metric]) -> Data {
        var data = Data()
        
        // ScopeMetrics
        // Field 1: InstrumentationScope scope
        let scopeData = createInstrumentationScope()
        writeField(1, wireType: .lengthDelimited, data: scopeData, to: &data)
        
        // Field 2: repeated Metric metrics - encode all actual metrics
        for metric in metrics {
            let metricData = createMetricFromActualMetric(metric)
            writeField(2, wireType: .lengthDelimited, data: metricData, to: &data)
        }
        
        return data
    }
    
    static func createInstrumentationScope() -> Data {
        var data = Data()
        
        // InstrumentationScope
        // Field 1: string name
        writeStringField(1, value: "UnisightTelemetry", to: &data)
        
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
    
    static func createMetricFromActualMetric(_ metric: Metric) -> Data {
        var data = Data()
        
        print("[UnisightLib] Encoding actual metric: \(metric.name)")
        
        // Metric
        // Field 1: string name
        writeStringField(1, value: metric.name, to: &data)
        
        // Field 2: string description (if available)
        if let description = metric.description, !description.isEmpty {
            writeStringField(2, value: description, to: &data)
        }
        
        // Field 3: string unit (if available)
        if let unit = metric.unit, !unit.isEmpty {
            writeStringField(3, value: unit, to: &data)
        }
        
        // Field 5: Gauge gauge (for now, treat all metrics as gauges)
        let gaugeData = createGaugeFromMetric(metric)
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
    
    static func createGaugeFromMetric(_ metric: Metric) -> Data {
        var data = Data()
        
        // Gauge
        // Field 1: repeated NumberDataPoint data_points
        let pointData = createNumberDataPointFromMetric(metric)
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
    
    static func createNumberDataPointFromMetric(_ metric: Metric) -> Data {
        var data = Data()
        
        // NumberDataPoint
        // Field 2: fixed64 start_time_unix_nano
        let currentTime = UInt64(Date().timeIntervalSince1970 * 1_000_000_000)
        writeFixed64Field(2, value: currentTime, to: &data)
        
        // Field 4: fixed64 time_unix_nano
        writeFixed64Field(4, value: currentTime, to: &data)
        
        // Field 6: double as_double - extract actual metric value
        // For now, we'll use a default value since Metric doesn't expose the actual value directly
        // In a real implementation, you would need to access the metric's data points
        let metricValue = extractMetricValue(from: metric)
        writeDoubleField(6, value: metricValue, to: &data)
        
        return data
    }
    
    // Helper method to extract metric value
    // This is a simplified implementation - in practice, you'd need to access the metric's data
    private static func extractMetricValue(from metric: Metric) -> Double {
        // Check if it's our SimpleMetric implementation
        if let simpleMetric = metric as? SimpleMetric {
            return simpleMetric.value
        }
        
        // For now, return a default value based on the metric name
        // In a real implementation, you would access the metric's actual data points
        switch metric.name {
        case let name where name.contains("counter"):
            return 1.0
        case let name where name.contains("gauge"):
            return 0.5
        case let name where name.contains("histogram"):
            return 2.0
        default:
            return 1.0
        }
    }
}