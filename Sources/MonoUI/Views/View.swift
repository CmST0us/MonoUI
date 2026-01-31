import CU8g2

// MARK: - View Base Class

/// A base class representing a visual element that can be drawn on screen.
///
/// Views are the fundamental building blocks of the UI system. Each view has a frame
/// that defines its position and size, and a `draw` method that renders its content.
open class View {
    /// The frame defining the view's position and size relative to its parent.
    open var frame: Rect

    public init(frame: Rect) {
        self.frame = frame
    }

    /// Renders the view's content.
    ///
    /// - Parameters:
    ///   - u8g2: Pointer to the u8g2 graphics context.
    ///   - origin: The absolute origin point of the parent's content area.
    ///                The view should add its own `frame.origin` to this to get its absolute position.
    open func draw(u8g2: UnsafeMutablePointer<u8g2_t>?, origin: Point) {
        // Override in subclasses
    }

    // MARK: - Modal Support

    /// Whether this view can be dismissed with animation.
    /// Override in subclasses that support dismissal.
    open var canDismiss: Bool { false }

    /// Dismisses the view with animation.
    /// Default implementation calls completion immediately.
    /// Override in subclasses that support animated dismissal.
    /// - Parameter completion: Closure to execute when dismissal completes.
    open func dismiss(completion: @escaping () -> Void) {
        completion()
    }

    /// Whether this view can handle input.
    /// Override in subclasses that support input handling.
    open var canHandleInput: Bool { false }

    /// Handles keyboard input.
    /// Default implementation does nothing.
    /// Override in subclasses that need to handle input.
    /// - Parameter key: The key code of the pressed key.
    open func handleInput(key: Int32) {
        // Default: do nothing
    }
}
