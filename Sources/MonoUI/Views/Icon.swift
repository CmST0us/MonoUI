import CU8g2
#if canImport(Glibc)
import Glibc
#elseif canImport(Darwin)
import Darwin
#endif

// MARK: - Icon

/// A view that displays an icon bitmap.
///
/// `Icon` is similar to SwiftUI's image views, focusing on content rather than position.
/// Position and layout are managed by parent views like `HStack` or `VStack`.
///
/// Example:
/// ```swift
/// HStack {
///     Icon(iconBits: iconData, iconSize: Size(width: 16, height: 16))
///     Text("Label")
/// }
/// ```
public class Icon: View {
    // MARK: - Public Properties
    
    /// The frame of the icon view.
    public var frame: Rect
    
    /// The icon bitmap data in XBM format.
    public var iconBits: [UInt8]? {
        didSet {
            updateFrameIfNeeded()
        }
    }
    
    /// The size of the icon in pixels.
    public var iconSize: Size {
        didSet {
            updateFrameIfNeeded()
        }
    }
    
    /// The draw mode for the icon.
    public enum DrawMode {
        /// Normal draw mode (white on black background).
        case normal
        /// XOR draw mode (inverts against background).
        case xor
        /// Transparent mode (only draws foreground pixels).
        case transparent
    }
    
    /// The draw mode for rendering the icon.
    public var drawMode: DrawMode = .normal
    
    // MARK: - Initialization
    
    /// Initializes a new icon view with the specified icon data.
    /// This is the primary initializer, similar to SwiftUI's `Image`.
    /// Position is managed by parent views (e.g., HStack or VStack).
    /// - Parameters:
    ///   - iconBits: The icon bitmap data in XBM format.
    ///   - iconSize: The size of the icon in pixels.
    ///   - drawMode: The draw mode for rendering (default: .normal).
    public init(iconBits: [UInt8]?, iconSize: Size, drawMode: DrawMode = .normal) {
        self.iconBits = iconBits
        self.iconSize = iconSize
        self.drawMode = drawMode
        // Frame starts at zero with icon size, position will be set by layout system
        self.frame = Rect(x: 0, y: 0, width: iconSize.width, height: iconSize.height)
    }
    
    /// Initializes a new icon view with a fixed frame.
    /// Use this only when you need to manually position the icon.
    /// For most cases, use `Icon(iconBits:iconSize:)` and let HStack or VStack manage positioning.
    /// - Parameters:
    ///   - frame: The frame of the icon view.
    ///   - iconBits: The icon bitmap data in XBM format.
    ///   - iconSize: The size of the icon in pixels.
    ///   - drawMode: The draw mode for rendering (default: .normal).
    public init(frame: Rect, iconBits: [UInt8]?, iconSize: Size, drawMode: DrawMode = .normal) {
        self.frame = frame
        self.iconBits = iconBits
        self.iconSize = iconSize
        self.drawMode = drawMode
    }
    
    // MARK: - Drawing
    
    /// Renders the icon view.
    /// - Parameters:
    ///   - u8g2: Pointer to the u8g2 graphics context.
    ///   - origin: The absolute origin of the parent.
    public func draw(u8g2: UnsafeMutablePointer<u8g2_t>?, origin: Point) {
        guard let u8g2 = u8g2 else { return }
        guard let iconBits = iconBits else { return }
        
        let absX = origin.x + frame.origin.x
        let absY = origin.y + frame.origin.y
        
        // Set draw mode
        switch drawMode {
        case .normal:
            u8g2_SetDrawColor(u8g2, 1)
        case .xor:
            u8g2_SetDrawColor(u8g2, 2)
        case .transparent:
            u8g2_SetBitmapMode(u8g2, 1)
            u8g2_SetDrawColor(u8g2, 1)
        }
        
        // Draw the XBM bitmap
        iconBits.withUnsafeBufferPointer { ptr in
            guard let baseAddress = ptr.baseAddress else { return }
            u8g2_DrawXBM(u8g2,
                        u8g2_uint_t(bitPattern: Int16(absX)),
                        u8g2_uint_t(bitPattern: Int16(absY)),
                        u8g2_uint_t(iconSize.width),
                        u8g2_uint_t(iconSize.height),
                        baseAddress)
        }
        
        // Restore default draw mode
        if drawMode == .transparent {
            u8g2_SetBitmapMode(u8g2, 0)
        }
        u8g2_SetDrawColor(u8g2, 1)
    }
    
    // MARK: - Private Methods
    
    /// Updates the frame if needed based on icon size.
    private func updateFrameIfNeeded() {
        // If frame size doesn't match icon size, update it
        if frame.size.width != iconSize.width || frame.size.height != iconSize.height {
            frame = Rect(x: frame.origin.x, y: frame.origin.y, 
                        width: iconSize.width, height: iconSize.height)
        }
    }
}

