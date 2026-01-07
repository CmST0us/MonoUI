import MonoUI
import U8g2Kit
import CU8g2

// MARK: - LinuxI2CApp

/// Application for Linux I2C device with SSD1306 display.
class LinuxI2CApp: Application {
    
    override init(context: Context) {
        super.init(context: context)
        self.setFrameRate(60)
    }
    
    override func setup() {
        // Initialize display
        driver.withUnsafeU8g2 { u8g2 in
            u8g2_ClearBuffer(u8g2)
            u8g2_InitDisplay(u8g2)
            u8g2_SetPowerSave(u8g2, 0)
        }
        
        // Set root page
        let homePage = HomePage()
        router.setRoot(homePage)
    }
    
    override func loop() {
        driver.withUnsafeU8g2 { u8g2 in
            u8g2_ClearBuffer(u8g2)
            u8g2_SetBitmapMode(u8g2, 1)
            u8g2_SetFontMode(u8g2, 1)
            
            // Draw router (pages and modals)
            router.draw(u8g2: u8g2)
            
            u8g2_SendBuffer(u8g2)
        }
        
        // TODO: Handle input (GPIO, keyboard, etc.)
    }
}

// MARK: - Main Entry Point

// Default I2C bus and address - adjust as needed
// Common SSD1306 I2C addresses: 0x3C (7-bit) or 0x3D (7-bit)
let i2cBus: Int32 = 1  // /dev/i2c-1 (adjust based on your system)
let i2cAddress = I2CAddress(address7Bit: 0x3C)  // Common SSD1306 address

let driver = LinuxI2CDeviceDriver(i2cBus: i2cBus, address: i2cAddress)
let screenSize = Size(width: 128, height: 64)
let context = Context(driver: driver, screenSize: screenSize)
let app = LinuxI2CApp(context: context)
app.run()
