import Foundation
import UIKit
import SwiftUI

/// Manages user journey tracking and navigation state
public class JourneyManager: ObservableObject {
    
    // MARK: - Singleton
    public static var shared: JourneyManager?
    
    // MARK: - Properties
    private let configuration: UnisightConfiguration
    private var currentSession: JourneySession
    private let maxScreenHistory = 10
    
    @Published public private(set) var currentScreen: String = ""
    @Published public private(set) var screenHistory: [ScreenTransition] = []
    @Published public private(set) var userPath: [String] = []
    
    // MARK: - Initialization
    
    public init(config: UnisightConfiguration) {
        self.configuration = config
        self.currentSession = JourneySession(id: UUID().uuidString)
        JourneyManager.shared = self
        
        setupNavigationTracking()
    }
    
    // MARK: - Session Management
    
    public func startNewSession(sessionId: String) {
        currentSession = JourneySession(id: sessionId)
        screenHistory.removeAll()
        userPath.removeAll()
        currentScreen = ""
        
        logSessionEvent(.started)
    }
    
    public func endSession() {
        logSessionEvent(.ended)
        currentSession.endTime = Date()
    }
    
    // MARK: - Screen Tracking
    
    public func trackScreenTransition(
        from source: String?,
        to destination: String,
        method: NavigationMethod = .unknown,
        deepLink: String? = nil
    ) {
        let previousScreen = currentScreen.isEmpty ? source : currentScreen
        let timeOnPreviousScreen = calculateTimeOnScreen(previousScreen)
        
        let transition = ScreenTransition(
            from: previousScreen,
            to: destination,
            method: method,
            deepLink: deepLink,
            timestamp: Date(),
            timeOnPreviousScreen: timeOnPreviousScreen
        )
        
        // Update current state
        currentScreen = destination
        screenHistory.append(transition)
        updateUserPath(destination)
        
        // Maintain history size
        if screenHistory.count > maxScreenHistory {
            screenHistory.removeFirst()
        }
        
        // Log the transition
        UnisightTelemetry.shared.logEvent(
            name: "screen_transition",
            category: .navigation,
            attributes: [
                "source_screen": previousScreen ?? "unknown",
                "destination_screen": destination,
                "navigation_method": method.rawValue,
                "deep_link": deepLink ?? "",
                "time_on_previous_screen": timeOnPreviousScreen,
                "screen_path": userPath.suffix(5).joined(separator: " -> ")
            ]
        )
    }
    
    public func trackScreenAppeared(_ screenName: String) {
        if currentScreen != screenName {
            trackScreenTransition(from: currentScreen, to: screenName, method: .appeared)
        }
        
        UnisightTelemetry.shared.logEvent(
            name: "screen_appeared",
            category: .navigation,
            attributes: [
                "screen_name": screenName,
                "screen_path": userPath.suffix(3).joined(separator: " -> ")
            ]
        )
    }
    
    public func trackScreenDisappeared(_ screenName: String) {
        let timeOnScreen = calculateTimeOnScreen(screenName)
        
        UnisightTelemetry.shared.logEvent(
            name: "screen_disappeared",
            category: .navigation,
            attributes: [
                "screen_name": screenName,
                "time_on_screen": timeOnScreen,
                "screen_path": userPath.suffix(3).joined(separator: " -> ")
            ]
        )
    }
    
    // MARK: - User Journey Analysis
    
    public func getCurrentScreenPath() -> [String] {
        return userPath
    }
    
    public func getRecentScreens(count: Int = 5) -> [String] {
        return Array(userPath.suffix(count))
    }
    
    public func getSessionDuration() -> TimeInterval {
        return Date().timeIntervalSince(currentSession.startTime)
    }
    
    public func getTimeOnCurrentScreen() -> TimeInterval {
        return calculateTimeOnScreen(currentScreen)
    }
    
    // MARK: - Private Methods
    
    private func setupNavigationTracking() {
        // For UIKit navigation tracking
        if #available(iOS 13.0, *) {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(viewControllerDidAppear),
                name: NSNotification.Name("ViewControllerDidAppear"),
                object: nil
            )
        }
    }
    
    @objc private func viewControllerDidAppear(_ notification: Notification) {
        if let viewController = notification.object as? UIViewController {
            let screenName = String(describing: type(of: viewController))
            trackScreenAppeared(screenName)
        }
    }
    
    private func updateUserPath(_ screenName: String) {
        userPath.append(screenName)
        
        // Keep path manageable
        if userPath.count > maxScreenHistory {
            userPath.removeFirst()
        }
    }
    
    private func calculateTimeOnScreen(_ screenName: String?) -> TimeInterval {
        guard let screenName = screenName,
              let lastTransition = screenHistory.last(where: { $0.to == screenName }) else {
            return 0
        }
        
        return Date().timeIntervalSince(lastTransition.timestamp)
    }
    
    private func logSessionEvent(_ event: SessionEvent) {
        UnisightTelemetry.shared.logEvent(
            name: "session_\(event.rawValue)",
            category: .system,
            attributes: [
                "session_id": currentSession.id,
                "session_duration": getSessionDuration()
            ]
        )
    }
}

// MARK: - Supporting Models

public struct JourneySession {
    public let id: String
    public let startTime: Date
    public var endTime: Date?
    
    public init(id: String) {
        self.id = id
        self.startTime = Date()
    }
    
    public var duration: TimeInterval {
        return (endTime ?? Date()).timeIntervalSince(startTime)
    }
}

public struct ScreenTransition: Identifiable {
    public let id = UUID()
    public let from: String?
    public let to: String
    public let method: NavigationMethod
    public let deepLink: String?
    public let timestamp: Date
    public let timeOnPreviousScreen: TimeInterval
}

public enum NavigationMethod: String, CaseIterable {
    case push = "push"
    case present = "present"
    case pop = "pop"
    case dismiss = "dismiss"
    case tab = "tab"
    case deepLink = "deep_link"
    case appeared = "appeared"
    case unknown = "unknown"
}

public enum SessionEvent: String {
    case started = "started"
    case ended = "ended"
    case paused = "paused"
    case resumed = "resumed"
}

// MARK: - SwiftUI View Modifiers

@available(iOS 13.0, *)
public extension View {
    /// Track when this view appears
    func trackScreenAppeared(_ screenName: String) -> some View {
        self.onAppear {
            JourneyManager.shared?.trackScreenAppeared(screenName)
        }
    }
    
    /// Track when this view disappears
    func trackScreenDisappeared(_ screenName: String) -> some View {
        self.onDisappear {
            JourneyManager.shared?.trackScreenDisappeared(screenName)
        }
    }
    
    /// Track both appear and disappear events
    func trackScreen(_ screenName: String) -> some View {
        self
            .trackScreenAppeared(screenName)
            .trackScreenDisappeared(screenName)
    }
    
    /// Track navigation destination changes (iOS 16.0+)
    @available(iOS 16.0, *)
    func trackNavigationDestination<D>(
        for data: D.Type,
        destination: @escaping (D) -> some View
    ) -> some View where D: Hashable {
        self.navigationDestination(for: data) { value in
            let destinationName = String(describing: type(of: value))
            return destination(value)
                .trackScreen(destinationName)
        }
    }
}