import CU8g2

// MARK: - ItemMenuCellModel

/// Protocol for data models used by menu cells.
///
/// This protocol defines the interface for data models that provide
/// information to `ItemMenuCell` instances for rendering.
public protocol ItemMenuCellModel {
    /// A unique identifier for the cell model (for reuse).
    var identifier: String { get }
    
    /// The height of the cell (default implementation returns 16.0).
    var cellHeight: Double { get }
}

extension ItemMenuCellModel {
    /// Default cell height.
    public var cellHeight: Double {
        return 16.0
    }
}

