import CU8g2

// MARK: - HStack

/// A container view that arranges its children horizontally.
/// Similar to SwiftUI's HStack.
///
/// Example:
/// ```swift
/// HStack(spacing: 5) {
///     Text("Hello")
///     Text("World")
/// }
/// ```
public class HStack<Content: View>: View {
    public var frame: Rect {
        didSet {
            // Re-layout when frame size changes
            if frame.size.width != oldValue.size.width || frame.size.height != oldValue.size.height {
                layoutContent()
            }
        }
    }
    private let content: Content
    private let spacing: Double
    private let alignment: VerticalAlignment
    
    /// Vertical alignment options for HStack.
    public enum VerticalAlignment {
        case top
        case center
        case bottom
    }
    
    /// Initializes a horizontal stack with the given content.
    /// - Parameters:
    ///   - alignment: The vertical alignment of children (default: .center).
    ///   - spacing: The spacing between children (default: 0).
    ///   - content: The view builder content.
    public init(alignment: VerticalAlignment = .center, spacing: Double = 0, @ViewBuilder content: () -> Content) {
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
        
        // Helper function to check if a view is a Spacer (including wrapped in AnyView)
        func isSpacerView(_ view: any View) -> Bool {
            if view is Spacer { return true }
            if let anyView = view as? AnyView {
                let mirror = Mirror(reflecting: anyView)
                if let wrappedView = mirror.children.first(where: { $0.label == "_view" })?.value as? (any View),
                   wrappedView is Spacer {
                    return true
                }
            }
            return false
        }
        
        // Ensure non-spacer children have valid sizes before calculating
        for child in children {
            if isSpacerView(child) { continue }
            
            // Ensure child has valid width
            if child.frame.size.width <= 0 {
                if let text = child as? Text {
                    let estimatedWidth = Double(text.text.count) * 6.0
                    child.frame = Rect(x: child.frame.origin.x,
                                     y: child.frame.origin.y,
                                     width: max(estimatedWidth, 60.0),
                                     height: max(child.frame.size.height, 10.0))
                }
            }
            // Ensure child has valid height
            if child.frame.size.height <= 0 {
                child.frame = Rect(x: child.frame.origin.x,
                                 y: child.frame.origin.y,
                                 width: child.frame.size.width,
                                 height: 10.0)
            }
        }
        
        // Separate spacers from non-spacers
        // Need to handle Spacer wrapped in AnyView
        var spacers: [Spacer] = []
        var nonSpacers: [any View] = []
        
        for child in children {
            // Check if child is Spacer directly
            if let spacer = child as? Spacer {
                spacers.append(spacer)
            } else if let anyView = child as? AnyView {
                // Check if AnyView wraps a Spacer using reflection
                let mirror = Mirror(reflecting: anyView)
                if let wrappedView = mirror.children.first(where: { $0.label == "_view" })?.value as? (any View),
                   let spacer = wrappedView as? Spacer {
                    spacers.append(spacer)
                } else {
                    nonSpacers.append(child)
                }
            } else {
                nonSpacers.append(child)
            }
        }
        
        // Calculate total width of non-spacer children
        let nonSpacerWidth = nonSpacers.reduce(0.0) { $0 + $1.frame.size.width }
        
        // Calculate spacing between all children (including spacers)
        // Spacing is between adjacent children, so for n children there are n-1 gaps
        let totalSpacing = spacing * Double(max(0, children.count - 1))
        
        // Calculate max height of children (needed for alignment)
        let maxChildHeight = children.map { $0.frame.size.height }.max() ?? 0
        
        // Get container width - MUST use frame.size.width if set (by parent like SwiftUIPage)
        // This is critical for Spacer to work correctly
        // If frame.width is 0, we need to calculate a minimum width (without Spacer expansion)
        let calculatedMinWidth = nonSpacerWidth + totalSpacing
        let containerWidth = frame.size.width > 0 ? frame.size.width : calculatedMinWidth
        
        // Calculate available space for spacers
        // This is the space that Spacer should fill
        // Only calculate if we have a valid container width (set by parent)
        let availableWidth: Double
        if frame.size.width > 0 {
            // Parent has set a width, so we can calculate available space for Spacers
            availableWidth = max(0.0, containerWidth - nonSpacerWidth - totalSpacing)
        } else {
            // No parent width set, Spacers get no space (they collapse to minLength)
            availableWidth = 0.0
        }
        let actualSpacerWidth = spacers.isEmpty ? 0.0 : max(0.0, availableWidth / Double(spacers.count))
        
        // Update frame size if needed
        // For width: if frame.width is already set (by parent), keep it; otherwise use calculated width
        if frame.size.width == 0 {
            // Calculate total width including Spacer widths
            let totalSpacerWidth = spacers.reduce(0.0) { $0 + max($1.minLength, actualSpacerWidth) }
            frame.size.width = nonSpacerWidth + totalSpacerWidth + totalSpacing
        }
        // Don't change frame.width if it's already set - parent wants us to use that width for Spacer
        if frame.size.height == 0 {
            frame.size.height = maxChildHeight
        }
        
        // Use actual frame height for alignment calculations
        let containerHeight = frame.size.height > 0 ? frame.size.height : maxChildHeight
        
        // Position children horizontally
        var currentX: Double = 0
        for child in children {
            // Get child width - for spacers, use the calculated width; for others, use their frame width
            let childWidth: Double
            // Check if child is Spacer (directly or wrapped in AnyView)
            var isSpacer = false
            var spacer: Spacer? = nil
            
            if let directSpacer = child as? Spacer {
                spacer = directSpacer
                isSpacer = true
            } else if let anyView = child as? AnyView {
                // Check if AnyView wraps a Spacer using reflection
                let mirror = Mirror(reflecting: anyView)
                if let wrappedView = mirror.children.first(where: { $0.label == "_view" })?.value as? (any View),
                   let wrappedSpacer = wrappedView as? Spacer {
                    spacer = wrappedSpacer
                    isSpacer = true
                }
            }
            
            if isSpacer, let spacer = spacer {
                // Use the calculated spacer width - this is critical for Spacer to work
                childWidth = max(actualSpacerWidth, spacer.minLength)
            } else {
                childWidth = child.frame.size.width
            }
            
            // Calculate Y position based on alignment
            let y: Double
            switch alignment {
            case .top:
                y = 0
            case .center:
                y = (containerHeight - child.frame.size.height) / 2
            case .bottom:
                y = containerHeight - child.frame.size.height
            }
            
            // Set child frame with correct width and position
            // For Spacer, ensure width is set correctly
            child.frame = Rect(x: currentX, y: y,
                             width: childWidth,
                             height: child.frame.size.height > 0 ? child.frame.size.height : containerHeight)
            currentX += childWidth + spacing
        }
    }
    
    private func extractChildren(from view: any View) -> [any View] {
        return ViewExtractionHelper.extractChildren(from: view)
    }
}

