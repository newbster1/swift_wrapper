import Foundation
import UIKit

/// Represents a telemetry event with comprehensive context
public struct TelemetryEvent: Codable {
    // MARK: - Core Properties
    public let id: String
    public let name: String
    public let category: EventCategory
    public let timestamp: Date
    public let sessionId: String
    
    // MARK: - Attributes and Context
    public let attributes: [String: AnyCodable]
    public let viewContext: ViewContext?
    public let userContext: UserContext?
    public let deviceContext: DeviceContext
    public let appContext: AppContext
    
    // MARK: - Navigation Context
    public let screenPath: [String]
    public let previousScreen: String?
    public let timeOnScreen: TimeInterval?
    
    // MARK: - Initialization
    
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

extension TelemetryEvent {
    enum CodingKeys: String, CodingKey {
        case id, name, category, timestamp, sessionId, attributes, viewContext, userContext, deviceContext, appContext, screenPath, previousScreen, timeOnScreen
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.category = try container.decode(EventCategory.self, forKey: .category)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
        self.sessionId = try container.decode(String.self, forKey: .sessionId)
        self.attributes = try container.decode([String: AnyCodable].self, forKey: .attributes)
        self.viewContext = try container.decodeIfPresent(ViewContext.self, forKey: .viewContext)
        self.userContext = try container.decodeIfPresent(UserContext.self, forKey: .userContext)
        self.deviceContext = try container.decodeIfPresent(DeviceContext.self, forKey: .deviceContext) ?? DeviceContext.current
        self.appContext = try container.decodeIfPresent(AppContext.self, forKey: .appContext) ?? AppContext.current
        self.screenPath = try container.decodeIfPresent([String].self, forKey: .screenPath) ?? []
        self.previousScreen = try container.decodeIfPresent(String.self, forKey: .previousScreen)
        self.timeOnScreen = try container.decodeIfPresent(TimeInterval.self, forKey: .timeOnScreen)
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
    
    public init(
        deviceModel: String,
        osVersion: String,
        appVersion: String,
        networkStatus: String,
        batteryLevel: Float,
        memoryUsage: UInt64,
        diskSpace: UInt64,
        screenSize: CGSize,
        locale: String,
        timezone: String
    ) {
        self.deviceModel = deviceModel
        self.osVersion = osVersion
        self.appVersion = appVersion
        self.networkStatus = networkStatus
        self.batteryLevel = batteryLevel
        self.memoryUsage = memoryUsage
        self.diskSpace = diskSpace
        self.screenSize = screenSize
        self.locale = locale
        self.timezone = timezone
    }
}

public struct AppContext: Codable {
    public let appState: String
    public let isFirstLaunch: Bool
    public let sessionCount: Int
    public let lastActiveTime: Date
    public let installationDate: Date
    
    static var current: AppContext {
        return AppContext(
            appState: AppStateManager.currentState,
            isFirstLaunch: InstallationManager.isFirstLaunch,
            sessionCount: InstallationManager.sessionCount,
            lastActiveTime: AppStateManager.lastActiveTime,
            installationDate: InstallationManager.installationDate
        )
    }
    
    public init(
        appState: String,
        isFirstLaunch: Bool,
        sessionCount: Int,
        lastActiveTime: Date,
        installationDate: Date
    ) {
        self.appState = appState
        self.isFirstLaunch = isFirstLaunch
        self.sessionCount = sessionCount
        self.lastActiveTime = lastActiveTime
        self.installationDate = installationDate
    }
}

// MARK: - AnyCodable for flexible attribute values

public struct AnyCodable: Codable {
    public let value: Any
    
    public init(_ value: Any) {
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self.value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            self.value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            self.value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable value cannot be decoded")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self.value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            let context = EncodingError.Context(codingPath: container.codingPath, debugDescription: "AnyCodable value cannot be encoded")
            throw EncodingError.invalidValue(self.value, context)
        }
    }
}

