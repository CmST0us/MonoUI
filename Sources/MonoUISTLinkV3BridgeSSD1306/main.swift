import Foundation
import SwiftSTLinkV3Bridge
import MonoUI
import CU8g2

class STLinkV3BridgeSSD1306App: Application {
    @AnimationValue var x: Double = 0
    @AnimationValue var y: Double = 0

    private let bridge: SwiftSTLinkV3Bridge.Bridge

    init(context: Context, bridge: SwiftSTLinkV3Bridge.Bridge) {
        self.bridge = bridge
        super.init(context: context)
        self.setFrameRate(60)
    }

    override func setup() {
        let gpioConfig = GPIOConfiguration.inputPullDown
        bridge.initGPIO(mask: [.gpio0, .gpio1, .gpio2], config: [gpioConfig, gpioConfig, gpioConfig])

        driver.withUnsafeU8g2 { u8g2 in
            u8g2_ClearBuffer(u8g2)
            u8g2_InitDisplay(u8g2)
            u8g2_SetPowerSave(u8g2, 0)
        }
    }
    
    override func loop() {
        driver.withUnsafeU8g2 { u8g2 in
            u8g2_ClearBuffer(u8g2)
            u8g2_DrawRBox(u8g2, u8g2_uint_t(x), u8g2_uint_t(y), 30, 30, 4)
            u8g2_SendBuffer(u8g2)
        }

        guard let values = bridge.readGPIO(mask: [.gpio0, .gpio1, .gpio2]) else {
            return
        }

        if values[0] == .set {
            x = 55
        }

        if values[1] == .reset {
            x = 0
        }
        
    }
}

// 主程序
let device = SwiftSTLinkV3Bridge.Bridge()
device.enumDevices()
device.openDevice()

let i2cConfiguration = I2CConfiguration.fastPlus
device.initI2CDevice(configuration: i2cConfiguration)
let address = I2CAddress.address8BitWrite(0x78)

var u8g2Driver = SSD1306STLinkV3BridgeU8g2Driver(device: device, address: address)
let context = Context(driver: u8g2Driver)
let app = STLinkV3BridgeSSD1306App(context: context, bridge: device)
app.run()

