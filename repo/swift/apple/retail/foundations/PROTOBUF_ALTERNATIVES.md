# Protobuf Alternatives for Telemetry Data

This document outlines several approaches to send telemetry data in protobuf format without requiring generated protobuf files.

## Overview

Your current implementation relies on manually generated protobuf files like:
- `Opentelemetry_Proto_Common_V1`
- `Opentelemetry_Proto_Resource_V1`
- `Opentelemetry_Proto_Trace_V1`
- etc.

Here are alternative approaches that eliminate this dependency:

## 1. Manual Binary Protobuf Encoding

**File**: `ManualProtobufEncoder.swift`

This approach manually constructs the protobuf binary format by implementing the wire protocol directly.

### Advantages:
- ✅ Creates true protobuf binary format
- ✅ No external dependencies
- ✅ Full control over serialization
- ✅ Compatible with all OTLP collectors
- ✅ Smaller payload size

### Disadvantages:
- ❌ More complex implementation
- ❌ Requires understanding of protobuf wire format
- ❌ Manual maintenance if proto schemas change

### Usage:
```swift
let exporter = ManualTelemetryExporter(
    endpoint: "https://your-otlp-endpoint.com",
    headers: ["Authorization": "Bearer your-token"],
    bypassSSL: false
)

// Use with OpenTelemetry SDK
let spanProcessor = BatchSpanProcessor(spanExporter: exporter)
```

## 2. JSON with Protobuf Headers

**File**: `JSONToProtobufExporter.swift`

This approach sends JSON data but with protobuf-compatible structure and headers.

### Advantages:
- ✅ Simple to implement and debug
- ✅ Human-readable format
- ✅ No protobuf knowledge required
- ✅ Some OTLP collectors accept JSON

### Disadvantages:
- ❌ Larger payload size
- ❌ Not all collectors support JSON on protobuf endpoints
- ❌ May require specific collector configuration

### Usage:
```swift
let exporter = JSONToProtobufExporter(
    endpoint: "https://your-otlp-endpoint.com",
    headers: ["Authorization": "Bearer your-token"],
    bypassSSL: false
)
```

## 3. gRPC-Web Approach

**File**: `ProtobufAlternativesExample.swift` (GRPCWebTelemetryExporter)

Uses gRPC-Web protocol with base64-encoded protobuf data.

### Advantages:
- ✅ Standard gRPC-Web protocol
- ✅ Works through HTTP proxies
- ✅ Supported by many collectors

### Disadvantages:
- ❌ Still requires protobuf encoding
- ❌ Base64 encoding increases payload size
- ❌ Requires gRPC-Web compatible endpoint

### Usage:
```swift
let exporter = GRPCWebTelemetryExporter(
    endpoint: "https://your-grpc-web-endpoint.com",
    headers: ["Authorization": "Bearer your-token"]
)
```

## 4. HTTP/JSON OTLP

Many OTLP collectors support HTTP/JSON endpoints alongside protobuf:

```swift
// Send to JSON endpoint instead
let jsonEndpoint = "https://your-collector.com/v1/traces" // Note: no /v1/traces suffix sometimes
request.setValue("application/json", forHTTPHeaderField: "Content-Type")
```

### Advantages:
- ✅ Standard OTLP protocol
- ✅ Supported by most collectors (Jaeger, OTEL Collector, etc.)
- ✅ Simple JSON serialization

### Disadvantages:
- ❌ Requires collector to support JSON
- ❌ Larger payload size than protobuf

## 5. Custom Binary Format

**File**: `ProtobufAlternativesExample.swift` (sendSimplifiedBinaryFormat)

Create your own simplified binary format.

### Advantages:
- ✅ Full control over format
- ✅ Can be very compact
- ✅ Simple to implement

### Disadvantages:
- ❌ Requires custom collector support
- ❌ Not compatible with standard OTLP
- ❌ Additional infrastructure needed

## 6. MessagePack or CBOR

Alternative binary serialization formats:

```swift
// Using MessagePack (add dependency)
import MessagePacker

let messagePackData = try! MessagePackEncoder().encode(telemetryData)
request.setValue("application/msgpack", forHTTPHeaderField: "Content-Type")
```

### Advantages:
- ✅ Compact binary format
- ✅ Easier than protobuf
- ✅ Good library support

### Disadvantages:
- ❌ Requires collector support
- ❌ Additional dependencies
- ❌ Not standard OTLP

## Recommendations

### For Production Use:
1. **Manual Binary Protobuf** - Best compatibility and performance
2. **HTTP/JSON OTLP** - If your collector supports it

### For Development/Testing:
1. **JSON with Protobuf Headers** - Easy to debug
2. **HTTP/JSON OTLP** - Standard and simple

### For Custom Infrastructure:
1. **Custom Binary Format** - If you control the entire pipeline
2. **MessagePack/CBOR** - Good middle ground

## Implementation Guide

### Step 1: Choose Your Approach
Pick based on your collector's capabilities and performance requirements.

### Step 2: Update Your Exporter
Replace your current `TelemetryExporter` with one of the alternatives:

```swift
// Replace this:
let exporter = TelemetryExporter(...)

// With this (for example):
let exporter = ManualTelemetryExporter(...)
```

### Step 3: Test Compatibility
Verify your collector receives and processes the data correctly.

### Step 4: Monitor Performance
Compare payload sizes and processing times.

## Collector Compatibility

### Jaeger:
- ✅ HTTP/JSON OTLP
- ✅ Manual protobuf
- ❌ Custom formats

### OpenTelemetry Collector:
- ✅ HTTP/JSON OTLP  
- ✅ Manual protobuf
- ✅ gRPC-Web (with proper configuration)

### Cloud Providers (AWS X-Ray, GCP, Azure):
- ✅ HTTP/JSON OTLP (usually)
- ✅ Manual protobuf
- ❌ Custom formats

## Performance Comparison

| Approach | Payload Size | Complexity | Compatibility |
|----------|-------------|------------|---------------|
| Manual Protobuf | Smallest | High | Excellent |
| HTTP/JSON OTLP | Large | Low | Good |
| JSON w/ Protobuf Headers | Large | Low | Limited |
| gRPC-Web | Medium | Medium | Good |
| Custom Binary | Smallest | Medium | Poor |

## Troubleshooting

### Common Issues:

1. **"Unsupported Content-Type"**
   - Check if collector supports your chosen format
   - Verify Content-Type header is correct

2. **"Invalid protobuf data"**
   - Verify manual encoding is correct
   - Check field numbers and wire types

3. **"Endpoint not found"**
   - Confirm endpoint URL format
   - Some collectors use different paths for different formats

### Debug Tips:

1. **Compare with working example**:
   ```bash
   # Capture working protobuf request
   curl -v -X POST https://collector.com/v1/traces \
     -H "Content-Type: application/x-protobuf" \
     --data-binary @working_trace.pb
   ```

2. **Validate binary data**:
   ```swift
   // Log hex dump for comparison
   print("Protobuf hex: \(protobufData.map { String(format: "%02x", $0) }.joined())")
   ```

3. **Test with curl**:
   ```bash
   # Test JSON approach
   curl -X POST https://collector.com/v1/traces \
     -H "Content-Type: application/json" \
     -d @trace.json
   ```

## Migration Path

1. **Phase 1**: Implement manual protobuf encoder alongside existing code
2. **Phase 2**: Test with small percentage of traffic
3. **Phase 3**: Gradually migrate all telemetry
4. **Phase 4**: Remove generated protobuf dependencies

This allows for safe, incremental migration without breaking existing functionality.