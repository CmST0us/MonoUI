import CU8g2

// MARK: - StackAxis

/// The axis along which views are arranged in a stack.
public enum StackAxis {
    /// Views are arranged horizontally (like HStack).
    case horizontal
    /// Views are arranged vertically (like VStack).
    case vertical
}

// MARK: - StackAlignment

/// The alignment of views within a stack.
public enum StackAlignment {
    /// Align views to the leading edge (left for horizontal, top for vertical).
    case leading
    /// Align views to the center.
    case center
    /// Align views to the trailing edge (right for horizontal, bottom for vertical).
    case trailing
    /// Align views to fill the available space.
    case fill
}

// MARK: - StackView

/// A container view that arranges its children in a horizontal or vertical stack.
///
/// `StackView` is similar to SwiftUI's `HStack` and `VStack`, arranging child views
/// along a single axis with optional spacing and alignment.
///
/// Example:
/// ```swift
/// let stack = StackView(frame: Rect(x: 0, y: 0, width: 128, height: 64),
///                       axis: .horizontal,
///                       spacing: 5,
///                       alignment: .center)
/// stack.addSubview(textView1)
/// stack.addSubview(iconView)
/// ```
open class StackView: View {
    // MARK: - Public Properties
    
    /// The frame of the stack view.
    public var frame: Rect
    
    /// The axis along which views are arranged.
    public var axis: StackAxis {
        didSet {
            layoutChildren()
        }
    }
    
    /// The spacing between child views.
    public var spacing: Double {
        didSet {
            layoutChildren()
        }
    }
    
    /// The alignment of child views within the stack.
    public var alignment: StackAlignment {
        didSet {
            layoutChildren()
        }
    }
    
    /// The child views contained within the stack.
    public var children: [View] = [] {
        didSet {
            layoutChildren()
        }
    }
    
    // MARK: - Initialization
    
    /// Initializes a new stack view.
    /// - Parameters:
    ///   - frame: The frame of the stack view.
    ///   - axis: The axis along which to arrange views (default: .horizontal).
    ///   - spacing: The spacing between child views (default: 0).
    ///   - alignment: The alignment of child views (default: .leading).
    public init(frame: Rect, axis: StackAxis = .horizontal, spacing: Double = 0, alignment: StackAlignment = .center) {
        self.frame = frame
        self.axis = axis
        self.spacing = spacing
        self.alignment = alignment
    }
    
    // MARK: - View Management
    
    /// Adds a child view to the stack.
    /// - Parameter view: The view to add.
    public func addSubview(_ view: View) {
        children.append(view)
        layoutChildren()
    }
    
    /// Removes a child view from the stack.
    /// - Parameter view: The view to remove.
    public func removeSubview(_ view: View) {
        children.removeAll { $0 === view }
        layoutChildren()
    }
    
    /// Removes all child views from the stack.
    public func removeAllSubviews() {
        children.removeAll()
    }
    
    // MARK: - Drawing
    
    /// Renders the stack view and its children.
    /// - Parameters:
    ///   - u8g2: Pointer to the u8g2 graphics context.
    ///   - origin: The absolute origin of the parent.
    open func draw(u8g2: UnsafeMutablePointer<u8g2_t>?, origin: Point) {
        guard let u8g2 = u8g2 else { return }
        
        let absX = origin.x + frame.origin.x
        let absY = origin.y + frame.origin.y
        
        // Draw all child views
        let childOrigin = Point(x: absX, y: absY)
        for child in children {
            child.draw(u8g2: u8g2, origin: childOrigin)
        }
    }
    
    // MARK: - Layout
    
    /// Lays out all child views according to the stack's axis, spacing, and alignment.
    private func layoutChildren() {
        guard !children.isEmpty else { return }
        
        switch axis {
        case .horizontal:
            layoutHorizontally()
        case .vertical:
            layoutVertically()
        }
    }
    
