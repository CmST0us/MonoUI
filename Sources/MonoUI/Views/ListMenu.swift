import CU8g2

// MARK: - ListMenu

/// A scrollable menu list with cursor navigation and highlighting.
///
/// `ListMenu` manages a list of text items with cursor-based navigation:
/// - Text items are directly laid out within the menu (no StackView)
/// - Cursor position and size are animated
/// - Text positions remain fixed when cursor moves
/// - Cursor and text overlap areas are displayed with inverse colors
///
/// Example:
/// ```swift
/// let menu = ListMenu(size: Size(width: 128, height: 64))
/// menu.setItems(["Item 1", "Item 2", "Item 3"])
/// menu.selectedIndex = 0
/// ```
open class ListMenu: ScrollView {
    // MARK: - Public Properties
    
    /// The list of text items to display.
    public var items: [String] = [] {
        didSet {
            updateContentSize()
            if selectedIndex >= items.count {
                selectedIndex = max(0, items.count - 1)
            }
            updateCursorAnimation()
        }
    }
    
    /// The currently selected item index.
    public var selectedIndex: Int = 0 {
        didSet {
            let clampedIndex = max(0, min(selectedIndex, items.count - 1))
            if clampedIndex != selectedIndex {
                selectedIndex = clampedIndex
                return
            }
            updateCursorAnimation()
            updateScrollForCursor()
        }
    }
    
    /// The number of items in the menu.
    public var itemCount: Int {
        return items.count
    }
    
    /// Font to use for text items (default: u8g2_font_6x10_tf).
    public var font: UnsafePointer<UInt8>? = u8g2_font_6x10_tf
    
    /// Height of each line/item (default: 16.0).
    public var lineHeight: Double = 16.0
    
    /// Text padding (default: 4.0).
    public var textPadding: Double = 4.0
    
    /// Animation speed for cursor movement (default: 60.0).
    public var cursorAnimationSpeed: Double = 60.0
    
    /// Animation speed for scroll movement (default: 25.0).
    public var scrollAnimationSpeed: Double = 25.0
    
    /// Corner radius for the selection box (default: 0.5).
    public var selectionCornerRadius: Double = 0.5
    
    /// Width of the scroll progress bar on the right side (default: 5.0).
    public var scrollBarWidth: Double = 5.0
    
    // MARK: - Private Properties
    
    /// Animated cursor Y position in content coordinates.
    @AnimationValue private var cursorY: Double = 0
    
    /// Animated cursor height.
    @AnimationValue private var cursorHeight: Double = 0
    
    /// Animated cursor width.
    @AnimationValue private var cursorWidth: Double = 0
    
    /// Animated scroll offset.
    @AnimationValue private var animatedScrollOffset: Double = 0
    
    /// Animated scroll bar Y position.
    @AnimationValue private var scrollBarY: Double = 0
    
    /// Cached text widths for each item.
    private var textWidths: [Double] = []
    
    // MARK: - Initialization
    
    /// Initializes a new list menu with the specified size.
    /// - Parameters:
    ///   - size: The size of the menu viewport.
    public override init(size: Size, direction: ScrollDirection = .vertical) {
        super.init(size: size, direction: direction)
        self._cursorY = AnimationValue(wrappedValue: 0)
        self._cursorHeight = AnimationValue(wrappedValue: 0)
        self._cursorWidth = AnimationValue(wrappedValue: 0)
        self._animatedScrollOffset = AnimationValue(wrappedValue: 0)
        self._scrollBarY = AnimationValue(wrappedValue: 0)
        
        _cursorY.speed = cursorAnimationSpeed
        _cursorHeight.speed = cursorAnimationSpeed
        _cursorWidth.speed = cursorAnimationSpeed
        _animatedScrollOffset.speed = scrollAnimationSpeed
        _scrollBarY.speed = cursorAnimationSpeed
    }
    
