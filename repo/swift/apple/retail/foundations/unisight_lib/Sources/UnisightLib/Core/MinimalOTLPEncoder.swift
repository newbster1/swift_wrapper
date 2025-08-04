import Foundation
import OpenTelemetrySdk

/// Minimal OTLP encoder for manual protobuf encoding
/// This is a simplified implementation for testing purposes
public class MinimalOTLPEncoder {
    
    // MARK: - Public Methods
    
    /// Create a minimal OTLP request for testing
    public static func createMinimalOTLPRequest() -> Data {
        print("[MinimalOTLPEncoder] Creating minimal OTLP request")
        
        // Create a simple test metric
        let testMetric = createTestMetric()
        
        // Encode as OTLP protobuf
        var data = Data()
        
        // OTLP ExportMetricsServiceRequest
        data.append(encodeField(tag: 1, wireType: 2)) // repeated ResourceMetrics resource_metrics
        data.append(encodeLengthDelimited(testMetric))
        
        print("[MinimalOTLPEncoder] Created minimal OTLP request: \(data.count) bytes")
        return data
    }
    
    /// Create OTLP request from actual metrics
    public static func createOTLPRequestFromMetrics(_ metrics: [StableMetricData]) -> Data {
        print("[MinimalOTLPEncoder] Creating OTLP request from \(metrics.count) actual metrics")
        
        var data = Data()
        
        // OTLP ExportMetricsServiceRequest
        data.append(encodeField(tag: 1, wireType: 2)) // repeated ResourceMetrics resource_metrics
        
        // Create resource metrics from actual metrics
        let resourceMetrics = createResourceMetricsFromMetrics(metrics)
        data.append(encodeLengthDelimited(resourceMetrics))
        
        print("[MinimalOTLPEncoder] Created OTLP request from actual metrics: \(data.count) bytes")
        return data
    }
    
    // MARK: - Private Methods
    
    private static func createTestMetric() -> Data {
        var data = Data()
        
        // ResourceMetrics
        data.append(encodeField(tag: 1, wireType: 2)) // repeated ScopeMetrics scope_metrics
        
        // ScopeMetrics
        let scopeMetrics = createScopeMetrics()
        data.append(encodeLengthDelimited(scopeMetrics))
        
        return data
    }
    
    private static func createResourceMetricsFromMetrics(_ metrics: [StableMetricData]) -> Data {
        var data = Data()
        
        // ResourceMetrics
        data.append(encodeField(tag: 1, wireType: 2)) // repeated ScopeMetrics scope_metrics
        
        // Group metrics by scope
        let scopeMetrics = createScopeMetricsFromMetrics(metrics)
        data.append(encodeLengthDelimited(scopeMetrics))
        
        return data
    }
    
    private static func createScopeMetrics() -> Data {
        var data = Data()
        
        // ScopeMetrics
        data.append(encodeField(tag: 1, wireType: 2)) // repeated Metric metrics
        
        // Create a test metric
        let testMetric = createTestMetricData()
        data.append(encodeLengthDelimited(testMetric))
        
        return data
    }
    
    private static func createScopeMetricsFromMetrics(_ metrics: [StableMetricData]) -> Data {
        var data = Data()
        
        // ScopeMetrics
        data.append(encodeField(tag: 1, wireType: 2)) // repeated Metric metrics
        
        // Encode each actual metric
        for metric in metrics {
            let metricData = createMetricFromActualMetric(metric)
            data.append(encodeLengthDelimited(metricData))
        }
        
        return data
    }
    
    private static func createTestMetricData() -> Data {
        var data = Data()
        
        // Metric
        data.append(encodeField(tag: 1, wireType: 2)) // string name
        data.append(encodeString("test_metric"))
        
        data.append(encodeField(tag: 2, wireType: 2)) // string description
        data.append(encodeString("Test metric for OTLP export"))
        
        data.append(encodeField(tag: 3, wireType: 2)) // string unit
        data.append(encodeString("1"))
        
        // Gauge data
        data.append(encodeField(tag: 5, wireType: 2)) // Gauge gauge
        let gaugeData = createGaugeData()
        data.append(encodeLengthDelimited(gaugeData))
        
        return data
    }
    
