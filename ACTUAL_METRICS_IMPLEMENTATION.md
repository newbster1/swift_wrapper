# Actual Metrics Implementation

## Problem Statement

The user reported that the telemetry system was still sending "test_metric" instead of actual event-driven metrics. The logs showed:
- "Using test metrics (no actual metrics provided)"
- Only "test_metric" was being exported
- No actual event-driven metrics like "screen_loaded", "product_viewed", "settings_accessed" were being sent

## Root Cause Analysis

1. **MetricProcessor Missing**: The `MeterProvider` was not configured with a `MetricProcessor`, so metrics weren't being collected and batched properly.

2. **Manual Export Bypass**: The `recordMetric` method was manually calling `telemetryExporter.export()` instead of relying on the OpenTelemetry SDK's metric processing flow.

3. **EventProcessor Not Recording Metrics**: The `EventProcessor` was not generating metrics from events, especially for consolidated events.

4. **Type Mismatch**: The `ManualTelemetryExporter` was expecting `[Metric]` but the OpenTelemetry SDK provides `[StableMetricData]`.

5. **Redundant Metric Recording**: `TelemetryService.logEvent` was calling `recordMetric` directly, creating duplicate metrics.

## Solution Implementation

### 1. Fixed UnisightTelemetry.swift

**Changes Made:**
- Added `private var metricProcessor: MetricProcessor!` property
- Reverted `recordMetric` to use OpenTelemetry SDK's counter creation (no manual export)
- Reverted `forceMetricExport` to use `metricProcessor.forceFlush()`
- Re-added `MetricProcessor` setup in `setupOpenTelemetry()`
- Removed `SimpleMetric` class and `createSimpleMetricData` helper

**Key Code Changes:**
```swift
// Added metric processor property
private var metricProcessor: MetricProcessor!

// Fixed setupOpenTelemetry to include MetricProcessor
if configuration.usesBatchProcessor {
    self.metricProcessor = BatchMetricProcessor(metricExporter: telemetryExporter)
} else {
    self.metricProcessor = SimpleMetricProcessor(metricExporter: telemetryExporter)
}

self.meterProvider = MeterProviderBuilder()
    .add(metricProcessor: self.metricProcessor)
    .with(resource: resource)
    .build()

// Reverted recordMetric to use SDK properly
public func recordMetric(name: String, value: Double, labels: [String: String] = [:]) {
    let counter = meter.createDoubleCounter(name: name)
    counter.add(value: value, labels: labels)
}

// Fixed forceMetricExport to use processor
public func forceMetricExport() {
    guard isInitialized else {
        print("[UnisightLib] Telemetry not initialized")
        return
    }
    print("[UnisightLib] Forced metric export triggered")
    _ = metricProcessor.forceFlush()
}
```

### 2. Fixed ManualTelemetryExporter.swift

**Changes Made:**
- Updated `export(metrics:)` method signature from `[Metric]` to `[StableMetricData]`
- Updated `sendOTLPRequest` to accept `[StableMetricData]?` parameter
- Improved logging to distinguish between actual metrics and test metrics

**Key Code Changes:**
```swift
// Fixed method signature
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

// Updated sendOTLPRequest signature
private func sendOTLPRequest(request: Data, type: String, metrics: [StableMetricData]? = nil) -> SpanExporterResultCode
```

### 3. Enhanced MinimalOTLPEncoder.swift

**Changes Made:**
- Updated `createOTLPRequestFromMetrics` to accept `[StableMetricData]`
- Implemented proper encoding for different `MetricData` types:
  - `GaugeData` → `encodeGaugeData`
  - `SumData` → `encodeSumData` 
  - `HistogramData` → `encodeHistogramData`
- Added specific encoding functions for data points:
  - `encodeNumberDataPoint` for gauge/sum data points
  - `encodeHistogramDataPoint` for histogram data points
- Removed old `SimpleMetric` approach

**Key Code Changes:**
```swift
// Updated method signature
public static func createOTLPRequestFromMetrics(_ metrics: [StableMetricData]) -> Data

// Enhanced metric encoding
private static func createMetricFromActualMetric(_ metric: StableMetricData) -> Data {
    // ... encode metric name, description, unit ...
    
    // Encode based on metric type
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
        
    // ... handle other types ...
    }
}
```

### 4. Enhanced EventProcessor.swift

**Changes Made:**
- Added `recordMetricForEvent` method to generate metrics from events
- Added `recordMetricForConsolidatedEvent` method for consolidated events
- Modified `processImmediate` and `processConsolidatedEvent` to record metrics

