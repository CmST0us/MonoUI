import Foundation
import SwiftSTLinkV3Bridge
import MonoUI
import CU8g2

// MARK: - STLinkV3BridgeSSD1306App

/// Application for STLink V3 bridge with SSD1306 display.
class STLinkV3BridgeSSD1306App: Application {
    private let bridge: SwiftSTLinkV3Bridge.Bridge
    let router = Router()
    
    // GPIO state tracking for edge detection
    private var lastGPIOStates: [Any]?
    
    init(context: Context, bridge: SwiftSTLinkV3Bridge.Bridge) {
        self.bridge = bridge
        super.init(context: context)
        self.setFrameRate(60)
    }
    
    override func setup() {
        // Initialize GPIO
        let gpioConfig = GPIOConfiguration.inputPullDown
        _ = bridge.initGPIO(mask: [.gpio0, .gpio1, .gpio2], 
                           config: [gpioConfig, gpioConfig, gpioConfig])
        
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
        
        // Handle GPIO input
        handleGPIOInput()
    }
    
    /// Handles GPIO button input with edge detection.
    private func handleGPIOInput() {
        guard let gpioStates = bridge.readGPIO(mask: [.gpio0, .gpio1, .gpio2]) else {
            return
        }
        
        // Store last state for edge detection
        defer {
            lastGPIOStates = gpioStates as [Any]
        }
        
        guard let last = lastGPIOStates else {
            return // Skip first iteration
        }
        
        // Detect rising edge (button press) by comparing string representations
        // GPIO0 -> Next
        if "\(gpioStates[0])" == "set" && "\(last[0])" == "reset" {
            router.handleInput(key: 0)
        }
        
        // GPIO1 -> Previous/Back
        if "\(gpioStates[1])" == "set" && "\(last[1])" == "reset" {
            router.handleInput(key: 1)
        }
        
        // GPIO2 -> Confirm/Select  
        if "\(gpioStates[2])" == "set" && "\(last[2])" == "reset" {
            router.handleInput(key: 2)
        }
    }
}

// MARK: - Main Entry Point

let device = SwiftSTLinkV3Bridge.Bridge()
device.enumDevices()
device.openDevice()

let i2cConfiguration = I2CConfiguration.fastPlus
device.initI2CDevice(configuration: i2cConfiguration)
let address = I2CAddress.address8BitWrite(0x78)

var u8g2Driver = SSD1306STLinkV3BridgeU8g2Driver(device: device, address: address)
let screenSize = Size(width: 128, height: 64)
let context = Context(driver: u8g2Driver, screenSize: screenSize)
let app = STLinkV3BridgeSSD1306App(context: context, bridge: device)
app.run()
