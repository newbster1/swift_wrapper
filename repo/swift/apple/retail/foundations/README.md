# UnisightLib - Swift Telemetry Wrapper for iOS

A comprehensive Swift telemetry library that provides journey tracking and observability features for iOS applications. Built on top of OpenTelemetry, it sends data in OTLP format to configurable dispatcher endpoints.

## 🚀 Features

- **User Interaction Tracking**: Comprehensive gesture and tap tracking
- **Navigation Monitoring**: Screen transitions and user journey analysis
- **System Event Monitoring**: App lifecycle, battery, accessibility changes
- **Network Request Instrumentation**: Automatic HTTP request tracking
- **Custom Event Logging**: Rich context and metadata support
- **OTLP-Compliant Export**: Standards-based telemetry data format
- **Privacy-Focused**: Built-in PII redaction and data anonymization
- **Configurable Sampling**: Control data collection and performance impact
- **SwiftUI Integration**: Easy-to-use view modifiers and extensions

## 📁 Repository Structure

```
repo/swift/apple/retail/foundations/
├── unisight_lib/           # Main telemetry library
│   ├── Package.swift       # Swift Package Manager configuration
│   └── Sources/
│       └── UnisightLib/
│           ├── UnisightTelemetry.swift      # Main telemetry class
│           ├── Models/                      # Data models
│           ├── Core/                        # Core functionality
│           ├── Utils/                       # Utility classes
│           └── SwiftUI/                     # SwiftUI extensions
└── sample_app/             # Demo iOS application
    ├── UnisightSampleApp.xcodeproj/
    └── UnisightSampleApp/
        ├── UnisightSampleAppApp.swift       # Main app file
        ├── ContentView.swift                # Main content view
        ├── ProductListView.swift            # Product listing
        ├── ProductDetailView.swift          # Product details
        ├── SettingsView.swift               # Settings and preferences
        ├── TelemetryService.swift           # Telemetry integration
        └── Info.plist                       # App configuration
```

## 🛠 Installation

### Swift Package Manager

Add the following dependency to your `Package.swift`:

```swift
dependencies: [
    .package(path: "../unisight_lib")
]
```

Or in Xcode:
1. File → Add Package Dependencies
2. Enter the local path to `unisight_lib`
3. Add `UnisightLib` to your target

## 🔧 Quick Start

### 1. Initialize the Library

```swift
import UnisightLib

// Simple initialization
try UnisightLib.initialize(
    serviceName: "MyRetailApp",
    version: "1.0.0",
    dispatcherEndpoint: "https://ref-tel-dis-dev.kbusw2a.shld.apple.com/otlp/v1/metrics"
)

// Or with custom configuration
let config = UnisightLib.retailConfiguration(
    appName: "MyRetailApp",
    version: "1.0.0",
    dispatcherEndpoint: "https://your-dispatcher.com/otlp/v1/metrics"
)
try UnisightLib.initialize(with: config)
```

### 2. Track Events

```swift
// Log custom events
UnisightTelemetry.shared.logEvent(
    name: "user_action",
    category: .user,
    attributes: ["action": "button_press"]
)

// Log user interactions
UnisightTelemetry.shared.logUserInteraction(
    .tap,
    viewName: "ProductList",
    elementId: "addToCart"
)

// Log navigation
UnisightTelemetry.shared.logNavigation(
    from: "ProductList",
    to: "ProductDetail"
)
```

### 3. SwiftUI Integration

```swift
import SwiftUI
import UnisightLib

struct ContentView: View {
    var body: some View {
        Button("Add to Cart") {
            // Handle action
        }
        .trackTapGesture(
            viewName: "ProductView",
            elementId: "addToCartButton"
        )
        .trackScreen("ProductView")
    }
}
```

## 📊 JourneyKit Compatibility

UnisightLib supports all JourneyKit requirements:

### Event Types Supported

- **User Events**: `.tap`, `.swipe()`, `.rotate`, `.pinch`, `.pan`, `.longPress`, `.selection`, `.entry`
- **Screen Events**: `.navigated`, `.appeared`, `.disappeared`
- **Functional Events**: `.network()`, `.custom`
- **System Events**: `.foreground`, `.background`, `.battery()`, `.accessibility`, `.colorScheme`

