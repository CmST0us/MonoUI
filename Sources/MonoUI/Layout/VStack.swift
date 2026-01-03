import CU8g2

// MARK: - VStack

/// A container view that arranges its children vertically.
/// Similar to SwiftUI's VStack.
///
/// Example:
/// ```swift
/// VStack(spacing: 5) {
///     Text("Hello")
///     Text("World")
/// }
/// ```
public class VStack<Content: View>: View {
    public var frame: Rect {
        didSet {
            // Re-layout when frame size changes (but not when only position changes)
            // Only re-layout if the size actually changed
            if frame.size.width != oldValue.size.width || frame.size.height != oldValue.size.height {
                // Only re-layout if we have a valid size (avoid layout with 0 size)
                if frame.size.width > 0 || frame.size.height > 0 {
                    layoutContent()
                }
            }
        }
    }
    private let content: Content
    private let spacing: Double
    private let alignment: HorizontalAlignment
    
    /// Horizontal alignment options for VStack.
    public enum HorizontalAlignment {
        case leading
        case center
        case trailing
    }
    
    /// Initializes a vertical stack with the given content.
    /// - Parameters:
    ///   - alignment: The horizontal alignment of children (default: .center).
    ///   - spacing: The spacing between children (default: 0).
    ///   - content: The view builder content.
    public init(alignment: HorizontalAlignment = .center, spacing: Double = 0, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.spacing = spacing
        self.alignment = alignment
        self.frame = .zero
        layoutContent()
    }
    
    public func draw(u8g2: UnsafeMutablePointer<u8g2_t>?, origin: Point) {
        let absX = origin.x + frame.origin.x
        let absY = origin.y + frame.origin.y
        let childOrigin = Point(x: absX, y: absY)
        
        // Extract and draw children
        let children = extractChildren(from: content)
        for child in children {
            child.draw(u8g2: u8g2, origin: childOrigin)
        }
    }
    
    private func layoutContent() {
        let children = extractChildren(from: content)
        guard !children.isEmpty else { return }
        
        // Ensure children have valid sizes before calculating
        for child in children {
            // If child has 0 height, use default text height (10.0 for 6x10 font)
            if child.frame.size.height <= 0 {
                child.frame = Rect(x: child.frame.origin.x,
                                 y: child.frame.origin.y,
                                 width: child.frame.size.width,
                                 height: 10.0)
            }
            // If child has 0 width, estimate it (for Text views)
            if child.frame.size.width <= 0 {
                if let text = child as? Text {
                    let estimatedWidth = Double(text.text.count) * 6.0
                    child.frame = Rect(x: child.frame.origin.x,
                                     y: child.frame.origin.y,
                                     width: max(estimatedWidth, 60.0),
                                     height: child.frame.size.height)
                }
            }
        }
        
        // Calculate total height (use max to ensure minimum height)
        let totalSpacing = spacing * Double(max(0, children.count - 1))
        let totalHeight = children.reduce(0.0) { $0 + max($1.frame.size.height, 10.0) } + totalSpacing
        
        // Calculate max width of children (needed for centering)
        let maxChildWidth = children.map { $0.frame.size.width }.max() ?? 0
        
        // Update frame size if needed
        // For width: use max of children widths or keep existing if larger
        if frame.size.width == 0 || frame.size.width < maxChildWidth {
            frame.size.width = maxChildWidth
        }
        // For height: if frame.height is already set (e.g., by parent), keep it for centering
        // Otherwise, use content height
        if frame.size.height == 0 {
            frame.size.height = totalHeight
        }
        // If frame.height is larger than content, we'll center the content (handled below)
        
        // Use actual frame width for alignment calculations
        let containerWidth = frame.size.width > 0 ? frame.size.width : maxChildWidth
        let containerHeight = frame.size.height > 0 ? frame.size.height : totalHeight
        
        // Calculate starting Y position - center children vertically if container is larger than content
        let startY: Double
        if containerHeight > totalHeight {
            // Center vertically if container is larger than content
            startY = (containerHeight - totalHeight) / 2
        } else {
            // Start from top if container is same size or smaller
            startY = 0
        }
        
        // Position children vertically
        var currentY: Double = startY
        for child in children {
            // Calculate X position based on alignment (always center horizontally)
            let x: Double
            switch alignment {
            case .leading:
                x = 0
            case .center:
                x = (containerWidth - child.frame.size.width) / 2
            case .trailing:
                x = containerWidth - child.frame.size.width
            }
            
            child.frame = Rect(x: x, y: currentY,
                             width: child.frame.size.width,
                             height: child.frame.size.height)
            currentY += child.frame.size.height + spacing
        }
    }
    
    private func extractChildren(from view: any View) -> [any View] {
        return ViewExtractionHelper.extractChildren(from: view)
    }
}

