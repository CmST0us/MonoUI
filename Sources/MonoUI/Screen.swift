//
//  Screen.swift
//  MonoUI
//
//  Created by MonoUI Team
//  Copyright © 2024 MonoUI. All rights reserved.
//
//  Licensed under the MIT License
//  See LICENSE file for more information
//

/// A class that manages the display output using a surface and a rendering backend.
public class Screen {
    public let surface: Surface
    private let backend: RenderBackend
    
    /// Creates a screen with the specified dimensions and rendering backend.
    /// - Parameters:
    ///   - width: The width of the screen in pixels.
    ///   - height: The height of the screen in pixels.
    ///   - backend: The rendering backend to use for display.
    public init(width: Int, height: Int, backend: RenderBackend) {
        self.surface = Surface(width: width, height: height)
        self.backend = backend
    }
    
    /// Updates the display with the current surface contents.
    public func update() {
        backend.update(buffer: surface.buffer, width: surface.width, height: surface.height)
    }
} 