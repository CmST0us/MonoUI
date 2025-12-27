import MonoUI
import CU8g2

// MARK: - DetailPage

/// Detail page showing information about a selected item.
class DetailPage: Page {
    @AnimationValue var offsetX: Double = 128
    
    let title: String
    
    init(title: String) {
        self.title = title
        super.init(frame: Rect(x: 128, y: 0, width: 128, height: 64))
    }
    
    override func animateIn() {
        offsetX = 0
    }
    
    override func animateOut() {
        offsetX = 128
    }
    
    override func isExitAnimationFinished() -> Bool {
        return offsetX >= 127.5
    }
    
    override func draw(u8g2: UnsafeMutablePointer<u8g2_t>?, origin: Point) {
        frame.origin.x = offsetX
        super.draw(u8g2: u8g2, origin: origin)
        
        guard let u8g2 = u8g2 else { return }
        
        let absX = origin.x + frame.origin.x
        let absY = origin.y + frame.origin.y
        
        u8g2_SetDrawColor(u8g2, 1)
        u8g2_DrawFrame(u8g2, u8g2_uint_t(absX), u8g2_uint_t(absY), 128, 64)
        
        u8g2_SetFont(u8g2, u8g2_font_6x10_tf)
        u8g2_DrawStr(u8g2, u8g2_uint_t(absX + 10), u8g2_uint_t(absY + 20), "Detail: \(title)")
        u8g2_DrawStr(u8g2, u8g2_uint_t(absX + 10), u8g2_uint_t(absY + 40), "GPIO1 to Back")
    }
    
    override func handleInput(key: Int32) {
        // GPIO mapping: key 1 -> Back
        if key == 1 {
            if let app = Application.shared as? STLinkV3BridgeSSD1306App {
                if app.router.modal != nil {
                    app.router.dismissModal()
                } else {
                    app.router.pop()
                }
            }
        }
        
        // GPIO mapping: key 2 -> Show Alert
        if key == 2 {
            if let app = Application.shared as? STLinkV3BridgeSSD1306App {
                let alert = AlertView(frame: Rect(x: 14, y: 12, width: 100, height: 40), 
                                      title: "Info", 
                                      message: "Hello World")
                app.router.present(alert)
            }
        }
    }
}

// MARK: - HomePage

/// Home page with scrollable icon tiles.
class HomePage: Page {
    let scrollView: ScrollView
    @AnimationValue var scrollOffset: Double = 0
    
    // Icon data
    static let icon1: [UInt8] = [0x00,0x00,0x00,0x40,0x00,0x00,0x40,0x04,0x00,0x40,0x04,0x00,0x40,0x04,0x00,0x50,0x14,0x00,0x50,0x15,0x00,0x54,0x15,0x00,0x55,0x55,0x01,0x50,0x55,0x00,0x50,0x15,0x00,0x50,0x04,0x00,0x40,0x04,0x00,0x40,0x04,0x00,0x40,0x00,0x00,0x00,0x00,0x00]
    static let icon2: [UInt8] = [0x80,0x00,0x48,0x01,0x38,0x02,0x98,0x04,0x48,0x09,0x24,0x12,0x12,0x24,0x09,0x48,0x66,0x30,0x64,0x10,0x04,0x17,0x04,0x15,0x04,0x17,0x04,0x15,0xfc,0x1f,0x00,0x00]
    static let icon3: [UInt8] = [0x1c,0x00,0x22,0x00,0xe3,0x3f,0x22,0x00,0x1c,0x00,0x00,0x0e,0x00,0x11,0xff,0x31,0x00,0x11,0x00,0x0e,0x1c,0x00,0x22,0x00,0xe3,0x3f,0x22,0x00,0x1c,0x00,0x00,0x00]
    
    var selectedIndex: Int = 0
    var tiles: [IconTileView]
    
    init() {
        self.scrollView = ScrollView(frame: Rect(x: 0, y: 0, width: 128, height: 45))
        self.scrollView.contentSize = Size(width: 212, height: 45)
        self.scrollView.direction = .horizontal
        self.tiles = []
        
        super.init(frame: Rect(x: 0, y: 0, width: 128, height: 64))
        
        let startX: Double = 45
        let spacing: Double = 6
        let cardSize = Size(width: 36, height: 36)
        let yPos: Double = 4
        
        let tile1 = IconTileView(frame: Rect(x: startX, y: yPos, width: cardSize.width, height: cardSize.height),
                                 iconBits: Self.icon1,
                                 iconSize: Size(width: 17, height: 16)) {
            if let app = Application.shared as? STLinkV3BridgeSSD1306App {
                app.router.push(DetailPage(title: "Music"))
            }
        }
        scrollView.addSubview(tile1)
        tiles.append(tile1)
        
        let tile2 = IconTileView(frame: Rect(x: startX + cardSize.width + spacing, y: yPos, width: cardSize.width, height: cardSize.height),
                                 iconBits: Self.icon2,
                                 iconSize: Size(width: 15, height: 16)) {
            if let app = Application.shared as? STLinkV3BridgeSSD1306App {
                app.router.push(DetailPage(title: "Home"))
            }
        }
        scrollView.addSubview(tile2)
        tiles.append(tile2)
        
        let tile3 = IconTileView(frame: Rect(x: startX + (cardSize.width + spacing) * 2, y: yPos, width: cardSize.width, height: cardSize.height),
                                 iconBits: Self.icon3,
                                 iconSize: Size(width: 14, height: 16)) {
            if let app = Application.shared as? STLinkV3BridgeSSD1306App {
                app.router.push(DetailPage(title: "Download"))
            }
        }
        scrollView.addSubview(tile3)
        tiles.append(tile3)
        
        self.addSubview(scrollView)
    }
    
    override func draw(u8g2: UnsafeMutablePointer<u8g2_t>?, origin: Point) {
        scrollView.contentOffset.x = scrollOffset
        super.draw(u8g2: u8g2, origin: origin)
        
        if let u8g2 = u8g2 {
            u8g2_DrawBox(u8g2, 0, 47, 4, 17)
        }
    }
    
    override func handleInput(key: Int32) {
        // GPIO mapping: key 0 -> Next
        if key == 0 {
            if selectedIndex < tiles.count - 1 {
                selectedIndex += 1
                scrollToSelected()
            }
        }
        
        // GPIO mapping: key 1 -> Previous
        if key == 1 {
            if selectedIndex > 0 {
                selectedIndex -= 1
                scrollToSelected()
            }
        }
        
        // GPIO mapping: key 2 -> Select/Confirm
        if key == 2 {
            tiles[selectedIndex].onClick?()
        }
    }
    
    private func scrollToSelected() {
        let tile = tiles[selectedIndex]
        let tileCenterX = tile.frame.origin.x + tile.frame.size.width / 2
        let scrollViewCenterX = scrollView.frame.size.width / 2
        
        var targetOffset = tileCenterX - scrollViewCenterX
        let maxOffset = scrollView.contentSize.width - scrollView.frame.size.width
        
        if maxOffset > 0 {
            targetOffset = max(0, min(targetOffset, maxOffset))
        } else {
            targetOffset = 0
        }
        
        scrollOffset = targetOffset
    }
}

