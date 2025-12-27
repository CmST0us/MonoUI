import CU8g2
#if canImport(Glibc)
import Glibc
#elseif canImport(Darwin)
import Darwin
#endif

// MARK: - IconTileView

/// A view that displays an icon with a rounded rectangle background.
///
/// `IconTileView` is typically used to represent selectable items in a grid or list,
/// such as menu items or app icons.
public class IconTileView: View {
    // MARK: - Public Properties
    
    /// The frame of the icon tile in its parent's coordinate system.
    public var frame: Rect
    
    /// Whether this tile is currently selected.
    public var isSelected: Bool = false
    
    /// Callback executed when the tile is clicked/activated.
    public var onClick: (() -> Void)?
    
    // MARK: - Private Properties
    
    /// The icon bitmap data in XBM format.
    private var iconBits: [UInt8]?
    
    /// The size of the icon in pixels.
    private var iconSize: Size
    
    // MARK: - Initialization
    
    /// Initializes a new icon tile view.
    /// - Parameters:
    ///   - frame: The frame of the tile.
    ///   - iconBits: Optional icon bitmap data in XBM format.
    ///   - iconSize: The size of the icon.
    ///   - onClick: Optional callback for click events.
    public init(frame: Rect, 
                iconBits: [UInt8]? = nil, 
                iconSize: Size = .zero,
                onClick: (() -> Void)? = nil) {
        self.frame = frame
        self.iconBits = iconBits
        self.iconSize = iconSize
        self.onClick = onClick
    }
    
    // MARK: - Drawing
    
    /// Renders the icon tile.
    /// - Parameters:
    ///   - u8g2: Pointer to the u8g2 graphics context.
    ///   - origin: The absolute origin of the parent.
    public func draw(u8g2: UnsafeMutablePointer<u8g2_t>?, origin: Point) {
        guard let u8g2 = u8g2 else { return }
        
        let absX = origin.x + frame.origin.x
        let absY = origin.y + frame.origin.y
        
        // Draw rounded rectangle background
        u8g2_DrawRBox(u8g2, 
                      u8g2_uint_t(bitPattern: Int16(absX)), 
                      u8g2_uint_t(bitPattern: Int16(absY)), 
                      u8g2_uint_t(frame.size.width), 
                      u8g2_uint_t(frame.size.height), 
                      4)
        
        // Draw icon if available
        if let iconBits = iconBits {
            drawIcon(u8g2: u8g2, absX: absX, absY: absY, iconBits: iconBits)
        }
    }
    
    // MARK: - Private Methods
    
    /// Draws the icon centered within the tile.
    private func drawIcon(u8g2: UnsafeMutablePointer<u8g2_t>, absX: Double, absY: Double, iconBits: [UInt8]) {
        // Set XOR draw mode for icon (will invert against white background)
        u8g2_SetDrawColor(u8g2, 2)
        
        // Calculate centered position
        let iconX = absX + (frame.size.width - iconSize.width) / 2
        let iconY = absY + (frame.size.height - iconSize.height) / 2
        
        // Draw the XBM bitmap
        iconBits.withUnsafeBufferPointer { ptr in
            guard let baseAddress = ptr.baseAddress else { return }
            u8g2_DrawXBM(u8g2, 
                         u8g2_uint_t(bitPattern: Int16(iconX)), 
                         u8g2_uint_t(bitPattern: Int16(iconY)), 
                         u8g2_uint_t(iconSize.width), 
                         u8g2_uint_t(iconSize.height), 
                         baseAddress)
        }
        
        // Restore default draw color
        u8g2_SetDrawColor(u8g2, 1)
    }
}
