import SwiftUI
import UIKit

/// SwiftUI view modifiers for tracking user gestures and interactions
@available(iOS 13.0, *)
public extension View {
    
    // MARK: - Tap Gesture Tracking
    
    /// Track tap gestures on this view
    func trackTapGesture(
        viewName: String,
        elementId: String? = nil,
        elementType: String? = nil,
        onTap: (() -> Void)? = nil
    ) -> some View {
        self.onTapGesture {
            trackUserInteraction(
                type: .tap,
                viewName: viewName,
                elementId: elementId,
                elementType: elementType
            )
            onTap?()
        }
    }
    
    /// Track tap gesture with coordinate tracking
    func trackTapGestureWithLocation(
        viewName: String,
        elementId: String? = nil,
        elementType: String? = nil,
        onTap: ((CGPoint) -> Void)? = nil
    ) -> some View {
        self.gesture(
            DragGesture(minimumDistance: 0)
                .onEnded { value in
                    trackUserInteraction(
                        type: .tap,
                        viewName: viewName,
                        elementId: elementId,
                        elementType: elementType,
                        coordinates: value.location
                    )
                    onTap?(value.location)
                }
        )
    }
    
    // MARK: - Long Press Tracking
    
    /// Track long press gestures
    func trackLongPressGesture(
        viewName: String,
        elementId: String? = nil,
        minimumDuration: Double = 0.5,
        onLongPress: (() -> Void)? = nil
    ) -> some View {
        self.onLongPressGesture(minimumDuration: minimumDuration) {
            trackUserInteraction(
                type: .longPress,
                viewName: viewName,
                elementId: elementId,
                gestureProperties: ["duration": minimumDuration]
            )
            onLongPress?()
        }
    }
    
    // MARK: - Drag/Pan Tracking
    
    /// Track drag/pan gestures
    func trackDragGesture(
        viewName: String,
        elementId: String? = nil,
        onDragEnded: ((DragGesture.Value) -> Void)? = nil
    ) -> some View {
        self.gesture(
            DragGesture()
                .onEnded { value in
                    trackUserInteraction(
                        type: .pan,
                        viewName: viewName,
                        elementId: elementId,
                        coordinates: value.location,
                        gestureProperties: [
                            "start_location": "\(value.startLocation.x),\(value.startLocation.y)",
                            "end_location": "\(value.location.x),\(value.location.y)",
                            "translation": "\(value.translation.x),\(value.translation.y)",
                            "velocity": "\(value.velocity.x),\(value.velocity.y)"
                        ]
                    )
                    onDragEnded?(value)
                }
        )
    }
    
    // MARK: - Magnification/Pinch Tracking
    
    /// Track magnification/pinch gestures
    func trackMagnificationGesture(
        viewName: String,
        elementId: String? = nil,
        onMagnificationEnded: ((MagnificationGesture.Value) -> Void)? = nil
    ) -> some View {
        self.gesture(
            MagnificationGesture()
                .onEnded { value in
                    trackUserInteraction(
                        type: .pinch,
                        viewName: viewName,
                        elementId: elementId,
                        gestureProperties: [
                            "magnification": value
                        ]
                    )
                    onMagnificationEnded?(value)
                }
        )
    }
    
    // MARK: - Rotation Tracking
    
    /// Track rotation gestures
    func trackRotationGesture(
        viewName: String,
        elementId: String? = nil,
        onRotationEnded: ((RotationGesture.Value) -> Void)? = nil
    ) -> some View {
        self.gesture(
            RotationGesture()
                .onEnded { value in
                    trackUserInteraction(
                        type: .rotate,
                        viewName: viewName,
                        elementId: elementId,
                        gestureProperties: [
                            "rotation_radians": value.radians,
                            "rotation_degrees": value.degrees
                        ]
                    )
                    onRotationEnded?(value)
                }
        )
    }
    
    // MARK: - Text Input Tracking
    
    /// Track text field changes
    func trackTextInput<T: Equatable>(
        viewName: String,
        elementId: String? = nil,
        value: T,
        onChanged: ((T) -> Void)? = nil
    ) -> some View {
        self.onChange(of: value) { oldValue, newValue in
            trackUserInteraction(
                type: .entry,
                viewName: viewName,
                elementId: elementId,
                inputValues: [
                    "old_value": String(describing: oldValue),
                    "new_value": String(describing: newValue)
                ]
            )
            onChanged?(newValue)
        }
    }
    
    // MARK: - Selection Tracking
    
