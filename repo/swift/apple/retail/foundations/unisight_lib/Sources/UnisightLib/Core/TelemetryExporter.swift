import Foundation
import OpenTelemetryApi
import OpenTelemetrySdk

/// OTLP-compatible telemetry exporter for sending data to the dispatcher
public class TelemetryExporter: SpanExporter, MetricExporter {
    
    // MARK: - Properties
    private let endpoint: String
    private let headers: [String: String]
    private let session: URLSession
    private let encoder = JSONEncoder()
    
    // MARK: - Initialization
    
    public init(endpoint: String, headers: [String: String] = [:]) {
        self.endpoint = endpoint
        self.headers = headers
        
        // Configure URLSession for telemetry export
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        
        // For development - bypass certificate validation
        #if DEBUG
        config.urlSessionDidReceiveChallenge = { session, challenge in
            let credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
            return (.useCredential, credential)
        }
        #endif
        
        self.session = URLSession(configuration: config)
        
        // Configure JSON encoder
        encoder.dateEncodingStrategy = .millisecondsSince1970
    }
    
    // MARK: - SpanExporter
    
    public func export(spans: [SpanData], explicitTimeout: TimeInterval?) -> SpanExporterResultCode {
        let otlpSpans = spans.map { convertToOTLPSpan($0) }
        let request = OTLPTraceRequest(resourceSpans: [
            OTLPResourceSpans(
                resource: createOTLPResource(),
                scopeSpans: [
                    OTLPScopeSpans(
                        scope: createOTLPScope(),
                        spans: otlpSpans
                    )
                ]
            )
        ])
        
        return sendRequest(request, to: "\(endpoint)/traces") ? .success : .failure
    }
    
    public func flush(explicitTimeout: TimeInterval?) -> SpanExporterResultCode {
        return .success
    }
    
    public func shutdown(explicitTimeout: TimeInterval?) {
        session.invalidateAndCancel()
    }
    
    // MARK: - MetricExporter
    
    public func export(metrics: [Metric], shouldCancel: (() -> Bool)?) -> MetricExporterResultCode {
        let otlpMetrics = metrics.map { convertToOTLPMetric($0) }
        let request = OTLPMetricRequest(resourceMetrics: [
            OTLPResourceMetrics(
                resource: createOTLPResource(),
                scopeMetrics: [
                    OTLPScopeMetrics(
                        scope: createOTLPScope(),
                        metrics: otlpMetrics
                    )
                ]
            )
        ])
        
        return sendRequest(request, to: "\(endpoint)/metrics") ? .success : .failure
    }
    
    public func flush() -> MetricExporterResultCode {
        return .success
    }
    
    // MARK: - Private Methods
    
