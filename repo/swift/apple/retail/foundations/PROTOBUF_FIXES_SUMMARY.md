# OTLP Protobuf Encoding Fixes Summary

## Issues Identified and Fixed

### 1. URL Path Correction
**Problem**: The exporter was using `/v1/metrics` instead of `/otlp/v1/metrics`
**Fix**: Updated both metrics and traces endpoints to use the correct OTLP path structure
- Changed from: `\(endpoint)/v1/metrics` 
- Changed to: `\(endpoint)/otlp/v1/metrics`

### 2. Protobuf Wire Format Fix
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

### 3. Hex String Validation
**Problem**: Invalid hex strings could cause encoding failures
**Fix**: Added validation to the Data extension for hex string parsing
- Check for even-length hex strings
- Validate hex characters
- Return nil for invalid strings with warning messages

### 4. Enhanced Error Handling and Debugging
**Problem**: Limited visibility into what was causing the 400 error
**Fix**: Added comprehensive debugging and error handling
- Detailed request logging (headers, body preview)
- Response status and body logging
- Specific 400 error diagnostics
- Protobuf encoding step-by-step logging

### 5. Span ID and Trace ID Validation
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

## Testing Recommendations

1. **Run the test file**: Execute `PROTOBUF_FIX_TEST.swift` to verify encoding works
2. **Check logs**: Look for the detailed debugging output to identify any remaining issues
3. **Verify endpoint**: Ensure the OTLP collector endpoint is correct and accessible
4. **Test with minimal data**: Start with a single metric to isolate issues

## Common 400 Error Causes

1. **Incorrect protobuf structure**: Fixed with proper field encoding
2. **Wrong content type**: Using `application/x-protobuf` (correct)
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

- `ManualProtobufEncoder.swift`: Fixed protobuf encoding and validation
- `ManualTelemetryExporter.swift`: Fixed URL paths and enhanced debugging
- `PROTOBUF_FIX_TEST.swift`: Created test file for verification