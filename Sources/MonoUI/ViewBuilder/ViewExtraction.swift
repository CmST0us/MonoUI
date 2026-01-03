// MARK: - ViewExtraction Protocol

/// A protocol that helps extract child views from container views.
internal protocol ViewExtraction {
    /// Extracts child views from this view.
    /// - Returns: An array of child views, or nil if this is not a container.
    func extractChildren() -> [any View]?
}

/// Helper functions for extracting children from views.
internal enum ViewExtractionHelper {
    /// Extracts child views from any view.
    /// - Parameter view: The view to extract children from.
    /// - Returns: An array of child views.
    static func extractChildren(from view: any View) -> [any View] {
        // Check if view conforms to ViewExtraction
        if let extractable = view as? ViewExtraction, let children = extractable.extractChildren() {
            return children
        }
        
        // Check if it's a TupleView using reflection
        let mirror = Mirror(reflecting: view)
        if String(describing: mirror.subjectType).contains("TupleView") {
            if let children = mirror.children.first(where: { $0.label == "children" })?.value as? [any View] {
                return children
            }
        }
        
        // Single view
        return [view]
    }
}

extension TupleView: ViewExtraction {
    func extractChildren() -> [any View]? {
        return children
    }
}

