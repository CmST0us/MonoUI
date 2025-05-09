//
//  Color.swift
//  MonoUI
//
//  Created by MonoUI Team
//  Copyright © 2024 MonoUI. All rights reserved.
//
//  Licensed under the MIT License
//  See LICENSE file for more information
//

/// An enumeration that represents a monochrome color.
public enum Color {
    /// Represents the color black.
    case black
    /// Represents the color white.
    case white
    /// Represents a transparent/ignored color.
    case none
    
    /// The raw value of the color (0 for black, 1 for white, 2 for none).
    public var rawValue: UInt8 {
        switch self {
        case .black: return 0
        case .white: return 1
        case .none: return 2
        }
    }
    
    /// Creates a color from a raw value.
    /// - Parameter rawValue: The raw value (0 for black, 1 for white, 2 for none).
    public init?(rawValue: UInt8) {
        switch rawValue {
        case 0: self = .black
        case 1: self = .white
        case 2: self = .none
        default: return nil
        }
    }
} 