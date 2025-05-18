public class TextLayer: Layer {
    public var text: Text
    public private(set) var color: Color = .white

    public init(text: Text) {
        self.text = text
        super.init()
    }

    public func setColor(_ color: Color) {
        self.color = color
    }
}
