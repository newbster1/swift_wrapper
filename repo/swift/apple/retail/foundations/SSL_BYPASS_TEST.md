# SSL Bypass Testing Guide

## What Was Implemented

### 1. BypassSSLCertificateURLSessionDelegate
- Created a URLSession delegate that bypasses SSL certificate validation
- Only used for testing and development environments
- ⚠️ **WARNING**: Never use in production

### 2. Updated TelemetryExporter
- Added `bypassSSL` parameter to constructor
- Automatically enables SSL bypass when environment is "development"

### 3. Updated Sample App Configuration
- Set environment to "development" to enable SSL bypass
- Updated endpoint to use the actual Apple telemetry endpoint

## How It Works

```swift
// In TelemetryExporter.swift
public init(endpoint: String, headers: [String: String] = [:], bypassSSL: Bool = false) {
    // ...
    if bypassSSL {
        // Use SSL bypass delegate for testing
        let delegate = BypassSSLCertificateURLSessionDelegate()
        self.session = URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
    } else {
        self.session = URLSession(configuration: config)
    }
}

// In UnisightTelemetry.swift
self.telemetryExporter = TelemetryExporter(
    endpoint: config.dispatcherEndpoint,
    headers: config.headers,
    bypassSSL: config.environment == "development" // Enable SSL bypass for development
)
```

## Testing

1. **Build and run the app**
2. **Check console logs** for:
   - `✅ Telemetry initialized successfully`
   - `[UnisightLib] Telemetry data sent successfully. Status: 200` (or similar)

3. **Expected behavior**:
   - No more SSL certificate errors
   - Telemetry data should be sent successfully
   - Console should show successful network requests

## Verification

Look for these log messages:
```
✅ Telemetry initialized successfully
[UnisightLib] Telemetry data sent successfully. Status: 200
```

Instead of:
```
Telemetry export error: Error Domain=NSURLErrorDomain Code=-1202 "The certificate for this server is invalid"
```

## Production Warning

⚠️ **IMPORTANT**: This SSL bypass should ONLY be used for testing. In production:

1. Use proper SSL certificates
2. Set environment to "production"
3. Remove SSL bypass functionality
4. Use proper certificate validation

## Troubleshooting

If SSL bypass is not working:

1. **Check environment setting**: Must be "development"
2. **Clean build folder**: Product → Clean Build Folder
3. **Rebuild the app**: Product → Build
4. **Check console logs**: Look for SSL bypass messages

## Next Steps

Once SSL bypass is working:
1. Test telemetry data flow
2. Verify all events are being sent
3. Check the telemetry endpoint for received data
4. Remove SSL bypass for production deployment