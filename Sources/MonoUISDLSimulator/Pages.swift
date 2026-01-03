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
        
        // Create TileMenu
        self.tileMenu = TileMenu(frame: Rect(x: 0, y: 0, width: screenSize.width, height: screenSize.height))
        
        super.init(frame: Rect(x: 0, y: 0, width: screenSize.width, height: screenSize.height))
        
        // Setup menu items and icons
        let menuItems = ["Sleep", "Editor", "Volt", "Setting"]
        let menuIcons = [Self.iconSleep, Self.iconEditor, Self.iconVolt, Self.iconSetting]
        tileMenu.setItems(menuItems, icons: menuIcons)
        
        // Setup selection callback
        tileMenu.onSelect = { [weak self] index in
            self?.handleSelection(index: index)
        }
        
        // Add tile menu as subview
        addSubview(tileMenu)
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

/// Test page for ScrollView containing different types of menu items.
class ScrollViewTestPage: Page {
    @AnimationValue var offsetX: Double
    let listMenu: ListMenu
    
    // State variables for menu items
    private var toggleState = false
    private var radioValueHolder: RadioValueHolder
    private var checkboxStatesHolder: CheckboxStatesHolder
    private var brightnessValue = 50
    
    init() {
        let screenSize = Context.shared.screenSize
        self._offsetX = AnimationValue(wrappedValue: screenSize.width)
        
        // Initialize state holders
        self.radioValueHolder = RadioValueHolder(1)
        self.checkboxStatesHolder = CheckboxStatesHolder([false, false, false])
        
        // Create a ListMenu
        self.listMenu = ListMenu(size: Size(width: screenSize.width, height: screenSize.height),
                                direction: .vertical)
        
        super.init(frame: Rect(x: screenSize.width, y: 0, width: screenSize.width, height: screenSize.height))
        
        // Create different types of menu items
        let header = HeaderMenuItem("[ Menu Test ]")
        
        let separator1 = SeparatorMenuItem()
        
        // Toggle items
        let toggle1 = ToggleMenuItem("Enable Feature", isOn: false) { [weak self] isOn in
            self?.toggleState = isOn
            print("Toggle changed to: \(isOn)")
        }
        
        let toggle2 = ToggleMenuItem("Dark Mode", isOn: true) { isOn in
            print("Dark Mode: \(isOn)")
        }
        
        let separator2 = SeparatorMenuItem()
        
        // Radio button items (single selection group)
        let radio1 = RadioMenuItem("Option 1", value: 1, selectedValueHolder: radioValueHolder, position: 0) { value in
            print("Radio selected: \(value)")
        }
        
        let radio2 = RadioMenuItem("Option 2", value: 2, selectedValueHolder: radioValueHolder, position: 1) { value in
            print("Radio selected: \(value)")
        }
        
        let radio3 = RadioMenuItem("Option 3", value: 3, selectedValueHolder: radioValueHolder, position: 2) { value in
            print("Radio selected: \(value)")
        }
        
        let separator3 = SeparatorMenuItem()
        
        // Checkbox items (multiple selection group)
        let checkbox1 = CheckboxMenuItem("Check 1", index: 0, checkboxStatesHolder: checkboxStatesHolder) { index, isChecked in
            print("Checkbox \(index) changed to: \(isChecked)")
        }
        
        let checkbox2 = CheckboxMenuItem("Check 2", index: 1, checkboxStatesHolder: checkboxStatesHolder) { index, isChecked in
            print("Checkbox \(index) changed to: \(isChecked)")
        }
        
        let checkbox3 = CheckboxMenuItem("Check 3", index: 2, checkboxStatesHolder: checkboxStatesHolder) { index, isChecked in
            print("Checkbox \(index) changed to: \(isChecked)")
        }
        
        let separator4 = SeparatorMenuItem()
        
        // Value display items
        let value1 = ValueMenuItem("Brightness", value: brightnessValue) { [weak self] value in
            self?.brightnessValue = value
            print("Brightness: \(value)")
        }
        
        let value2 = ValueMenuItem("Volume", value: 75) { value in
            print("Volume: \(value)")
        }
        
        let separator5 = SeparatorMenuItem()
        
        // Plain text items
        let text1 = TextMenuItem("Plain Text Item 1")
        let text2 = TextMenuItem("Plain Text Item 2")
        let text3 = TextMenuItem("Plain Text Item 3")
        
        // Set menu items
        listMenu.setMenuItems([
            header,
            separator1,
            toggle1,
            toggle2,
            separator2,
            radio1,
            radio2,
            radio3,
            separator3,
            checkbox1,
            checkbox2,
            checkbox3,
            separator4,
            value1,
            value2,
            separator5,
            text1,
            text2,
            text3
        ])
        
        // Initialize cursor to first selectable item (skip header and separator)
        listMenu.selectedIndex = 2
        
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
            moveToNextSelectableItem(direction: -1)
        }
        
        // 's' (115) -> Move cursor down
        if key == 115 {
            moveToNextSelectableItem(direction: 1)
        }
        
        // 'Enter' or 'e' (101) -> Select/Activate item
        if key == 101 {
            listMenu.handleSelection()
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
    
    /// Moves to the next selectable item, skipping headers and separators.
    private func moveToNextSelectableItem(direction: Int) {
        guard listMenu.itemCount > 0 else { return }
        
        var currentIndex = listMenu.selectedIndex
        let maxIndex = listMenu.itemCount - 1
        let startIndex = currentIndex
        
        // Find next selectable item
        repeat {
            currentIndex += direction
            
            // Check bounds
            if currentIndex < 0 {
                // Reached top, try wrapping to bottom
                currentIndex = maxIndex
            } else if currentIndex > maxIndex {
                // Reached bottom, try wrapping to top
                currentIndex = 0
            }
            
            // Check if current item is selectable
            if currentIndex >= 0 && currentIndex <= maxIndex {
                let item = listMenu.menuItems[currentIndex]
                if item.itemType != .header && item.itemType != .separator {
                    // Found a selectable item
                    listMenu.selectedIndex = currentIndex
                    return
                }
            }
            
            // Prevent infinite loop if all items are non-selectable
            if currentIndex == startIndex {
                break
            }
        } while currentIndex != startIndex
    }
}

