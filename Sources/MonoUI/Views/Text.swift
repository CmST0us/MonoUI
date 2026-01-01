import CU8g2

// MARK: - Text

/// A view that displays text on the screen.
///
/// `Text` is similar to SwiftUI's `Text`, focusing on content rather than position.
/// Position and layout are managed by parent views like `StackView`.
///
/// Example:
/// ```swift
/// let text = Text("Hello World")
/// stackView.addSubview(text)  // Position is managed by StackView
/// ```
public class Text: View {
    // MARK: - Public Properties
    
    /// The frame of the text view.
    public var frame: Rect
    
    /// The text string to display.
    public var text: String {
        didSet {
            updateFrameIfNeeded()
        }
    }
    
    /// The font to use for rendering.
    /// Default is `u8g2_font_6x10_tf`.
    /// Font is represented as a pointer to u8g2 font structure.
    public var font: UnsafePointer<UInt8>? {
        didSet {
            updateFrameIfNeeded()
        }
    }
    
    /// The text alignment within the frame.
    public enum Alignment {
        /// Align text to the left.
        case left
        /// Align text to the center.
        case center
        /// Align text to the right.
        case right
    }
    
    /// The text alignment.
    public var alignment: Alignment = .left
    
    /// Whether to automatically calculate frame size based on text content.
    /// When true, the frame size will be updated based on actual text measurements.
    public var autoSize: Bool = true
    
    /// Whether to draw a border around the text frame for debugging/positioning.
    /// When true, a rectangle border will be drawn around the text's frame.
    public var showBorder: Bool = false
    
    // MARK: - Private Properties
    
    /// Cached text width for performance.
    private var cachedTextWidth: Double = 0
    
    /// Cached text height for performance.
    private var cachedTextHeight: Double = 0
    
    // MARK: - Initialization
    
    /// Initializes a new text view with the specified text.
    /// This is the primary initializer, similar to SwiftUI's `Text("Hello")`.
    /// Position is managed by parent views (e.g., StackView).
    /// - Parameters:
    ///   - text: The text string to display.
    ///   - font: Optional font to use. If nil, uses default font.
    public init(_ text: String, font: UnsafePointer<UInt8>? = u8g2_font_6x10_tf) {
        self.text = text
        self.font = font
        self.alignment = .left
        self.autoSize = true
        // Initialize with estimated size (will be updated during draw with accurate measurements)
        let charWidth: Double = 6.0
        let estimatedWidth = Double(text.count) * charWidth
        let estimatedHeight: Double = 10.0
        self.frame = Rect(x: 0, y: 0, width: estimatedWidth, height: estimatedHeight)
        self.cachedTextWidth = estimatedWidth
        self.cachedTextHeight = estimatedHeight
    }
    
    /// Initializes a new text view with the specified text and alignment.
    /// - Parameters:
    ///   - text: The text string to display.
    ///   - font: Optional font to use. If nil, uses default font.
    ///   - alignment: The text alignment within its frame.
    public init(_ text: String, font: UnsafePointer<UInt8>? = u8g2_font_6x10_tf, alignment: Alignment) {
        self.text = text
        self.font = font
        self.alignment = alignment
        self.autoSize = true
        // Initialize with estimated size (will be updated during draw with accurate measurements)
        let charWidth: Double = 6.0
        let estimatedWidth = Double(text.count) * charWidth
        let estimatedHeight: Double = 10.0
        self.frame = Rect(x: 0, y: 0, width: estimatedWidth, height: estimatedHeight)
        self.cachedTextWidth = estimatedWidth
        self.cachedTextHeight = estimatedHeight
    }
    
    /// Initializes a new text view with a fixed frame.
    /// Use this only when you need to manually position the text.
    /// For most cases, use `Text(_:)` and let StackView manage positioning.
    /// - Parameters:
    ///   - frame: The frame of the text view.
    ///   - text: The text string to display.
    ///   - font: Optional font to use. If nil, uses default font.
    ///   - alignment: The text alignment (default: .left).
    public init(frame: Rect, text: String, font: UnsafePointer<UInt8>? = u8g2_font_6x10_tf, alignment: Alignment = .left) {
        self.frame = frame
        self.text = text
        self.font = font
        self.alignment = alignment
        self.autoSize = false  // When frame is provided, don't auto-size
        updateFrameIfNeeded()
    }
    
    // MARK: - Drawing
    
