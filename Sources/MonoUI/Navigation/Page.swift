import CU8g2

// MARK: - Page

/// The base class for full-screen pages in the navigation system.
///
/// Pages represent distinct screens in your application and support
/// lifecycle hooks and transition animations.
open class Page: View {
    // MARK: - Public Properties
    
    /// The frame of the page (typically full screen).
    public var frame: Rect
    
    /// Child views contained within the page.
    public var children: [View] = []
    
    // MARK: - Initialization
    
    /// Initializes a new page with the specified frame.
    /// - Parameter frame: The frame of the page.
    public init(frame: Rect) {
        self.frame = frame
    }
    
    // MARK: - View Management
    
    /// Adds a child view to the page.
    /// - Parameter view: The view to add.
    open func addSubview(_ view: View) {
        children.append(view)
    }
    
    /// Removes all child views from the page.
    open func removeAllocatedViews() {
        children.removeAll()
    }
    
    // MARK: - Lifecycle Hooks
    
    /// Called when the page is about to be displayed.
    open func onEnter() {}
    
    /// Called when the page is about to be hidden.
    open func onExit() {}
    
    // MARK: - Transition Animations
    
    /// Called to start the page's enter animation.
    /// Override this to define custom transition animations.
    open func animateIn() {}
    
    /// Called to start the page's exit animation.
    /// Override this to define custom transition animations.
    open func animateOut() {}
    
    /// Returns whether the exit animation has completed.
    /// - Returns: `true` if the exit animation is finished, `false` otherwise.
    open func isExitAnimationFinished() -> Bool {
        return true
    }
    
    // MARK: - Drawing
    
    /// Renders the page and its children.
    /// - Parameters:
    ///   - u8g2: Pointer to the u8g2 graphics context.
    ///   - origin: The absolute origin point.
    open func draw(u8g2: UnsafeMutablePointer<u8g2_t>?, origin: Point) {
        guard let u8g2 = u8g2 else { return }
        
        let absX = origin.x + frame.origin.x
        let absY = origin.y + frame.origin.y
        
        // Draw opaque background to prevent bleed-through from previous page
        u8g2_SetDrawColor(u8g2, 0)
        u8g2_DrawBox(u8g2, u8g2_uint_t(absX), u8g2_uint_t(absY), 
                     u8g2_uint_t(frame.size.width), u8g2_uint_t(frame.size.height))
        u8g2_SetDrawColor(u8g2, 1)
        
        // Draw all child views
        let childOrigin = Point(x: absX, y: absY)
        for child in children {
            child.draw(u8g2: u8g2, origin: childOrigin)
        }
    }
    
    // MARK: - Input Handling
    
    /// Handles input events for the page.
    /// Override this to respond to user input.
    /// - Parameter key: The key code of the pressed key.
    open func handleInput(key: Int32) {}
}
