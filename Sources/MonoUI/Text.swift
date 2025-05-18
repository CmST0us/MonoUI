
public struct Text {
    public var content: String
    public var font: UnsafePointer<UInt8> // 指向 u8g2 字体数据
    public var fontSize: Int // 实际上 u8g2 字体是定高的，这里可做逻辑分组
    public var position: Point

    public init(content: String, font: UnsafePointer<UInt8>, fontSize: Int, position: Point) {
        self.content = content
        self.font = font
        self.fontSize = fontSize
        self.position = position
    }
}
