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
    
    /// The screen size of the display.
    public let screenSize: Size
    
    /// The screen bounds (full screen rectangle).
    public var screenBounds: Rect {
        return Rect(x: 0, y: 0, width: screenSize.width, height: screenSize.height)
    }

    /// Initializes a new Context with the specified driver and screen size.
    /// - Parameters:
    ///   - driver: The display driver to use.
    ///   - screenSize: The size of the display screen.
    public init(driver: Driver, screenSize: Size) {
        self.driver = driver
        self.screenSize = screenSize
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
        let targetObject = animationValue as AnyObject
        animationValues.removeAll { ($0 as AnyObject) === targetObject }
    }

    /// Updates all registered animation values.
    public func updateAnimationValues() {
        for animationValue in animationValues {
            animationValue.update()
        }
    }
}
