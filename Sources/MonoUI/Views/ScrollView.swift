import CU8g2

// MARK: - ScrollDirection

/// The scrolling direction for a `ScrollView`.
public enum ScrollDirection {
    /// Allows horizontal scrolling only.
    case horizontal
    
    /// Allows vertical scrolling only.
    case vertical
    
    /// Allows both horizontal and vertical scrolling.
    case both
}

// MARK: - ScrollView

/// A view that provides scrollable content within a fixed viewport.
///
/// `ScrollView` manages a collection of child views and renders only the portion
/// that is visible within its frame. Content can be scrolled by modifying the `contentOffset`.
open class ScrollView: View {
    // MARK: - Public Properties
    
    /// The frame of the scroll view in its parent's coordinate system.
    public var frame: Rect
    
    /// The total size of the scrollable content.
    /// This should be large enough to contain all child views.
    public var contentSize: Size
    
    /// The current scroll offset.
    /// - Note: Positive values scroll the content left/up, making content to the right/bottom visible.
    public var contentOffset: Point = .zero
    
    /// The child views contained within the scroll view.
    public var children: [View] = []
    
    /// The allowed scrolling direction(s).
    public var direction: ScrollDirection = .vertical
    
    // MARK: - Initialization
    
    /// Initializes a new scroll view with the specified frame.
    /// - Parameter frame: The frame of the scroll view.
    public init(frame: Rect) {
        self.frame = frame
        self.contentSize = frame.size
    }
    
    // MARK: - Public Methods
    
    /// Adds a child view to the scroll view.
    /// - Parameter view: The view to add.
    public func addSubview(_ view: View) {
        children.append(view)
    }
    
    // MARK: - Drawing
    
    /// Renders the scroll view and its visible children.
    /// - Parameters:
    ///   - u8g2: Pointer to the u8g2 graphics context.
    ///   - origin: The absolute origin of the parent.
    open func draw(u8g2: UnsafeMutablePointer<u8g2_t>?, origin: Point) {
        guard let u8g2 = u8g2 else { return }
        
        // Calculate absolute position of the scroll view
        let absX = origin.x + frame.origin.x
        let absY = origin.y + frame.origin.y
        
        // Set clipping window to constrain child drawing
        u8g2_SetClipWindow(u8g2,
                           u8g2_uint_t(max(0, absX)),
                           u8g2_uint_t(max(0, absY)),
                           u8g2_uint_t(absX + frame.size.width),
                           u8g2_uint_t(absY + frame.size.height))
        
        // Draw visible children
        for child in children {
            let childAbsFrame = calculateChildAbsoluteFrame(child: child, absX: absX, absY: absY)
            let clipFrame = Rect(x: absX, y: absY, width: frame.size.width, height: frame.size.height)
            
            // Only draw if child intersects with visible area
            if childAbsFrame.intersects(clipFrame) {
                let contentOrigin = Point(x: absX - contentOffset.x, y: absY - contentOffset.y)
                child.draw(u8g2: u8g2, origin: contentOrigin)
            }
        }
        
        // Restore clipping window
        u8g2_SetMaxClipWindow(u8g2)
    }
    
    // MARK: - Private Methods
    
    /// Calculates the absolute frame of a child view on screen.
    private func calculateChildAbsoluteFrame(child: View, absX: Double, absY: Double) -> Rect {
        let childOriginX = absX + child.frame.origin.x - contentOffset.x
        let childOriginY = absY + child.frame.origin.y - contentOffset.y
        return Rect(x: childOriginX, y: childOriginY, 
                   width: child.frame.size.width, height: child.frame.size.height)
    }
}
