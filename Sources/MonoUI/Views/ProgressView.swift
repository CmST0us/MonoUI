import CU8g2

// MARK: - ProgressView

/// A modal view that displays a progress bar with adjustable value.
///
/// `ProgressView` appears with a slide-up animation and allows adjusting
/// the progress value using keyboard input (a/d keys).
/// It consists of a title text, a progress bar component, and a current value text.
public class ProgressView: ModalView {
    // MARK: - Constants
    private static let DefaultWindowHeight: Double = 32
    private static let DefaultWindowWidth: Double = 102
    private static let DefaultProgressBarWidth: Double = 92
    private static let DefaultProgressBarHeight: Double = 7
    private static let DefaultPadding: Double = 5
    
    // MARK: - Public Properties
    
    /// The title text to display.
    public var title: String
    
    /// The current progress value.
    public var value: Double {
        didSet {
            // Clamp value to valid range
            let clampedValue = max(minimum, min(maximum, value))
            if clampedValue != value {
                value = clampedValue
                return
            }
            // Update progress bar value
            progressBar.value = value
        }
    }
    
    /// The minimum value (default: 0).
    public var minimum: Double = 0
    
    /// The maximum value (default: 100).
    public var maximum: Double = 100
    
    /// The step size for value changes (default: 1).
    public var step: Double = 1
    
    /// Callback executed when the value changes.
    public var onValueChanged: ((Double) -> Void)?
    
    // MARK: - Private Properties
    
    /// The progress bar component.
    private var progressBar: ProgressBar!
    
    // MARK: - Initialization
    
    /// Initializes a new progress view.
    /// - Parameters:
    ///   - frame: The frame of the window. If nil, uses default centered frame.
    ///   - title: The title text to display.
    ///   - value: The initial progress value (default: 0).
    ///   - minimum: The minimum value (default: 0).
    ///   - maximum: The maximum value (default: 100).
    ///   - step: The step size for value changes (default: 1).
    public init(frame: Rect? = nil, 
                title: String,
                value: Double = 0,
                minimum: Double = 0,
                maximum: Double = 100,
                step: Double = 1) {
        self.title = title
        self.minimum = minimum
        self.maximum = maximum
        self.step = step
        
        // Initialize value (clamped to valid range)
        let clampedValue = max(minimum, min(maximum, value))
        self.value = clampedValue
        
        let screenSize = Context.shared.screenSize
        
        // Use provided frame or create default centered frame
        let modalFrame: Rect
        if let frame = frame {
            modalFrame = frame
        } else {
            let windowWidth = Self.DefaultWindowWidth
            let windowHeight = Self.DefaultWindowHeight
            let x = (screenSize.width - windowWidth) / 2
            let y = (screenSize.height - windowHeight) / 2
            modalFrame = Rect(x: x, y: y, width: windowWidth, height: windowHeight)
        }
        
        super.init(frame: modalFrame)
        
        // Create progress bar component (after super.init)
        let progressBarX = Self.DefaultPadding
        let progressBarY: Double = 20
        let progressBarFrame = Rect(x: progressBarX, y: progressBarY, 
                                    width: Self.DefaultProgressBarWidth, 
                                    height: Self.DefaultProgressBarHeight)
        self.progressBar = ProgressBar(frame: progressBarFrame,
                                       value: clampedValue,
                                       minimum: minimum,
                                       maximum: maximum)
    }
    
    // MARK: - Public Methods
    
    /// Handles keyboard input for the progress view.
    /// - Parameter key: The key code of the pressed key.
    public func handleInput(key: Int32) {
        // 'a' (97) -> Decrease value
        if key == 97 {
            value -= step
            onValueChanged?(value)
        }
        
        // 'd' (100) -> Increase value
        if key == 100 {
            value += step
            onValueChanged?(value)
        }
    }
    
    // MARK: - Drawing
    
    /// Draws the progress view content (title, progress bar, and value text).
    /// - Parameters:
    ///   - u8g2: Pointer to the u8g2 graphics context.
    ///   - absX: The absolute X coordinate of the modal.
    ///   - absY: The absolute Y coordinate of the modal.
    public override func drawContent(u8g2: UnsafeMutablePointer<u8g2_t>, absX: Double, absY: Double) {
        // Draw title text
        u8g2_SetFont(u8g2, u8g2_font_6x10_tf)
        u8g2_SetDrawColor(u8g2, 1)
        let titleX = absX + Self.DefaultPadding
        let titleY = absY + 14
        u8g2_DrawStr(u8g2,
                    u8g2_uint_t(max(0, min(titleX, Double(UInt16.max)))),
                    u8g2_uint_t(max(0, min(titleY, Double(UInt16.max)))),
                    title)
        
        // Draw progress bar component
        progressBar.draw(u8g2: u8g2, origin: Point(x: absX, y: absY))
        
        // Draw current value text
        let valueText = "\(Int(value))"
        let valueTextWidth = Double(u8g2_GetStrWidth(u8g2, valueText))
        let valueTextX = absX + frame.size.width - valueTextWidth - Self.DefaultPadding
        u8g2_DrawStr(u8g2,
                    u8g2_uint_t(max(0, min(valueTextX, Double(UInt16.max)))),
                    u8g2_uint_t(max(0, min(titleY, Double(UInt16.max)))),
                    valueText)
        
        // Draw visible border (opposite color of background)
        // Normal mode: black background (0) -> white border (1)
        // Inverse mode: white background (1) -> black border (0)
        let borderColor: UInt8 = colorMode == .normal ? 1 : 0
        u8g2_SetDrawColor(u8g2, borderColor)
        u8g2_DrawRFrame(u8g2,
                       u8g2_uint_t(absX),
                       u8g2_uint_t(absY),
                       u8g2_uint_t(frame.size.width),
                       u8g2_uint_t(frame.size.height),
                       u8g2_uint_t(cornerRadius))
    }
}

