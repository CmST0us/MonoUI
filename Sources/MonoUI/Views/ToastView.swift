import CU8g2

// MARK: - ToastView

/// A temporary toast notification view.
///
/// `ToastView` displays a brief message at the bottom of the screen
/// and can be configured to auto-dismiss after a duration.
/// It consists of a simple message text.
public class ToastView: ModalView {
    // MARK: - Private Properties

    /// The message text to display.
    private var message: String

    /// The duration to show the toast (in seconds).
    private var duration: Double

    // MARK: - Initialization

    /// Initializes a new toast view.
    /// - Parameters:
    ///   - message: The message text to display.
    ///   - duration: How long to show the toast (default: 2.0 seconds).
    public init(message: String, duration: Double = 2.0) {
        self.message = message
        self.duration = duration

        let screenSize = Context.shared.screenSize
        // Position toast at bottom with margins
        let margin: Double = 10
        let toastHeight: Double = 14
        let toastWidth = screenSize.width - margin * 2
        let toastY = screenSize.height - toastHeight - margin
        let frame = Rect(x: margin, y: toastY, width: toastWidth, height: toastHeight)

        super.init(frame: frame)
    }

    // MARK: - Drawing

    /// Draws the toast content (message text).
    /// - Parameters:
    ///   - u8g2: Pointer to the u8g2 graphics context.
    ///   - absX: The absolute X coordinate of the modal.
    ///   - absY: The absolute Y coordinate of the modal.
    public override func drawContent(u8g2: UnsafeMutablePointer<u8g2_t>, absX: Double, absY: Double) {
        // Draw message text
        u8g2_SetDrawColor(u8g2, 0)
        u8g2_DrawStr(u8g2, u8g2_uint_t(absX + 2), u8g2_uint_t(absY + 10), message)

        // Restore draw color
        u8g2_SetDrawColor(u8g2, 1)
    }
}
