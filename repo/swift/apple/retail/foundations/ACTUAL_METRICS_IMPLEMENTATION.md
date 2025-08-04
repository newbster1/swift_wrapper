# Actual Metrics Implementation

## Overview
This document describes the changes made to send actual metrics instead of hardcoded test metrics in the Unisight telemetry system.

## Problem
The original implementation was using `MinimalOTLPEncoder.createMinimalOTLPRequest()` which created a hardcoded test metric named "test_metric" with a value of 1.0, regardless of what actual metrics were being recorded by the application.

## Solution
Modified the `ManualTelemetryExporter` to use actual metrics when available, falling back to test metrics only when no actual metrics are provided.

## Changes Made

### 1. ManualTelemetryExporter.swift
- **Modified `sendOTLPRequest` method**: Now checks if actual metrics are available and uses them instead of hardcoded test data
- **Added `createOTLPRequestFromMetrics` method**: Creates OTLP requests from actual Metric objects
- **Added `createResourceMetricsFromMetrics` method**: Creates resource metrics from actual metrics
- **Added `createScopeMetricsFromMetrics` method**: Creates scope metrics from actual metrics
- **Added `createMetricFromActualMetric` method**: Encodes individual actual metrics
- **Added `createGaugeFromMetric` method**: Creates gauge data from actual metrics
- **Added `createNumberDataPointFromMetric` method**: Creates data points from actual metrics
- **Added `extractMetricValue` helper**: Extracts values from actual metrics (simplified implementation)

### 2. UnisightTelemetry.swift
- **Enhanced metric recording**: Added automatic metric recording to system events
- **Added initialization metrics**: Records metrics during telemetry initialization
- **Added session metrics**: Records metrics when sessions start
- **Added app lifecycle metrics**: Records metrics for app background/foreground events
- **Added battery level metrics**: Records battery level as gauge metrics
- **Added `forceMetricExport` method**: Allows manual triggering of metric export for testing

### 3. TelemetryService.swift
- **Enhanced event logging**: Automatically records metrics for important events
- **Added testing methods**: 
  - `forceMetricExport()`: Triggers metric export
  - `recordTestMetrics()`: Records sample metrics for testing

### 4. Sample App Integration
- **SettingsView.swift**: Added "Test Actual Metrics" button for manual testing
- **UnisightSampleAppApp.swift**: Added app launch metrics recording

## How It Works

### Before (Test Metrics Only)
```swift
// Always sent the same hardcoded test metric
let protobufData = MinimalOTLPEncoder.createMinimalOTLPRequest()
```

### After (Actual Metrics)
```swift
// Use actual metrics if available, fall back to test data
let protobufData: Data
if type == "metrics", let metrics = metrics, !metrics.isEmpty {
    print("[UnisightLib] Using actual metrics: \(metrics.count) metrics")
    protobufData = MinimalOTLPEncoder.createOTLPRequestFromMetrics(metrics)
} else {
    print("[UnisightLib] Using test metrics (no actual metrics provided)")
    protobufData = MinimalOTLPEncoder.createMinimalOTLPRequest()
}
```

## Actual Metrics Generated

The system now automatically generates metrics for:

1. **System Events**:
   - `telemetry_initialization_count`
   - `app_startup_time`
   - `session_start_count`
   - `session_id_hash`
   - `app_background_count`
   - `app_foreground_count`
   - `battery_level_gauge`

2. **User Events**:
   - `event_{event_name}_count` (for user and functional events)
   - `app_launch_count`
   - `app_launch_timestamp`

3. **Test Metrics** (via testing methods):
   - `test_counter`
   - `test_gauge`
   - `test_histogram`
   - `forced_export_test`

## Testing

### Manual Testing
1. Run the sample app
2. Go to Settings
3. Tap "Test Actual Metrics" button
4. Check console logs for:
   - "Using actual metrics: X metrics"
   - "Encoding actual metric: metric_name"
   - "Export successful with status: 200"

### Automated Testing
Run the `ACTUAL_METRICS_TEST.swift` file to verify the implementation.

## Expected Log Output
When actual metrics are being sent, you should see logs like:
```
[UnisightLib] Using actual metrics: 5 metrics
[UnisightLib] Creating OTLP request from 5 actual metrics
[UnisightLib] Encoding actual metric: test_counter_actual
[UnisightLib] Encoding actual metric: test_gauge_actual
[UnisightLib] Export successful with status: 200
```

## Limitations

1. **Metric Value Extraction**: The current implementation uses simplified metric value extraction. In a production environment, you would need to access the actual metric data points from the OpenTelemetry SDK.

2. **Metric Types**: Currently treats all metrics as gauges. For production use, you would need to handle different metric types (counters, histograms, etc.) appropriately.

3. **Batch Processing**: The metric processor setup is simplified. For production use, you would want to implement proper batch processing and periodic export.

## Next Steps

1. **Implement proper metric value extraction** from OpenTelemetry SDK
2. **Add support for different metric types** (counters, histograms, etc.)
3. **Implement batch processing** for better performance
4. **Add metric aggregation** and filtering capabilities
5. **Add metric validation** and error handling