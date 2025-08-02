import Foundation
import UIKit

/// Extensions to provide device information for the sample app
struct DeviceInfo {
    static var model: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value))!)
        }
        
        return identifier.isEmpty ? "Unknown" : identifier
    }
    
    static var osVersion: String {
        return UIDevice.current.systemVersion
    }
    
    static var appVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
}