    /// Lays out children horizontally (like HStack).
    private func layoutHorizontally() {
        // Separate spacers from regular views
        let spacers = children.compactMap { $0 as? Spacer }
        let regularViews = children.filter { !($0 is Spacer) }
        
        // Calculate total width needed for regular views
        let totalSpacing = spacing * Double(max(0, children.count - 1))
        let totalRegularWidth = regularViews.reduce(0.0) { $0 + $1.frame.size.width }
        
        // Calculate available space for spacers
        let availableWidth = frame.size.width - totalRegularWidth - totalSpacing
        let spacerWidth = spacers.isEmpty ? 0 : max(0, availableWidth) / Double(spacers.count)
        
        // Assign widths to spacers
        for spacer in spacers {
            let finalWidth = max(spacer.minLength, spacerWidth)
            spacer.frame = Rect(x: spacer.frame.origin.x, y: spacer.frame.origin.y,
                               width: finalWidth, height: spacer.frame.size.height)
        }
        
        // Calculate total width with spacers
        let totalWidth = totalRegularWidth + (spacerWidth * Double(spacers.count)) + totalSpacing
        
        // Calculate starting position based on alignment
        var currentX: Double = 0
        switch alignment {
        case .leading:
            currentX = 0
        case .center:
            currentX = (frame.size.width - totalWidth) / 2
        case .trailing:
            currentX = frame.size.width - totalWidth
        case .fill:
            // Distribute space evenly
            let availableWidth = frame.size.width - totalSpacing
            let childWidth = availableWidth / Double(children.count)
            var x: Double = 0
            for child in children {
                let y = calculateVerticalAlignment(child: child)
                child.frame = Rect(x: x, y: y, 
                                 width: childWidth, height: child.frame.size.height)
                x += childWidth + spacing
            }
            return
        }
        
        // Position children horizontally
        var x = currentX
        for child in children {
            // Calculate Y position based on alignment
            let y: Double
            switch alignment {
            case .leading, .center, .trailing:
                y = calculateVerticalAlignment(child: child)
            case .fill:
                y = 0
            }
            
            child.frame = Rect(x: x, y: y, 
                             width: child.frame.size.width, 
                             height: child.frame.size.height)
            x += child.frame.size.width + spacing
        }
    }
    
    /// Lays out children vertically (like VStack).
    private func layoutVertically() {
        // Separate spacers from regular views
        let spacers = children.compactMap { $0 as? Spacer }
        let regularViews = children.filter { !($0 is Spacer) }
        
        // Calculate total height needed for regular views
        let totalSpacing = spacing * Double(max(0, children.count - 1))
        let totalRegularHeight = regularViews.reduce(0.0) { $0 + $1.frame.size.height }
        
        // Calculate available space for spacers
        let availableHeight = frame.size.height - totalRegularHeight - totalSpacing
        let spacerHeight = spacers.isEmpty ? 0 : max(0, availableHeight) / Double(spacers.count)
        
        // Assign heights to spacers
        for spacer in spacers {
            let finalHeight = max(spacer.minLength, spacerHeight)
            spacer.frame = Rect(x: spacer.frame.origin.x, y: spacer.frame.origin.y,
                               width: spacer.frame.size.width, height: finalHeight)
        }
        
        // Calculate total height with spacers
        let totalHeight = totalRegularHeight + (spacerHeight * Double(spacers.count)) + totalSpacing
        
        // Calculate starting position based on alignment
        var currentY: Double = 0
        switch alignment {
        case .leading:
            currentY = 0
        case .center:
            currentY = (frame.size.height - totalHeight) / 2
        case .trailing:
            currentY = frame.size.height - totalHeight
        case .fill:
            // Distribute space evenly
            let availableHeight = frame.size.height - totalSpacing
            let childHeight = availableHeight / Double(children.count)
            var y: Double = 0
            for child in children {
                let x = calculateHorizontalAlignment(child: child)
                child.frame = Rect(x: x, y: y, 
                                 width: child.frame.size.width, height: childHeight)
                y += childHeight + spacing
            }
            return
        }
        
        // Position children vertically
        var y = currentY
        for child in children {
            // Calculate X position based on alignment
            let x: Double
            switch alignment {
            case .leading, .center, .trailing:
                x = calculateHorizontalAlignment(child: child)
            case .fill:
                x = 0
            }
            
            child.frame = Rect(x: x, y: y, 
                             width: child.frame.size.width, 
                             height: child.frame.size.height)
            y += child.frame.size.height + spacing
        }
    }
    
    /// Calculates the horizontal alignment position for a child view.
    private func calculateHorizontalAlignment(child: View) -> Double {
        switch alignment {
        case .leading:
            return 0
        case .center:
            return (frame.size.width - child.frame.size.width) / 2
        case .trailing:
            return frame.size.width - child.frame.size.width
        case .fill:
            return 0
        }
    }
    
    /// Calculates the vertical alignment position for a child view.
    private func calculateVerticalAlignment(child: View) -> Double {
        switch alignment {
        case .leading:
            return 0
        case .center:
            return (frame.size.height - child.frame.size.height) / 2
        case .trailing:
            return frame.size.height - child.frame.size.height
        case .fill:
            return 0
        }
    }
}

