import CU8g2

// MARK: - ListMenu

/// A scrollable menu list with cursor navigation and highlighting.
///
/// `ListMenu` manages a list of menu items with cursor-based navigation:
/// - Uses `ItemMenuCell` and `ItemMenuCellModel` for data-driven rendering
/// - Cursor position and size are animated
/// - Item positions are animated from y=0 when menu appears
/// - Cursor and text overlap areas are displayed with inverse colors
///
/// Example:
/// ```swift
/// let menu = ListMenu(size: Size(width: 128, height: 64))
/// menu.setItems(["Item 1", "Item 2", "Item 3"]) // Convenience method
/// // Or use models directly:
/// menu.models = [TextMenuCellModel(text: "Item 1"), ...]
/// menu.selectedIndex = 0
/// ```
open class ListMenu: ScrollView {
    // MARK: - Public Properties
    
    /// The list of data models to display.
    public var models: [ItemMenuCellModel] = [] {
        didSet {
            // Initialize item Y positions with animation from y=0
            itemYPositions = []
            var currentY: Double = 0
            for model in models {
                let animValue = AnimationValue(wrappedValue: 0)
                animValue.speed = itemAnimationSpeed
                // Set current value to 0, then animate to target
                animValue.setCurrentValue(0)
                animValue.wrappedValue = currentY
                itemYPositions.append(animValue)
                currentY += model.cellHeight
            }
            
            // Clear cell cache when models change
            cellCache.removeAll()
            
            updateContentSize()
            if selectedIndex >= models.count {
                selectedIndex = max(0, models.count - 1)
            }
            updateCursorAnimation()
        }
    }
    
    /// The list of text items to display (convenience property).
    /// Setting this automatically creates `TextMenuCellModel` instances.
    public var items: [String] {
        get {
            return models.compactMap { $0 as? TextMenuCellModel }.map { $0.text }
        }
        set {
            self.models = newValue.map { TextMenuCellModel(text: $0, cellHeight: lineHeight, font: font, textPadding: textPadding) }
        }
    }
    
    /// The currently selected item index.
    public var selectedIndex: Int = 0 {
        didSet {
            let clampedIndex = max(0, min(selectedIndex, models.count - 1))
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
        return models.count
    }
    
    /// Cell class type to use for creating cells (default: TextMenuCell).
    /// Subclasses can override this to use different cell types.
    open var cellClass: ItemMenuCell.Type = TextMenuCell.self
    
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
    
    /// Animation speed for item appearance (default: 40.0).
    public var itemAnimationSpeed: Double = 40.0
    
    /// Corner radius for the selection box (default: 0.5).
    public var selectionCornerRadius: Double = 0.5
    
    /// Width of the scroll progress bar on the right side (default: 5.0).
    public var scrollBarWidth: Double = 5.0
    
    // MARK: - Private Properties
    
    /// Animated Y positions for each item in content coordinates.
    private var itemYPositions: [AnimationValue<Double>] = []
    
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
    
    /// Cached text widths for each item (for backward compatibility).
    private var textWidths: [Double] = []
    
    /// Cell cache for reuse (keyed by model identifier).
    private var cellCache: [String: ItemMenuCell] = [:]
    
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
    
    /// Sets the list items (convenience method).
    /// - Parameter items: Array of text strings to display.
    public func setItems(_ items: [String]) {
        self.items = items
        textWidths = []
        // Item Y positions are initialized in models didSet
    }
    
    /// Gets or creates a cell for the given model.
    /// - Parameter model: The model to get a cell for.
    /// - Returns: A cell instance configured with the model.
    private func cellForModel(_ model: ItemMenuCellModel) -> ItemMenuCell {
        // Try to reuse cell from cache
        if let cachedCell = cellCache[model.identifier] {
            cachedCell.prepareForReuse(with: model)
            return cachedCell
        }
        
        // Create new cell
        let cell = cellClass.init()
        cell.model = model
        cellCache[model.identifier] = cell
        return cell
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
        
        // Draw all cells except the selected one (normal color)
        // The selected cell will be drawn later with inverse color over the cursor
        u8g2_SetDrawColor(u8g2, 1)
        for (index, model) in models.enumerated() {
            // Skip selected item - it will be drawn with inverse color later
            if index == selectedIndex {
                continue
            }
            
            // Use animated Y position for item
            let itemY: Double
            if index < itemYPositions.count {
                itemY = itemYPositions[index].wrappedValue
            } else {
                // Fallback: calculate from previous items
                var calculatedY: Double = 0
                for i in 0..<index {
                    calculatedY += models[i].cellHeight
                }
                itemY = calculatedY
            }
            
            let itemHeight = model.cellHeight
            let itemScreenY = absY + itemY - contentOffset.y
            
            // Only draw if item is visible in viewport
            if itemScreenY + itemHeight >= absY && itemScreenY <= absY + frame.size.height {
                // Get or create cell for this model
                let cell = cellForModel(model)
                cell.isSelected = false
                cell.frame = Rect(x: 0, y: itemY, width: frame.size.width, height: itemHeight)
                
                // Draw cell
                cell.draw(u8g2: u8g2, absX: absX, absY: absY + itemY - contentOffset.y, isSelected: false)
            }
        }
        
        // Draw cursor (selection box) and selected cell with inverse color
        drawCursor(u8g2: u8g2, absX: absX, absY: absY)
        
        // Draw scroll progress bar on the right side
        drawScrollBar(u8g2: u8g2, absX: absX, absY: absY)
        
        // Restore clipping window
        u8g2_SetMaxClipWindow(u8g2)
    }
    
    // MARK: - Private Methods
    
    /// Draws the cursor (selection box) and selected cell with inverse colors.
    private func drawCursor(u8g2: UnsafeMutablePointer<u8g2_t>, absX: Double, absY: Double) {
        guard selectedIndex >= 0 && selectedIndex < models.count else { return }
        
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
            
            // Draw selected cell in inverse color (over the selection box)
            let selectedModel = models[selectedIndex]
            // Use animated Y position for selected item
            let itemY: Double
            if selectedIndex < itemYPositions.count {
                itemY = itemYPositions[selectedIndex].wrappedValue
            } else {
                // Fallback: calculate from previous items
                var calculatedY: Double = 0
                for i in 0..<selectedIndex {
                    calculatedY += models[i].cellHeight
                }
                itemY = calculatedY
            }
            
            let itemHeight = selectedModel.cellHeight
            let itemScreenY = absY + itemY - contentOffset.y
            
            // Get or create cell for selected model
            let cell = cellForModel(selectedModel)
            cell.isSelected = true
            cell.frame = Rect(x: 0, y: itemY, width: frame.size.width, height: itemHeight)
            
            // Draw selected cell
            cell.draw(u8g2: u8g2, absX: absX, absY: itemScreenY, isSelected: true)
            
            // Restore draw color
            u8g2_SetDrawColor(u8g2, 1)
        }
    }
    
