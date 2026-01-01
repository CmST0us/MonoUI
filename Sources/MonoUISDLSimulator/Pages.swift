import MonoUI
import CU8g2

class DetailPage: Page {
    @AnimationValue var offsetX: Double // 初始在屏幕右侧外
    
    let title: String
    
    init(title: String) {
        self.title = title
        let screenSize = Context.shared?.screenSize ?? Size(width: 128, height: 64)
        // 初始位置设为屏幕宽度 (屏幕外)，实际通过 offsetX 动画控制偏移
        self._offsetX = AnimationValue(wrappedValue: screenSize.width)
        super.init(frame: Rect(x: screenSize.width, y: 0, width: screenSize.width, height: screenSize.height))
    }
    
    override func animateIn() {
        // 进场动画：从右侧滑入到 (0)
        // 确保使用动画属性
        offsetX = 0
    }
    
    override func animateOut() {
        // 出场动画：滑出到右侧
        let screenWidth = Context.shared?.screenSize.width ?? 128
        offsetX = screenWidth
    }
    
    override func isExitAnimationFinished() -> Bool {
        // 当 offsetX 接近屏幕宽度时认为完成
        let screenWidth = Context.shared?.screenSize.width ?? 128
        return offsetX >= screenWidth - 0.5
    }
    
    override func draw(u8g2: UnsafeMutablePointer<u8g2_t>?, origin: Point) {
        // 同步动画值
        frame.origin.x = offsetX
        
        // 调用父类 draw，父类会自动绘制黑色背景防止透视
        super.draw(u8g2: u8g2, origin: origin)
        
        guard let u8g2 = u8g2 else { return }
        
        let absX = origin.x + frame.origin.x
        let absY = origin.y + frame.origin.y
        
        // 绘制详情内容边框 (白线)
        // 由于父类已经画了黑底，这里直接画框即可
        u8g2_SetDrawColor(u8g2, 1)
        u8g2_DrawFrame(u8g2, u8g2_uint_t(absX), u8g2_uint_t(absY), 
                      u8g2_uint_t(frame.size.width), u8g2_uint_t(frame.size.height))
        
        u8g2_SetFont(u8g2, u8g2_font_6x10_tf)
        u8g2_DrawStr(u8g2, u8g2_uint_t(absX + 10), u8g2_uint_t(absY + 20), "Detail: \(title)")
        u8g2_DrawStr(u8g2, u8g2_uint_t(absX + 10), u8g2_uint_t(absY + 40), "Press 'Q' to Back")
    }
    
    override func handleInput(key: Int32) {
        // 'q' (113) -> Back
        if key == 113 {
            // 需要访问 Router 才能 pop
            // 简单起见，我们假设 Context 持有 Router，或者这里使用回调
            // 暂时通过 Application 访问
            if let app = Application.shared as? SDL2SimulatorApp {
                let router = (app as Application).router
                // 如果有 Modal，先关闭 Modal
                if router.modal != nil {
                    router.dismissModal()
                } else {
                    router.pop()
                }
            }
        }
        
        // 'e' (101) -> Show Alert
        if key == 101 {
             if let app = Application.shared as? SDL2SimulatorApp {
                let alert = AlertView(frame: Rect(x: 14, y: 12, width: 100, height: 40), 
                                      title: "Info", 
                                      message: "Hello World")
                (app as Application).router.present(alert)
             }
        }
    }
}

class HomePage: Page {
    let scrollView: ScrollView
    @AnimationValue var scrollOffset: Double = 0
    
    // 数据源
    static let icon1: [UInt8] = [0x00,0x00,0x00,0x40,0x00,0x00,0x40,0x04,0x00,0x40,0x04,0x00,0x40,0x04,0x00,0x50,0x14,0x00,0x50,0x15,0x00,0x54,0x15,0x00,0x55,0x55,0x01,0x50,0x55,0x00,0x50,0x15,0x00,0x50,0x04,0x00,0x40,0x04,0x00,0x40,0x04,0x00,0x40,0x00,0x00,0x00,0x00,0x00]
    static let icon2: [UInt8] = [0x80,0x00,0x48,0x01,0x38,0x02,0x98,0x04,0x48,0x09,0x24,0x12,0x12,0x24,0x09,0x48,0x66,0x30,0x64,0x10,0x04,0x17,0x04,0x15,0x04,0x17,0x04,0x15,0xfc,0x1f,0x00,0x00]
    static let icon3: [UInt8] = [0x1c,0x00,0x22,0x00,0xe3,0x3f,0x22,0x00,0x1c,0x00,0x00,0x0e,0x00,0x11,0xff,0x31,0x00,0x11,0x00,0x0e,0x1c,0x00,0x22,0x00,0xe3,0x3f,0x22,0x00,0x1c,0x00,0x00,0x00]

