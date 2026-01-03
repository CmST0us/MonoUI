// MARK: - View Modifiers

/// Extension to View for frame modifier.
extension View {
    /// Sets the frame of the view.
    /// - Parameters:
    ///   - width: The width of the frame.
    ///   - height: The height of the frame.
    /// - Returns: The view itself (mutated).
    @discardableResult
    public func frame(width: Double? = nil, height: Double? = nil) -> Self {
        if let width = width {
            self.frame.size.width = width
        }
        if let height = height {
            self.frame.size.height = height
        }
        return self
    }
    
    /// Sets the position of the view.
    /// - Parameters:
    ///   - x: The x coordinate.
    ///   - y: The y coordinate.
    /// - Returns: The view itself (mutated).
    @discardableResult
    public func position(x: Double? = nil, y: Double? = nil) -> Self {
        if let x = x {
            self.frame.origin.x = x
        }
        if let y = y {
            self.frame.origin.y = y
        }
        return self
    }
}

