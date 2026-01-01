import CU8g2

// MARK: - ToastView

/// A temporary toast notification view.
///
/// `ToastView` displays a brief message at the bottom of the screen
/// and can be configured to auto-dismiss after a duration.
public class ToastView: View {
    // MARK: - Public Properties
    
    /// The frame of the toast view.
    public var frame: Rect
    
    // MARK: - Private Properties
    
    /// The message text to display.
    private var message: String
    
    /// The duration to show the toast (in seconds).
    private var duration: Double
    
    /// The time when the toast was shown.
    private var startTime: Double = 0
    
    /// Flag indicating if the toast is currently visible.
    private var isShowing = false
    
    // MARK: - Initialization
    
    /// Initializes a new toast view.
    /// - Parameters:
    ///   - message: The message text to display.
    ///   - duration: How long to show the toast (default: 2.0 seconds).
    public init(message: String, duration: Double = 2.0) {
        let screenSize = Context.shared.screenSize
        // Position toast at bottom with margins
        let margin: Double = 10
        let toastHeight: Double = 14
        let toastWidth = screenSize.width - margin * 2
        let toastY = screenSize.height - toastHeight - margin
        self.frame = Rect(x: margin, y: toastY, width: toastWidth, height: toastHeight)
        self.message = message
        self.duration = duration
    }
    
    // MARK: - Public Methods
    
    /// Shows the toast.
    /// - Note: Auto-dismiss functionality requires external timer management.
    public func show() {
        isShowing = true
    }
    
    // MARK: - Drawing
    
    /// Renders the toast view if visible.
    /// - Parameters:
    ///   - u8g2: Pointer to the u8g2 graphics context.
    ///   - origin: The absolute origin of the parent.
    public func draw(u8g2: UnsafeMutablePointer<u8g2_t>?, origin: Point) {
        guard isShowing else { return }
        guard let u8g2 = u8g2 else { return }
        
        let absX = origin.x + frame.origin.x
        let absY = origin.y + frame.origin.y
        
        // Draw toast background
        u8g2_SetDrawColor(u8g2, 1)
        u8g2_DrawBox(u8g2, u8g2_uint_t(absX), u8g2_uint_t(absY), 
                     u8g2_uint_t(frame.size.width), u8g2_uint_t(frame.size.height))
        
        // Draw message text
        u8g2_SetDrawColor(u8g2, 0)
        u8g2_DrawStr(u8g2, u8g2_uint_t(absX + 2), u8g2_uint_t(absY + 10), message)
        
        // Restore draw color
        u8g2_SetDrawColor(u8g2, 1)
    }
}

