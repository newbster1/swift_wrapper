import Foundation
import OpenTelemetryApi
import OpenTelemetrySdk
import Network

/// Updated telemetry exporter using manual protobuf encoding
/// This version doesn't require generated protobuf files
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
        let protobufData = ManualProtobufEncoder.encodeSpans(spans)
        let success = sendProtobufRequest(protobufData, to: "\(endpoint)/otlp/v1/traces")
        return success ? .success : .failure
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
        shutdown()
    }

    // MARK: - MetricExporter Protocol
    public func export(metrics: [Metric]) -> MetricExporterResultCode {
        let metricData = metrics.compactMap { $0 as? StableMetricData }
        print("[UnisightLib] Exporting \(metricData.count) metrics (from \(metrics.count) total)")
        let protobufData = ManualProtobufEncoder.encodeMetrics(metricData)
        print("[UnisightLib] Generated protobuf data: \(protobufData.count) bytes")
        print("[UnisightLib] Protobuf hex: \(protobufData.map { String(format: "%02x", $0) }.joined())")
        let success = sendProtobufRequest(protobufData, to: "\(endpoint)/otlp/v1/metrics")
        return .success // MetricExporterResultCode only has .success
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
    private func sendProtobufRequest(_ data: Data, to url: String) -> Bool {
        guard let url = URL(string: url) else {
            print("[UnisightLib] Invalid URL: \(url)")
            return false
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = data
        request.setValue("application/x-protobuf", forHTTPHeaderField: "Content-Type")
        request.setValue("application/x-protobuf", forHTTPHeaderField: "Accept")
        
        print("[UnisightLib] Sending to URL: \(url)")
        print("[UnisightLib] Content-Length: \(data.count)")
        print("[UnisightLib] Content-Type: application/x-protobuf")
        print("[UnisightLib] Request headers:")
        for (key, value) in request.allHTTPHeaderFields ?? [:] {
            print("[UnisightLib]   \(key): \(value)")
        }
        print("[UnisightLib] Request body (first 100 bytes): \(data.prefix(100).map { String(format: "%02x", $0) }.joined())")

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

        return success
    }
}