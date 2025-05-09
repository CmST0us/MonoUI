//
//  Geometry.swift
//  MonoUI
//
//  Created by MonoUI Team
//  Copyright © 2024 MonoUI. All rights reserved.
//
//  Licensed under the MIT License
//  See LICENSE file for more information
//

/// A structure that represents a point in a two-dimensional coordinate system.
public struct Point {
    /// The x-coordinate of the point.
    public var x: Double
    /// The y-coordinate of the point.
    public var y: Double
    
    /// Creates a point with the specified coordinates.
    /// - Parameters:
    ///   - x: The x-coordinate of the point.
    ///   - y: The y-coordinate of the point.
    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

/// A structure that represents a rectangle in a two-dimensional coordinate system.
public struct Rect {
    /// The origin point of the rectangle.
    public var origin: Point
    /// The size of the rectangle.
    public var size: Size
    
    /// Creates a rectangle with the specified origin and size.
    /// - Parameters:
    ///   - origin: The origin point of the rectangle.
    ///   - size: The size of the rectangle.
    public init(origin: Point, size: Size) {
        self.origin = origin
        self.size = size
    }
}

/// A structure that represents a size in a two-dimensional coordinate system.
public struct Size {
    /// The width value.
    public var width: Double
    /// The height value.
    public var height: Double
    
    /// Creates a size with the specified width and height.
    /// - Parameters:
    ///   - width: The width value.
    ///   - height: The height value.
    public init(width: Double, height: Double) {
        self.width = width
        self.height = height
    }
} 