//
//  RenderBackend.swift
//  MonoUI
//
//  Created by MonoUI Team
//  Copyright © 2024 MonoUI. All rights reserved.
//
//  Licensed under the MIT License
//  See LICENSE file for more information
//

/// A protocol that defines the interface for rendering backends.
public protocol RenderBackend {
    /// Updates the display with the provided buffer.
    /// - Parameters:
    ///   - buffer: The pixel buffer to display (0 for black, 1 for white).
    ///   - width: The width of the buffer in pixels.
    ///   - height: The height of the buffer in pixels.
    func update(buffer: [UInt8], width: Int, height: Int)
} 