    private func sendRequest<T: Codable>(_ request: T, to url: String) -> Bool {
        guard let requestURL = URL(string: url) else {
            print("Invalid URL: \(url)")
            return false
        }
        
        do {
            let data = try encoder.encode(request)
            
            var urlRequest = URLRequest(url: requestURL)
            urlRequest.httpMethod = "POST"
            urlRequest.httpBody = data
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
            
            // Add custom headers
            for (key, value) in headers {
                urlRequest.setValue(value, forHTTPHeaderField: key)
            }
            
            let semaphore = DispatchSemaphore(value: 0)
            var success = false
            
            let task = session.dataTask(with: urlRequest) { data, response, error in
                defer { semaphore.signal() }
                
                if let error = error {
                    print("Telemetry export error: \(error)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    success = (200...299).contains(httpResponse.statusCode)
                    if !success {
                        print("Telemetry export failed with status: \(httpResponse.statusCode)")
                        if let data = data, let responseString = String(data: data, encoding: .utf8) {
                            print("Response: \(responseString)")
                        }
                    }
                }
            }
            
            task.resume()
            semaphore.wait()
            
            return success
            
        } catch {
            print("Failed to encode telemetry data: \(error)")
            return false
        }
    }
    
    private func createOTLPResource() -> OTLPResource {
        return OTLPResource(
            attributes: [
                OTLPKeyValue(key: "service.name", value: OTLPAnyValue.stringValue("UnisightTelemetry")),
                OTLPKeyValue(key: "service.version", value: OTLPAnyValue.stringValue("1.0.0")),
                OTLPKeyValue(key: "device.model", value: OTLPAnyValue.stringValue(DeviceInfo.model)),
                OTLPKeyValue(key: "os.name", value: OTLPAnyValue.stringValue(DeviceInfo.osName)),
                OTLPKeyValue(key: "os.version", value: OTLPAnyValue.stringValue(DeviceInfo.osVersion))
            ]
        )
    }
    
    private func createOTLPScope() -> OTLPInstrumentationScope {
        return OTLPInstrumentationScope(
            name: "UnisightTelemetry",
            version: "1.0.0"
        )
    }
    
    private func convertToOTLPSpan(_ spanData: SpanData) -> OTLPSpan {
        return OTLPSpan(
            traceId: spanData.traceId.hexString,
            spanId: spanData.spanId.hexString,
            parentSpanId: spanData.parentSpanId?.hexString,
            name: spanData.name,
            kind: convertSpanKind(spanData.kind),
            startTimeUnixNano: UInt64(spanData.startTime.timeIntervalSince1970 * 1_000_000_000),
            endTimeUnixNano: UInt64(spanData.endTime.timeIntervalSince1970 * 1_000_000_000),
            attributes: spanData.attributes.map { convertToOTLPKeyValue($0.key, $0.value) },
            status: convertSpanStatus(spanData.status)
        )
    }
    
    private func convertToOTLPMetric(_ metric: Metric) -> OTLPMetric {
        // This is a simplified conversion - in practice, you'd need to handle different metric types
        return OTLPMetric(
            name: metric.name,
            description: metric.description,
            unit: metric.unit
        )
    }
    

    
    private func convertSpanKind(_ kind: SpanKind) -> Int {
        switch kind {
        case .internal: return 1
        case .server: return 2
        case .client: return 3
        case .producer: return 4
        case .consumer: return 5
        }
    }
    
    private func convertSpanStatus(_ status: Status) -> OTLPStatus {
        switch status {
        case .unset:
            return OTLPStatus(code: 0)
        case .ok:
            return OTLPStatus(code: 1)
        case .error(let description):
            return OTLPStatus(code: 2, message: description)
        }
    }
    

    
    private func convertToOTLPKeyValue(_ key: String, _ value: AttributeValue) -> OTLPKeyValue {
        let otlpValue: OTLPAnyValue
        
        switch value {
        case .string(let stringValue):
            otlpValue = .stringValue(stringValue)
        case .bool(let boolValue):
            otlpValue = .boolValue(boolValue)
        case .int(let intValue):
            otlpValue = .intValue(Int64(intValue))
        case .double(let doubleValue):
            otlpValue = .doubleValue(doubleValue)
        case .stringArray(let array):
            otlpValue = .arrayValue(OTLPArrayValue(values: array.map { .stringValue($0) }))
        case .boolArray(let array):
            otlpValue = .arrayValue(OTLPArrayValue(values: array.map { .boolValue($0) }))
        case .intArray(let array):
            otlpValue = .arrayValue(OTLPArrayValue(values: array.map { .intValue(Int64($0)) }))
        case .doubleArray(let array):
            otlpValue = .arrayValue(OTLPArrayValue(values: array.map { .doubleValue($0) }))
        }
        
        return OTLPKeyValue(key: key, value: otlpValue)
    }
}

// MARK: - OTLP Data Models

public struct OTLPTraceRequest: Codable {
    let resourceSpans: [OTLPResourceSpans]
}

public struct OTLPResourceSpans: Codable {
    let resource: OTLPResource
    let scopeSpans: [OTLPScopeSpans]
}

public struct OTLPScopeSpans: Codable {
    let scope: OTLPInstrumentationScope
    let spans: [OTLPSpan]
}

public struct OTLPMetricRequest: Codable {
    let resourceMetrics: [OTLPResourceMetrics]
}

public struct OTLPResourceMetrics: Codable {
    let resource: OTLPResource
    let scopeMetrics: [OTLPScopeMetrics]
}

public struct OTLPScopeMetrics: Codable {
    let scope: OTLPInstrumentationScope
    let metrics: [OTLPMetric]
}



public struct OTLPResource: Codable {
    let attributes: [OTLPKeyValue]
}

public struct OTLPInstrumentationScope: Codable {
    let name: String
    let version: String?
    
    init(name: String, version: String? = nil) {
        self.name = name
        self.version = version
    }
}

public struct OTLPSpan: Codable {
    let traceId: String
    let spanId: String
    let parentSpanId: String?
    let name: String
    let kind: Int
    let startTimeUnixNano: UInt64
    let endTimeUnixNano: UInt64
    let attributes: [OTLPKeyValue]
    let status: OTLPStatus
}

public struct OTLPMetric: Codable {
    let name: String
    let description: String?
    let unit: String?
}



public struct OTLPKeyValue: Codable {
    let key: String
    let value: OTLPAnyValue
}

public enum OTLPAnyValue: Codable {
    case stringValue(String)
    case boolValue(Bool)
    case intValue(Int64)
    case doubleValue(Double)
    case arrayValue(OTLPArrayValue)
    case kvlistValue(OTLPKeyValueList)
    
    enum CodingKeys: String, CodingKey {
        case stringValue, boolValue, intValue, doubleValue, arrayValue, kvlistValue
    }
}

public struct OTLPArrayValue: Codable {
    let values: [OTLPAnyValue]
}

public struct OTLPKeyValueList: Codable {
    let values: [OTLPKeyValue]
}

public struct OTLPStatus: Codable {
    let code: Int
    let message: String?
    
    init(code: Int, message: String? = nil) {
        self.code = code
        self.message = message
    }
}