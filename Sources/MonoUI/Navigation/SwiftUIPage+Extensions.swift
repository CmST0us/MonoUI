// MARK: - SwiftUIPage Extensions

extension ViewBuilder {
    /// Builds a single view and automatically wraps it in AnyView.
    /// This allows for cleaner syntax in SwiftUIPage body properties.
    public static func buildExpression<Content: View>(_ expression: Content) -> AnyView {
        return AnyView(expression)
    }
}