    /// Updates the cursor animation targets based on the selected item.
    private func updateCursorAnimation() {
        guard selectedIndex >= 0 && selectedIndex < models.count else { return }
        
        // Calculate target cursor position (Y position)
        var targetY: Double = 0
        for i in 0..<selectedIndex {
            targetY += models[i].cellHeight
        }
        
        let selectedModel = models[selectedIndex]
        let targetHeight = selectedModel.cellHeight
        
        // Calculate target cursor width
        // For TextMenuCellModel, use cached text width if available
        let targetWidth: Double
        if let textModel = selectedModel as? TextMenuCellModel {
            if selectedIndex < textWidths.count {
                targetWidth = textWidths[selectedIndex] + textModel.textPadding * 2
            } else {
                // Default width, will be updated when we measure the text
                targetWidth = frame.size.width
            }
        } else {
            // For other cell types, use cell's ideal size
            let cell = cellForModel(selectedModel)
            let idealSize = cell.idealSize(u8g2: nil)
            targetWidth = min(idealSize.width, frame.size.width)
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
        guard selectedIndex >= 0 && selectedIndex < models.count else { return }
        
        // Calculate item position in content coordinates
        var itemY: Double = 0
        for i in 0..<selectedIndex {
            itemY += models[i].cellHeight
        }
        let itemHeight = models[selectedIndex].cellHeight
        
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
        guard models.count > 1 else {
            scrollBarY = 0
            return
        }
        
        // Calculate scroll bar position: map selected index to viewport height
        let scrollBarTargetY = Double(selectedIndex) * (frame.size.height / Double(models.count - 1))
        scrollBarY = scrollBarTargetY
    }
    
    /// Draws the scroll progress bar on the right side.
    private func drawScrollBar(u8g2: UnsafeMutablePointer<u8g2_t>, absX: Double, absY: Double) {
        guard models.count > 1 else { return }
        
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
    
    /// Updates the content size based on the models.
    private func updateContentSize() {
        let totalHeight = models.reduce(0.0) { $0 + $1.cellHeight }
        contentSize = Size(width: frame.size.width, height: totalHeight)
        
        // Update cursor animation after content size update
        if selectedIndex < models.count {
            updateCursorAnimation()
        }
    }
    
    /// Updates text widths cache when drawing (called during draw).
    /// This is for backward compatibility with TextMenuCellModel.
    private func updateTextWidthsCache(u8g2: UnsafeMutablePointer<u8g2_t>?) {
        guard let u8g2 = u8g2 else { return }
        
        // Only update cache for TextMenuCellModel items
        let textModels = models.compactMap { $0 as? TextMenuCellModel }
        if textModels.count == models.count && textWidths.count != textModels.count {
            let fontToUse = font ?? u8g2_font_6x10_tf
            u8g2_SetFont(u8g2, fontToUse)
            
            textWidths = textModels.map { Double(u8g2_GetStrWidth(u8g2, $0.text)) }
            
            // Update cursor width if selected item width changed
            if selectedIndex < textWidths.count, let textModel = models[selectedIndex] as? TextMenuCellModel {
                let targetWidth = textWidths[selectedIndex] + textModel.textPadding * 2
                cursorWidth = targetWidth
            }
        }
    }
}
