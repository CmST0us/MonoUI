#if canImport(Glibc)
import Glibc
#elseif canImport(Darwin)
import Darwin
#endif

/// A structure representing a point in a 2D coordinate system.
public struct Point: Equatable, Animatable {
    /// The x-coordinate of the point.
    public var x: Double
    /// The y-coordinate of the point.
    public var y: Double
    
    /// Initializes a new Point with the specified coordinates.
    /// - Parameters:
    ///   - x: The x-coordinate.
    ///   - y: The y-coordinate.
    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
    
    /// A point with coordinates (0, 0).
    public static let zero = Point(x: 0, y: 0)
    
    public static func - (lhs: Point, rhs: Point) -> Point {
        return Point(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
    
    public static func + (lhs: Point, rhs: Point) -> Point {
        return Point(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
    public func scaled(by factor: Double) -> Point {
        return Point(x: x * factor, y: y * factor)
    }
    
    public func distance(to other: Point) -> Double {
        let dx = x - other.x
        let dy = y - other.y
        return sqrt(dx*dx + dy*dy)
    }
}

/// A structure representing the size of a 2D object.
public struct Size: Equatable, Animatable {
    /// The width component.
    public var width: Double
    /// The height component.
    public var height: Double
    
    /// Initializes a new Size with the specified dimensions.
    /// - Parameters:
    ///   - width: The width.
    ///   - height: The height.
    public init(width: Double, height: Double) {
        self.width = width
        self.height = height
    }
    
    /// A size with zero width and height.
    public static let zero = Size(width: 0, height: 0)
    
    public static func - (lhs: Size, rhs: Size) -> Size {
        return Size(width: lhs.width - rhs.width, height: lhs.height - rhs.height)
    }
    
    public static func + (lhs: Size, rhs: Size) -> Size {
        return Size(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
    }
    
    public func scaled(by factor: Double) -> Size {
        return Size(width: width * factor, height: height * factor)
    }
    
    public func distance(to other: Size) -> Double {
        let dw = width - other.width
        let dh = height - other.height
        return sqrt(dw*dw + dh*dh)
    }
}

/// A structure representing a rectangle.
public struct Rect: Equatable, Animatable {
    /// The origin point of the rectangle.
    public var origin: Point
    /// The size of the rectangle.
    public var size: Size
    
    /// Initializes a new Rect with the specified origin and size.
    /// - Parameters:
    ///   - origin: The origin point.
    ///   - size: The size.
    public init(origin: Point, size: Size) {
        self.origin = origin
        self.size = size
    }
    
    /// Initializes a new Rect with the specified components.
    /// - Parameters:
    ///   - x: The x-coordinate of the origin.
    ///   - y: The y-coordinate of the origin.
    ///   - width: The width.
    ///   - height: The height.
    public init(x: Double, y: Double, width: Double, height: Double) {
        self.origin = Point(x: x, y: y)
        self.size = Size(width: width, height: height)
    }
    
    public var minX: Double { return origin.x }
    public var minY: Double { return origin.y }
    public var maxX: Double { return origin.x + size.width }
    public var maxY: Double { return origin.y + size.height }
    public var midX: Double { return origin.x + size.width / 2 }
    public var midY: Double { return origin.y + size.height / 2 }
    
    /// A rectangle with zero origin and size.
    public static let zero = Rect(x: 0, y: 0, width: 0, height: 0)
    
    /// Checks if the rectangle contains a point.
    public func contains(_ point: Point) -> Bool {
        return point.x >= minX && point.x < maxX && point.y >= minY && point.y < maxY
    }
    
    /// Checks if the rectangle intersects with another rectangle.
    public func intersects(_ other: Rect) -> Bool {
        return !(other.minX >= maxX || other.maxX <= minX || other.minY >= maxY || other.maxY <= minY)
    }
    
    // MARK: - Animatable Implementation
    
    public static func - (lhs: Rect, rhs: Rect) -> Rect {
        return Rect(origin: lhs.origin - rhs.origin, size: lhs.size - rhs.size)
    }
    
    public static func + (lhs: Rect, rhs: Rect) -> Rect {
        return Rect(origin: lhs.origin + rhs.origin, size: lhs.size + rhs.size)
    }
    
    public func scaled(by factor: Double) -> Rect {
        return Rect(origin: origin.scaled(by: factor), size: size.scaled(by: factor))
    }
    
    public func distance(to other: Rect) -> Double {
        let dOrigin = origin.distance(to: other.origin)
        let dSize = size.distance(to: other.size)
        return sqrt(dOrigin*dOrigin + dSize*dSize)
    }
}