    // 当前选中的 Tile 索引 (0, 1, 2)
    var selectedIndex: Int = 0
    var tiles: [IconTileView]
    
    init() {
        let screenSize = Context.shared?.screenSize ?? Size(width: 128, height: 64)
        self.scrollView = ScrollView(frame: Rect(x: 0, y: 0, width: screenSize.width, height: 45))
        // 增加宽度以允许最后一个 Tile 居中
        // Tile 3 center at 147. Viewport center 64. Offset needed 83.
        // Viewport width 128. 128 + 83 = 211. 
        self.scrollView.contentSize = Size(width: 212, height: 45)
        self.scrollView.direction = .horizontal
        
        // 必须在 super.init 之前初始化所有属性
        self.tiles = []
        
        super.init(frame: Rect(x: 0, y: 0, width: screenSize.width, height: screenSize.height))
        
        let startX: Double = 45
        let spacing: Double = 6
        let cardSize = Size(width: 36, height: 36)
        let yPos: Double = 4
        
        let tile1 = IconTileView(frame: Rect(x: startX, y: yPos, width: cardSize.width, height: cardSize.height),
                                 iconBits: Self.icon1,
                                 iconSize: Size(width: 17, height: 16)) {
            // Click Handler
            if let app = Application.shared as? SDL2SimulatorApp {
                (app as Application).router.push(DetailPage(title: "Music"))
            }
        }
        scrollView.addSubview(tile1)
        tiles.append(tile1)
        
        let tile2 = IconTileView(frame: Rect(x: startX + cardSize.width + spacing, y: yPos, width: cardSize.width, height: cardSize.height),
                                 iconBits: Self.icon2,
                                 iconSize: Size(width: 15, height: 16)) {
            if let app = Application.shared as? SDL2SimulatorApp {
                (app as Application).router.push(DetailPage(title: "Home"))
            }
        }
        scrollView.addSubview(tile2)
        tiles.append(tile2)
        
        let tile3 = IconTileView(frame: Rect(x: startX + (cardSize.width + spacing) * 2, y: yPos, width: cardSize.width, height: cardSize.height),
                                 iconBits: Self.icon3,
                                 iconSize: Size(width: 14, height: 16)) {
            if let app = Application.shared as? SDL2SimulatorApp {
                (app as Application).router.push(DetailPage(title: "Download"))
            }
        }
        scrollView.addSubview(tile3)
        tiles.append(tile3)
        
        self.addSubview(scrollView)
    }
    
    override func draw(u8g2: UnsafeMutablePointer<u8g2_t>?, origin: Point) {
        scrollView.contentOffset.x = scrollOffset
        super.draw(u8g2: u8g2, origin: origin)
        
        // 绘制底部固定条
        if let u8g2 = u8g2 {
             u8g2_DrawBox(u8g2, 0, 47, 4, 17)
        }
    }
    
    override func handleInput(key: Int32) {
        // 'd' (100) -> Next
        if key == 100 {
            if selectedIndex < tiles.count - 1 {
                selectedIndex += 1
                scrollToSelected()
            }
        }
        
        // 'a' (97) -> Previous
        if key == 97 {
            if selectedIndex > 0 {
                selectedIndex -= 1
                scrollToSelected()
            }
        }
        
        // 'Enter' or 'Space' or 'w' -> Click/Select
        // Assuming 'e' (101) for Enter/Confirm for now
        if key == 101 {
            tiles[selectedIndex].onClick?()
        }
    }
    
    private func scrollToSelected() {
        // 计算居中偏移量
        // 目标是将 selectedIndex 对应的 Tile 居中显示
        // Tile 中心点 x 坐标 = tile.x + tile.width / 2
        // ScrollView 中心点 x 坐标 = scrollView.width / 2
        // contentOffset.x = Tile 中心点 x - ScrollView 中心点 x
        
        let tile = tiles[selectedIndex]
        let tileCenterX = tile.frame.origin.x + tile.frame.size.width / 2
        let scrollViewCenterX = scrollView.frame.size.width / 2
        
        var targetOffset = tileCenterX - scrollViewCenterX
        
        // 边界处理：不让内容滚出可视区域太多（可选，看设计需求，这里做简单的 clamp）
        // 最小 offset = 0
        // 最大 offset = contentSize.width - scrollView.width
        let maxOffset = scrollView.contentSize.width - scrollView.frame.size.width
        
        // 如果内容比视口小，则不需要滚动或居中显示（这里假设内容比视口宽）
        if maxOffset > 0 {
            targetOffset = max(0, min(targetOffset, maxOffset))
        } else {
            targetOffset = 0
        }
        
        scrollOffset = targetOffset
    }
}

