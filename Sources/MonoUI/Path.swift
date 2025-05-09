//
//  Path.swift
//  MonoUI
//
//  Created by MonoUI Team
//  Copyright © 2024 MonoUI. All rights reserved.
//
//  Licensed under the MIT License
//  See LICENSE file for more information
//

import Foundation

/// An enumeration that represents different types of path commands.
public enum PathCommand {
    /// Moves the current point to the specified location.
    case moveTo(Point)
    /// Draws a line from the current point to the specified location.
    case lineTo(Point)
    /// Draws a quadratic Bézier curve from the current point to the specified location.
    case quadCurveTo(Point, control: Point)
    /// Draws a cubic Bézier curve from the current point to the specified location.
    case cubicCurveTo(Point, control1: Point, control2: Point)
    /// Closes the current path by drawing a line to the starting point.
    case closePath
}

/// A class that represents a path consisting of a sequence of path commands.
public class Path {
    internal var commands: [PathCommand] = []
    
    /// Creates an empty path.
    public init() {}
    
    /// Moves the current point to the specified location.
    /// - Parameter point: The target point to move to.
    public func move(to point: Point) {
        commands.append(.moveTo(point))
    }
    
    /// Adds a line from the current point to the specified location.
    /// - Parameter point: The end point of the line.
    public func addLine(to point: Point) {
        commands.append(.lineTo(point))
    }
    
    /// Adds a quadratic Bézier curve from the current point to the specified location.
    /// - Parameters:
    ///   - point: The end point of the curve.
    ///   - control: The control point of the quadratic curve.
    public func addQuadCurve(to point: Point, control: Point) {
        commands.append(.quadCurveTo(point, control: control))
    }
    
    /// Adds a cubic Bézier curve from the current point to the specified location.
    /// - Parameters:
    ///   - point: The end point of the curve.
    ///   - control1: The first control point of the cubic curve.
    ///   - control2: The second control point of the cubic curve.
    public func addCurve(to point: Point, control1: Point, control2: Point) {
        commands.append(.cubicCurveTo(point, control1: control1, control2: control2))
    }
    
    /// Closes the current path by drawing a line to the starting point.
    public func close() {
        commands.append(.closePath)
    }
    
    /// Adds a circle to the path.
    /// - Parameters:
    ///   - center: The center point of the circle.
    ///   - radius: The radius of the circle.
    public func addCircle(center: Point, radius: Double) {
        addArc(center: center, radius: radius, startAngle: 0, endAngle: 2 * .pi)
    }
    
    /// Adds an arc to the path.
    /// - Parameters:
    ///   - center: The center point of the arc.
    ///   - radius: The radius of the arc.
    ///   - startAngle: The starting angle in radians.
    ///   - endAngle: The ending angle in radians.
    ///   - clockwise: Whether the arc should be drawn clockwise.
    public func addArc(center: Point, radius: Double, startAngle: Double, endAngle: Double, clockwise: Bool = false) {
        let steps = max(Int(radius * abs(endAngle - startAngle) / 2), 8)
        let angleStep = (endAngle - startAngle) / Double(steps)
        
        // 计算起始点
        let startX = center.x + radius * cos(startAngle)
        let startY = center.y + radius * sin(startAngle)
        move(to: Point(x: startX, y: startY))
        
        // 使用三次贝塞尔曲线近似圆弧
        for i in 1...steps {
            let angle = startAngle + angleStep * Double(i)
            let x = center.x + radius * cos(angle)
            let y = center.y + radius * sin(angle)
            
            // 计算控制点
            let prevAngle = angle - angleStep
            let prevX = center.x + radius * cos(prevAngle)
            let prevY = center.y + radius * sin(prevAngle)
            
            // 计算控制点的偏移量
            let controlOffset = radius * 0.552284749831 * abs(angleStep)
            let control1X = prevX - controlOffset * sin(prevAngle)
            let control1Y = prevY + controlOffset * cos(prevAngle)
            let control2X = x + controlOffset * sin(angle)
            let control2Y = y - controlOffset * cos(angle)
            
            addCurve(to: Point(x: x, y: y),
                    control1: Point(x: control1X, y: control1Y),
                    control2: Point(x: control2X, y: control2Y))
        }
    }
    
    /// Adds a rounded rectangle to the path.
    /// - Parameters:
    ///   - rect: The rectangle to round.
    ///   - cornerRadius: The radius of the corners.
    public func addRoundedRect(_ rect: Rect, cornerRadius: Double) {
        let minX = rect.origin.x
        let minY = rect.origin.y
        let maxX = minX + rect.size.width
        let maxY = minY + rect.size.height
        
        // 确保圆角半径不超过矩形边长的一半
        let radius = min(cornerRadius, min(rect.size.width, rect.size.height) / 2)
        
        // 移动到左上角
        move(to: Point(x: minX + radius, y: minY))
        
        // 上边
        addLine(to: Point(x: maxX - radius, y: minY))
        
        // 右上角
        addArc(center: Point(x: maxX - radius, y: minY + radius),
               radius: radius,
               startAngle: -(.pi / 2),
               endAngle: 0)
        
        // 右边
        addLine(to: Point(x: maxX, y: maxY - radius))
        
        // 右下角
        addArc(center: Point(x: maxX - radius, y: maxY - radius),
               radius: radius,
               startAngle: 0,
               endAngle: .pi / 2)
        
        // 下边
        addLine(to: Point(x: minX + radius, y: maxY))
        
        // 左下角
        addArc(center: Point(x: minX + radius, y: maxY - radius),
               radius: radius,
               startAngle: .pi / 2,
               endAngle: .pi)
        
        // 左边
        addLine(to: Point(x: minX, y: minY + radius))
        
        // 左上角
        addArc(center: Point(x: minX + radius, y: minY + radius),
               radius: radius,
               startAngle: .pi,
               endAngle: .pi * 1.5)
        
        close()
    }
} 