import CU8g2

// MARK: - AlertView

/// A modal alert view that displays a message with an optional title.
///
/// `AlertView` appears with a slide-up animation from the bottom of the screen
/// and can be dismissed with a slide-down animation.
public class AlertView: View {
    // MARK: - Public Properties
    
    /// The frame of the alert view.
    public var frame: Rect
    
    /// Callback executed when the dismiss animation completes.
    public var onAnimationCompleted: (() -> Void)?
    
    // MARK: - Private Properties
    
    /// The vertical offset for slide animation.
    /// Starts at screen height (below screen) and animates to `frame.origin.y`.
    @AnimationValue private var offsetY: Double
    
    /// The message text to display.
    private var message: String
    
    /// The optional title text.
    private var title: String?
    
    /// Flag indicating if the alert is currently dismissing.
    private var isDismissing: Bool = false
    
    // MARK: - Initialization
    
    /// Initializes a new alert view.
    /// - Parameters:
    ///   - frame: The frame of the alert.
    ///   - title: Optional title text.
    ///   - message: The message text to display.
    public init(frame: Rect, title: String? = nil, message: String) {
        // Initialize offsetY to screen height (below screen) as default
        let screenHeight = Context.shared.screenSize.height
        self._offsetY = AnimationValue(wrappedValue: screenHeight)
        
        self.frame = frame
        self.title = title
        self.message = message
        
        // Trigger slide-up animation
        self.offsetY = frame.origin.y
    }
    
    // MARK: - Public Methods
    
    /// Dismisses the alert with a slide-down animation.
    /// - Parameter completion: Closure to execute when animation completes.
    public func dismiss(completion: @escaping () -> Void) {
        isDismissing = true
        onAnimationCompleted = completion
        let screenHeight = Context.shared.screenSize.height
        offsetY = screenHeight // Animate off screen
    }
    
    // MARK: - Drawing
    
    /// Renders the alert view.
    /// - Parameters:
    ///   - u8g2: Pointer to the u8g2 graphics context.
    ///   - origin: The absolute origin of the parent.
    public func draw(u8g2: UnsafeMutablePointer<u8g2_t>?, origin: Point) {
        guard let u8g2 = u8g2 else { return }
        
        // Check if dismiss animation is complete
        let screenHeight = Context.shared.screenSize.height
        if isDismissing && abs(offsetY - screenHeight) < 1.0 {
            onAnimationCompleted?()
            return
        }
        
        let absX = origin.x + frame.origin.x
        let absY = origin.y + offsetY
        
        // Draw alert box with rounded corners
        u8g2_SetDrawColor(u8g2, 1)
        u8g2_DrawRBox(u8g2, 
                      u8g2_uint_t(absX), 
                      u8g2_uint_t(absY), 
                      u8g2_uint_t(frame.size.width), 
                      u8g2_uint_t(frame.size.height), 
                      3)
        
        // Set inverse color for text
        u8g2_SetDrawColor(u8g2, 0)
        u8g2_SetFontMode(u8g2, 1)
        
        // Draw title if present
        if let title = title {
            u8g2_DrawStr(u8g2, u8g2_uint_t(absX + 5), u8g2_uint_t(absY + 12), title)
        }
        
        // Draw message
        u8g2_DrawStr(u8g2, u8g2_uint_t(absX + 5), u8g2_uint_t(absY + 25), message)
        
        // Restore draw color
        u8g2_SetDrawColor(u8g2, 1)
    }
}

