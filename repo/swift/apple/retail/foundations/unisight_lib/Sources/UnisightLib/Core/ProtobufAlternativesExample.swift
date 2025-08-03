import Foundation
import OpenTelemetryApi
import OpenTelemetrySdk

/// Examples of how to use protobuf telemetry without generated files
public class ProtobufAlternativesExample {
    
    // MARK: - Example 1: Manual Binary Protobuf Encoding
    public static func setupManualProtobufExporter() -> ManualTelemetryExporter {
        let exporter = ManualTelemetryExporter(
            endpoint: "https://your-otlp-endpoint.com",
            headers: [
                "Authorization": "Bearer your-token",
                "X-Custom-Header": "custom-value"
            ],
            bypassSSL: false // Set to true only for testing
        )
        
        return exporter
    }
    
    // MARK: - Example 2: JSON with Protobuf Headers
    public static func setupJSONProtobufExporter() -> JSONToProtobufExporter {
        let exporter = JSONToProtobufExporter(
            endpoint: "https://your-otlp-endpoint.com",
            headers: [
                "Authorization": "Bearer your-token",
                "X-Custom-Header": "custom-value"
            ],
            bypassSSL: false
        )
        
        return exporter
    }
    
    // MARK: - Example 3: HTTP/gRPC-Web Approach
    public static func setupGRPCWebExporter() -> GRPCWebTelemetryExporter {
        let exporter = GRPCWebTelemetryExporter(
            endpoint: "https://your-grpc-web-endpoint.com",
            headers: [
                "Authorization": "Bearer your-token"
            ]
        )
        
        return exporter
    }
    
    // MARK: - Example 4: Using with OpenTelemetry SDK
    public static func configureOpenTelemetryWithManualProtobuf() {
        // Configure resource
        let resource = Resource(attributes: [
            "service.name": AttributeValue.string("UnisightApp"),
            "service.version": AttributeValue.string("1.0.0")
        ])
        
        // Setup manual protobuf exporter
        let spanExporter = setupManualProtobufExporter()
        let spanProcessor = BatchSpanProcessor(spanExporter: spanExporter)
        
        // Configure tracer provider
        let tracerProvider = TracerProviderBuilder()
            .with(resource: resource)
            .add(spanProcessor: spanProcessor)
            .build()
        
        OpenTelemetry.registerTracerProvider(tracerProvider: tracerProvider)
        
        // Configure metrics
        let metricExporter = setupManualProtobufExporter()
        let metricReader = PeriodicMetricReader(
            exporter: metricExporter,
            interval: 30.0
        )
        
        let meterProvider = MeterProviderBuilder()
            .with(resource: resource)
            .registerMetricReader(metricReader)
            .build()
        
        OpenTelemetry.registerMeterProvider(meterProvider: meterProvider)
    }
    
    // MARK: - Example 5: Custom Binary Format (Simplified)
    public static func sendSimplifiedBinaryFormat() {
        // Create a simplified binary format that resembles protobuf
        // but is easier to construct manually
        let data = createSimplifiedTelemetryData()
        
        // Send with custom content type
        var request = URLRequest(url: URL(string: "https://your-endpoint.com/custom")!)
        request.httpMethod = "POST"
        request.httpBody = data
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.setValue("unisight-telemetry-v1", forHTTPHeaderField: "X-Format")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error)")
            } else if let httpResponse = response as? HTTPURLResponse {
                print("Status: \(httpResponse.statusCode)")
            }
        }.resume()
    }
    
    private static func createSimplifiedTelemetryData() -> Data {
        // Simple binary format: [version][type][length][payload]
        var data = Data()
        
        // Version (1 byte)
        data.append(0x01)
        
        // Type: traces (1 byte)
        data.append(0x01)
        
        // Sample span data in simplified format
        let spanJson: [String: Any] = [
            "traceId": "1234567890abcdef",
            "spanId": "abcdef1234567890",
            "name": "test-span",
            "startTime": Date().timeIntervalSince1970 * 1000,
            "endTime": (Date().timeIntervalSince1970 + 1) * 1000
        ]
        
        let jsonData = try! JSONSerialization.data(withJSONObject: spanJson)
        
        // Length (4 bytes, big endian)
        let length = UInt32(jsonData.count).bigEndian
        data.append(Data(bytes: &length, count: 4))
        
        // Payload
        data.append(jsonData)
        
        return data
    }
}

// MARK: - Example 6: gRPC-Web Implementation
public class GRPCWebTelemetryExporter: SpanExporter, MetricExporter {
    private let endpoint: String
    private let headers: [String: String]
    private let session: URLSession
    
    public init(endpoint: String, headers: [String: String] = [:]) {
        self.endpoint = endpoint
        self.headers = headers
        self.session = URLSession.shared
    }
    
    public func export(spans: [SpanData]) -> SpanExporterResultCode {
        // gRPC-Web uses base64-encoded protobuf with specific headers
        let protobufData = ManualProtobufEncoder.encodeSpans(spans)
        let base64Data = protobufData.base64EncodedData()
        
        var request = URLRequest(url: URL(string: "\(endpoint)/opentelemetry.proto.collector.trace.v1.TraceService/Export")!)
        request.httpMethod = "POST"
        request.httpBody = base64Data
        
        // gRPC-Web specific headers
        request.setValue("application/grpc-web+proto", forHTTPHeaderField: "Content-Type")
        request.setValue("grpc", forHTTPHeaderField: "X-Grpc-Web")
        
        // Add custom headers
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let semaphore = DispatchSemaphore(value: 0)
        var success = false
        
        session.dataTask(with: request) { _, response, error in
            defer { semaphore.signal() }
            
            if let httpResponse = response as? HTTPURLResponse {
                success = (200...299).contains(httpResponse.statusCode)
            }
        }.resume()
        
        semaphore.wait()
        return success ? .success : .failure
    }
    
    public func flush() -> SpanExporterResultCode { .success }
    public func shutdown() { }
    
    public func export(metrics: [Metric]) -> MetricExporterResultCode {
        // Similar implementation for metrics
        return .success
    }
}