# OTLP Protobuf Implementation Test Guide

## What Was Implemented

### 1. OTLPProtobufEncoder.swift
- Created a simplified OTLP protobuf encoder
- Implements proper protobuf wire format encoding
- Handles spans and metrics conversion

### 2. Updated TelemetryExporter.swift
- Changed from JSON to protobuf encoding
- Updated Content-Type to `application/x-protobuf`
- Added `sendProtobufRequest` method

## Key Changes

### Content-Type Header
```swift
// Before (JSON)
urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

// After (Protobuf)
urlRequest.setValue("application/x-protobuf", forHTTPHeaderField: "Content-Type")
```

### Data Encoding
```swift
// Before (JSON)
let data = try encoder.encode(request)

// After (Protobuf)
let protobufData = OTLPProtobufEncoder.encodeSpans(spans)
```

## Testing the Implementation

### 1. Build and Run
```bash
cd /workspace/repo/swift/apple/retail/foundations
./build_and_test.sh
```

### 2. Check Console Logs
Look for these messages:
```
✅ Telemetry initialized successfully
[UnisightLib] Telemetry data sent successfully. Status: 200
```

### 3. Verify Protobuf Format
The data should now be sent as binary protobuf instead of JSON.

## Expected Results

### Before (JSON - Unsupported Media Type)
```
Telemetry export failed with status: 415
Response: {"error": "Unsupported media type"}
```

### After (Protobuf - Success)
```
[UnisightLib] Telemetry data sent successfully. Status: 200
```

## Troubleshooting

### If still getting errors:

1. **Check Content-Type**: Ensure `application/x-protobuf` is being sent
2. **Verify protobuf data**: The data should be binary, not JSON
3. **Check endpoint**: Ensure the endpoint accepts protobuf format

### Common Issues:

1. **"Unsupported media type"**: Still sending JSON instead of protobuf
2. **"Invalid protobuf"**: Protobuf encoding is malformed
3. **"Missing required fields"**: OTLP protobuf structure is incomplete

## Next Steps

Once protobuf is working:

1. **Verify data flow**: Check that telemetry data is being received
2. **Test different event types**: Spans, metrics, logs
3. **Monitor performance**: Protobuf should be more efficient than JSON
4. **Production deployment**: Remove SSL bypass for production

## Production Considerations

- **Use proper protobuf library**: Consider SwiftProtobuf for production
- **Validate OTLP schema**: Ensure full OTLP v1.0 compliance
- **Error handling**: Add proper error handling for protobuf encoding
- **Performance**: Monitor protobuf encoding performance

## Verification Commands

```bash
# Check if the app builds
swift build

# Run the app and check logs
# Look for successful protobuf transmission
```