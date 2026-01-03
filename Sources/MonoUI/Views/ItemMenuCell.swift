import CU8g2

// MARK: - ItemMenuCell

/// Base class for menu cells that display content in a list menu.
///
/// `ItemMenuCell` provides a base implementation for cells that can be used
/// in `ListMenu`. Subclasses should override `draw` and `idealSize` methods
/// to implement their specific UI.
///
/// Example:
/// ```swift
/// class CustomCell: ItemMenuCell {
///     override func draw(u8g2: UnsafeMutablePointer<u8g2_t>?, frame: Rect, isSelected: Bool) {
///         // Custom drawing logic
///     }
/// }
/// ```
open class ItemMenuCell {
    // MARK: - Public Properties
    
    /// The data model associated with this cell.
    public var model: ItemMenuCellModel?
    
    /// The frame of the cell (set by ListMenu during layout).
    public var frame: Rect = Rect(x: 0, y: 0, width: 0, height: 0)
    
    /// Whether this cell is currently selected.
    public var isSelected: Bool = false
    
    // MARK: - Initialization
    
    /// Initializes a new menu cell.
    public required init() {
    }
    
    // MARK: - Public Methods
    
    /// Draws the cell content.
    ///
    /// Subclasses should override this method to implement their specific drawing logic.
    /// - Parameters:
    ///   - u8g2: Pointer to the u8g2 graphics context.
    ///   - absX: The absolute X coordinate where the cell should be drawn.
    ///   - absY: The absolute Y coordinate where the cell should be drawn.
    ///   - isSelected: Whether this cell is currently selected.
    open func draw(u8g2: UnsafeMutablePointer<u8g2_t>?, absX: Double, absY: Double, isSelected: Bool) {
        // Default implementation does nothing
        // Subclasses should override this
    }
    
    /// Calculates the ideal size for the cell.
    ///
    /// Subclasses should override this method to return the ideal size based on the model.
    /// - Parameter u8g2: Optional u8g2 context for accurate measurement. If nil, uses estimation.
    /// - Returns: The ideal size for the cell.
    open func idealSize(u8g2: UnsafeMutablePointer<u8g2_t>? = nil) -> Size {
        // Default implementation returns model's cellHeight or 16.0
        if let model = model {
            return Size(width: 0, height: model.cellHeight)
        }
        return Size(width: 0, height: 16.0)
    }
    
    /// Prepares the cell for reuse with a new model.
    ///
    /// This method is called when the cell is about to be reused with a different model.
    /// Subclasses can override this to reset any cell-specific state.
    /// - Parameter model: The new model to use.
    open func prepareForReuse(with model: ItemMenuCellModel) {
        self.model = model
        self.isSelected = false
    }
}

