import CU8g2

// MARK: - AnyView

/// A type-erased view wrapper.
/// Similar to SwiftUI's AnyView.
///
/// Use this to wrap views when you need to store different view types in the same container.
public class AnyView: View {
    public var frame: Rect {
        get { _view.frame }
        set { _view.frame = newValue }
    }
    
    private let _view: any View
    
    /// Creates an AnyView wrapping the given view.
    /// - Parameter view: The view to wrap.
    public init<V: View>(_ view: V) {
        self._view = view
        self.frame = view.frame
    }
    
    public func draw(u8g2: UnsafeMutablePointer<u8g2_t>?, origin: Point) {
        _view.draw(u8g2: u8g2, origin: origin)
    }
}