    /// Initializes a new list menu with the specified frame.
    /// - Parameter frame: The frame of the menu.
    public override init(frame: Rect) {
        super.init(frame: frame)
        self._cursorY = AnimationValue(wrappedValue: 0)
        self._cursorHeight = AnimationValue(wrappedValue: 0)
        self._cursorWidth = AnimationValue(wrappedValue: 0)
        self._animatedScrollOffset = AnimationValue(wrappedValue: 0)
        self._scrollBarY = AnimationValue(wrappedValue: 0)
        
        _cursorY.speed = cursorAnimationSpeed
        _cursorHeight.speed = cursorAnimationSpeed
        _cursorWidth.speed = cursorAnimationSpeed
        _animatedScrollOffset.speed = scrollAnimationSpeed
        _scrollBarY.speed = cursorAnimationSpeed
    }
    
    // MARK: - Public Methods
    
    /// Sets the list items.
    /// - Parameter items: Array of text strings to display.
    public func setItems(_ items: [String]) {
        self.items = items
        textWidths = []
    }
    
    /// Moves the cursor up by one item.
    public func moveUp() {
        if selectedIndex > 0 {
            selectedIndex -= 1
        }
    }
    
    /// Moves the cursor down by one item.
    public func moveDown() {
        if selectedIndex < items.count - 1 {
            selectedIndex += 1
        }
    }
    
    // MARK: - Drawing
    
    /// Renders the list menu with cursor highlighting.
    /// - Parameters:
    ///   - u8g2: Pointer to the u8g2 graphics context.
    ///   - origin: The absolute origin of the parent.
    open override func draw(u8g2: UnsafeMutablePointer<u8g2_t>?, origin: Point) {
        guard let u8g2 = u8g2 else { return }
        
        // Update scroll offset from animation
        contentOffset.y = animatedScrollOffset
        
        // Calculate absolute position of the scroll view
        let absX = origin.x + frame.origin.x
        let absY = origin.y + frame.origin.y
        
        // Set clipping window to constrain drawing
        u8g2_SetClipWindow(u8g2,
                           u8g2_uint_t(max(0, absX)),
                           u8g2_uint_t(max(0, absY)),
                           u8g2_uint_t(absX + frame.size.width),
                           u8g2_uint_t(absY + frame.size.height))
        
        // Set font
        let fontToUse = font ?? u8g2_font_6x10_tf
        u8g2_SetFont(u8g2, fontToUse)
        
        // Update text widths cache
        updateTextWidthsCache(u8g2: u8g2)
        
        // Calculate font metrics
        let fontAscent = Double(u8g2_GetAscent(u8g2))
        
        // Draw all text items except the selected one (normal color)
        // The selected text will be drawn later with inverse color over the cursor
        u8g2_SetDrawColor(u8g2, 1)
        for (index, item) in items.enumerated() {
            // Skip selected item - it will be drawn with inverse color later
            if index == selectedIndex {
                continue
            }
            
            let itemY = Double(index) * lineHeight
            let itemScreenY = absY + itemY - contentOffset.y
            
            // Only draw if item is visible in viewport
            if itemScreenY + lineHeight >= absY && itemScreenY <= absY + frame.size.height {
                let textX = absX + textPadding
                let textY = absY + itemY + textPadding + fontAscent - contentOffset.y
                
                // Draw text (normal color)
                u8g2_DrawStr(u8g2,
                            u8g2_uint_t(max(0, min(textX, Double(UInt16.max)))),
                            u8g2_uint_t(max(0, min(textY, Double(UInt16.max)))),
                            item)
            }
        }
        
        // Draw cursor (selection box) and selected text with inverse color
        drawCursor(u8g2: u8g2, absX: absX, absY: absY, fontAscent: fontAscent)
        
        // Draw scroll progress bar on the right side
        drawScrollBar(u8g2: u8g2, absX: absX, absY: absY)
        
        // Restore clipping window
        u8g2_SetMaxClipWindow(u8g2)
    }
    
    // MARK: - Private Methods
    
