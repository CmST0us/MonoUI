import CU8g2

// MARK: - ModalView

/// Base class for modal views that appear with slide animations.
///
/// `ModalView` provides common functionality for modal dialogs including:
/// - Slide-up/down animations
/// - Dismiss handling
/// - Window background and border drawing
///
/// Subclasses should override `drawContent` to implement their specific content.
open class ModalView: View {
    // MARK: - Constants
    internal static let DefaultCornerRadius: Double = 3
    internal static let DefaultAnimationSpeed: Double = 25.0
    internal static let AnimationCompletionThreshold: Double = 1.0
    
    // MARK: - Public Properties
    
    /// The frame of the modal view.
    public var frame: Rect
    
    /// Callback executed when the dismiss animation completes.
    public var onAnimationCompleted: (() -> Void)?
    
    /// Corner radius for the modal window (default: 3).
    public var cornerRadius: Double = DefaultCornerRadius
    
    /// Animation speed for slide animations (default: 25.0).
    public var animationSpeed: Double = DefaultAnimationSpeed {
        didSet {
            _offsetY.speed = animationSpeed
        }
    }
    
    // MARK: - Protected Properties
    
    /// The vertical offset for slide animation.
    /// Starts at screen height (below screen) and animates to `frame.origin.y`.
    @AnimationValue internal var offsetY: Double
    
    /// Flag indicating if the modal is currently dismissing.
    internal var isDismissing: Bool = false
    
    // MARK: - Initialization
    
    /// Initializes a new modal view.
    /// - Parameter frame: The frame of the modal.
    public init(frame: Rect) {
        // Initialize offsetY to screen height (below screen)
        let screenHeight = Context.shared.screenSize.height
        self._offsetY = AnimationValue(wrappedValue: screenHeight)
        
        self.frame = frame
        
        // Set animation speed (use the default value from animationSpeed property)
        _offsetY.speed = 25.0
        
        // Trigger slide-up animation
        self.offsetY = frame.origin.y
    }
    
    // MARK: - Public Methods
    
    /// Dismisses the modal with a slide-down animation.
    /// - Parameter completion: Closure to execute when animation completes.
    public func dismiss(completion: @escaping () -> Void) {
        isDismissing = true
        onAnimationCompleted = completion
        let screenHeight = Context.shared.screenSize.height
        offsetY = screenHeight // Animate off screen
    }
    
    // MARK: - Drawing
    
    /// Renders the modal view.
    /// - Parameters:
    ///   - u8g2: Pointer to the u8g2 graphics context.
    ///   - origin: The absolute origin of the parent.
    public func draw(u8g2: UnsafeMutablePointer<u8g2_t>?, origin: Point) {
        guard let u8g2 = u8g2 else { return }
        
        // Check if dismiss animation is complete
        let screenHeight = Context.shared.screenSize.height
        if isDismissing && abs(offsetY - screenHeight) < Self.AnimationCompletionThreshold {
            onAnimationCompleted?()
            return
        }
        
        let absX = origin.x + frame.origin.x
        let absY = origin.y + offsetY
        
        // Draw window background with rounded corners
        u8g2_SetDrawColor(u8g2, 0)
        u8g2_DrawRBox(u8g2,
                     u8g2_uint_t(absX),
                     u8g2_uint_t(absY),
                     u8g2_uint_t(frame.size.width),
                     u8g2_uint_t(frame.size.height),
                     u8g2_uint_t(cornerRadius))
        
        // Draw window border
        u8g2_SetDrawColor(u8g2, 1)
        u8g2_DrawRFrame(u8g2,
                       u8g2_uint_t(absX),
                       u8g2_uint_t(absY),
                       u8g2_uint_t(frame.size.width),
                       u8g2_uint_t(frame.size.height),
                       u8g2_uint_t(cornerRadius))
        
        // Draw content (implemented by subclasses)
        drawContent(u8g2: u8g2, absX: absX, absY: absY)
    }
    
    // MARK: - Protected Methods
    
    /// Draws the modal content.
    /// Subclasses should override this method to implement their specific content.
    /// - Parameters:
    ///   - u8g2: Pointer to the u8g2 graphics context.
    ///   - absX: The absolute X coordinate of the modal.
    ///   - absY: The absolute Y coordinate of the modal.
    open func drawContent(u8g2: UnsafeMutablePointer<u8g2_t>, absX: Double, absY: Double) {
        // Default implementation does nothing
        // Subclasses should override this
    }
}

