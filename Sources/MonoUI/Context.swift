import U8g2Kit
import CU8g2
#if canImport(Glibc)
import Glibc
#elseif canImport(Darwin)
import Darwin
#endif

/// A class representing the application context.
/// It manages the display driver and global states like animations.
public class Context {

    /// The shared singleton instance of the Context.
    /// Warning: This is implicitly unwrapped and must be initialized early in the application lifecycle.
    public static var shared: Context!

    /// The display driver used by the context.
    let driver: Driver

    /// A list of objects that require animation updates.
    private var animationValues: [AnimationUpdateable] = []

    /// Initializes a new Context with the specified driver.
    /// - Parameter driver: The display driver to use.
    public init(driver: Driver) {
        self.driver = driver
        Context.shared = self
    }

    /// Performs setup tasks for the context.
    func setup() {
        // Reserved for future setup logic
    }

    /// Performs the main loop tasks for the context.
    /// This should be called once per frame.
    func loop() {
        updateAnimationValues()
    }

}

extension Context {
    /// Adds an animation value to the update list.
    /// - Parameter animationValue: The animation value to add.
    public func addAnimationValue(_ animationValue: AnimationUpdateable) {
        animationValues.append(animationValue)
    }

    /// Removes an animation value from the update list.
    /// - Parameter animationValue: The animation value to remove.
    public func removeAnimationValue(_ animationValue: AnimationUpdateable) {
        animationValues.removeAll { ObjectIdentifier($0) == ObjectIdentifier(animationValue) }
    }

    /// Updates all registered animation values.
    public func updateAnimationValues() {
        for animationValue in animationValues {
            animationValue.update()
        }
    }
}
