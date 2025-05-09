//
//  Render.swift
//  MonoUI
//
//  Created by MonoUI Team
//  Copyright © 2024 MonoUI. All rights reserved.
//
//  Licensed under the MIT License
//  See LICENSE file for more information
//

/// A class that represents a drawing surface with a pixel buffer.
public class Surface {
    var buffer: [UInt8]
    private var layers: [ShapeLayer] = []
    
    public let width: Int
    public let height: Int
    
    /// Creates a surface with the specified dimensions.
    /// - Parameters:
    ///   - width: The width of the surface in pixels.
    ///   - height: The height of the surface in pixels.
    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
        self.buffer = Array(repeating: 0, count: width * height) // 1 bit per pixel
    }
    
    /// Adds a shape layer to the surface.
    /// - Parameter layer: The layer to add.
    public func addLayer(_ layer: ShapeLayer) {
        layers.append(layer)
    }
    
    /// Removes a shape layer from the surface.
    /// - Parameter layer: The layer to remove.
    public func removeLayer(_ layer: ShapeLayer) {
        if let index = layers.firstIndex(where: { $0 === layer }) {
            layers.remove(at: index)
        }
    }
    
    /// Removes all layers from the surface.
    public func removeAllLayers() {
        layers.removeAll()
    }
    
    /// Sets a pixel in the buffer to the specified color.
    /// - Parameters:
    ///   - x: The x-coordinate of the pixel.
    ///   - y: The y-coordinate of the pixel.
    ///   - color: The color to set.
    private func setPixel(x: Int, y: Int, color: Color) {
        guard x >= 0 && x < width && y >= 0 && y < height else { return }
        let index = y * width + x
        buffer[index] = color.rawValue
    }
    
    /// Draws a line using Bresenham's algorithm.
    /// - Parameters:
    ///   - x0: The x-coordinate of the start point.
    ///   - y0: The y-coordinate of the start point.
    ///   - x1: The x-coordinate of the end point.
    ///   - y1: The y-coordinate of the end point.
    ///   - color: The color of the line.
    private func drawLine(x0: Int, y0: Int, x1: Int, y1: Int, color: Color) {
        var x0 = x0, y0 = y0, x1 = x1, y1 = y1
        let dx = abs(x1 - x0)
        let dy = abs(y1 - y0)
        let sx = x0 < x1 ? 1 : -1
        let sy = y0 < y1 ? 1 : -1
        var err = dx - dy
        
        while true {
            setPixel(x: x0, y: y0, color: color)
            if x0 == x1 && y0 == y1 { break }
            let e2 = 2 * err
            if e2 > -dy {
                err -= dy
                x0 += sx
            }
            if e2 < dx {
                err += dx
                y0 += sy
            }
        }
    }
    
    /// Fills a scan line segment.
    /// - Parameters:
    ///   - y: The y-coordinate of the scan line.
    ///   - x1: The start x-coordinate.
    ///   - x2: The end x-coordinate.
    ///   - color: The fill color.
    private func fillScanLine(y: Int, x1: Int, x2: Int, color: Color) {
        let startX = max(0, min(x1, x2))
        let endX = min(width - 1, max(x1, x2))
        for x in startX...endX {
            setPixel(x: x, y: y, color: color)
        }
    }
    
    /// Draws a path with the specified colors.
    /// - Parameters:
    ///   - path: The path to draw.
    ///   - fillColor: The color to use for filling.
    ///   - strokeColor: The color to use for stroking.
    private func drawPath(path: Path, fillColor: Color, strokeColor: Color) {
        // 存储路径中的所有点
        var points: [Point] = []
        var currentPoint: Point?
        
        // 解析路径命令
        for command in path.commands {
            switch command {
            case .moveTo(let point):
                currentPoint = point
                points.append(point)
            case .lineTo(let point):
                if let start = currentPoint {
                    points.append(point)
                    // 只有当描边颜色不是 none 时才绘制线段
                    if strokeColor != .none {
                        drawLine(x0: Int(start.x), y0: Int(start.y),
                                x1: Int(point.x), y1: Int(point.y),
                                color: strokeColor)
                    }
                }
                currentPoint = point
            case .quadCurveTo(let point, let control):
                if let start = currentPoint {
                    // 二次贝塞尔曲线采样
                    let steps = 20
                    for i in 0...steps {
                        let t = Double(i) / Double(steps)
                        let x = (1-t)*(1-t)*start.x + 2*(1-t)*t*control.x + t*t*point.x
                        let y = (1-t)*(1-t)*start.y + 2*(1-t)*t*control.y + t*t*point.y
                        let newPoint = Point(x: x, y: y)
                        points.append(newPoint)
                        if i > 0 && strokeColor != .none {
                            drawLine(x0: Int(points[points.count-2].x),
                                   y0: Int(points[points.count-2].y),
                                   x1: Int(newPoint.x),
                                   y1: Int(newPoint.y),
                                   color: strokeColor)
                        }
                    }
                }
                currentPoint = point
            case .cubicCurveTo(let point, let control1, let control2):
                if let start = currentPoint {
                    // 三次贝塞尔曲线采样
                    let steps = 20
                    for i in 0...steps {
                        let t = Double(i) / Double(steps)
                        let x = (1-t)*(1-t)*(1-t)*start.x +
                               3*(1-t)*(1-t)*t*control1.x +
                               3*(1-t)*t*t*control2.x +
                               t*t*t*point.x
                        let y = (1-t)*(1-t)*(1-t)*start.y +
                               3*(1-t)*(1-t)*t*control1.y +
                               3*(1-t)*t*t*control2.y +
                               t*t*t*point.y
                        let newPoint = Point(x: x, y: y)
                        points.append(newPoint)
                        if i > 0 && strokeColor != .none {
                            drawLine(x0: Int(points[points.count-2].x),
                                   y0: Int(points[points.count-2].y),
                                   x1: Int(newPoint.x),
                                   y1: Int(newPoint.y),
                                   color: strokeColor)
                        }
                    }
                }
                currentPoint = point
            case .closePath:
                if let start = points.first, let end = currentPoint, strokeColor != .none {
                    drawLine(x0: Int(end.x), y0: Int(end.y),
                            x1: Int(start.x), y1: Int(start.y),
                            color: strokeColor)
                }
            }
        }
        
        // 只有当填充颜色不是 none 时才进行填充
        if fillColor != .none && !points.isEmpty {
            // 找到路径的边界
            let minY = Int(points.map { $0.y }.min() ?? 0)
            let maxY = Int(points.map { $0.y }.max() ?? 0)
            
            // 对每一行进行扫描线填充
            for y in minY...maxY {
                var intersections: [Double] = []
                
                // 计算与当前扫描线的交点
                for i in 0..<points.count {
                    let p1 = points[i]
                    let p2 = points[(i + 1) % points.count]
                    
                    if (p1.y <= Double(y) && p2.y > Double(y)) ||
                       (p2.y <= Double(y) && p1.y > Double(y)) {
                        let x = p1.x + (p2.x - p1.x) * (Double(y) - p1.y) / (p2.y - p1.y)
                        intersections.append(x)
                    }
                }
                
                // 对交点进行排序
                intersections.sort()
                
                // 填充扫描线
                for i in stride(from: 0, to: intersections.count - 1, by: 2) {
                    if i + 1 < intersections.count {
                        fillScanLine(y: y,
                                   x1: Int(intersections[i]),
                                   x2: Int(intersections[i + 1]),
                                   color: fillColor)
                    }
                }
            }
        }
    }
    
    /// Renders all layers to the surface.
    public func render() {
        // 清除缓冲区
        buffer = Array(repeating: 0, count: width * height)
        
        // 按顺序渲染每个图层
        for layer in layers {
            drawPath(path: layer.path,
                    fillColor: layer.fillColor,
                    strokeColor: layer.strokeColor)
        }
    }
    
    /// Clears the surface by setting all pixels to black.
    public func clear() {
        buffer = Array(repeating: 0, count: width * height)
        layers.removeAll()
    }
} 