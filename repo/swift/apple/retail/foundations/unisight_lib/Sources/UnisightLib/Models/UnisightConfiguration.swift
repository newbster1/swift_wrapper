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
    
    public static var defaultEvents: Set<EventType> {
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
    case doubleTap
    case longPress
    case swipe(SwipeDirection)
    case selection
    case entry
    case exit
    case scroll
    case pinch
    case rotation
    case custom(String)
    
    var userEventName: String {
        switch self {
        case .tap:
            return "tap"
        case .doubleTap:
            return "double_tap"
        case .longPress:
            return "long_press"
        case .swipe(let direction):
            return "swipe_\(direction.rawValue)"
        case .selection:
            return "selection"
        case .entry:
            return "entry"
        case .exit:
            return "exit"
        case .scroll:
            return "scroll"
        case .pinch:
            return "pinch"
        case .rotation:
            return "rotation"
        case .custom(let name):
            return name
        }
    }
}

public enum SwipeDirection: String, CaseIterable {
    case up = "up"
    case down = "down"
    case left = "left"
    case right = "right"
}

public enum ScreenEventType: Hashable {
    case appeared
    case disappeared
    case navigated
    case refreshed
    case error
    case custom(String)
}

public enum FunctionalEventType: Hashable {
    case network(NetworkEventType)
    case database(DatabaseEventType)
    case cache(CacheEventType)
    case api(APIEventType)
    case custom(String)
}

public enum NetworkEventType: Hashable {
    case request(RequestType)
    case response(RequestType)
    case error(RequestType)
    case timeout(RequestType)
}

public enum RequestType: String, CaseIterable {
    case foreground = "foreground"
    case background = "background"
    case critical = "critical"
}

public enum DatabaseEventType: Hashable {
    case read
    case write
    case delete
    case query
    case transaction
}

public enum CacheEventType: Hashable {
    case hit
    case miss
    case set
    case delete
    case clear
}

public enum APIEventType: Hashable {
    case call
    case response
    case error
    case timeout
}

public enum SystemEventType: Hashable {
    case foreground
    case background
    case terminate
    case memoryWarning
    case battery(Float)
    case networkChange
    case accessibilityChange
    case custom(String)
    
    var systemEventName: String {
        switch self {
        case .foreground:
            return "foreground"
        case .background:
            return "background"
        case .terminate:
            return "terminate"
        case .memoryWarning:
            return "memory_warning"
        case .battery:
            return "battery"
        case .networkChange:
            return "network_change"
        case .accessibilityChange:
            return "accessibility_change"
        case .custom(let name):
            return name
        }
    }
}

// MARK: - Configuration Enums

public enum EventScheme: String, CaseIterable {
    case debug = "debug"
    case production = "production"
    case all = "all"
}

public enum EventVerbosity: String, CaseIterable {
    case minimal = "minimal"
    case discrete = "discrete"
    case verbose = "verbose"
    case debug = "debug"
}

public enum EventProcessing: String, CaseIterable {
    case none = "none"
    case consolidate = "consolidate"
    case batch = "batch"
}