**Key Code Changes:**
```swift
private func recordMetricForEvent(_ event: TelemetryEvent) {
    // Record a metric for the event
    let metricName = "\(event.name)_count"
    UnisightTelemetry.shared.recordMetric(name: metricName, value: 1.0)
    
    // Record event-specific metrics based on category
    switch event.category {
    case .user:
        UnisightTelemetry.shared.recordMetric(name: "user_event_count", value: 1.0)
    case .system:
        UnisightTelemetry.shared.recordMetric(name: "system_event_count", value: 1.0)
    // ... other categories ...
    }
}

private func recordMetricForConsolidatedEvent(_ consolidatedEvent: TelemetryEvent, originalEvents: [TelemetryEvent]) {
    // Record metrics for consolidated events
    UnisightTelemetry.shared.recordMetric(
        name: "consolidated_event_screen_appeared_count", 
        value: Double(originalEvents.count)
    )
    
    // Record time span of consolidation
    if let firstTime = originalEvents.first?.timestamp.timeIntervalSince1970,
       let lastTime = originalEvents.last?.timestamp.timeIntervalSince1970 {
        let timeSpan = lastTime - firstTime
        UnisightTelemetry.shared.recordMetric(
            name: "consolidated_event_screen_appeared_time_span", 
            value: timeSpan
        )
    }
}
```

### 5. Simplified TelemetryService.swift

**Changes Made:**
- Removed redundant `recordMetric` call from `logEvent`
- Simplified the service to focus on event logging
- Added `recordTestMetrics()` method for testing purposes
- Kept `forceMetricExport()` for manual testing

**Key Code Changes:**
```swift
public func logEvent(
    name: String,
    category: EventCategory = .user,
    attributes: [String: Any] = [:]
) {
    UnisightTelemetry.shared.logEvent(
        name: name,
        category: category,
        attributes: attributes
    )
    // Removed redundant recordMetric call - EventProcessor handles this now
}
```

## How It Works Now

### 1. Event Flow
```
User Action → TelemetryService.logEvent() → UnisightTelemetry.logEvent() → EventProcessor.process()
```

### 2. Metric Generation
```
EventProcessor → recordMetricForEvent() → UnisightTelemetry.recordMetric() → Meter.createDoubleCounter()
```

### 3. Metric Collection
```
Meter → MetricProcessor (Batch/Simple) → ManualTelemetryExporter.export()
```

### 4. Metric Export
```
ManualTelemetryExporter → MinimalOTLPEncoder → OTLP Protobuf → HTTP Request
```

## Actual Metrics Generated

### System Metrics (Automatic)
- `telemetry_initialization_count`
- `app_startup_time`
- `session_start_count`
- `session_id_hash`
- `app_background_count`
- `app_foreground_count`
- `battery_level_gauge`
- `session_duration`

### Event-Driven Metrics (From Events)
- `{event_name}_count` (e.g., `screen_loaded_count`, `product_viewed_count`)
- `user_event_count`
- `system_event_count`
- `performance_event_count`
- `error_event_count`

### Consolidated Event Metrics
- `consolidated_event_screen_appeared_count`
- `consolidated_event_screen_appeared_time_span`
- `consolidation_efficiency_ratio`

### Test Metrics (Manual)
- `screen_loaded`
- `product_viewed`
- `settings_accessed`
- `button_clicked`
- `api_call_duration`
- `memory_usage`
- `battery_level`

## Testing Instructions

### 1. Run the Sample App
```swift
// In your app
TelemetryService.shared.logEvent(name: "screen_loaded", category: .user)
TelemetryService.shared.recordMetric(name: "api_call_duration", value: 150.0)
TelemetryService.shared.forceMetricExport()
```

### 2. Check Logs
Look for these log messages:
```
[ManualTelemetryExporter] Using actual metrics for export
[ManualTelemetryExporter] Exported X actual metrics
[ManualTelemetryExporter] - Metric: screen_loaded_count
[ManualTelemetryExporter] - Metric: api_call_duration
```

### 3. Verify No Test Metrics
The logs should NOT show:
```
[ManualTelemetryExporter] Using test metrics (no actual metrics provided)
[ManualTelemetryExporter] Exported test metric
```

## Expected Log Output

When working correctly, you should see:
```
[ManualTelemetryExporter] Exporting 5 metrics
[ManualTelemetryExporter] Using actual metrics for export
[ManualTelemetryExporter] Metrics export response: 200
[ManualTelemetryExporter] ✅ Successfully exported metrics
[ManualTelemetryExporter] Exported 5 actual metrics
[ManualTelemetryExporter] - Metric: screen_loaded_count
[ManualTelemetryExporter] - Metric: product_viewed_count
[ManualTelemetryExporter] - Metric: settings_accessed_count
[ManualTelemetryExporter] - Metric: button_clicked_count
[ManualTelemetryExporter] - Metric: api_call_duration
```

## Current Limitations

1. **Protobuf Encoding**: The manual protobuf encoding is simplified and may not handle all edge cases
2. **Metric Types**: Only supports Gauge, Sum, and Histogram metrics (not ExponentialHistogram or Summary)
3. **Batch Processing**: While `BatchMetricProcessor` is configured, its specific behavior may need tuning
4. **Error Handling**: Limited error handling for malformed metrics or network failures

## Future Improvements

1. **Use Official OTLP Exporter**: Replace manual protobuf encoding with the official OpenTelemetry OTLP exporter
2. **Enhanced Metric Types**: Add support for ExponentialHistogram and Summary metrics
3. **Better Error Handling**: Implement comprehensive error handling and retry logic
4. **Metric Validation**: Add validation for metric names, values, and labels
5. **Performance Optimization**: Implement metric aggregation and filtering capabilities