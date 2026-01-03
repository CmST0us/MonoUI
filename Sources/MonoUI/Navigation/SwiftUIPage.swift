import CU8g2

// Note: AnyView is defined in ViewBuilder/AnyView.swift

// MARK: - SwiftUIPage

/// A page that uses SwiftUI-style `body` property to define its content.
///
/// Similar to SwiftUI's View protocol, you can define the page content using a `body` property.
///
/// Example:
/// ```swift
/// class MyPage: SwiftUIPage {
///     var body: some View {
///         HStack {
///             Text("Hello")
///             Text("World")
///         }
///     }
/// }
/// ```
open class SwiftUIPage: Page {
    // MARK: - Body Property
    
    /// The body of the page. Override this property to define the page's content.
    /// This is similar to SwiftUI's `body` property.
    /// Subclasses should override this property to provide their content.
    ///
    /// Example:
    /// ```swift
    /// var body: some View {
    ///     HStack {
    ///         Text("Hello")
    ///         Text("World")
    ///     }
    /// }
    /// ```
    ///
    /// Note: In subclasses, you can use `@ViewBuilder` attribute:
    /// ```swift
    /// @ViewBuilder
    /// var body: AnyView {
    ///     HStack {
    ///         Text("Hello")
    ///         Text("World")
    ///     }
    /// }
    /// ```
    open var body: AnyView {
        // Default empty body - subclasses should override
        return AnyView(EmptyView())
    }
    
    // MARK: - Cached Body View
    
    /// Cached body view to avoid recomputing on every draw
    private var bodyViewContainer: (any View)?
    
    // MARK: - Initialization
    
    /// Initializes a new SwiftUI-style page.
    /// The frame will be set to the screen bounds automatically.
    public init() {
        let screenSize = Context.shared.screenSize
        super.init(frame: Rect(x: 0, y: 0, width: screenSize.width, height: screenSize.height))
        updateBody()
    }
    
    /// Initializes a new SwiftUI-style page with a custom frame.
    /// - Parameter frame: The frame of the page.
    public override init(frame: Rect) {
        super.init(frame: frame)
        updateBody()
    }
    
    // MARK: - Body Management
    
    /// Updates the page's children from the body property.
    /// This should be called when state changes to refresh the view.
    open func updateBody() {
        let bodyView = body
        bodyViewContainer = bodyView
        
        // AnyView wraps a single view, so we extract from the wrapped view
        // Use reflection to get the wrapped view
        let mirror = Mirror(reflecting: bodyView)
        if let wrappedView = mirror.children.first(where: { $0.label == "_view" })?.value as? (any View) {
            let extractedChildren = ViewExtractionHelper.extractChildren(from: wrappedView)
            
            // Layout children to center them in the page
            layoutBodyChildren(extractedChildren)
            
            children = extractedChildren
        } else {
            // Fallback: treat AnyView itself as a child
            children = [bodyView]
            layoutBodyChildren(children)
        }
    }
    
