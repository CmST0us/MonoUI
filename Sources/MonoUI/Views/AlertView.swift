import CU8g2

// MARK: - AlertView

/// A modal alert view that displays a message with an optional title.
///
/// `AlertView` appears with a slide-up animation from the bottom of the screen
/// and can be dismissed with a slide-down animation.
/// It consists of an optional title text and a message text.
public class AlertView: ModalView {
    // MARK: - Private Properties

    /// The message text to display.
    private var message: String

    /// The optional title text.
    private var title: String?

    // MARK: - Initialization

    /// Initializes a new alert view.
    /// - Parameters:
    ///   - frame: The frame of the alert.
    ///   - title: Optional title text.
    ///   - message: The message text to display.
    public init(frame: Rect, title: String? = nil, message: String) {
        self.title = title
        self.message = message
        super.init(frame: frame)
        // Set inverse color mode for highlighted display
        self.colorMode = .inverse
    }

    // MARK: - Drawing

    /// Draws the alert content (title and message).
    /// - Parameters:
    ///   - u8g2: Pointer to the u8g2 graphics context.
    ///   - absX: The absolute X coordinate of the modal.
    ///   - absY: The absolute Y coordinate of the modal.
    public override func drawContent(u8g2: UnsafeMutablePointer<u8g2_t>, absX: Double, absY: Double) {
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