    /// Draws the cursor (selection box) and selected text with inverse colors.
    private func drawCursor(u8g2: UnsafeMutablePointer<u8g2_t>, absX: Double, absY: Double, fontAscent: Double) {
        guard selectedIndex >= 0 && selectedIndex < items.count else { return }
        
        // Calculate cursor position in screen coordinates
        let cursorContentY = cursorY
        let cursorScreenY = absY + cursorContentY - contentOffset.y
        
        // Check if cursor is visible in viewport
        if cursorScreenY + cursorHeight >= absY && cursorScreenY <= absY + frame.size.height {
            // Draw selection box with rounded corners (inverse color)
            u8g2_SetDrawColor(u8g2, 2) // Inverse color
            u8g2_DrawRBox(u8g2,
                         u8g2_uint_t(max(0, min(absX, Double(UInt16.max)))),
                         u8g2_uint_t(max(0, min(cursorScreenY, Double(UInt16.max)))),
                         u8g2_uint_t(max(0, min(cursorWidth, Double(UInt16.max)))),
                         u8g2_uint_t(max(0, min(cursorHeight, Double(UInt16.max)))),
                         u8g2_uint_t(selectionCornerRadius))
            
            // Draw selected text in inverse color (over the selection box)
            let selectedItem = items[selectedIndex]
            let itemY = Double(selectedIndex) * lineHeight
            let textX = absX + textPadding
            let textY = absY + itemY + textPadding + fontAscent - contentOffset.y
            
            u8g2_DrawStr(u8g2,
                        u8g2_uint_t(max(0, min(textX, Double(UInt16.max)))),
                        u8g2_uint_t(max(0, min(textY, Double(UInt16.max)))),
                        selectedItem)
            
            // Restore draw color
            u8g2_SetDrawColor(u8g2, 1)
        }
    }
    
    /// Updates the cursor animation targets based on the selected item.
    private func updateCursorAnimation() {
        guard selectedIndex >= 0 && selectedIndex < items.count else { return }
        
        // Calculate target cursor position (Y position)
        let targetY = Double(selectedIndex) * lineHeight
        let targetHeight = lineHeight
        
        // Calculate target cursor width (text width + padding on both sides)
        // We need to measure the text width, but we'll do it during draw
        // For now, use a reasonable default or cached value
        let targetWidth: Double
        if selectedIndex < textWidths.count {
            targetWidth = textWidths[selectedIndex] + textPadding * 2
        } else {
            // Default width, will be updated when we measure the text
            targetWidth = frame.size.width
        }
        
        // Update animation targets
        cursorY = targetY
        cursorHeight = targetHeight
        cursorWidth = targetWidth
        
        // Update scroll bar position
        updateScrollBarPosition()
    }
    
    /// Measures text width and updates cursor width if needed.
    private func measureTextWidth(u8g2: UnsafeMutablePointer<u8g2_t>?, text: String) -> Double {
        guard let u8g2 = u8g2 else { return 0 }
        let fontToUse = font ?? u8g2_font_6x10_tf
        u8g2_SetFont(u8g2, fontToUse)
        return Double(u8g2_GetStrWidth(u8g2, text))
    }
    
    /// Updates the scroll offset to keep the cursor visible.
    private func updateScrollForCursor() {
        guard selectedIndex >= 0 && selectedIndex < items.count else { return }
        
        // Calculate item position in content coordinates
        let itemY = Double(selectedIndex) * lineHeight
        let itemHeight = lineHeight
        
        // Calculate item position relative to viewport
        let itemTopInViewport = itemY - animatedScrollOffset
        let itemBottomInViewport = itemY + itemHeight - animatedScrollOffset
        
        // Define margins for auto-scrolling
        let topMargin: Double = 5
        let bottomMargin: Double = 5
        
        // If item is near bottom of viewport, scroll up
        if itemBottomInViewport > frame.size.height - bottomMargin {
            let targetOffset = itemY + itemHeight - frame.size.height + bottomMargin
            animatedScrollOffset = max(0, min(targetOffset, max(0, contentSize.height - frame.size.height)))
        }
        // If item is near top of viewport, scroll down
        else if itemTopInViewport < topMargin {
            let targetOffset = itemY - topMargin
            animatedScrollOffset = max(0, min(targetOffset, max(0, contentSize.height - frame.size.height)))
        }
        
        // Update scroll bar position based on selected index
        updateScrollBarPosition()
    }
    
