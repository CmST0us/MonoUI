import MonoUI
import CU8g2

class DetailPage: Page {
    @AnimationValue var offsetX: Double // 初始在屏幕右侧外
    
    let title: String
    
    init(title: String) {
        self.title = title
        let screenSize = Context.shared.screenSize
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
        let screenWidth = Context.shared.screenSize.width
        offsetX = screenWidth
    }
    
    override func isExitAnimationFinished() -> Bool {
        // 当 offsetX 接近屏幕宽度时认为完成
        let screenWidth = Context.shared.screenSize.width
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
    // MARK: - Icon Data (from reference code main_icon_pic)
    static let iconSleep: [UInt8] = [
        0xFF,0xFF,0xFF,0x3F,0xFF,0xFF,0xFF,0x3F,0xFF,0xFF,0xFF,0x3F,0xFF,0xFF,0xF1,0x3F,
        0xFF,0xFF,0xC3,0x3F,0xFF,0xFF,0x87,0x3F,0xFF,0xFF,0x07,0x3F,0xFF,0xFF,0x0F,0x3E,
        0xFF,0xFF,0x0F,0x3E,0xFF,0xFF,0x0F,0x3C,0xFF,0xFF,0x0F,0x3C,0xFF,0xFF,0x0F,0x38,
        0xFF,0xFF,0x0F,0x38,0xFF,0xFF,0x0F,0x38,0xFF,0xFF,0x07,0x38,0xFF,0xFF,0x07,0x38,
        0xFF,0xFF,0x03,0x38,0xF7,0xFF,0x01,0x38,0xE7,0xFF,0x00,0x3C,0x87,0x3F,0x00,0x3C,
        0x0F,0x00,0x00,0x3E,0x0F,0x00,0x00,0x3E,0x1F,0x00,0x00,0x3F,0x3F,0x00,0x80,0x3F,
        0x7F,0x00,0xC0,0x3F,0xFF,0x01,0xF0,0x3F,0xFF,0x07,0xFC,0x3F,0xFF,0xFF,0xFF,0x3F,
        0xFF,0xFF,0xFF,0x3F,0xFF,0xFF,0xFF,0x3F
    ]
    
    static let iconEditor: [UInt8] = [
        0xFF,0xFF,0xFF,0x3F,0xFF,0xFF,0xFF,0x3F,0xFF,0xFF,0xFF,0x3F,0xFF,0xF9,0xE7,0x3F,
        0xFF,0xF9,0xE7,0x3F,0xFF,0xF9,0xE7,0x3F,0xFF,0xF0,0xE7,0x3F,0x7F,0xE0,0xE7,0x3F,
        0x7F,0xE0,0xC3,0x3F,0x7F,0xE0,0xC3,0x3F,0x7F,0xE0,0xC3,0x3F,0x7F,0xE0,0xE7,0x3F,
        0xFF,0xF0,0xE7,0x3F,0xFF,0xF9,0xE7,0x3F,0xFF,0xF9,0xE7,0x3F,0xFF,0xF9,0xE7,0x3F,
        0xFF,0xF9,0xE7,0x3F,0xFF,0xF9,0xC3,0x3F,0xFF,0xF9,0x81,0x3F,0xFF,0xF0,0x81,0x3F,
        0xFF,0xF0,0x81,0x3F,0xFF,0xF0,0x81,0x3F,0xFF,0xF9,0x81,0x3F,0xFF,0xF9,0xC3,0x3F,
        0xFF,0xF9,0xE7,0x3F,0xFF,0xF9,0xE7,0x3F,0xFF,0xF9,0xE7,0x3F,0xFF,0xFF,0xFF,0x3F,
        0xFF,0xFF,0xFF,0x3F,0xFF,0xFF,0xFF,0x3F
    ]
    
    static let iconVolt: [UInt8] = [
        0xFF,0xFF,0xFF,0x3F,0xFF,0xFF,0xFF,0x3F,0xEF,0xFF,0xFF,0x3F,0xC7,0xFF,0xFF,0x3F,
        0xC7,0xF3,0xFF,0x3F,0x83,0xC0,0xFF,0x3F,0xEF,0xCC,0xFF,0x3F,0x6F,0x9E,0xFF,0x3F,
        0x6F,0x9E,0xFF,0x3F,0x2F,0x3F,0xFF,0x3F,0x2F,0x3F,0xFF,0x3F,0x8F,0x7F,0xFE,0x3F,
        0x8F,0x7F,0xFE,0x39,0x8F,0x7F,0xFE,0x39,0xCF,0xFF,0xFC,0x3C,0xCF,0xFF,0xFC,0x3C,
        0xEF,0xFF,0xFC,0x3C,0xEF,0xFF,0x79,0x3E,0xEF,0xFF,0x79,0x3E,0xEF,0xFF,0x33,0x3F,
        0xEF,0xFF,0x33,0x3F,0xEF,0xFF,0x87,0x3F,0xEF,0xFF,0xCF,0x3F,0xEF,0xFF,0x7F,0x3E,
        0xEF,0xFF,0x7F,0x38,0x0F,0x00,0x00,0x30,0xFF,0xFF,0x7F,0x38,0xFF,0xFF,0x7F,0x3E,
        0xFF,0xFF,0xFF,0x3F,0xFF,0xFF,0xFF,0x3F,
    ]
    
    static let iconSetting: [UInt8] = [
        0xFF,0xFF,0xFF,0x3F,0xFF,0xFF,0xFF,0x3F,0xFF,0xFF,0xFF,0x3F,0xFF,0xFF,0xFF,0x3F,
        0xFF,0x1F,0xFE,0x3F,0xFF,0x1F,0xFE,0x3F,0xFF,0x0C,0xCC,0x3F,0x7F,0x00,0x80,0x3F,
        0x3F,0x00,0x00,0x3F,0x3F,0xE0,0x01,0x3F,0x7F,0xF8,0x87,0x3F,0x7F,0xFC,0x8F,0x3F,
        0x3F,0xFC,0x0F,0x3F,0x0F,0x3E,0x1F,0x3C,0x0F,0x1E,0x1E,0x3C,0x0F,0x1E,0x1E,0x3C,
        0x0F,0x3E,0x1F,0x3C,0x3F,0xFC,0x0F,0x3F,0x7F,0xFC,0x8F,0x3F,0x7F,0xF8,0x87,0x3F,
        0x3F,0xE0,0x01,0x3F,0x3F,0x00,0x00,0x3F,0x7F,0x00,0x80,0x3F,0xFF,0x0C,0xCC,0x3F,
        0xFF,0x1F,0xFE,0x3F,0xFF,0x1F,0xFE,0x3F,0xFF,0xFF,0xFF,0x3F,0xFF,0xFF,0xFF,0x3F,
        0xFF,0xFF,0xFF,0x3F,0xFF,0xFF,0xFF,0x3F
    ]
    
    // MARK: - Properties
    private let tileMenu: TileMenu
    
    init() {
        let screenSize = Context.shared.screenSize
        
        // Create and configure TileMenu
        let menu = TileMenu(frame: Rect(x: 0, y: 0, width: screenSize.width, height: screenSize.height))
        
        // Setup menu items and icons
        let menuItems = ["Sleep", "Editor", "Volt", "Setting"]
        let menuIcons = [Self.iconSleep, Self.iconEditor, Self.iconVolt, Self.iconSetting]
        menu.setItems(menuItems, icons: menuIcons)
        
        // Initialize tileMenu property before super.init
        self.tileMenu = menu
        
        // Initialize with ViewBuilder content (SwiftUI style)
        super.init(frame: Rect(x: 0, y: 0, width: screenSize.width, height: screenSize.height)) {
            menu
        }
        
        // Setup selection callback after super.init
        menu.onSelect = { [weak self] index in
            self?.handleSelection(index: index)
        }
    }
    
    override func draw(u8g2: UnsafeMutablePointer<u8g2_t>?, origin: Point) {
        super.draw(u8g2: u8g2, origin: origin)
    }
    
    override func handleInput(key: Int32) {
        // 'd' (100) -> Next
        if key == 100 {
            tileMenu.moveNext()
        }
        
        // 'a' (97) -> Previous
        if key == 97 {
            tileMenu.movePrevious()
        }
        
        // 'Enter' or 'e' (101) -> Select/Click
        if key == 101 {
            tileMenu.onSelect?(tileMenu.selectedIndex)
        }
        
        // 'p' (112) -> Show Progress View
        if key == 112 {
            if let app = Application.shared as? SDL2SimulatorApp {
                let progressView = ProgressView(title: "Progress", value: 50, minimum: 0, maximum: 100, step: 5)
                (app as Application).router.present(progressView)
            }
        }
    }
    
    private func handleSelection(index: Int) {
        switch index {
        case 0: // Sleep -> HelloWorldPage (SwiftUI example)
            if let app = Application.shared as? SDL2SimulatorApp {
                (app as Application).router.push(HelloWorldPage())
            }
        case 1: // Editor
            if let app = Application.shared as? SDL2SimulatorApp {
                (app as Application).router.push(TextIconTestPage())
            }
        case 2: // Volt
            if let app = Application.shared as? SDL2SimulatorApp {
                (app as Application).router.push(DetailPage(title: "Volt"))
            }
        case 3: // Setting
            if let app = Application.shared as? SDL2SimulatorApp {
                (app as Application).router.push(ScrollViewTestPage())
            }
        default:
            break
        }
    }
}

// MARK: - TextIconTestPage

/// Test page for Text and Icon views.
/// Uses SwiftUIPage with SwiftUI-style body property.
class TextIconTestPage: SwiftUIPage {
    @AnimationValue var offsetX: Double
    let screenSize = Context.shared.screenSize
    
