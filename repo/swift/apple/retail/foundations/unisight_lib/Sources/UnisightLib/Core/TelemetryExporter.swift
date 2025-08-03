import Foundation
import OpenTelemetryApi
import OpenTelemetrySdk
#if os(iOS)
import UIKit
#endif
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

/// OTLP-compatible telemetry exporter for sending data to the dispatcher
public class TelemetryExporter: SpanExporter, MetricExporter {
    
    // MARK: - Properties
    private let endpoint: String
    private let headers: [String: String]
    private let session: URLSession
    
    // MARK: - Initialization
    
    public init(endpoint: String, headers: [String: String] = [:], bypassSSL: Bool = false) {
        self.endpoint = endpoint
        self.headers = headers
        
        // Configure URLSession for telemetry export
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        
        if bypassSSL {
            // Use SSL bypass delegate for testing
            let delegate = BypassSSLCertificateURLSessionDelegate()
            self.session = URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
        } else {
            self.session = URLSession(configuration: config)
        }
    }
    
    // MARK: - SpanExporter Protocol
    
    public func export(spans: [SpanData], explicitTimeout: TimeInterval?) -> SpanExporterResultCode {
        // Encode spans to OTLP protobuf format using manual encoder
        let protobufData = ManualProtobufEncoder.encodeSpans(spans)
        
        let success = sendProtobufRequest(protobufData, to: "\(endpoint)/v1/traces")
        return success ? .success : .failure
    }
    
    // Legacy method for compatibility
    public func export(spans: [SpanData]) -> SpanExporterResultCode {
        return export(spans: spans, explicitTimeout: nil)
    }
    
    public func flush(explicitTimeout: TimeInterval?) -> SpanExporterResultCode {
        return .success
    }
    
    // Legacy method for compatibility
    public func flush() -> SpanExporterResultCode {
        return flush(explicitTimeout: nil)
    }
    
    public func shutdown(explicitTimeout: TimeInterval?) {
        session.invalidateAndCancel()
    }
    
    // MARK: - MetricExporter Protocol
    
    public func export(metrics: [Metric], shouldCancel: (() -> Bool)?) -> MetricExporterResultCode {
        // Convert metrics to stable metric data
        let metricData = metrics.compactMap { $0 as? StableMetricData }
        
        // Encode metrics to OTLP protobuf format using manual encoder
        let protobufData = ManualProtobufEncoder.encodeMetrics(metricData)
        
        let success = sendProtobufRequest(protobufData, to: "\(endpoint)/v1/metrics")
        if !success {
            print("[UnisightLib] Metric export failed!")
        }
        return .success // OpenTelemetry's MetricExporterResultCode only supports .success
    }
    
    // Legacy method for compatibility
    public func export(metrics: [Metric]) -> MetricExporterResultCode {
        return export(metrics: metrics, shouldCancel: nil)
    }
    
    public func flush() -> MetricExporterResultCode {
        return .success
    }
    
    // MARK: - Private Methods
    
    private func sendProtobufRequest(_ data: Data, to url: String) -> Bool {
        guard let requestURL = URL(string: url) else {
            print("[UnisightLib] Invalid URL: \(url)")
            return false
        }
        
        var urlRequest = URLRequest(url: requestURL)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = data
        urlRequest.setValue("application/x-protobuf", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/x-protobuf", forHTTPHeaderField: "Accept")
        
        // Add custom headers
        for (key, value) in headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }
        
        let semaphore = DispatchSemaphore(value: 0)
        var success = false
        
        let task = session.dataTask(with: urlRequest) { data, response, error in
            defer { semaphore.signal() }
            
            if let error = error {
                print("[UnisightLib] Export error: \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                success = (200...299).contains(httpResponse.statusCode)
                if !success {
                    print("[UnisightLib] Export failed with status: \(httpResponse.statusCode)")
                    if let data = data, let responseString = String(data: data, encoding: .utf8) {
                        print("[UnisightLib] Response: \(responseString)")
                    }
                } else {
                    print("[UnisightLib] Protobuf data exported successfully. Status: \(httpResponse.statusCode), Size: \(data?.count ?? 0) bytes")
                }
            }
        }
        
        task.resume()
        semaphore.wait()
        
        return success
    }
}