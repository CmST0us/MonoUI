import CU8g2

// MARK: - TileMenu

/// A tile-based menu view with horizontal scrolling icons and animated title text.
///
/// `TileMenu` displays a row of icons that can be scrolled horizontally, with
/// a title text that animates from bottom to top when the selection changes.
open class TileMenu: View {
    // MARK: - Constants
    private static let DefaultIconHeight: Double = 30
    private static let DefaultIconWidth: Double = 30
    private static let DefaultIconSpacing: Double = 36
    private static let DefaultIndicatorHeight: Double = 27
    private static let DefaultIndicatorWidth: Double = 7
    private static let DefaultIndicatorTopMargin: Double = 36
    private static let DefaultTitleFontHeight: Double = 18
    private static let DefaultAnimationSpeed: Double = 30.0
    private static let AnimationCompletionThreshold: Double = 0.15

    // MARK: - Public Properties

    /// The menu items (titles) to display.
    public var items: [String] = []

    /// The icon data for each menu item (XBM format).
    public var icons: [[UInt8]] = []

    /// The currently selected index.
    public var selectedIndex: Int = 0 {
        didSet {
            updateAnimations()
            updateScrollPosition()
        }
    }

    /// Callback executed when an item is selected.
    public var onSelect: ((Int) -> Void)?

    /// Icon height in pixels (default: 30).
    public var iconHeight: Double = DefaultIconHeight

    /// Icon width in pixels (default: 30).
    public var iconWidth: Double = DefaultIconWidth

    /// Spacing between icons in pixels (default: 36).
    public var iconSpacing: Double = DefaultIconSpacing

    /// Title indicator height in pixels (default: 27).
    public var indicatorHeight: Double = DefaultIndicatorHeight

    /// Title indicator width in pixels (default: 7).
    public var indicatorWidth: Double = DefaultIndicatorWidth

    /// Title indicator top margin in pixels (default: 36).
    public var indicatorTopMargin: Double = DefaultIndicatorTopMargin

    /// Title font height in pixels (default: 18).
    public var titleFontHeight: Double = DefaultTitleFontHeight

    /// Animation speed for tile menu animations (default: 30.0).
    /// Higher values make animations slower (smoother).
    public var animationSpeed: Double = DefaultAnimationSpeed {
        didSet {
            updateAnimationSpeeds()
        }
    }

    /// Font to use for title text (default: u8g2_font_helvB18_tr).
    public var titleFont: UnsafePointer<UInt8>? = u8g2_font_helvB18_tr

    // MARK: - Private Properties

    /// ScrollView for horizontal icon scrolling.
    private let scrollView: ScrollView

    /// Animation for icon X position offset.
    @AnimationValue private var iconXOffset: Double = 0

    /// Animation for title Y position (from bottom to top).
    @AnimationValue private var titleY: Double

    /// Animation for indicator width.
    @AnimationValue private var indiX: Double = 0

    /// Whether initialization animation is complete.
    private var isInitialized: Bool = false

    // MARK: - Computed Properties

    private var titleYInitial: Double {
        return indicatorTopMargin + (indicatorHeight - titleFontHeight) / 2 + titleFontHeight * 2
    }

    private var titleYTarget: Double {
        return indicatorTopMargin + (indicatorHeight - titleFontHeight) / 2 + titleFontHeight
    }

    // MARK: - Initialization

    /// Initializes a new tile menu with the specified frame.
    /// - Parameter frame: The frame of the tile menu.
    public override init(frame: Rect) {
        // Initialize ScrollView for icon scrolling
        self.scrollView = ScrollView(size: Size(width: frame.size.width, height: Self.DefaultIconHeight),
                                    direction: .horizontal)

        // Calculate initial title Y value using default values
        let initialTitleY = Self.DefaultIndicatorTopMargin +
                           (Self.DefaultIndicatorHeight - Self.DefaultTitleFontHeight) / 2 +
                           Self.DefaultTitleFontHeight * 2
        self._titleY = AnimationValue(wrappedValue: initialTitleY)

        super.init(frame: frame)

        // Initialize animation values
        iconXOffset = 0
        titleY = initialTitleY
        indiX = 0

        // Set animation speeds
        updateAnimationSpeeds()

        // Set initial targets using default values
        iconXOffset = Self.DefaultIconSpacing
        let targetTitleY = Self.DefaultIndicatorTopMargin +
                          (Self.DefaultIndicatorHeight - Self.DefaultTitleFontHeight) / 2 +
                          Self.DefaultTitleFontHeight
        titleY = targetTitleY
        indiX = Self.DefaultIndicatorWidth

        // Setup ScrollView content size
        updateScrollViewContentSize()
    }

