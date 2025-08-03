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
        let success = sendProtobufRequest(protobufData, to: "\(endpoint)/v1/traces")
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
        let protobufData = ManualProtobufEncoder.encodeMetrics(metricData)
        let success = sendProtobufRequest(protobufData, to: "\(endpoint)/v1/metrics")
        return success ? .success : .failure
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