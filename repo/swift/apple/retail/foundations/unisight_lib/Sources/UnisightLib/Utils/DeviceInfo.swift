import Foundation
import UIKit

/// Utility class for gathering device and app information
public struct DeviceInfo {
    
    // MARK: - Device Information
    
    public static var model: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value))!)
        }
        
        return mapToDevice(identifier: identifier)
    }
    
    public static var osName: String {
        return UIDevice.current.systemName
    }
    
    public static var osVersion: String {
        return UIDevice.current.systemVersion
    }
    
    public static var deviceName: String {
        return UIDevice.current.name
    }
    
    public static var deviceId: String {
        return UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
    }
    
    // MARK: - App Information
    
    public static var appVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    }
    
    public static var buildNumber: String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
    }
    
    public static var bundleIdentifier: String {
        return Bundle.main.bundleIdentifier ?? "unknown"
    }
    
    public static var appName: String {
        return Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ??
               Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "unknown"
    }
    
    // MARK: - Screen Information
    
    public static var screenSize: CGSize {
        return UIScreen.main.bounds.size
    }
    
    public static var screenScale: CGFloat {
        return UIScreen.main.scale
    }
    
    public static var screenBrightness: CGFloat {
        return UIScreen.main.brightness
    }
    
    // MARK: - Locale Information
    
    public static var locale: String {
        return Locale.current.identifier
    }
    
    public static var language: String {
        return Locale.current.languageCode ?? "unknown"
    }
    
    public static var region: String {
        return Locale.current.regionCode ?? "unknown"
    }
    
    public static var timezone: String {
        return TimeZone.current.identifier
    }
    
    // MARK: - Private Methods
    
    private static func mapToDevice(identifier: String) -> String {
        #if os(iOS)
        switch identifier {
        case "iPod5,1":                                       return "iPod Touch 5"
        case "iPod7,1":                                       return "iPod Touch 6"
        case "iPod9,1":                                       return "iPod Touch 7"
        case "iPhone3,1", "iPhone3,2", "iPhone3,3":          return "iPhone 4"
        case "iPhone4,1":                                     return "iPhone 4s"
        case "iPhone5,1", "iPhone5,2":                        return "iPhone 5"
        case "iPhone5,3", "iPhone5,4":                        return "iPhone 5c"
        case "iPhone6,1", "iPhone6,2":                        return "iPhone 5s"
        case "iPhone7,2":                                     return "iPhone 6"
        case "iPhone7,1":                                     return "iPhone 6 Plus"
        case "iPhone8,1":                                     return "iPhone 6s"
        case "iPhone8,2":                                     return "iPhone 6s Plus"
        case "iPhone9,1", "iPhone9,3":                        return "iPhone 7"
        case "iPhone9,2", "iPhone9,4":                        return "iPhone 7 Plus"
        case "iPhone8,4":                                     return "iPhone SE"
        case "iPhone10,1", "iPhone10,4":                      return "iPhone 8"
        case "iPhone10,2", "iPhone10,5":                      return "iPhone 8 Plus"
        case "iPhone10,3", "iPhone10,6":                      return "iPhone X"
        case "iPhone11,2":                                    return "iPhone XS"
        case "iPhone11,4", "iPhone11,6":                      return "iPhone XS Max"
        case "iPhone11,8":                                    return "iPhone XR"
        case "iPhone12,1":                                    return "iPhone 11"
        case "iPhone12,3":                                    return "iPhone 11 Pro"
        case "iPhone12,5":                                    return "iPhone 11 Pro Max"
        case "iPhone12,8":                                    return "iPhone SE (2nd generation)"
        case "iPhone13,1":                                    return "iPhone 12 mini"
        case "iPhone13,2":                                    return "iPhone 12"
        case "iPhone13,3":                                    return "iPhone 12 Pro"
        case "iPhone13,4":                                    return "iPhone 12 Pro Max"
        case "iPhone14,4":                                    return "iPhone 13 mini"
        case "iPhone14,5":                                    return "iPhone 13"
        case "iPhone14,2":                                    return "iPhone 13 Pro"
        case "iPhone14,3":                                    return "iPhone 13 Pro Max"
        case "iPhone14,6":                                    return "iPhone SE (3rd generation)"
        case "iPhone14,7":                                    return "iPhone 14"
        case "iPhone14,8":                                    return "iPhone 14 Plus"
        case "iPhone15,2":                                    return "iPhone 14 Pro"
        case "iPhone15,3":                                    return "iPhone 14 Pro Max"
        case "iPhone15,4":                                    return "iPhone 15"
        case "iPhone15,5":                                    return "iPhone 15 Plus"
        case "iPhone16,1":                                    return "iPhone 15 Pro"
        case "iPhone16,2":                                    return "iPhone 15 Pro Max"
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":     return "iPad 2"
        case "iPad3,1", "iPad3,2", "iPad3,3":                return "iPad 3"
        case "iPad3,4", "iPad3,5", "iPad3,6":                return "iPad 4"
        case "iPad4,1", "iPad4,2", "iPad4,3":                return "iPad Air"
        case "iPad5,3", "iPad5,4":                            return "iPad Air 2"
        case "iPad6,11", "iPad6,12":                          return "iPad 5"
        case "iPad7,5", "iPad7,6":                            return "iPad 6"
        case "iPad11,3", "iPad11,4":                          return "iPad Air 3"
        case "iPad7,11", "iPad7,12":                          return "iPad 7"
        case "iPad11,6", "iPad11,7":                          return "iPad 8"
        case "iPad12,1", "iPad12,2":                          return "iPad 9"
        case "iPad2,5", "iPad2,6", "iPad2,7":                return "iPad Mini"
        case "iPad4,4", "iPad4,5", "iPad4,6":                return "iPad Mini 2"
        case "iPad4,7", "iPad4,8", "iPad4,9":                return "iPad Mini 3"
        case "iPad5,1", "iPad5,2":                            return "iPad Mini 4"
        case "iPad11,1", "iPad11,2":                          return "iPad Mini 5"
        case "iPad14,1", "iPad14,2":                          return "iPad Mini 6"
        case "iPad6,3", "iPad6,4":                            return "iPad Pro 9.7 Inch"
        case "iPad6,7", "iPad6,8":                            return "iPad Pro 12.9 Inch"
        case "iPad7,1", "iPad7,2":                            return "iPad Pro 12.9 Inch 2"
        case "iPad7,3", "iPad7,4":                            return "iPad Pro 10.5 Inch"
        case "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4":     return "iPad Pro 11 Inch"
        case "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8":     return "iPad Pro 12.9 Inch 3"
        case "iPad8,9", "iPad8,10":                           return "iPad Pro 11 Inch 2"
        case "iPad8,11", "iPad8,12":                          return "iPad Pro 12.9 Inch 4"
        case "iPad13,1", "iPad13,2":                          return "iPad Pro 11 Inch 3"
        case "iPad13,4", "iPad13,5", "iPad13,6", "iPad13,7": return "iPad Pro 12.9 Inch 5"
        case "iPad13,8", "iPad13,9", "iPad13,10", "iPad13,11": return "iPad Pro 11 Inch 4"
        case "iPad14,3", "iPad14,4", "iPad14,5", "iPad14,6": return "iPad Pro 12.9 Inch 6"
        case "AppleTV5,3":                                    return "Apple TV"
        case "AppleTV6,2":                                    return "Apple TV 4K"
        case "AudioAccessory1,1":                             return "HomePod"
        case "AudioAccessory5,1":                             return "HomePod mini"
        case "i386", "x86_64":                                return "Simulator \(mapToDevice(identifier: ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "iOS"))"
        default:                                              return identifier
        }
        #elseif os(tvOS)
        switch identifier {
        case "AppleTV5,3": return "Apple TV 4"
        case "AppleTV6,2": return "Apple TV 4K"
        case "i386", "x86_64": return "Simulator \(mapToDevice(identifier: ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "tvOS"))"
        default: return identifier
        }
        #endif
    }
}