    private static func createMetricFromActualMetric(_ metric: StableMetricData) -> Data {
        var data = Data()
        
        // Metric
        data.append(encodeField(tag: 1, wireType: 2)) // string name
        data.append(encodeString(metric.name))
        
        data.append(encodeField(tag: 2, wireType: 2)) // string description
        data.append(encodeString(metric.description ?? "Metric from UnisightTelemetry"))
        
        if let unit = metric.unit {
            data.append(encodeField(tag: 3, wireType: 2)) // string unit
            data.append(encodeString(unit))
        }
        
        // Encode the actual metric data based on its type
        switch metric.data {
        case .gauge(let gaugeData):
            data.append(encodeField(tag: 5, wireType: 2)) // Gauge gauge
            let encodedGauge = encodeGaugeData(gaugeData)
            data.append(encodeLengthDelimited(encodedGauge))
            
        case .sum(let sumData):
            data.append(encodeField(tag: 7, wireType: 2)) // Sum sum
            let encodedSum = encodeSumData(sumData)
            data.append(encodeLengthDelimited(encodedSum))
            
        case .histogram(let histogramData):
            data.append(encodeField(tag: 9, wireType: 2)) // Histogram histogram
            let encodedHistogram = encodeHistogramData(histogramData)
            data.append(encodeLengthDelimited(encodedHistogram))
            
        case .exponentialHistogram(_):
            // Not implemented yet
            print("[MinimalOTLPEncoder] Exponential histogram not yet supported")
            
        case .summary(_):
            // Not implemented yet
            print("[MinimalOTLPEncoder] Summary not yet supported")
        }
        
        return data
    }
    
    private static func createGaugeData() -> Data {
        var data = Data()
        
        // Gauge
        data.append(encodeField(tag: 1, wireType: 2)) // repeated NumberDataPoint data_points
        
        // NumberDataPoint
        let dataPoint = createNumberDataPoint()
        data.append(encodeLengthDelimited(dataPoint))
        
        return data
    }
    
    private static func encodeGaugeData(_ gaugeData: GaugeData) -> Data {
        var data = Data()
        
        // Gauge
        data.append(encodeField(tag: 1, wireType: 2)) // repeated NumberDataPoint data_points
        
        // Encode each data point
        for dataPoint in gaugeData.dataPoints {
            let encodedPoint = encodeNumberDataPoint(dataPoint)
            data.append(encodeLengthDelimited(encodedPoint))
        }
        
        return data
    }
    
    private static func encodeSumData(_ sumData: SumData) -> Data {
        var data = Data()
        
        // Sum
        data.append(encodeField(tag: 1, wireType: 2)) // repeated NumberDataPoint data_points
        
        // Encode each data point
        for dataPoint in sumData.dataPoints {
            let encodedPoint = encodeNumberDataPoint(dataPoint)
            data.append(encodeLengthDelimited(encodedPoint))
        }
        
        data.append(encodeField(tag: 2, wireType: 0)) // bool is_monotonic
        data.append(encodeBool(sumData.isMonotonic))
        
        data.append(encodeField(tag: 3, wireType: 0)) // AggregationTemporality aggregation_temporality
        data.append(encodeInt32(Int32(sumData.aggregationTemporality.rawValue)))
        
        return data
    }
    
    private static func encodeHistogramData(_ histogramData: HistogramData) -> Data {
        var data = Data()
        
        // Histogram
        data.append(encodeField(tag: 1, wireType: 2)) // repeated HistogramDataPoint data_points
        
        // Encode each data point
        for dataPoint in histogramData.dataPoints {
            let encodedPoint = encodeHistogramDataPoint(dataPoint)
            data.append(encodeLengthDelimited(encodedPoint))
        }
        
        data.append(encodeField(tag: 2, wireType: 0)) // AggregationTemporality aggregation_temporality
        data.append(encodeInt32(Int32(histogramData.aggregationTemporality.rawValue)))
        
        return data
    }
    
