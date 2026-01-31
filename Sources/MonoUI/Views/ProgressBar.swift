import CU8g2

// MARK: - ProgressBar

/// A progress bar component that displays a value as a filled bar.
///
/// `ProgressBar` is a reusable component that can be used in any view
/// to display progress or percentage values.
public class ProgressBar: View {
    // MARK: - Constants
    private static let DefaultWidth: Double = 92
    private static let DefaultHeight: Double = 7
    private static let DefaultCornerRadius: Double = 1
    private static let DefaultAnimationSpeed: Double = 25.0
    private static let DefaultPadding: Double = 2

    // MARK: - Public Properties

    /// The current progress value.
    public var value: Double {
        didSet {
            // Clamp value to valid range
            let clampedValue = max(minimum, min(maximum, value))
            if clampedValue != value {
                value = clampedValue
                return
            }
            // Update animated progress bar width
            progressBarWidth = calculateProgressBarWidth()
        }
    }

    /// The minimum value (default: 0).
    public var minimum: Double = 0

    /// The maximum value (default: 100).
    public var maximum: Double = 100

    /// Width of the progress bar (default: 92).
    public var barWidth: Double = ProgressBar.DefaultWidth

    /// Height of the progress bar (default: 7).
    public var barHeight: Double = ProgressBar.DefaultHeight

    /// Corner radius for the progress bar frame (default: 1).
    public var cornerRadius: Double = ProgressBar.DefaultCornerRadius

    /// Animation speed for progress bar width changes (default: 25.0).
    public var animationSpeed: Double = ProgressBar.DefaultAnimationSpeed {
        didSet {
            _progressBarWidth.speed = animationSpeed
        }
    }

    // MARK: - Private Properties

    /// Animated progress bar fill width.
    @AnimationValue private var progressBarWidth: Double = 0

    // MARK: - Computed Properties

    private var innerWidth: Double {
        return barWidth - Self.DefaultPadding * 2
    }

    // MARK: - Initialization

    /// Initializes a new progress bar.
    /// - Parameters:
    ///   - frame: The frame of the progress bar.
    ///   - value: The initial progress value (default: 0).
    ///   - minimum: The minimum value (default: 0).
    ///   - maximum: The maximum value (default: 100).
    public init(frame: Rect,
                value: Double = 0,
                minimum: Double = 0,
                maximum: Double = 100) {
        self.minimum = minimum
        self.maximum = maximum
        self.value = max(minimum, min(maximum, value))

        // Initialize progress bar width
        self._progressBarWidth = AnimationValue(wrappedValue: 0)

        super.init(frame: frame)

        _progressBarWidth.speed = Self.DefaultAnimationSpeed
        progressBarWidth = calculateProgressBarWidth()
    }

    // MARK: - Drawing

    /// Renders the progress bar.
    /// - Parameters:
    ///   - u8g2: Pointer to the u8g2 graphics context.
    ///   - origin: The absolute origin of the parent.
    public override func draw(u8g2: UnsafeMutablePointer<u8g2_t>?, origin: Point) {
        guard let u8g2 = u8g2 else { return }

        let absX = origin.x + frame.origin.x
        let absY = origin.y + frame.origin.y

        // Draw progress bar frame
        u8g2_DrawRFrame(u8g2,
                       u8g2_uint_t(max(0, min(absX, Double(UInt16.max)))),
                       u8g2_uint_t(max(0, min(absY, Double(UInt16.max)))),
                       u8g2_uint_t(barWidth),
                       u8g2_uint_t(barHeight),
                       u8g2_uint_t(cornerRadius))

        // Draw progress bar fill
        let fillWidth = max(0, min(progressBarWidth, innerWidth))
        if fillWidth > 0 {
            u8g2_DrawBox(u8g2,
                        u8g2_uint_t(max(0, min(absX + Self.DefaultPadding, Double(UInt16.max)))),
                        u8g2_uint_t(max(0, min(absY + Self.DefaultPadding, Double(UInt16.max)))),
                        u8g2_uint_t(fillWidth),
                        u8g2_uint_t(barHeight - Self.DefaultPadding * 2))
        }
    }

    // MARK: - Private Methods

    /// Calculates the progress bar fill width based on current value.
    private func calculateProgressBarWidth() -> Double {
        guard maximum > minimum else { return 0 }
        let progress = (value - minimum) / (maximum - minimum)
        return progress * innerWidth
    }
}