    /// Track selection changes (for pickers, toggles, etc.)
    func trackSelection<T: Equatable>(
        viewName: String,
        elementId: String? = nil,
        selection: T,
        onSelectionChanged: ((T) -> Void)? = nil
    ) -> some View {
        self.onChange(of: selection) { oldValue, newValue in
            trackUserInteraction(
                type: .selection,
                viewName: viewName,
                elementId: elementId,
                inputValues: [
                    "previous_selection": String(describing: oldValue),
                    "new_selection": String(describing: newValue)
                ]
            )
            onSelectionChanged?(newValue)
        }
    }
    
    // MARK: - Button Tracking
    
    /// Track button presses with enhanced context
    func trackButtonPress(
        viewName: String,
        buttonId: String,
        buttonLabel: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            trackUserInteraction(
                type: .tap,
                viewName: viewName,
                elementId: buttonId,
                elementType: "Button",
                elementLabel: buttonLabel
            )
            action()
        }) {
            self
        }
    }
    
    // MARK: - Generic Any Gesture Tracking
    
    /// Track any gesture type
    func trackAnyGesture(
        viewName: String,
        elementId: String? = nil,
        gestureTypes: [UserEventType] = [.tap, .longPress, .swipe(.left), .pinch, .rotation]
    ) -> some View {
        var gestures: [AnyGesture] = []
        
        if gestureTypes.contains(.tap) {
            gestures.append(
                AnyGesture(
                    TapGesture()
                        .onEnded { _ in
                            trackUserInteraction(type: .tap, viewName: viewName, elementId: elementId)
                        }
                )
            )
        }
        
        if gestureTypes.contains(.longPress) {
            gestures.append(
                AnyGesture(
                    LongPressGesture()
                        .onEnded { _ in
                            trackUserInteraction(type: .longPress, viewName: viewName, elementId: elementId)
                        }
                )
            )
        }
        
        if gestureTypes.contains(.swipe(.left)) {
            gestures.append(
                AnyGesture(
                    DragGesture()
                        .onEnded { value in
                            trackUserInteraction(
                                type: .swipe(.left),
                                viewName: viewName,
                                elementId: elementId,
                                coordinates: value.location
                            )
                        }
                )
            )
        }
        
        return self.gesture(
            gestures.reduce(AnyGesture(TapGesture().onEnded { _ in })) { result, gesture in
                AnyGesture(result.exclusively(before: gesture))
            }
        )
    }
    
    // MARK: - View State Tracking
    
    /// Track view state changes
    func trackViewState<T: Equatable>(
        viewName: String,
        state: T,
        onStateChanged: ((T, T) -> Void)? = nil
    ) -> some View {
        self.onChange(of: state) { oldValue, newValue in
            UnisightTelemetry.shared.logEvent(
                name: "view_state_changed",
                category: .user,
                attributes: [
                    "view_name": viewName,
                    "previous_state": String(describing: oldValue),
                    "new_state": String(describing: newValue)
                ]
            )
            onStateChanged?(oldValue, newValue)
        }
    }
    
    // MARK: - Accessibility Tracking
    
    /// Track accessibility actions
    func trackAccessibilityAction(
        viewName: String,
        elementId: String? = nil,
        actionName: String,
        action: @escaping () -> Void
    ) -> some View {
        self.accessibilityAction(named: actionName) {
            trackUserInteraction(
                type: .tap,
                viewName: viewName,
                elementId: elementId,
                elementType: "AccessibilityAction",
                elementLabel: actionName,
                gestureProperties: ["accessibility_action": actionName]
            )
            action()
        }
    }
}

// MARK: - Private Helper Functions

@available(iOS 13.0, *)
extension View {
    private func trackUserInteraction(
        type: UserEventType,
        viewName: String,
        elementId: String? = nil,
        elementType: String? = nil,
        elementLabel: String? = nil,
        coordinates: CGPoint? = nil,
        gestureProperties: [String: Any]? = nil,
        inputValues: [String: Any]? = nil
    ) {
        let viewContext = ViewContext(
            viewName: viewName,
            elementIdentifier: elementId,
            elementType: elementType,
            elementLabel: elementLabel,
            coordinates: coordinates,
            gestureProperties: gestureProperties,
            inputValues: inputValues
        )
        
        let eventName = "user_\(type.userEventName)"
        
        UnisightTelemetry.shared.logEvent(
            name: eventName,
            category: .user,
            attributes: [
                "interaction_type": type.userEventName,
                "view_name": viewName,
                "element_id": elementId ?? "",
                "element_type": elementType ?? "",
                "element_label": elementLabel ?? ""
            ],
            viewContext: viewContext
        )
    }
}



// MARK: - Custom Gesture Recognizer Wrapper