    /*
    should be like this:
----------------------
|                    |
|                    |
|A                  C|
|                    |
|                    |
----------------------
    */
    @ViewBuilder
    override var body: AnyView {
        HStack(spacing: 0) {
            Text("A")
            Spacer()
            Text("C")
        }
    }
    
    override init() {
        let screenSize = Context.shared.screenSize
        self._offsetX = AnimationValue(wrappedValue: screenSize.width)
        
        // Initialize SwiftUIPage (frame will be set to screen bounds)
        super.init()
        
        // Override frame to start off-screen for slide-in animation
        self.frame = Rect(x: screenSize.width, y: 0, width: screenSize.width, height: screenSize.height)
    }
    
    override func animateIn() {
        offsetX = 0
    }
    
    override func animateOut() {
        let screenWidth = Context.shared.screenSize.width
        offsetX = screenWidth
    }
    
    override func isExitAnimationFinished() -> Bool {
        let screenWidth = Context.shared.screenSize.width
        return offsetX >= screenWidth - 0.5
    }
    
    override func draw(u8g2: UnsafeMutablePointer<u8g2_t>?, origin: Point) {
        // Update frame position based on animation
        frame.origin.x = offsetX
        super.draw(u8g2: u8g2, origin: origin)
    }
    
    override func handleInput(key: Int32) {
        // 'q' (113) -> Back
        if key == 113 {
            if let app = Application.shared as? SDL2SimulatorApp {
                let router = (app as Application).router
                if router.modal != nil {
                    router.dismissModal()
                } else {
                    router.pop()
                }
            }
        }
    }
}

// MARK: - ScrollViewTestPage

/// Test page for ScrollView containing ListMenu.
class ScrollViewTestPage: Page {
    @AnimationValue var offsetX: Double
    let listMenu: ListMenu
    