### Configuration Options

```swift
let config = UnisightConfiguration(
    serviceName: "MyApp",
    version: "1.0.0",
    dispatcherEndpoint: "https://your-endpoint.com/otlp/v1/metrics",
    events: [.user(.tap), .screen(.navigated), .system(.battery(0.1))],
    scheme: .production,           // .debug, .production, .all
    verbosity: .discrete,          // .complete, .discrete
    processing: .consolidate,      // .consolidate, .none
    resolveIdentifiers: true,
    samplingRate: 1.0,
    enablePIIRedaction: true
)
```

## 🎯 Sample App

The included sample app demonstrates:

- **Product Catalog**: Browse and search products with telemetry tracking
- **User Interactions**: Tap, swipe, and gesture tracking
- **Navigation Tracking**: Screen transitions and user journey analysis
- **Settings Integration**: Telemetry controls and privacy settings
- **Network Monitoring**: API call tracking and performance metrics

### Running the Sample App

1. Open `sample_app/UnisightSampleApp.xcodeproj` in Xcode
2. Build and run the project
3. Observe telemetry events in the console
4. Explore different app features to see comprehensive tracking

## 🔒 Privacy & Security

- **Certificate Bypass**: Development configuration bypasses SSL validation
- **PII Redaction**: Automatic detection and redaction of sensitive data
- **Anonymous Tracking**: No personal information collection
- **Opt-out Support**: Users can disable telemetry collection
- **Data Encryption**: All data encrypted in transit

## 📈 Advanced Features

### Custom Event Processing

```swift
let config = UnisightConfiguration(
    // ... other settings
    customEventProcessor: { event in
        // Custom processing logic
        print("Processing event: \(event.name)")
    }
)
```

### Journey Analysis

```swift
let journeyManager = UnisightTelemetry.shared.getJourneyManager()

// Get current user path
let screenPath = journeyManager.getCurrentScreenPath()

// Get session duration
let duration = journeyManager.getSessionDuration()

// Get time on current screen
let timeOnScreen = journeyManager.getTimeOnCurrentScreen()
```

### Performance Monitoring

```swift
// Create spans for performance tracking
let span = UnisightTelemetry.shared.createSpan(
    name: "api_call",
    kind: .client,
    attributes: ["endpoint": "/api/products"]
)

// Perform operation
performAPICall()

// End span
span.end()
```

## 🌐 OTLP Integration

The library exports data in OpenTelemetry Protocol (OTLP) format:

- **Traces**: User interactions and application flows
- **Metrics**: Performance counters and business metrics
- **Logs**: Application events and error reporting

### Dispatcher Endpoint

Configure your dispatcher endpoint:
```
https://ref-tel-dis-dev.kbusw2a.shld.apple.com/otlp/v1/metrics
```

## 🧪 Development Setup

### Requirements

- iOS 14.0+
- Xcode 15.0+
- Swift 5.9+

### Building the Library

```bash
cd unisight_lib
swift build
swift test
```

### Development Configuration

For development environments, the library includes:
- Certificate validation bypass
- Debug logging
- Console output for events
- Immediate export (no batching)

## 📚 API Reference

### Core Classes

- `UnisightTelemetry`: Main telemetry interface
- `UnisightConfiguration`: Configuration management
- `JourneyManager`: User journey tracking
- `EventProcessor`: Event processing and filtering
- `TelemetryExporter`: OTLP data export

### SwiftUI Extensions

- `.trackTapGesture()`: Track tap interactions
- `.trackScreen()`: Track screen appearances
- `.trackTextInput()`: Track text input changes
- `.trackSelection()`: Track selection changes

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🔗 Related Projects

- [OpenTelemetry Swift](https://github.com/open-telemetry/opentelemetry-swift)
- [Swift Distributed Tracing](https://github.com/apple/swift-distributed-tracing)
- [Swift Metrics](https://github.com/apple/swift-metrics)

## 📞 Support

For questions and support:
- Review the sample app implementation
- Check the inline documentation
- Create an issue for bugs or feature requests

---

**UnisightLib** - Comprehensive iOS telemetry for retail applications 📱📊