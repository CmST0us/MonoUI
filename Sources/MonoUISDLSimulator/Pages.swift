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
    // MARK: - Constants (from reference code)
    private static let TILE_ICON_H: Double = 30      // 磁贴图标高度
    private static let TILE_ICON_W: Double = 30      // 磁贴图标宽度
    private static let TILE_ICON_S: Double = 36      // 磁贴图标间距
    private static let TILE_INDI_H: Double = 27     // 磁贴大标题指示器高度
    private static let TILE_INDI_W: Double = 7       // 磁贴大标题指示器宽度
    private static let TILE_INDI_S: Double = 36      // 磁贴大标题指示器上边距
    private static let TILE_B_TITLE_H: Double = 18   // 磁贴大标题字体高度
    
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
    
    // MARK: - Menu Items
    private let menuItems = ["Sleep", "Editor", "Volt", "Setting"]
    private let menuIcons = [iconSleep, iconEditor, iconVolt, iconSetting]
    
    // MARK: - Animation Properties
    @AnimationValue var iconX: Double = 0
    @AnimationValue var titleY: Double
    @AnimationValue var indiX: Double = 0
    
    // MARK: - State
    var selectedIndex: Int = 0 {
        didSet {
            updateAnimations()
        }
    }
    private var isInitialized: Bool = false
    
    // MARK: - Computed Properties
    private static var titleYCalc: Double {
        return TILE_INDI_S + (TILE_INDI_H - TILE_B_TITLE_H) / 2 + TILE_B_TITLE_H * 2
    }
    
    private static var titleYTargetCalc: Double {
        return TILE_INDI_S + (TILE_INDI_H - TILE_B_TITLE_H) / 2 + TILE_B_TITLE_H
    }
    
    init() {
        let screenSize = Context.shared.screenSize
        
        // Calculate initial values
        let initialTitleY = Self.titleYCalc
        let initialTitleYTarget = Self.titleYTargetCalc
        
        // Initialize animation values
        self._titleY = AnimationValue(wrappedValue: initialTitleY)
        
        super.init(frame: Rect(x: 0, y: 0, width: screenSize.width, height: screenSize.height))
        
        // Set animation speeds (from reference code: TILE_ANI = 30)
        _iconX.speed = 30
        _titleY.speed = 30
        _indiX.speed = 30
        
        // Initialize animation values
        iconX = 0
        titleY = initialTitleY
        indiX = 0
        
        // Set initial targets
        iconX = Self.TILE_ICON_S
        titleY = initialTitleYTarget
        indiX = Self.TILE_INDI_W
    }
    
    private func updateAnimations() {
        guard isInitialized else { return }
        
        // Update icon X position based on selected index
        iconX = -Double(selectedIndex) * Self.TILE_ICON_S
        
        // Update title Y animation (from bottom to top)
        // When switching tiles, text should animate from bottom to top
        // First set current value to bottom position immediately (no animation)
        _titleY.setCurrentValue(Self.titleYCalc)
        // Then set target to animate to top position
        titleY = Self.titleYTargetCalc
        
        // Reset indicator when selection changes
        _indiX.setCurrentValue(0)
        indiX = Self.TILE_INDI_W
    }
    
    override func draw(u8g2: UnsafeMutablePointer<u8g2_t>?, origin: Point) {
        guard let u8g2 = u8g2 else { return }
        
        super.draw(u8g2: u8g2, origin: origin)
        
        let screenSize = Context.shared.screenSize
        let absX = origin.x + frame.origin.x
        let absY = origin.y + frame.origin.y
        
        // Set clipping window to prevent icons from drawing outside screen bounds
        u8g2_SetClipWindow(u8g2,
                           u8g2_uint_t(max(0, absX)),
                           u8g2_uint_t(max(0, absY)),
                           u8g2_uint_t(absX + screenSize.width),
                           u8g2_uint_t(absY + screenSize.height))
        
        // Check if initialization animation is complete
        if !isInitialized {
            let iconXTarget = Self.TILE_ICON_S
            let titleYTarget = Self.titleYTargetCalc
            if abs(iconX - iconXTarget) < 0.15 && abs(titleY - titleYTarget) < 0.15 {
                isInitialized = true
                // Reset icon X to final position
                iconX = -Double(selectedIndex) * Self.TILE_ICON_S
            }
        }
        
        // Draw icons
        // Reference code: (DISP_W - TILE_ICON_W) / 2 + (int16_t)tile.icon_x + i * TILE_ICON_S
        // where tile.icon_x = - ui.select[ui.layer] * TILE_ICON_S after initialization
        u8g2_SetDrawColor(u8g2, 1)
        for (index, iconBits) in menuIcons.enumerated() {
            let iconXPos: Double
            if !isInitialized {
                // Initial animation: icons slide in from center
                // Reference: (DISP_W - TILE_ICON_W) / 2 + i * tile.icon_x - TILE_ICON_S * ui.select[ui.layer]
                iconXPos = (screenSize.width - Self.TILE_ICON_W) / 2 + Double(index) * iconX - Self.TILE_ICON_S * Double(selectedIndex)
            } else {
                // Normal state: (DISP_W - TILE_ICON_W) / 2 + (int16_t)tile.icon_x + i * TILE_ICON_S
                iconXPos = (screenSize.width - Self.TILE_ICON_W) / 2 + iconX + Double(index) * Self.TILE_ICON_S
            }
            
            // Calculate icon position (may be negative, which is OK - clipping will handle it)
            let iconDrawX = absX + iconXPos
            let iconDrawY = absY
            
            // Only draw if icon is within or partially within screen bounds
            // Icon is visible if its right edge is past screen left, and left edge is before screen right
            let iconRightEdge = iconDrawX + Self.TILE_ICON_W
            let iconLeftEdge = iconDrawX
            let screenRight = absX + screenSize.width
            let screenLeft = absX
            
            if iconRightEdge > screenLeft && iconLeftEdge < screenRight {
                iconBits.withUnsafeBufferPointer { ptr in
                    guard let baseAddress = ptr.baseAddress else { return }
                    // Use bitPattern to allow negative coordinates (clipping window handles boundaries)
                    // Clamp to Int16 range to avoid overflow
                    let clampedX = max(Int16.min, min(Int16.max, Int16(iconDrawX)))
                    let clampedY = max(Int16.min, min(Int16.max, Int16(iconDrawY)))
                    u8g2_DrawXBM(u8g2,
                                u8g2_uint_t(bitPattern: clampedX),
                                u8g2_uint_t(bitPattern: clampedY),
                                u8g2_uint_t(Self.TILE_ICON_W),
                                u8g2_uint_t(Self.TILE_ICON_H),
                                baseAddress)
                }
            }
        }
        
        // Restore clipping window after drawing icons
        u8g2_SetMaxClipWindow(u8g2)
        
        // Draw title indicator (left side bar)
        u8g2_DrawBox(u8g2,
                    u8g2_uint_t(max(0, min(absX, Double(UInt16.max)))),
                    u8g2_uint_t(max(0, min(absY + Self.TILE_INDI_S, Double(UInt16.max)))),
                    u8g2_uint_t(max(0, min(indiX, Double(UInt16.max)))),
                    u8g2_uint_t(Self.TILE_INDI_H))
        
        // Draw title text
        // Reference code: u8g2_font_helvB18_tr, TILE_B_TITLE_H = 18
        // Position: ((DISP_W - TILE_INDI_W) - u8g2.getStrWidth(...)) / 2 + TILE_INDI_W
        // Y position: TILE_INDI_S + (TILE_INDI_H - TILE_B_TITLE_H) / 2 + TILE_B_TITLE_H (baseline)
        let titleText = menuItems[selectedIndex]
        u8g2_SetFont(u8g2, u8g2_font_helvB18_tr)
        
        let textWidth = Double(u8g2_GetStrWidth(u8g2, titleText))
        // Reference: ((DISP_W - TILE_INDI_W) - u8g2.getStrWidth(...)) / 2 + TILE_INDI_W
        let textX = ((screenSize.width - Self.TILE_INDI_W) - textWidth) / 2 + Self.TILE_INDI_W
        
        // Y position: titleYTargetCalc is the baseline position
        // Reference: TILE_INDI_S + (TILE_INDI_H - TILE_B_TITLE_H) / 2 + TILE_B_TITLE_H
        let textBaselineY = absY + titleY
        
        u8g2_DrawStr(u8g2,
                    u8g2_uint_t(max(0, min(absX + textX, Double(UInt16.max)))),
                    u8g2_uint_t(max(0, min(textBaselineY, Double(UInt16.max)))),
                    titleText)
    }
    
    override func handleInput(key: Int32) {
        // 'd' (100) -> Next
        if key == 100 {
            if selectedIndex < menuItems.count - 1 {
                selectedIndex += 1
            }
        }
        
        // 'a' (97) -> Previous
        if key == 97 {
            if selectedIndex > 0 {
                selectedIndex -= 1
            }
        }
        
        // 'Enter' or 'e' (101) -> Select/Click
        if key == 101 {
            handleSelection()
        }
    }
    
    private func handleSelection() {
        switch selectedIndex {
        case 0: // Sleep
            // TODO: Implement sleep functionality
            break
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
class TextIconTestPage: Page {
    @AnimationValue var offsetX: Double
    
    init() {
        let screenSize = Context.shared.screenSize
        self._offsetX = AnimationValue(wrappedValue: screenSize.width)
        super.init(frame: Rect(x: screenSize.width, y: 0, width: screenSize.width, height: screenSize.height))
        
        // Create a vertical stack for text views (SwiftUI style)
        let textStack = StackView(frame: Rect(x: 0, y: 0, width: screenSize.width, height: screenSize.height),
                                 axis: .horizontal)
        
        // Add Text views using SwiftUI-style initialization
        // Position and size are automatically managed by StackView
        let text1 = Text("A")
        textStack.addSubview(text1)
        
        textStack.addSubview(Spacer())

        let text2 = Text("C")
        textStack.addSubview(text2)
        addSubview(textStack)
        

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

/// Test page for ScrollView containing StackView with Text list.
class ScrollViewTestPage: Page {
    @AnimationValue var offsetX: Double
    let listMenu: ListMenu
    
    init() {
        let screenSize = Context.shared.screenSize
        self._offsetX = AnimationValue(wrappedValue: screenSize.width)
        
        // Create a ListMenu
        self.listMenu = ListMenu(size: Size(width: screenSize.width, height: screenSize.height),
                                direction: .vertical)
        
        super.init(frame: Rect(x: screenSize.width, y: 0, width: screenSize.width, height: screenSize.height))
        
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
        
        // Set items in ListMenu (no StackView needed)
        listMenu.setItems(texts)
        
        // Initialize cursor to first item
        listMenu.selectedIndex = 0
        
        // Add ListMenu to page
        addSubview(listMenu)
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