    /// Lays out body children to center them in the page.
    private func layoutBodyChildren(_ children: [any View]) {
        guard !children.isEmpty else { return }
        
        // If there's only one child, center it
        if children.count == 1 {
            let child = children[0]
            
            // Check if child is a container (HStack/VStack) that handles its own layout
            let childTypeName = String(describing: type(of: child))
            let isContainer = childTypeName.contains("HStack") || childTypeName.contains("VStack")
            
            if isContainer {
                // For containers (VStack/HStack), they should be centered in the page
                // First ensure children have valid frame sizes
                let containerChildren = ViewExtractionHelper.extractChildren(from: child)
                for containerChild in containerChildren {
                    // Ensure each child has a valid size (Text views need at least estimated size)
                    if containerChild.frame.size.width <= 0 {
                        if let text = containerChild as? Text {
                            let estimatedWidth = Double(text.text.count) * 6.0
                            containerChild.frame = Rect(x: containerChild.frame.origin.x,
                                                       y: containerChild.frame.origin.y,
                                                       width: max(estimatedWidth, 60.0),
                                                       height: max(containerChild.frame.size.height, 10.0))
                        }
                    }
                    if containerChild.frame.size.height <= 0 {
                        containerChild.frame = Rect(x: containerChild.frame.origin.x,
                                                   y: containerChild.frame.origin.y,
                                                   width: containerChild.frame.size.width,
                                                   height: 10.0)
                    }
                }
                
                // Set container frame to page size to allow it to center its content
                let pageWidth = frame.size.width > 0 ? frame.size.width : 128
                let pageHeight = frame.size.height > 0 ? frame.size.height : 64
                
                // Set container to full page size - VStack/HStack will center its content internally
                // For HStack with Spacer, we want it to use the full width
                // Setting the frame will trigger didSet and layoutContent()
                child.frame = Rect(x: 0, y: 0, width: pageWidth, height: pageHeight)
                
                // After layoutContent is triggered by didSet, the container should have correct size
                // For HStack with Spacer, we want it to use full page width
                let childTypeName = String(describing: type(of: child))
                let isHStack = childTypeName.contains("HStack")
                
                let centerX: Double
                let finalWidth: Double
                let finalHeight: Double
                
                if isHStack {
                    // HStack should span full width when it has Spacer
                    centerX = 0
                    finalWidth = pageWidth
                    finalHeight = child.frame.size.height > 0 ? child.frame.size.height : pageHeight
                } else {
                    // VStack should be centered
                    let containerWidth = child.frame.size.width
                    let containerHeight = child.frame.size.height
                    centerX = (frame.size.width - containerWidth) / 2
                    finalWidth = containerWidth
                    finalHeight = containerHeight
                }
                
                let centerY = (frame.size.height - finalHeight) / 2
                
                // Set final position
                // For HStack, we need to preserve the width so Spacer calculation is correct
                // Only update position if width/height haven't changed to avoid unnecessary re-layout
                if child.frame.size.width != finalWidth || child.frame.size.height != finalHeight ||
                   child.frame.origin.x != centerX || child.frame.origin.y != centerY {
                    child.frame = Rect(x: centerX, y: centerY,
                                     width: finalWidth,
                                     height: finalHeight)
                }
            } else {
                // Single view - center it
                let centerX = (frame.size.width - child.frame.size.width) / 2
                let centerY = (frame.size.height - child.frame.size.height) / 2
                child.frame = Rect(x: centerX, y: centerY,
                                 width: child.frame.size.width,
                                 height: child.frame.size.height)
            }
        } else {
            // Multiple children - center them as a group
            // Calculate bounding box
            var minX = Double.infinity
            var minY = Double.infinity
            var maxX = -Double.infinity
            var maxY = -Double.infinity
            
            for child in children {
                minX = min(minX, child.frame.origin.x)
                minY = min(minY, child.frame.origin.y)
                maxX = max(maxX, child.frame.origin.x + child.frame.size.width)
                maxY = max(maxY, child.frame.origin.y + child.frame.size.height)
            }
            
            let groupWidth = maxX - minX
            let groupHeight = maxY - minY
            let centerX = (frame.size.width - groupWidth) / 2 - minX
            let centerY = (frame.size.height - groupHeight) / 2 - minY
            
            // Offset all children
            for child in children {
                child.frame = Rect(x: child.frame.origin.x + centerX,
                                 y: child.frame.origin.y + centerY,
                                 width: child.frame.size.width,
                                 height: child.frame.size.height)
            }
        }
    }
    
    // MARK: - Drawing
    
    /// Renders the page and its body content.
    /// - Parameters:
    ///   - u8g2: Pointer to the u8g2 graphics context.
    ///   - origin: The absolute origin point.
    open override func draw(u8g2: UnsafeMutablePointer<u8g2_t>?, origin: Point) {
        guard let u8g2 = u8g2 else { return }
        
        let absX = origin.x + frame.origin.x
        let absY = origin.y + frame.origin.y
        
        // Draw opaque background to prevent bleed-through from previous page
        u8g2_SetDrawColor(u8g2, 0)
        u8g2_DrawBox(u8g2, u8g2_uint_t(absX), u8g2_uint_t(absY), 
                     u8g2_uint_t(frame.size.width), u8g2_uint_t(frame.size.height))
        u8g2_SetDrawColor(u8g2, 1)
        
        // Draw body content
        let childOrigin = Point(x: absX, y: absY)
        for child in children {
            child.draw(u8g2: u8g2, origin: childOrigin)
        }
    }
}

// MARK: - EmptyView

/// An empty view that renders nothing.
/// Used as the default body for SwiftUIPage.
public class EmptyView: View {
    public var frame: Rect = .zero
    
    public init() {}
    
    public func draw(u8g2: UnsafeMutablePointer<u8g2_t>?, origin: Point) {
        // Empty view renders nothing
    }
}

