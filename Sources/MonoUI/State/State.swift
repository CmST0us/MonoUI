// MARK: - ObservableObject Protocol

/// A protocol for objects that can be observed for changes.
/// Similar to SwiftUI's ObservableObject.
public protocol ObservableObject: AnyObject {
    /// Called when the object's state changes.
    /// Implementations should call this to notify observers.
    func objectWillChange()
}

// MARK: - ObservableObjectPublisher

/// A publisher that manages change notifications for ObservableObject.
public class ObservableObjectPublisher {
    private var observers: [() -> Void] = []
    
    /// Subscribes to change notifications.
    /// - Parameter handler: The closure to call when changes occur.
    public func subscribe(_ handler: @escaping () -> Void) {
        observers.append(handler)
    }
    
    /// Notifies all subscribers of a change.
    public func send() {
        for observer in observers {
            observer()
        }
    }
    
    /// Removes all observers.
    public func removeAll() {
        observers.removeAll()
    }
}

// MARK: - State Property Wrapper

/// A property wrapper that manages local state for a view.
/// Similar to SwiftUI's @State.
///
/// When the wrapped value changes, the view will be marked for update.
///
/// Example:
/// ```swift
/// class MyView: View {
///     @State var count: Int = 0
///     
///     func increment() {
///         count += 1  // This will trigger a view update
///     }
/// }
/// ```
@propertyWrapper
public class State<T> {
    private var value: T
    private var updateHandler: (() -> Void)?
    
    /// Initializes the state with a wrapped value.
    /// - Parameter wrappedValue: The initial value.
    public init(wrappedValue: T) {
        self.value = wrappedValue
    }
    
    /// The wrapped value. Setting this triggers a view update.
    public var wrappedValue: T {
        get { value }
        set {
            value = newValue
            updateHandler?()
        }
    }
    
    /// Projects the State instance itself for advanced usage.
    public var projectedValue: State<T> {
        return self
    }
    
    /// Sets the update handler that will be called when the value changes.
    /// - Parameter handler: The closure to call on value change.
    public func setUpdateHandler(_ handler: @escaping () -> Void) {
        self.updateHandler = handler
    }
}

// MARK: - StateObject Property Wrapper

/// A property wrapper that creates and manages an ObservableObject instance.
/// Similar to SwiftUI's @StateObject.
///
/// The object is created once and owned by the view.
///
/// Example:
/// ```swift
/// class MyViewModel: ObservableObject {
///     @Published var name: String = "Hello"
/// }
///
/// class MyView: View {
///     @StateObject var viewModel = MyViewModel()
/// }
/// ```
@propertyWrapper
public class StateObject<T: ObservableObject> {
    private var value: T?
    private var factory: () -> T
    private var updateHandler: (() -> Void)?
    
    /// Initializes the state object with a factory closure.
    /// - Parameter wrappedValue: A closure that creates the object.
    public init(wrappedValue: @autoclosure @escaping () -> T) {
        self.factory = wrappedValue
    }
    
    /// The wrapped object. The object is created on first access.
    public var wrappedValue: T {
        if value == nil {
            value = factory()
            // Set up observation if the object supports it
            // Note: T already conforms to ObservableObject, so no need to check
        }
        return value!
    }
    
    /// Projects the StateObject instance itself.
    public var projectedValue: StateObject<T> {
        return self
    }
    
    /// Sets the update handler that will be called when the object changes.
    /// - Parameter handler: The closure to call on object change.
    internal func setUpdateHandler(_ handler: @escaping () -> Void) {
        self.updateHandler = handler
        // Subscribe to object changes
        // Note: T already conforms to ObservableObject, so we can integrate with its notification system
        if value != nil {
            // We'll need to integrate with ObservableObject's notification system
        }
    }
}

// MARK: - ObservedObject Property Wrapper

/// A property wrapper that observes an ObservableObject from outside the view.
/// Similar to SwiftUI's @ObservedObject.
///
/// The object is not owned by the view, but the view will update when it changes.
///
/// Example:
/// ```swift
/// class MyView: View {
///     @ObservedObject var viewModel: MyViewModel
///     
///     init(viewModel: MyViewModel) {
///         self._viewModel = ObservedObject(wrappedValue: viewModel)
///     }
/// }
/// ```
@propertyWrapper
public class ObservedObject<T: ObservableObject> {
    private var value: T
    private var updateHandler: (() -> Void)?
    private var subscription: Any?
    
    /// Initializes the observed object.
    /// - Parameter wrappedValue: The object to observe.
    public init(wrappedValue: T) {
        self.value = wrappedValue
    }
    
    /// The wrapped object.
    public var wrappedValue: T {
        get { value }
        set {
            value = newValue
            // Re-subscribe to the new object
            setupObservation()
        }
    }
    
    /// Projects the ObservedObject instance itself.
    public var projectedValue: ObservedObject<T> {
        return self
    }
    
    /// Sets the update handler that will be called when the object changes.
    /// - Parameter handler: The closure to call on object change.
    internal func setUpdateHandler(_ handler: @escaping () -> Void) {
        self.updateHandler = handler
        setupObservation()
    }
    
    private func setupObservation() {
        // Subscribe to object changes
        // This will be implemented when we integrate with the view update system
    }
}

// MARK: - Published Property Wrapper

/// A property wrapper that publishes changes to an ObservableObject.
/// Similar to SwiftUI's @Published.
///
/// Example:
/// ```swift
/// class MyViewModel: ObservableObject {
///     @Published var count: Int = 0
///     
///     func objectWillChange() {
///         // Notify observers
///     }
/// }
/// ```
@propertyWrapper
public class Published<T> {
    private var value: T
    private weak var owner: ObservableObject?
    
    /// Initializes the published property with a wrapped value.
    /// - Parameter wrappedValue: The initial value.
    public init(wrappedValue: T) {
        self.value = wrappedValue
    }
    
    /// The wrapped value. Setting this notifies the owner object.
    public var wrappedValue: T {
        get { value }
        set {
            value = newValue
            owner?.objectWillChange()
        }
    }
    
    /// Projects the Published instance itself.
    public var projectedValue: Published<T> {
        return self
    }
    
    /// Sets the owner object that will be notified of changes.
    /// This is called automatically when the property is accessed in an ObservableObject.
    /// - Parameter owner: The ObservableObject that owns this property.
    internal func setOwner(_ owner: ObservableObject) {
        self.owner = owner
    }
}

// MARK: - ObservableObject Default Implementation

/// Default implementation for ObservableObject that uses a publisher.
extension ObservableObject {
    /// Default implementation that does nothing.
    /// Subclasses should override this to notify observers.
    public func objectWillChange() {
        // Default implementation - subclasses should override
    }
}