    private static func createNumberDataPoint() -> Data {
        var data = Data()
        
        // NumberDataPoint
        data.append(encodeField(tag: 1, wireType: 1)) // uint64 time_unix_nano
        data.append(encodeUInt64(UInt64(Date().timeIntervalSince1970 * 1_000_000_000)))
        
        data.append(encodeField(tag: 2, wireType: 5)) // double value
        data.append(encodeDouble(42.0))
        
        return data
    }
    
    private static func encodeNumberDataPoint(_ dataPoint: NumberDataPoint) -> Data {
        var data = Data()
        
        // NumberDataPoint
        data.append(encodeField(tag: 1, wireType: 1)) // uint64 time_unix_nano
        data.append(encodeUInt64(UInt64(dataPoint.timeUnixNano)))
        
        // Encode the value based on its type
        switch dataPoint.value {
        case .double(let doubleValue):
            data.append(encodeField(tag: 2, wireType: 5)) // double value
            data.append(encodeDouble(doubleValue))
        case .int(let intValue):
            data.append(encodeField(tag: 3, wireType: 0)) // int64 value
            data.append(encodeInt64(intValue))
        }
        
        return data
    }
    
    private static func encodeHistogramDataPoint(_ dataPoint: HistogramDataPoint) -> Data {
        var data = Data()
        
        // HistogramDataPoint
        data.append(encodeField(tag: 1, wireType: 1)) // uint64 time_unix_nano
        data.append(encodeUInt64(UInt64(dataPoint.timeUnixNano)))
        
        data.append(encodeField(tag: 2, wireType: 5)) // double sum
        data.append(encodeDouble(dataPoint.sum))
        
        data.append(encodeField(tag: 3, wireType: 1)) // uint64 count
        data.append(encodeUInt64(UInt64(dataPoint.count)))
        
        // Bucket counts
        data.append(encodeField(tag: 4, wireType: 2)) // repeated uint64 bucket_counts
        for bucketCount in dataPoint.bucketCounts {
            data.append(encodeUInt64(UInt64(bucketCount)))
        }
        
        // Explicit bounds
        data.append(encodeField(tag: 5, wireType: 2)) // repeated double explicit_bounds
        for bound in dataPoint.explicitBounds {
            data.append(encodeDouble(bound))
        }
        
        return data
    }
    
    // MARK: - Protobuf Encoding Helpers
    
    private static func encodeField(tag: Int, wireType: Int) -> Data {
        let fieldNumber = UInt32(tag)
        let wireTypeValue = UInt32(wireType)
        let key = (fieldNumber << 3) | wireTypeValue
        return encodeVarint(key)
    }
    
    private static func encodeLengthDelimited(_ data: Data) -> Data {
        var result = encodeVarint(UInt32(data.count))
        result.append(data)
        return result
    }
    
    private static func encodeString(_ string: String) -> Data {
        let data = string.data(using: .utf8)!
        return encodeLengthDelimited(data)
    }
    
    private static func encodeVarint(_ value: UInt32) -> Data {
        var data = Data()
        var val = value
        
        while val >= 0x80 {
            data.append(UInt8((val & 0x7F) | 0x80))
            val >>= 7
        }
        data.append(UInt8(val))
        
        return data
    }
    
    private static func encodeUInt64(_ value: UInt64) -> Data {
        var data = Data()
        var val = value
        
        while val >= 0x80 {
            data.append(UInt8((val & 0x7F) | 0x80))
            val >>= 7
        }
        data.append(UInt8(val))
        
        return data
    }
    
    private static func encodeInt64(_ value: Int64) -> Data {
        return encodeUInt64(UInt64(bitPattern: value))
    }
    
    private static func encodeInt32(_ value: Int32) -> Data {
        return encodeVarint(UInt32(bitPattern: value))
    }
    
    private static func encodeDouble(_ value: Double) -> Data {
        var data = Data()
        withUnsafeBytes(of: value) { bytes in
            data.append(contentsOf: bytes)
        }
        return data
    }
    
    private static func encodeBool(_ value: Bool) -> Data {
        return Data([value ? 1 : 0])
    }
}