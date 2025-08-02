import Foundation

// MARK: - EventCategory Enum

public enum EventCategory: String, Codable, CaseIterable {
    case user = "user"
    case navigation = "navigation"
    case functional = "functional"
    case system = "system"
    case custom = "custom"
}