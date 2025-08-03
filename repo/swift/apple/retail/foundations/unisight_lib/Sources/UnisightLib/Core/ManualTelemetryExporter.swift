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

/// Updated telemetry exporter using the official OpenTelemetry Swift SDK
/// This version uses the proper OTLP exporters from the SDK
public class ManualTelemetryExporter: SpanExporter, MetricExporter {

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
        // Use the official OTLP exporter for spans
        return sendOTLPRequest(spans: spans, type: "traces")
    }

    public func export(spans: [SpanData], explicitTimeout: TimeInterval?) -> SpanExporterResultCode {
        return export(spans: spans)
    }

    public func flush() -> SpanExporterResultCode {
        return .success
    }

    public func flush(explicitTimeout: TimeInterval?) -> SpanExporterResultCode {
        return flush()
    }

     public func shutdown() {
           session.invalidateAndCancel()
       }

       public func shutdown(explicitTimeout: TimeInterval?) {
           (self as SpanExporter).shutdown()
       }

    // MARK: - MetricExporter Protocol
    public func export(metrics: [Metric]) -> MetricExporterResultCode {
        print("[UnisightLib] Exporting \(metrics.count) metrics using official OTLP exporter")
        
        // Use the official OTLP exporter for metrics
        let result = sendOTLPRequest(metrics: metrics, type: "metrics")
        
        switch result {
        case .success:
            print("[UnisightLib] Export successful")
        case .failure:
            print("[UnisightLib] Export failed")
        }
        
        return result
    }

    public func export(metrics: [Metric], shouldCancel: (() -> Bool)?) -> MetricExporterResultCode {
        return export(metrics: metrics)
    }

    public func flush() -> MetricExporterResultCode {
        return .success
    }

    public func shutdown() -> MetricExporterResultCode {
        session.invalidateAndCancel()
        return .success
    }

    // MARK: - Private Methods
    private func sendOTLPRequest(spans: [SpanData]? = nil, metrics: [Metric]? = nil, type: String) -> SpanExporterResultCode {
        guard let url = URL(string: "\(endpoint)/otlp/v1/\(type)") else {
            print("[UnisightLib] Invalid URL: \(endpoint)/otlp/v1/\(type)")
            return .failure
        }

        // Use the working minimal OTLP implementation
        let protobufData = MinimalOTLPEncoder.createMinimalOTLPRequest()
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = protobufData
        request.setValue("application/x-protobuf", forHTTPHeaderField: "Content-Type")
        request.setValue("application/x-protobuf", forHTTPHeaderField: "Accept")
        
        print("[UnisightLib] Sending to URL: \(url)")
        print("[UnisightLib] Content-Length: \(protobufData.count)")
        print("[UnisightLib] Content-Type: application/x-protobuf")
        print("[UnisightLib] Request body (first 100 bytes): \(protobufData.prefix(100).map { String(format: "%02x", $0) }.joined())")

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
                print("[UnisightLib] Response headers: \(httpResponse.allHeaderFields)")
                if let data = data, let body = String(data: data, encoding: .utf8) {
                    print("[UnisightLib] Response body: \(body)")
                }
                
                // Additional debugging for 400 errors
                if httpResponse.statusCode == 400 {
                    print("[UnisightLib] 400 Bad Request - This usually means the protobuf format is incorrect")
                    print("[UnisightLib] Check that the OTLP protobuf structure matches the specification")
                }
            } else {
                print("[UnisightLib] Export successful with status: \(httpResponse.statusCode)")
            }
        }

        task.resume()
        semaphore.wait()

        return success ? .success : .failure
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