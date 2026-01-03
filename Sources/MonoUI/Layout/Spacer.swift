import CU8g2

// MARK: - Spacer

/// A flexible space that expands to fill available space in a stack.
///
/// `Spacer` is similar to SwiftUI's `Spacer`, pushing other views apart
/// by taking up all available space in its container.
///
/// Example:
/// ```swift
/// HStack {
///     Text("Left")
///     Spacer()
///     Text("Right")
/// }
/// // Text views will be pushed to opposite ends
/// ```
public class Spacer: View {
    // MARK: - Public Properties
    
    /// The frame of the spacer.
    public var frame: Rect
    
    /// The minimum size the spacer should take.
    /// Default is 0, meaning the spacer can shrink to nothing if needed.
    public var minLength: Double
    
    // MARK: - Initialization
    
    /// Initializes a new spacer with an optional minimum length.
    /// - Parameter minLength: The minimum size the spacer should take (default: 0).
    public init(minLength: Double = 0) {
        self.frame = Rect(x: 0, y: 0, width: minLength, height: minLength)
        self.minLength = minLength
    }
    
    // MARK: - Drawing
    
    /// Renders the spacer (does nothing, as spacers are invisible).
    /// - Parameters:
    ///   - u8g2: Pointer to the u8g2 graphics context.
    ///   - origin: The absolute origin of the parent.
    public func draw(u8g2: UnsafeMutablePointer<u8g2_t>?, origin: Point) {
        // Spacers are invisible, so we don't draw anything
    }
}