    /// Updates animation speeds for all animated properties.
    private func updateAnimationSpeeds() {
        _iconXOffset.speed = animationSpeed
        _titleY.speed = animationSpeed
        _indiX.speed = animationSpeed
    }

    // MARK: - Public Methods

    /// Sets the menu items and their corresponding icons.
    /// - Parameters:
    ///   - items: The menu item titles.
    ///   - icons: The icon data for each item (XBM format).
    public func setItems(_ items: [String], icons: [[UInt8]]) {
        self.items = items
        self.icons = icons
        updateScrollViewContentSize()
    }

    /// Moves selection to the next item.
    public func moveNext() {
        if selectedIndex < items.count - 1 {
            selectedIndex += 1
        }
    }

    /// Moves selection to the previous item.
    public func movePrevious() {
        if selectedIndex > 0 {
            selectedIndex -= 1
        }
    }

    // MARK: - Drawing

    /// Renders the tile menu.
    /// - Parameters:
    ///   - u8g2: Pointer to the u8g2 graphics context.
    ///   - origin: The absolute origin of the parent.
    public override func draw(u8g2: UnsafeMutablePointer<u8g2_t>?, origin: Point) {
        guard let u8g2 = u8g2 else { return }
        guard !items.isEmpty && !icons.isEmpty else { return }

        let absX = origin.x + frame.origin.x
        let absY = origin.y + frame.origin.y

        // Check if initialization animation is complete
        if !isInitialized {
            let iconXTarget = iconSpacing
            let targetTitleY = titleYTarget
            if abs(iconXOffset - iconXTarget) < Self.AnimationCompletionThreshold &&
               abs(titleY - targetTitleY) < Self.AnimationCompletionThreshold {
                isInitialized = true
                // Reset icon X offset to final position
                iconXOffset = -Double(selectedIndex) * iconSpacing
            }
        }

        // Draw icons in ScrollView
        drawIcons(u8g2: u8g2, absX: absX, absY: absY)

        // Draw title indicator (left side bar)
        u8g2_DrawBox(u8g2,
                    u8g2_uint_t(max(0, min(absX, Double(UInt16.max)))),
                    u8g2_uint_t(max(0, min(absY + indicatorTopMargin, Double(UInt16.max)))),
                    u8g2_uint_t(max(0, min(indiX, Double(UInt16.max)))),
                    u8g2_uint_t(indicatorHeight))

        // Draw title text
        drawTitle(u8g2: u8g2, absX: absX, absY: absY)
    }

    // MARK: - Private Methods

    /// Updates animations when selection changes.
    private func updateAnimations() {
        guard isInitialized else { return }

        // Update icon X offset based on selected index
        iconXOffset = -Double(selectedIndex) * iconSpacing

        // Update title Y animation (from bottom to top)
        _titleY.setCurrentValue(titleYInitial)
        titleY = titleYTarget

        // Reset indicator when selection changes
        _indiX.setCurrentValue(0)
        indiX = indicatorWidth
    }

    /// Updates scroll position to center selected icon.
    /// Note: The actual icon drawing uses iconXOffset animation, but we use ScrollView
    /// to manage the clipping and coordinate system for consistency.
    private func updateScrollPosition() {
        guard isInitialized else { return }

        // The icon position is managed by iconXOffset animation
        // ScrollView's contentOffset is used for clipping and coordinate management
        // Calculate the X position of the selected icon center in content coordinates
        let iconCenterX = (frame.size.width - iconWidth) / 2 + iconXOffset + Double(selectedIndex) * iconSpacing + iconWidth / 2

        // Calculate scroll offset to center the icon
        let scrollOffsetX = iconCenterX - frame.size.width / 2

        // Update ScrollView content offset
        scrollView.contentOffset.x = scrollOffsetX

        // Clamp to valid range
        let maxOffset = max(0, scrollView.contentSize.width - scrollView.frame.size.width)
        scrollView.contentOffset.x = max(0, min(scrollOffsetX, maxOffset))
    }

