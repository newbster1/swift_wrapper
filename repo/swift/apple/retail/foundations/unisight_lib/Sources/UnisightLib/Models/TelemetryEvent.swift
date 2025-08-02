import Foundation
import CoreGraphics

/// Represents a telemetry event with all associated metadata
public struct TelemetryEvent: Codable {
    
    // MARK: - Core Properties
    public let id: String
    public let name: String
    public let category: EventCategory
    public let timestamp: Date
    public let sessionId: String
    
    // MARK: - Context Information
    public let attributes: [String: AnyCodable]
    public let viewContext: ViewContext?
    public let userContext: UserContext?
    public let deviceContext: DeviceContext
    public let appContext: AppContext
    
    // MARK: - Journey Information
    public let screenPath: [String]
    public let previousScreen: String?
    public let timeOnScreen: TimeInterval?
    
    public init(
        name: String,
        category: EventCategory,
        attributes: [String: Any] = [:],
        timestamp: Date = Date(),
        sessionId: String,
        viewContext: ViewContext? = nil,
        userContext: UserContext? = nil,
        previousScreen: String? = nil,
        timeOnScreen: TimeInterval? = nil
    ) {
        self.id = UUID().uuidString
        self.name = name
        self.category = category
        self.timestamp = timestamp
        self.sessionId = sessionId
        self.attributes = attributes.mapValues { AnyCodable($0) }
        self.viewContext = viewContext
        self.userContext = userContext
        self.deviceContext = DeviceContext.current
        self.appContext = AppContext.current
        self.screenPath = JourneyManager.shared?.getCurrentScreenPath() ?? []
        self.previousScreen = previousScreen
        self.timeOnScreen = timeOnScreen
    }
}

// MARK: - Context Models

public struct ViewContext: Codable {
    public let viewName: String
    public let elementIdentifier: String?
    public let elementType: String?
    public let elementLabel: String?
    public let viewHierarchy: [String]
    public let coordinates: CGPoint?
    public let gestureProperties: [String: AnyCodable]?
    public let inputValues: [String: AnyCodable]?
    public let previousState: [String: AnyCodable]?
    public let newState: [String: AnyCodable]?
    
    public init(
        viewName: String,
        elementIdentifier: String? = nil,
        elementType: String? = nil,
        elementLabel: String? = nil,
        viewHierarchy: [String] = [],
        coordinates: CGPoint? = nil,
        gestureProperties: [String: Any]? = nil,
        inputValues: [String: Any]? = nil,
        previousState: [String: Any]? = nil,
        newState: [String: Any]? = nil
    ) {
        self.viewName = viewName
        self.elementIdentifier = elementIdentifier
        self.elementType = elementType
        self.elementLabel = elementLabel
        self.viewHierarchy = viewHierarchy
        self.coordinates = coordinates
        self.gestureProperties = gestureProperties?.mapValues { AnyCodable($0) }
        self.inputValues = inputValues?.mapValues { AnyCodable($0) }
        self.previousState = previousState?.mapValues { AnyCodable($0) }
        self.newState = newState?.mapValues { AnyCodable($0) }
    }
}

public struct UserContext: Codable {
    public let anonymousUserId: String
    public let userSegment: String?
    public let abTestVariants: [String: String]
    public let featureFlags: [String: Bool]
    
    public init(
        anonymousUserId: String,
        userSegment: String? = nil,
        abTestVariants: [String: String] = [:],
        featureFlags: [String: Bool] = [:]
    ) {
        self.anonymousUserId = anonymousUserId
        self.userSegment = userSegment
        self.abTestVariants = abTestVariants
        self.featureFlags = featureFlags
    }
}

public struct DeviceContext: Codable {
    public let deviceModel: String
    public let osVersion: String
    public let appVersion: String
    public let networkStatus: String
    public let batteryLevel: Float
    public let memoryUsage: UInt64
    public let diskSpace: UInt64
    public let screenSize: CGSize
    public let locale: String
    public let timezone: String
    
    static var current: DeviceContext {
        return DeviceContext(
            deviceModel: DeviceInfo.model,
            osVersion: DeviceInfo.osVersion,
            appVersion: DeviceInfo.appVersion,
            networkStatus: NetworkInfo.status,
            batteryLevel: UIDevice.current.batteryLevel,
            memoryUsage: MemoryInfo.usage,
            diskSpace: DiskInfo.availableSpace,
            screenSize: UIScreen.main.bounds.size,
            locale: Locale.current.identifier,
            timezone: TimeZone.current.identifier
        )
    }
}

public struct AppContext: Codable {
    public let appState: String
    public let buildNumber: String
    public let bundleIdentifier: String
    public let installationId: String
    public let launchTime: Date
    public let sessionDuration: TimeInterval
    
    static var current: AppContext {
        return AppContext(
            appState: AppStateManager.currentState,
            buildNumber: DeviceInfo.buildNumber,
            bundleIdentifier: DeviceInfo.bundleIdentifier,
            installationId: InstallationManager.installationId,
            launchTime: AppStateManager.launchTime,
            sessionDuration: AppStateManager.sessionDuration
        )
    }
}

// MARK: - AnyCodable for flexible attribute encoding

public struct AnyCodable: Codable {
    public let value: Any
    
    public init(_ value: Any) {
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue.map { $0.value }
        } else if let dictValue = try? container.decode([String: AnyCodable].self) {
            value = dictValue.mapValues { $0.value }
        } else {
            throw DecodingError.typeMismatch(
                AnyCodable.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Unsupported type"
                )
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let intValue as Int:
            try container.encode(intValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let floatValue as Float:
            try container.encode(floatValue)
        case let stringValue as String:
            try container.encode(stringValue)
        case let boolValue as Bool:
            try container.encode(boolValue)
        case let arrayValue as [Any]:
            try container.encode(arrayValue.map { AnyCodable($0) })
        case let dictValue as [String: Any]:
            try container.encode(dictValue.mapValues { AnyCodable($0) })
        default:
            try container.encode(String(describing: value))
        }
    }
}