@available(iOS 13.0, *)
public struct GestureTrackingWrapper<Content: View>: UIViewRepresentable {
    let content: Content
    let viewName: String
    let elementId: String?
    let gestureTypes: [UserEventType]
    
    public init(
        content: Content,
        viewName: String,
        elementId: String? = nil,
        gestureTypes: [UserEventType] = [.tap]
    ) {
        self.content = content
        self.viewName = viewName
        self.elementId = elementId
        self.gestureTypes = gestureTypes
    }
    
    public func makeUIView(context: Context) -> UIView {
        let hostingController = UIHostingController(rootView: content)
        let view = hostingController.view!
        
        // Add gesture recognizers based on types
        for gestureType in gestureTypes {
            switch gestureType {
            case .tap:
                let tapGesture = UITapGestureRecognizer(
                    target: context.coordinator,
                    action: #selector(Coordinator.handleTap(_:))
                )
                view.addGestureRecognizer(tapGesture)
                
            case .longPress:
                let longPressGesture = UILongPressGestureRecognizer(
                    target: context.coordinator,
                    action: #selector(Coordinator.handleLongPress(_:))
                )
                view.addGestureRecognizer(longPressGesture)
                
            case .swipe(let direction):
                let swipeGesture = UISwipeGestureRecognizer(
                    target: context.coordinator,
                    action: #selector(Coordinator.handleSwipe(_:))
                )
                swipeGesture.direction = direction.uiSwipeDirection
                view.addGestureRecognizer(swipeGesture)
                
            case .pinch:
                let pinchGesture = UIPinchGestureRecognizer(
                    target: context.coordinator,
                    action: #selector(Coordinator.handlePinch(_:))
                )
                view.addGestureRecognizer(pinchGesture)
                
            case .rotation:
                let rotationGesture = UIRotationGestureRecognizer(
                    target: context.coordinator,
                    action: #selector(Coordinator.handleRotation(_:))
                )
                view.addGestureRecognizer(rotationGesture)
                
            default:
                break
            }
        }
        
        return view
    }
    
    public func updateUIView(_ uiView: UIView, context: Context) {
        // Update the hosting controller's root view
        if let hostingController = context.coordinator.hostingController {
            hostingController.rootView = content
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator(viewName: viewName, elementId: elementId)
        coordinator.hostingController = UIHostingController(rootView: content)
        return coordinator
    }
    
    public class Coordinator: NSObject {
        let viewName: String
        let elementId: String?
        var hostingController: UIHostingController<Content>?
        
        init(viewName: String, elementId: String?) {
            self.viewName = viewName
            self.elementId = elementId
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            let location = gesture.location(in: gesture.view)
            trackGesture(.tap, location: location)
        }
        
        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            guard gesture.state == .began else { return }
            let location = gesture.location(in: gesture.view)
            trackGesture(.longPress, location: location)
        }
        
        @objc func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
            let location = gesture.location(in: gesture.view)
            let direction = SwipeDirection.from(uiDirection: gesture.direction)
            trackGesture(.swipe(direction), location: location)
        }
        
        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard gesture.state == .ended else { return }
            let location = gesture.location(in: gesture.view)
            trackGesture(.pinch, location: location, properties: [
                "scale": gesture.scale,
                "velocity": gesture.velocity
            ])
        }
        
        @objc func handleRotation(_ gesture: UIRotationGestureRecognizer) {
            guard gesture.state == .ended else { return }
            let location = gesture.location(in: gesture.view)
            trackGesture(.rotation, location: location, properties: [
                "rotation": gesture.rotation,
                "velocity": gesture.velocity
            ])
        }
        
        private func trackGesture(
            _ type: UserEventType,
            location: CGPoint,
            properties: [String: Any] = [:]
        ) {
            let viewContext = ViewContext(
                viewName: viewName,
                elementIdentifier: elementId,
                coordinates: location,
                gestureProperties: properties
            )
            
            UnisightTelemetry.shared.logEvent(
                name: "user_\(type.userEventName)",
                category: .user,
                viewContext: viewContext
            )
        }
    }
}

// MARK: - SwipeDirection Extensions

extension SwipeDirection {
    var uiSwipeDirection: UISwipeGestureRecognizer.Direction {
        switch self {
        case .left: return .left
        case .right: return .right
        case .up: return .up
        case .down: return .down
        }
    }
    
    static func from(uiDirection: UISwipeGestureRecognizer.Direction) -> SwipeDirection {
        switch uiDirection {
        case .left: return .left
        case .right: return .right
        case .up: return .up
        case .down: return .down
        default: return .left
        }
    }
}