    /// Renders the text view.
    /// - Parameters:
    ///   - u8g2: Pointer to the u8g2 graphics context.
    ///   - origin: The absolute origin of the parent.
    public func draw(u8g2: UnsafeMutablePointer<u8g2_t>?, origin: Point) {
        guard let u8g2 = u8g2 else { return }
        guard !text.isEmpty else { return }
        
        // Set font (use provided font or default to u8g2_font_6x10_tf)
        let fontToUse = font ?? u8g2_font_6x10_tf
        u8g2_SetFont(u8g2, fontToUse)
        
        // Calculate text width using u8g2 API if available, otherwise use cache or estimation
        let textWidth: Double
        if cachedTextWidth > 0 && !autoSize {
            textWidth = cachedTextWidth
        } else {
            // Use u8g2_GetStrWidth for accurate measurement (font is now always set)
            textWidth = Double(u8g2_GetStrWidth(u8g2, text))
            cachedTextWidth = textWidth
        }
        
        // Calculate text height using u8g2 API
        let textHeight: Double
        if cachedTextHeight > 0 && !autoSize {
            textHeight = cachedTextHeight
        } else {
            // Get font height (ascent + descent)
            let ascent = Double(u8g2_GetAscent(u8g2))
            let descent = Double(u8g2_GetDescent(u8g2))
            textHeight = ascent + descent
            cachedTextHeight = textHeight
        }
        
        // Update frame if auto-sizing is enabled
        if autoSize {
            frame = Rect(x: frame.origin.x, y: frame.origin.y, 
                        width: textWidth, height: textHeight)
        }
        
        let absX = origin.x + frame.origin.x
        let absY = origin.y + frame.origin.y
        
        // Calculate x position based on alignment
        let textX: Double
        switch alignment {
        case .left:
            textX = absX
        case .center:
            textX = absX + (frame.size.width - textWidth) / 2
        case .right:
            textX = absX + frame.size.width - textWidth
        }
        
        // Draw border if enabled (draw before text so text appears on top)
        if showBorder {
            u8g2_SetDrawColor(u8g2, 1)
            u8g2_DrawFrame(u8g2, 
                          u8g2_uint_t(max(0, min(absX, Double(UInt16.max)))), 
                          u8g2_uint_t(max(0, min(absY, Double(UInt16.max)))),
                          u8g2_uint_t(max(0, min(frame.size.width, Double(UInt16.max)))),
                          u8g2_uint_t(max(0, min(frame.size.height, Double(UInt16.max)))))
        }
        
        // Clamp coordinates to valid UInt16 range to prevent conversion errors
        let clampedX = max(0, min(textX, Double(UInt16.max)))
        // Y position: absY is top of frame, add ascent to get baseline
        let ascent = Double(u8g2_GetAscent(u8g2))
        let clampedY = max(0, min(absY + ascent, Double(UInt16.max)))
        
        // Draw text (y position is baseline)
        u8g2_DrawStr(u8g2, u8g2_uint_t(clampedX), u8g2_uint_t(clampedY), text)
    }
    
    // MARK: - Public Methods
    
    /// Calculates the ideal size for the text content.
    /// This is used by layout systems like StackView to determine the text's natural size.
    /// - Parameter u8g2: Optional u8g2 context for accurate measurement. If nil, uses estimation.
    /// - Returns: The ideal size for the text.
    public func idealSize(u8g2: UnsafeMutablePointer<u8g2_t>? = nil) -> Size {
        if let u8g2 = u8g2 {
            let fontToUse = font ?? u8g2_font_6x10_tf
            u8g2_SetFont(u8g2, fontToUse)
            let width = Double(u8g2_GetStrWidth(u8g2, text))
            let ascent = Double(u8g2_GetAscent(u8g2))
            let descent = Double(u8g2_GetDescent(u8g2))
            let height = ascent + descent
            return Size(width: width, height: height)
        } else {
            // Fallback estimation
            let charWidth: Double = 6.0
            let width = Double(text.count) * charWidth
            let height: Double = 10.0
            return Size(width: width, height: height)
        }
    }
    
    // MARK: - Private Methods
    
    /// Updates the frame if needed based on text content.
    private func updateFrameIfNeeded() {
        // Clear cache so it will be recalculated on next draw
        cachedTextWidth = 0
        cachedTextHeight = 0
    }
    
    /// Estimates the text size when u8g2 context is not available.
    /// - Parameters:
    ///   - text: The text string.
    ///   - font: The font to use for estimation.
    /// - Returns: Estimated size of the text.
    private func estimateTextSize(text: String, font: UnsafePointer<UInt8>?) -> Size {
        // Fallback estimation when u8g2 context is not available
        let charWidth: Double = 6.0 // Default for 6x10 font
        let width = Double(text.count) * charWidth
        let height: Double = 10.0 // Default font height
        return Size(width: width, height: height)
    }
    
    /// Calculates the width of the text string (fallback method).
    /// - Parameters:
    ///   - text: The text string.
    ///   - font: The font to use for calculation.
    /// - Returns: The width of the text in pixels (estimated).
    private func calculateTextWidth(text: String, font: UnsafePointer<UInt8>?) -> Double {
        return estimateTextSize(text: text, font: font).width
    }
}

