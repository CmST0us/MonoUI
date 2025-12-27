#if canImport(Glibc)
import Glibc
#elseif canImport(Darwin)
import Darwin
#endif

// MARK: - Animatable Protocol

/// A protocol that defines types that can be animated with smooth interpolation.
///
/// Types conforming to this protocol can be used with `AnimationValue` property wrapper
/// to automatically interpolate between values.
public protocol Animatable: Equatable {
    /// The zero value for this type.
    static var zero: Self { get }
    
    /// Subtracts two values and returns their difference.
    static func - (lhs: Self, rhs: Self) -> Self
    
    /// Adds two values and returns their sum.
    static func + (lhs: Self, rhs: Self) -> Self
    
    /// Scales this value by a factor.
    /// - Parameter factor: The scaling factor to apply.
    /// - Returns: A new value scaled by the factor.
    func scaled(by factor: Double) -> Self
    
    /// Calculates the distance to another value.
    /// - Parameter other: The value to calculate distance to.
    /// - Returns: The distance between the two values.
    func distance(to other: Self) -> Double
}

extension Double: Animatable {
    public func scaled(by factor: Double) -> Double {
        return self * factor
    }
    
    public func distance(to other: Double) -> Double {
        return abs(self - other)
    }
}

// MARK: - AnimationUpdateable Protocol

/// Internal protocol for type-erased animation value management.
public protocol AnimationUpdateable: AnyObject {
    /// Updates the animation state, interpolating towards the target value.
    func update()
}

// MARK: - AnimationValue Property Wrapper

/// A property wrapper that provides smooth animation between values.
///
/// When you set a new value, it will automatically interpolate from the current value
/// to the new target value over time. The interpolation is managed by the global `Context`.
///
/// Example:
/// ```swift
/// class MyView {
///     @AnimationValue var offset: Double = 0
///     
///     func moveRight() {
///         offset = 100 // Will animate smoothly from current value to 100
///     }
/// }
/// ```
@propertyWrapper
public class AnimationValue<T: Animatable>: AnimationUpdateable {
    /// The current interpolated value.
    private var value: T
    
    /// The target value to animate towards.
    private var target: T
    
    /// The animation speed. Higher values make the animation slower (more smooth).
    /// Default is 50. Lower values result in faster animations.
    public var speed: Double = 50
    
    /// Initializes the animation value with an initial value.
    /// - Parameter wrappedValue: The initial value.
    public init(wrappedValue: T) {
        self.value = wrappedValue
        self.target = wrappedValue
        Context.shared.addAnimationValue(self)
    }
    
    deinit {
        Context.shared.removeAnimationValue(self)
    }
    
    /// The wrapped value. Setting this triggers animation to the new value.
    public var wrappedValue: T {
        get {
            return value
        }
        set {
            target = newValue
        }
    }
    
    /// Projects the `AnimationValue` instance itself for advanced usage.
    public var projectedValue: AnimationValue<T> {
        return self
    }
    
    /// Updates the current value by interpolating towards the target.
    /// This is called automatically by the `Context` on each frame.
    public func update() {
        if value != target {
            if value.distance(to: target) < 0.15 {
                value = target
            } else {
                let diff = target - value
                let factor = 10.0 / speed
                let step = diff.scaled(by: factor)
                value = value + step
            }
        }
    }
}