    init() {
        let screenSize = Context.shared.screenSize
        self._offsetX = AnimationValue(wrappedValue: screenSize.width)
        
        // Create and configure ListMenu
        let menu = ListMenu(size: Size(width: screenSize.width, height: screenSize.height),
                           direction: .vertical)
        
        // Set list items (text strings)
        let texts = [
            "Item 1: First",
            "Item 2: Second",
            "Item 3: Third",
            "Item 4: Fourth",
            "Item 5: Fifth",
            "Item 6: Sixth",
            "Item 7: Seventh",
            "Item 8: Eighth",
            "Item 9: Ninth",
            "Item 10: Tenth"
        ]
        
        // Set items in ListMenu
        menu.setItems(texts)
        
        // Initialize cursor to first item
        menu.selectedIndex = 0
        
        self.listMenu = menu
        
        // Initialize with ViewBuilder content (SwiftUI style)
        super.init(frame: Rect(x: screenSize.width, y: 0, width: screenSize.width, height: screenSize.height)) {
            menu
        }
    }
    
    override func animateIn() {
        offsetX = 0
    }
    
    override func animateOut() {
        let screenWidth = Context.shared.screenSize.width
        offsetX = screenWidth
    }
    
    override func isExitAnimationFinished() -> Bool {
        let screenWidth = Context.shared.screenSize.width
        return offsetX >= screenWidth - 0.5
    }
    
    override func draw(u8g2: UnsafeMutablePointer<u8g2_t>?, origin: Point) {
        frame.origin.x = offsetX
        super.draw(u8g2: u8g2, origin: origin)
    }
    
    override func handleInput(key: Int32) {
        // 'w' (119) -> Move cursor up
        if key == 119 {
            listMenu.moveUp()
        }
        
        // 's' (115) -> Move cursor down
        if key == 115 {
            listMenu.moveDown()
        }
        
        // 'q' (113) -> Back
        if key == 113 {
            if let app = Application.shared as? SDL2SimulatorApp {
                let router = (app as Application).router
                if router.modal != nil {
                    router.dismissModal()
                } else {
                    router.pop()
                }
            }
        }
    }
}

// MARK: - HelloWorldPage

/// Example SwiftUI-style page that displays "Hello World" with a counter.
///
/// This demonstrates the SwiftUI-style `body` property usage with @State.
/// The content will be automatically centered on the screen.
/// The counter increments every second.
class HelloWorldPage: SwiftUIPage {
    @State var count: Int = 0
    private var lastUpdateTime: Double = 0
    
    @ViewBuilder
    override var body: AnyView {
        VStack(spacing: 5) {
            Text("Hello World")
            Text("Count: \(count)")
        }
    }
    
    override init() {
        super.init()
        
        // Setup @State update handler to refresh body when count changes
        _count.setUpdateHandler { [weak self] in
            self?.updateBody()
        }
        
        // Initialize last update time
        if let app = Application.shared {
            lastUpdateTime = app.getCurrentTime()
        }
    }
    
    /// Called every frame to update the counter.
    /// This is called by the Router when drawing the page.
    override func draw(u8g2: UnsafeMutablePointer<u8g2_t>?, origin: Point) {
        // Update counter every second
        if let app = Application.shared {
            let currentTime = app.getCurrentTime()
            if currentTime - lastUpdateTime >= 1.0 {
                count += 1
                lastUpdateTime = currentTime
            }
        }
        
        // Call super to draw the page
        super.draw(u8g2: u8g2, origin: origin)
    }
    
    override func handleInput(key: Int32) {
        // 'q' (113) -> Back
        if key == 113 {
            if let app = Application.shared as? SDL2SimulatorApp {
                let router = (app as Application).router
                if router.modal != nil {
                    router.dismissModal()
                } else {
                    router.pop()
                }
            }
        }
    }
}

