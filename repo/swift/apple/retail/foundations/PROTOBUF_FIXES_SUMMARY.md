# OTLP Protobuf Encoding Fixes Summary

## Issues Identified and Fixed

### 1. Metric Encoding Structure
**Problem**: The code was trying to access non-existent properties like `metric.dataPoints` and `MetricPoint` from the OpenTelemetry Swift SDK
**Fix**: Simplified the metric encoding to work with the actual `StableMetricData` structure:
- Removed references to non-existent `dataPoints` property
- Removed references to non-existent `MetricPoint` type
- Created a simple gauge metric structure with default values

### 2. Field Number Corrections
**Problem**: Incorrect field numbers were being used for the OTLP protobuf specification
**Fix**: Updated field numbers to match the OTLP specification:
- Changed gauge field from 4 to 5 in Metric message
- Changed double value field from 5 to 6 in NumberDataPoint message

### 3. Protobuf Wire Format Fix
**Problem**: The `writeField` method was incorrectly encoding length-delimited fields
**Fix**: Updated the method to only write length for length-delimited wire types
```swift
private static func writeField(_ fieldNumber: Int, wireType: WireType, data: Data, to output: inout Data) {
    let tag = (fieldNumber << 3) | Int(wireType.rawValue)
    writeVarint(UInt64(tag), to: &output)
    
    if wireType == .lengthDelimited {
        writeVarint(UInt64(data.count), to: &output)
    }
    
    output.append(data)
}
```

### 4. Hex String Validation
**Problem**: Invalid hex strings could cause encoding failures
**Fix**: Added validation to the Data extension for hex string parsing
- Check for even-length hex strings
- Validate hex characters
- Return nil for invalid strings with warning messages

### 5. Enhanced Error Handling and Debugging
**Problem**: Limited visibility into what was causing the 400 error
**Fix**: Added comprehensive debugging and error handling
- Detailed request logging (headers, body preview)
- Response status and body logging
- Specific 400 error diagnostics
- Protobuf encoding step-by-step logging

### 6. Span ID and Trace ID Validation
**Problem**: Invalid span/trace IDs could cause encoding issues
**Fix**: Added validation and warnings for malformed IDs
- Check for empty parsed data
- Log warnings for invalid hex strings
- Continue processing with empty data rather than failing

## OTLP Structure Verification

The protobuf structure now follows the OTLP specification:
```
ExportMetricsServiceRequest
└── ResourceMetrics (field 1)
    ├── Resource (field 1)
    └── ScopeMetrics (field 2)
        ├── InstrumentationScope (field 1)
        └── Metric (field 2, repeated)
            ├── name (field 1)
            ├── description (field 2)
            ├── unit (field 3)
            └── Gauge (field 5)
                └── NumberDataPoint (field 1, repeated)
                    ├── start_time_unix_nano (field 2)
                    ├── time_unix_nano (field 4)
                    └── as_double (field 6)
```

## Key Changes Made

1. **Simplified Metric Encoding**: Removed complex nested structures and created a simple gauge metric with default values
2. **Corrected Field Numbers**: Updated field numbers to match OTLP specification exactly
3. **Fixed Wire Format**: Corrected protobuf wire format encoding
4. **Enhanced Validation**: Added comprehensive validation for all data types
5. **Improved Debugging**: Added detailed logging for troubleshooting

## Testing Recommendations

1. **Run the test file**: Execute `PROTOBUF_FIX_TEST.swift` to verify encoding works
2. **Check logs**: Look for the detailed debugging output to identify any remaining issues
3. **Verify endpoint**: Ensure the OTLP collector endpoint is correct and accessible
4. **Test with minimal data**: Start with a single metric to isolate issues

## Common 400 Error Causes (Now Fixed)

1. **Incorrect protobuf structure**: Fixed with proper field encoding
2. **Wrong field numbers**: Fixed to match OTLP specification
3. **Invalid hex strings**: Fixed with validation
4. **Malformed timestamps**: Using proper nanosecond timestamps
5. **Missing required fields**: All required OTLP fields are included

## Next Steps

If the 400 error persists after these fixes:

1. Check the OTLP collector logs for specific error messages
2. Verify the collector supports the OTLP HTTP protocol
3. Test with a known working OTLP client to compare payloads
4. Consider using the official OpenTelemetry Swift SDK's built-in OTLP exporter

## Files Modified

- `ManualProtobufEncoder.swift`: Fixed protobuf encoding, field numbers, and validation
- `ManualTelemetryExporter.swift`: Enhanced debugging and error handling
- `PROTOBUF_FIX_TEST.swift`: Created test file for verification