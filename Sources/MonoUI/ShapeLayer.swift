//
//  ShapeLayer.swift
//  MonoUI
//
//  Created by MonoUI Team
//  Copyright © 2024 MonoUI. All rights reserved.
//
//  Licensed under the MIT License
//  See LICENSE file for more information
//

/// A class that represents a shape layer containing a path and its rendering properties.
public class ShapeLayer: Layer {
    public let path: Path
    public private(set) var fillColor: Color = .black
    public private(set) var strokeColor: Color = .white
    public private(set) var lineWidth: Double = 1.0
    
    /// Creates a shape layer with the specified path.
    /// - Parameter path: The path to be rendered.
    public init(path: Path) {
        self.path = path
        super.init()
    }
    
    /// Sets the fill color for this layer.
    /// - Parameter color: The color to use for filling.
    public func setFillColor(_ color: Color) {
        self.fillColor = color
    }
    
    /// Sets the stroke color for this layer.
    /// - Parameter color: The color to use for stroking.
    public func setStrokeColor(_ color: Color) {
        self.strokeColor = color
    }
    
    /// Sets the line width for this layer.
    /// - Parameter width: The width of the stroke in pixels.
    public func setLineWidth(_ width: Double) {
        self.lineWidth = width
    }
} 