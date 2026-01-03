import CU8g2

// MARK: - ViewBuilder

/// A result builder that constructs views from a series of view expressions.
/// Similar to SwiftUI's ViewBuilder.
///
/// This allows you to use a SwiftUI-like syntax for building view hierarchies:
/// ```swift
/// VStack {
///     Text("Hello")
///     Text("World")
/// }
/// ```
@resultBuilder
public enum ViewBuilder {
    /// Builds a single view.
    public static func buildBlock<Content: View>(_ content: Content) -> Content {
        return content
    }
    
    /// Builds multiple views into a tuple.
    public static func buildBlock<C0: View, C1: View>(_ c0: C0, _ c1: C1) -> TupleView<(C0, C1)> {
        return TupleView((c0, c1))
    }
    
    /// Builds three views into a tuple.
    public static func buildBlock<C0: View, C1: View, C2: View>(_ c0: C0, _ c1: C1, _ c2: C2) -> TupleView<(C0, C1, C2)> {
        return TupleView((c0, c1, c2))
    }
    
    /// Builds four views into a tuple.
    public static func buildBlock<C0: View, C1: View, C2: View, C3: View>(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3) -> TupleView<(C0, C1, C2, C3)> {
        return TupleView((c0, c1, c2, c3))
    }
    
    /// Builds five views into a tuple.
    public static func buildBlock<C0: View, C1: View, C2: View, C3: View, C4: View>(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4) -> TupleView<(C0, C1, C2, C3, C4)> {
        return TupleView((c0, c1, c2, c3, c4))
    }
    
    /// Builds six views into a tuple.
    public static func buildBlock<C0: View, C1: View, C2: View, C3: View, C4: View, C5: View>(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5) -> TupleView<(C0, C1, C2, C3, C4, C5)> {
        return TupleView((c0, c1, c2, c3, c4, c5))
    }
    
    /// Builds seven views into a tuple.
    public static func buildBlock<C0: View, C1: View, C2: View, C3: View, C4: View, C5: View, C6: View>(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5, _ c6: C6) -> TupleView<(C0, C1, C2, C3, C4, C5, C6)> {
        return TupleView((c0, c1, c2, c3, c4, c5, c6))
    }
    
    /// Builds eight views into a tuple.
    public static func buildBlock<C0: View, C1: View, C2: View, C3: View, C4: View, C5: View, C6: View, C7: View>(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5, _ c6: C6, _ c7: C7) -> TupleView<(C0, C1, C2, C3, C4, C5, C6, C7)> {
        return TupleView((c0, c1, c2, c3, c4, c5, c6, c7))
    }
    
    /// Builds nine views into a tuple.
    public static func buildBlock<C0: View, C1: View, C2: View, C3: View, C4: View, C5: View, C6: View, C7: View, C8: View>(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5, _ c6: C6, _ c7: C7, _ c8: C8) -> TupleView<(C0, C1, C2, C3, C4, C5, C6, C7, C8)> {
        return TupleView((c0, c1, c2, c3, c4, c5, c6, c7, c8))
    }
    
    /// Builds ten views into a tuple.
    public static func buildBlock<C0: View, C1: View, C2: View, C3: View, C4: View, C5: View, C6: View, C7: View, C8: View, C9: View>(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5, _ c6: C6, _ c7: C7, _ c8: C8, _ c9: C9) -> TupleView<(C0, C1, C2, C3, C4, C5, C6, C7, C8, C9)> {
        return TupleView((c0, c1, c2, c3, c4, c5, c6, c7, c8, c9))
    }
    
    /// Builds an optional view.
    public static func buildIf<Content: View>(_ content: Content?) -> Content? {
        return content
    }
    
    /// Builds either the first or second view based on a condition.
    public static func buildEither<TrueContent: View, FalseContent: View>(first: TrueContent) -> _ConditionalContent<TrueContent, FalseContent> {
        return _ConditionalContent(storage: .trueContent(first))
    }
    
    /// Builds either the first or second view based on a condition.
    public static func buildEither<TrueContent: View, FalseContent: View>(second: FalseContent) -> _ConditionalContent<TrueContent, FalseContent> {
        return _ConditionalContent(storage: .falseContent(second))
    }
    
    /// Builds an array of views.
    public static func buildArray<Content: View>(_ components: [Content]) -> [Content] {
        return components
    }
}

// MARK: - TupleView

/// A view that contains a tuple of views.
/// Used internally by ViewBuilder to handle multiple views.
public class TupleView<T>: View {
    public var frame: Rect
    private let storage: T
    internal let children: [any View]
    
    internal init(_ storage: T) {
        self.storage = storage
        self.frame = .zero
        
        // Extract views from tuple
        var views: [any View] = []
        Mirror(reflecting: storage).children.forEach { child in
            if let view = child.value as? (any View) {
                views.append(view)
            }
        }
        self.children = views
    }
    
    public func draw(u8g2: UnsafeMutablePointer<u8g2_t>?, origin: Point) {
        let absX = origin.x + frame.origin.x
        let absY = origin.y + frame.origin.y
        let childOrigin = Point(x: absX, y: absY)
        
        for child in children {
            child.draw(u8g2: u8g2, origin: childOrigin)
        }
    }
}

// MARK: - _ConditionalContent

/// A view that conditionally displays one of two views.
internal enum _ConditionalContentStorage<TrueContent: View, FalseContent: View> {
    case trueContent(TrueContent)
    case falseContent(FalseContent)
}

/// A view that conditionally displays one of two views.
/// This is an internal type used by ViewBuilder for conditional content.
public class _ConditionalContent<TrueContent: View, FalseContent: View>: View {
    public var frame: Rect
    private let storage: _ConditionalContentStorage<TrueContent, FalseContent>
    
    internal init(storage: _ConditionalContentStorage<TrueContent, FalseContent>) {
        self.storage = storage
        self.frame = .zero
    }
    
    public func draw(u8g2: UnsafeMutablePointer<u8g2_t>?, origin: Point) {
        switch storage {
        case .trueContent(let content):
            content.draw(u8g2: u8g2, origin: origin)
        case .falseContent(let content):
            content.draw(u8g2: u8g2, origin: origin)
        }
    }
}

