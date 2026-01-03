import CU8g2

// MARK: - TextMenuCellModel

/// Data model for text-based menu cells.
public struct TextMenuCellModel: ItemMenuCellModel {
    /// The text to display.
    public let text: String
    
    /// Unique identifier based on text content.
    public var identifier: String {
        return text
    }
    
    /// Cell height (default: 16.0).
    public var cellHeight: Double
    
    /// Font to use for the text (optional, uses ListMenu's default if nil).
    public var font: UnsafePointer<UInt8>?
    
    /// Text padding (default: 4.0).
    public var textPadding: Double
    
    /// Initializes a new text menu cell model.
    /// - Parameters:
    ///   - text: The text to display.
    ///   - cellHeight: The height of the cell (default: 16.0).
    ///   - font: Optional font to use (default: nil, uses ListMenu's default).
    ///   - textPadding: Text padding (default: 4.0).
    public init(text: String, 
                cellHeight: Double = 16.0,
                font: UnsafePointer<UInt8>? = nil,
                textPadding: Double = 4.0) {
        self.text = text
        self.cellHeight = cellHeight
        self.font = font
        self.textPadding = textPadding
    }
}

// MARK: - TextMenuCell

/// A menu cell that displays text content.
///
/// `TextMenuCell` is the default cell implementation for `ListMenu`,
/// displaying simple text strings.
open class TextMenuCell: ItemMenuCell {
    // MARK: - Public Properties
    
    /// Font to use for text (default: u8g2_font_6x10_tf).
    public var font: UnsafePointer<UInt8>? = u8g2_font_6x10_tf
    
    /// Text padding (default: 4.0).
    public var textPadding: Double = 4.0
    
    // MARK: - Initialization
    
    /// Initializes a new text menu cell.
    public required init() {
        super.init()
    }
    
    // MARK: - Drawing
    
    /// Draws the text cell content.
    /// - Parameters:
    ///   - u8g2: Pointer to the u8g2 graphics context.
    ///   - absX: The absolute X coordinate where the cell should be drawn.
    ///   - absY: The absolute Y coordinate where the cell should be drawn.
    ///   - isSelected: Whether this cell is currently selected.
    public override func draw(u8g2: UnsafeMutablePointer<u8g2_t>?, absX: Double, absY: Double, isSelected: Bool) {
        guard let u8g2 = u8g2 else { return }
        guard let model = model as? TextMenuCellModel else { return }
        
        // Use model's font or cell's default font
        let fontToUse = model.font ?? self.font ?? u8g2_font_6x10_tf
        u8g2_SetFont(u8g2, fontToUse)
        
        // Calculate text position
        let padding = model.textPadding
        let fontAscent = Double(u8g2_GetAscent(u8g2))
        let textX = absX + padding
        let textY = absY + padding + fontAscent
        
        // Draw text (color is handled by ListMenu based on isSelected)
        u8g2_DrawStr(u8g2,
                    u8g2_uint_t(max(0, min(textX, Double(UInt16.max)))),
                    u8g2_uint_t(max(0, min(textY, Double(UInt16.max)))),
                    model.text)
    }
    
    /// Calculates the ideal size for the text cell.
    /// - Parameter u8g2: Optional u8g2 context for accurate measurement.
    /// - Returns: The ideal size for the cell.
    public override func idealSize(u8g2: UnsafeMutablePointer<u8g2_t>? = nil) -> Size {
        guard let model = model as? TextMenuCellModel else {
            return super.idealSize(u8g2: u8g2)
        }
        
        let height = model.cellHeight
        
        // Calculate width if u8g2 context is available
        let width: Double
        if let u8g2 = u8g2 {
            let fontToUse = model.font ?? self.font ?? u8g2_font_6x10_tf
            u8g2_SetFont(u8g2, fontToUse)
            width = Double(u8g2_GetStrWidth(u8g2, model.text)) + model.textPadding * 2
        } else {
            // Estimation: 6 pixels per character
            width = Double(model.text.count) * 6.0 + model.textPadding * 2
        }
        
        return Size(width: width, height: height)
    }
    
    /// Prepares the cell for reuse with a new model.
    /// - Parameter model: The new model to use.
    public override func prepareForReuse(with model: ItemMenuCellModel) {
        super.prepareForReuse(with: model)
        
        // Update font and padding if model is TextMenuCellModel
        if let textModel = model as? TextMenuCellModel {
            if let modelFont = textModel.font {
                self.font = modelFont
            }
            self.textPadding = textModel.textPadding
        }
    }
}

