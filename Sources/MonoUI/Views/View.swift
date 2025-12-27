import CU8g2

// MARK: - View Protocol

/// A protocol representing a visual element that can be drawn on screen.
///
/// Views are the fundamental building blocks of the UI system. Each view has a frame
/// that defines its position and size, and a `draw` method that renders its content.
public protocol View: AnyObject {
    /// The frame defining the view's position and size relative to its parent.
    var frame: Rect { get set }
    
    /// Renders the view's content.
    ///
    /// - Parameters:
    ///   - u8g2: Pointer to the u8g2 graphics context.
    ///   - origin: The absolute origin point of the parent's content area.
    ///                The view should add its own `frame.origin` to this to get its absolute position.
    func draw(u8g2: UnsafeMutablePointer<u8g2_t>?, origin: Point)
}