    /// Updates the scroll bar position based on the selected index.
    private func updateScrollBarPosition() {
        guard items.count > 1 else {
            scrollBarY = 0
            return
        }
        
        // Calculate scroll bar position: map selected index to viewport height
        let scrollBarTargetY = Double(selectedIndex) * (frame.size.height / Double(items.count - 1))
        scrollBarY = scrollBarTargetY
    }
    
    /// Draws the scroll progress bar on the right side.
    private func drawScrollBar(u8g2: UnsafeMutablePointer<u8g2_t>, absX: Double, absY: Double) {
        guard items.count > 1 else { return }
        
        // Calculate scroll bar position
        let barX = absX + frame.size.width - scrollBarWidth
        
        // Set draw color to normal
        u8g2_SetDrawColor(u8g2, 1)
        
        // Draw top horizontal line
        u8g2_DrawHLine(u8g2,
                      u8g2_uint_t(max(0, min(barX, Double(UInt16.max)))),
                      u8g2_uint_t(max(0, min(absY, Double(UInt16.max)))),
                      u8g2_uint_t(max(0, min(scrollBarWidth, Double(UInt16.max)))))
        
        // Draw bottom horizontal line
        u8g2_DrawHLine(u8g2,
                      u8g2_uint_t(max(0, min(barX, Double(UInt16.max)))),
                      u8g2_uint_t(max(0, min(absY + frame.size.height - 1, Double(UInt16.max)))),
                      u8g2_uint_t(max(0, min(scrollBarWidth, Double(UInt16.max)))))
        
        // Draw center vertical line
        let centerX = barX + scrollBarWidth / 2
        u8g2_DrawVLine(u8g2,
                      u8g2_uint_t(max(0, min(centerX, Double(UInt16.max)))),
                      u8g2_uint_t(max(0, min(absY, Double(UInt16.max)))),
                      u8g2_uint_t(max(0, min(frame.size.height, Double(UInt16.max)))))
        
        // Draw filled portion (from top to current scroll bar position)
        let filledHeight = max(0, min(scrollBarY, frame.size.height))
        if filledHeight > 0 {
            u8g2_DrawBox(u8g2,
                        u8g2_uint_t(max(0, min(barX, Double(UInt16.max)))),
                        u8g2_uint_t(max(0, min(absY, Double(UInt16.max)))),
                        u8g2_uint_t(max(0, min(scrollBarWidth, Double(UInt16.max)))),
                        u8g2_uint_t(max(0, min(filledHeight, Double(UInt16.max)))))
        }
    }
    
    /// Updates the content size based on the items.
    private func updateContentSize() {
        let totalHeight = Double(items.count) * lineHeight
        contentSize = Size(width: frame.size.width, height: totalHeight)
        
        // Update cursor animation after content size update
        if selectedIndex < items.count {
            updateCursorAnimation()
        }
    }
    
    /// Updates text widths cache when drawing (called during draw).
    private func updateTextWidthsCache(u8g2: UnsafeMutablePointer<u8g2_t>?) {
        guard let u8g2 = u8g2, textWidths.count != items.count else { return }
        
        let fontToUse = font ?? u8g2_font_6x10_tf
        u8g2_SetFont(u8g2, fontToUse)
        
        textWidths = items.map { Double(u8g2_GetStrWidth(u8g2, $0)) }
        
        // Update cursor width if selected item width changed
        if selectedIndex < textWidths.count {
            let targetWidth = textWidths[selectedIndex] + textPadding * 2
            cursorWidth = targetWidth
        }
    }
}
