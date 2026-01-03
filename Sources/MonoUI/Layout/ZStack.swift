import CU8g2

// MARK: - ZStack

/// A container view that overlays its children on top of each other.
/// Similar to SwiftUI's ZStack.
///
/// Example:
/// ```swift
/// ZStack {
///     Text("Background")
///     Text("Foreground")
/// }
/// ```
public class ZStack<Content: View>: View {
    public var frame: Rect
    private let content: Content
    
    /// Initializes a Z-stack with the given content.
    /// - Parameter content: The view builder content.
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
        self.frame = .zero
        layoutContent()
    }
    
    public func draw(u8g2: UnsafeMutablePointer<u8g2_t>?, origin: Point) {
        let absX = origin.x + frame.origin.x
        let absY = origin.y + frame.origin.y
        let childOrigin = Point(x: absX, y: absY)
        
        // Extract and draw children (overlaying them)
        let children = ViewExtractionHelper.extractChildren(from: content)
        for child in children {
            child.draw(u8g2: u8g2, origin: childOrigin)
        }
    }
    
    private func layoutContent() {
        let children = ViewExtractionHelper.extractChildren(from: content)
        guard !children.isEmpty else { return }
        
        // All children are positioned at (0, 0) and sized to fill the ZStack
        for child in children {
            child.frame = Rect(x: 0, y: 0,
                             width: frame.size.width > 0 ? frame.size.width : child.frame.size.width,
                             height: frame.size.height > 0 ? frame.size.height : child.frame.size.height)
        }
        
        // Update frame size if needed
        if frame.size.width == 0 {
            let maxWidth = children.map { $0.frame.size.width }.max() ?? 0
            frame.size.width = maxWidth
        }
        if frame.size.height == 0 {
            let maxHeight = children.map { $0.frame.size.height }.max() ?? 0
            frame.size.height = maxHeight
        }
    }
}