/// Network information utilities
public struct NetworkInfo {
    public static var status: String {
        // This is a simplified implementation
        // In a real app, you might want to use Network framework or Reachability
        return "unknown"
    }
    
    public static var connectionType: String {
        return "unknown"
    }
}

/// Memory information utilities
public struct MemoryInfo {
    public static var usage: UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return info.resident_size
        } else {
            return 0
        }
    }
    
    public static var totalMemory: UInt64 {
        return ProcessInfo.processInfo.physicalMemory
    }
}

/// Disk space information utilities
public struct DiskInfo {
    public static var availableSpace: UInt64 {
        do {
            let systemAttributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
            if let freeSpace = systemAttributes[.systemFreeSize] as? NSNumber {
                return freeSpace.uint64Value
            }
        } catch {
            print("Error getting disk space: \(error)")
        }
        return 0
    }
    
    public static var totalSpace: UInt64 {
        do {
            let systemAttributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
            if let totalSpace = systemAttributes[.systemSize] as? NSNumber {
                return totalSpace.uint64Value
            }
        } catch {
            print("Error getting total disk space: \(error)")
        }
        return 0
    }
}

/// App state management utilities
public struct AppStateManager {
    private static var _launchTime = Date()
    private static var _lastActiveTime = Date()
    
    public static var launchTime: Date {
        return _launchTime
    }
    
    public static var lastActiveTime: Date {
        return _lastActiveTime
    }
    
    public static var sessionDuration: TimeInterval {
        return Date().timeIntervalSince(_launchTime)
    }
    
    public static var currentState: String {
        switch UIApplication.shared.applicationState {
        case .active:
            _lastActiveTime = Date()
            return "active"
        case .inactive:
            return "inactive"
        case .background:
            return "background"
        @unknown default:
            return "unknown"
        }
    }
}

/// Installation management utilities
public struct InstallationManager {
    private static let installationIdKey = "UnisightTelemetry.InstallationId"
    private static let firstLaunchKey = "UnisightTelemetry.FirstLaunch"
    private static let sessionCountKey = "UnisightTelemetry.SessionCount"
    private static let installationDateKey = "UnisightTelemetry.InstallationDate"
    
    public static var installationId: String {
        if let existingId = UserDefaults.standard.string(forKey: installationIdKey) {
            return existingId
        }
        
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: installationIdKey)
        return newId
    }
    
    public static var isFirstLaunch: Bool {
        if UserDefaults.standard.object(forKey: firstLaunchKey) == nil {
            UserDefaults.standard.set(false, forKey: firstLaunchKey)
            return true
        }
        return false
    }
    
    public static var sessionCount: Int {
        let count = UserDefaults.standard.integer(forKey: sessionCountKey)
        UserDefaults.standard.set(count + 1, forKey: sessionCountKey)
        return count + 1
    }
    
    public static var installationDate: Date {
        if let date = UserDefaults.standard.object(forKey: installationDateKey) as? Date {
            return date
        }
        let date = Date()
        UserDefaults.standard.set(date, forKey: installationDateKey)
        return date
    }
}