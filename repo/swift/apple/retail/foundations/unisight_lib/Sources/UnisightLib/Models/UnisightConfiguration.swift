import Foundation

/// Configuration for the Unisight Telemetry system
public struct UnisightConfiguration {
    
    // MARK: - Service Information
    public let serviceName: String
    public let version: String
    public let environment: String
    
    // MARK: - Dispatcher Configuration
    public let dispatcherEndpoint: String
    public let headers: [String: String]
    
    // MARK: - Event Configuration
    public let events: Set<EventType>
    public let scheme: EventScheme
    public let verbosity: EventVerbosity
    public let processing: EventProcessing
    public let resolveIdentifiers: Bool
    
    // MARK: - Performance Configuration
    public let usesBatchProcessor: Bool
    public let metricsExportInterval: Int // seconds
    public let shouldRecordPayloads: Bool
    public let samplingRate: Double // 0.0 to 1.0
    
    // MARK: - Privacy Configuration
    public let enablePIIRedaction: Bool
    public let customRedactionPatterns: [String]
    
    // MARK: - Custom Processing
    public let customEventProcessor: ((TelemetryEvent) -> Void)?
    
    public init(
        serviceName: String,
        version: String,
        environment: String = "development",
        dispatcherEndpoint: String,
        headers: [String: String] = [:],
        events: Set<EventType> = EventType.defaultEvents,
        scheme: EventScheme = .all,
        verbosity: EventVerbosity = .discrete,
        processing: EventProcessing = .none,
        resolveIdentifiers: Bool = true,
        usesBatchProcessor: Bool = true,
        metricsExportInterval: Int = 30,
        shouldRecordPayloads: Bool = false,
        samplingRate: Double = 1.0,
        enablePIIRedaction: Bool = true,
        customRedactionPatterns: [String] = [],
        customEventProcessor: ((TelemetryEvent) -> Void)? = nil
    ) {
        self.serviceName = serviceName
        self.version = version
        self.environment = environment
        self.dispatcherEndpoint = dispatcherEndpoint
        self.headers = headers
        self.events = events
        self.scheme = scheme
        self.verbosity = verbosity
        self.processing = processing
        self.resolveIdentifiers = resolveIdentifiers
        self.usesBatchProcessor = usesBatchProcessor
        self.metricsExportInterval = metricsExportInterval
        self.shouldRecordPayloads = shouldRecordPayloads
        self.samplingRate = samplingRate
        self.enablePIIRedaction = enablePIIRedaction
        self.customRedactionPatterns = customRedactionPatterns
        self.customEventProcessor = customEventProcessor
    }
}

// MARK: - Event Types

public enum EventType: Hashable {
    case user(UserEventType)
    case screen(ScreenEventType)
    case functional(FunctionalEventType)
    case system(SystemEventType)
    case custom(String)
    
    static var defaultEvents: Set<EventType> {
        return [
            .user(.tap),
            .user(.selection),
            .user(.entry),
            .screen(.navigated),
            .screen(.appeared),
            .screen(.disappeared),
            .functional(.network(.request(.foreground))),
            .functional(.network(.response(.foreground))),
            .system(.foreground),
            .system(.background),
            .system(.battery(0.1))
        ]
    }
}

public enum UserEventType: Hashable {
    case tap
    case swipe(SwipeDirection)
    case rotate
    case pinch
    case pan
    case longPress
    case anyGesture
    case selection
    case entry
    
    public var eventName: String {
        switch self {
        case .tap:
            return "tap"
        case .swipe(let direction):
            return "swipe_\(direction.rawValue)"
        case .rotate:
            return "rotate"
        case .pinch:
            return "pinch"
        case .pan:
            return "pan"
        case .longPress:
            return "long_press"
        case .anyGesture:
            return "gesture"
        case .selection:
            return "selection"
        case .entry:
            return "entry"
        }
    }
}

public enum SwipeDirection: String, CaseIterable, Hashable {
    case left, right, up, down
}

public enum ScreenEventType: Hashable {
    case navigated
    case appeared
    case disappeared
}

public enum FunctionalEventType: Hashable {
    case network(NetworkType)
    case custom
}

public enum NetworkType: Hashable {
    case request(RequestType)
    case response(RequestType)
}

public enum RequestType: String, CaseIterable, Hashable {
    case foreground
    case background
}

public enum SystemEventType: Hashable {
    case foreground
    case background
    case battery(Double)
    case accessibility
    case colorScheme
}

// MARK: - Event Configuration Enums

public enum EventScheme: String, CaseIterable {
    case debug
    case production
    case all
}

public enum EventVerbosity: String, CaseIterable {
    case complete
    case discrete
}

public enum EventProcessing: String, CaseIterable {
    case consolidate
    case none
}

// MARK: - Event Categories

public enum EventCategory: String, CaseIterable {
    case user
    case navigation
    case system
    case functional
    case custom
}