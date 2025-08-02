import Foundation
import OpenTelemetryApi
import OpenTelemetrySdk

/// OTLP Metric Exporter implementation
public class OTLPMetricExporter: MetricExporter {
    private let endpoint: String
    private let headers: [String: String]
    private let session: URLSession
    private let encoder = JSONEncoder()
    
    public init(endpoint: String, headers: [String: String] = [:]) {
        self.endpoint = endpoint
        self.headers = headers
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        
        #if DEBUG
        config.urlSessionDidReceiveChallenge = { session, challenge in
            let credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
            return (.useCredential, credential)
        }
        #endif
        
        self.session = URLSession(configuration: config)
        encoder.dateEncodingStrategy = .millisecondsSince1970
    }
    
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
    
    public func shutdown() -> MetricExporterResultCode {
        session.invalidateAndCancel()
        return .success
    }
    
    private func sendRequest<T: Codable>(_ request: T, to url: String) -> Bool {
        guard let requestURL = URL(string: url) else { return false }
        
        do {
            let data = try encoder.encode(request)
            
            var urlRequest = URLRequest(url: requestURL)
            urlRequest.httpMethod = "POST"
            urlRequest.httpBody = data
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            for (key, value) in headers {
                urlRequest.setValue(value, forHTTPHeaderField: key)
            }
            
            let semaphore = DispatchSemaphore(value: 0)
            var success = false
            
            let task = session.dataTask(with: urlRequest) { _, response, error in
                defer { semaphore.signal() }
                
                if let error = error {
                    print("Metric export error: \(error)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    success = (200...299).contains(httpResponse.statusCode)
                }
            }
            
            task.resume()
            semaphore.wait()
            
            return success
        } catch {
            print("Failed to encode metrics: \(error)")
            return false
        }
    }
    
    private func createOTLPResource() -> OTLPResource {
        return OTLPResource(
            attributes: [
                OTLPKeyValue(key: "service.name", value: OTLPAnyValue.stringValue("UnisightTelemetry")),
                OTLPKeyValue(key: "device.model", value: OTLPAnyValue.stringValue(DeviceInfo.model))
            ]
        )
    }
    
    private func createOTLPScope() -> OTLPInstrumentationScope {
        return OTLPInstrumentationScope(name: "UnisightTelemetry", version: "1.0.0")
    }
    
    private func convertToOTLPMetric(_ metric: Metric) -> OTLPMetric {
        return OTLPMetric(
            name: metric.name,
            description: metric.description,
            unit: metric.unit
        )
    }
}

/// OTLP Log Exporter implementation
public class OTLPLogExporter: LogRecordExporter {
    private let endpoint: String
    private let headers: [String: String]
    private let session: URLSession
    private let encoder = JSONEncoder()
    
    public init(endpoint: String, headers: [String: String] = [:]) {
        self.endpoint = endpoint
        self.headers = headers
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        
        #if DEBUG
        config.urlSessionDidReceiveChallenge = { session, challenge in
            let credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
            return (.useCredential, credential)
        }
        #endif
        
        self.session = URLSession(configuration: config)
        encoder.dateEncodingStrategy = .millisecondsSince1970
    }
    
    public func export(logRecords: [ReadableLogRecord], explicitTimeout: TimeInterval?) -> LogRecordExporterResult {
        let otlpLogs = logRecords.map { convertToOTLPLog($0) }
        let request = OTLPLogRequest(resourceLogs: [
            OTLPResourceLogs(
                resource: createOTLPResource(),
                scopeLogs: [
                    OTLPScopeLogs(
                        scope: createOTLPScope(),
                        logRecords: otlpLogs
                    )
                ]
            )
        ])
        
        return sendRequest(request, to: "\(endpoint)/logs") ? .success : .failure
    }
    
    public func forceFlush(explicitTimeout: TimeInterval?) -> LogRecordExporterResult {
        return .success
    }
    
    public func shutdown(explicitTimeout: TimeInterval?) -> LogRecordExporterResult {
        session.invalidateAndCancel()
        return .success
    }
    
    private func sendRequest<T: Codable>(_ request: T, to url: String) -> Bool {
        guard let requestURL = URL(string: url) else { return false }
        
        do {
            let data = try encoder.encode(request)
            
            var urlRequest = URLRequest(url: requestURL)
            urlRequest.httpMethod = "POST"
            urlRequest.httpBody = data
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            for (key, value) in headers {
                urlRequest.setValue(value, forHTTPHeaderField: key)
            }
            
            let semaphore = DispatchSemaphore(value: 0)
            var success = false
            
            let task = session.dataTask(with: urlRequest) { _, response, error in
                defer { semaphore.signal() }
                
                if let error = error {
                    print("Log export error: \(error)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    success = (200...299).contains(httpResponse.statusCode)
                }
            }
            
            task.resume()
            semaphore.wait()
            
            return success
        } catch {
            print("Failed to encode logs: \(error)")
            return false
        }
    }
    
    private func createOTLPResource() -> OTLPResource {
        return OTLPResource(
            attributes: [
                OTLPKeyValue(key: "service.name", value: OTLPAnyValue.stringValue("UnisightTelemetry")),
                OTLPKeyValue(key: "device.model", value: OTLPAnyValue.stringValue(DeviceInfo.model))
            ]
        )
    }
    
    private func createOTLPScope() -> OTLPInstrumentationScope {
        return OTLPInstrumentationScope(name: "UnisightTelemetry", version: "1.0.0")
    }
    
    private func convertToOTLPLog(_ logRecord: ReadableLogRecord) -> OTLPLogRecord {
        return OTLPLogRecord(
            timeUnixNano: UInt64(logRecord.timestamp.timeIntervalSince1970 * 1_000_000_000),
            severityNumber: convertLogSeverity(logRecord.severity),
            severityText: logRecord.severity.name,
            body: OTLPAnyValue.stringValue(logRecord.body),
            attributes: logRecord.attributes.map { convertToOTLPKeyValue($0.key, $0.value) }
        )
    }
    
    private func convertLogSeverity(_ severity: LogSeverity) -> Int {
        switch severity {
        case .trace: return 1
        case .debug: return 5
        case .info: return 9
        case .warn: return 13
        case .error: return 17
        case .fatal: return 21
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