    /// Updates ScrollView content size based on number of items.
    private func updateScrollViewContentSize() {
        guard !items.isEmpty else { return }

        // Calculate total width needed for all icons
        let totalWidth = Double(items.count) * iconSpacing
        // Add extra space to allow centering the last icon
        let extraSpace = frame.size.width / 2 - iconWidth / 2
        scrollView.contentSize = Size(width: totalWidth + extraSpace, height: iconHeight)
    }

    /// Draws the icons in the ScrollView area.
    /// Uses ScrollView's clipping and coordinate system for proper bounds management.
    private func drawIcons(u8g2: UnsafeMutablePointer<u8g2_t>, absX: Double, absY: Double) {
        // Set clipping window for icon area (same as ScrollView would)
        u8g2_SetClipWindow(u8g2,
                           u8g2_uint_t(max(0, absX)),
                           u8g2_uint_t(max(0, absY)),
                           u8g2_uint_t(absX + scrollView.frame.size.width),
                           u8g2_uint_t(absY + scrollView.frame.size.height))

        u8g2_SetDrawColor(u8g2, 1)

        for (index, iconBits) in icons.enumerated() {
            let iconXPos: Double
            if !isInitialized {
                // Initial animation: icons slide in from center
                iconXPos = (frame.size.width - iconWidth) / 2 + Double(index) * iconXOffset - iconSpacing * Double(selectedIndex)
            } else {
                // Normal state: icons positioned relative to selected
                iconXPos = (frame.size.width - iconWidth) / 2 + iconXOffset + Double(index) * iconSpacing
            }

            // Calculate icon position (may be negative, which is OK - clipping will handle it)
            let iconDrawX = absX + iconXPos
            let iconDrawY = absY

            // Only draw if icon is within or partially within screen bounds
            let iconRightEdge = iconDrawX + iconWidth
            let iconLeftEdge = iconDrawX
            let screenRight = absX + frame.size.width
            let screenLeft = absX

            if iconRightEdge > screenLeft && iconLeftEdge < screenRight {
                iconBits.withUnsafeBufferPointer { ptr in
                    guard let baseAddress = ptr.baseAddress else { return }
                    // Use bitPattern to allow negative coordinates (clipping window handles boundaries)
                    let clampedX = max(Int16.min, min(Int16.max, Int16(iconDrawX)))
                    let clampedY = max(Int16.min, min(Int16.max, Int16(iconDrawY)))
                    u8g2_DrawXBM(u8g2,
                                u8g2_uint_t(bitPattern: clampedX),
                                u8g2_uint_t(bitPattern: clampedY),
                                u8g2_uint_t(iconWidth),
                                u8g2_uint_t(iconHeight),
                                baseAddress)
                }
            }
        }

        // Restore clipping window
        u8g2_SetMaxClipWindow(u8g2)
    }

    /// Draws the title text.
    private func drawTitle(u8g2: UnsafeMutablePointer<u8g2_t>, absX: Double, absY: Double) {
        guard selectedIndex < items.count else { return }

        let titleText = items[selectedIndex]
        let fontToUse = titleFont ?? u8g2_font_helvB18_tr
        u8g2_SetFont(u8g2, fontToUse)

        let textWidth = Double(u8g2_GetStrWidth(u8g2, titleText))
        // Center text in the area from indicator to screen edge
        let textX = ((frame.size.width - indicatorWidth) - textWidth) / 2 + indicatorWidth

        // Y position: titleY is the baseline position
        let textBaselineY = absY + titleY

        u8g2_DrawStr(u8g2,
                    u8g2_uint_t(max(0, min(absX + textX, Double(UInt16.max)))),
                    u8g2_uint_t(max(0, min(textBaselineY, Double(UInt16.max)))),
                    titleText)
    }
}
