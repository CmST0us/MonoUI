import Foundation
import SwiftSTLinkV3Bridge
import MonoUI
import CU8g2

// 绘制速度仪表盘
func drawSpeedGauge(u8g2: UnsafeMutablePointer<u8g2_t>, speed: Int) {
    let centerX: UInt16 = 32  // 向左移动
    let centerY: UInt16 = 32
    let radius: UInt16 = 25   // 稍微缩小一点
    
    // 绘制外圈
    u8g2_DrawCircle(u8g2, centerX, centerY, radius, 0xFF)
    
    // 绘制刻度
    for i in 0..<12 {
        let angle = Double(i) * 30.0 * .pi / 180.0
        let x1 = Int16(centerX) + Int16(cos(angle) * Double(radius - 2))
        let y1 = Int16(centerY) + Int16(sin(angle) * Double(radius - 2))
        let x2 = Int16(centerX) + Int16(cos(angle) * Double(radius))
        let y2 = Int16(centerY) + Int16(sin(angle) * Double(radius))
        u8g2_DrawLine(u8g2, UInt16(x1), UInt16(y1), UInt16(x2), UInt16(y2))
    }
    
    // 绘制数字
    u8g2_SetFont(u8g2, u8g2_font_6x10_tr)
    for i in 0..<4 {
        let angle = Double(i) * 90.0 * .pi / 180.0
        let x = Int16(centerX) + Int16(cos(angle) * Double(radius - 8))
        let y = Int16(centerY) + Int16(sin(angle) * Double(radius - 8))
        let speed = i * 25  // 改为 0, 25, 50, 75
        u8g2_DrawStr(u8g2, UInt16(x - 5), UInt16(y - 3), "\(speed)")
    }
    
    // 绘制指针
    let pointerAngle = Double(speed) * 2.7 * .pi / 180.0  // 调整角度范围
    let pointerX = Int16(centerX) + Int16(cos(pointerAngle) * Double(radius - 5))
    let pointerY = Int16(centerY) + Int16(sin(pointerAngle) * Double(radius - 5))
    u8g2_DrawLine(u8g2, centerX, centerY, UInt16(pointerX), UInt16(pointerY))
    
    // 绘制中心点
    u8g2_DrawDisc(u8g2, centerX, centerY, 2, 0xFF)
    
    // 绘制当前速度值（放在右边）
    u8g2_SetFont(u8g2, u8g2_font_7x14_tr)
    u8g2_DrawStr(u8g2, 70, 20, "\(speed)")
    u8g2_SetFont(u8g2, u8g2_font_6x10_tr)
    u8g2_DrawStr(u8g2, 70, 35, "km/h")
}

// 主程序
let device = SwiftSTLinkV3Bridge.Bridge()
device.enumDevices()
device.openDevice()

let i2cConfiguration = I2CConfiguration.fastPlus
device.initI2CDevice(configuration: i2cConfiguration)
let address = I2CAddress.address8BitWrite(0x78)

var u8g2Driver = SSD1306STLinkV3BridgeU8g2Driver(device: device, address: address)

u8g2Driver.withUnsafeU8g2 { u8g2 in
    u8g2_InitDisplay(u8g2)
    u8g2_SetPowerSave(u8g2, 0)
    
    // 动画循环
    while true {
        // 0 到 100
        for speed in 0...100 {
            u8g2_ClearBuffer(u8g2)
            drawSpeedGauge(u8g2: u8g2, speed: speed)
            u8g2_SendBuffer(u8g2)
            Thread.sleep(forTimeInterval: 0.016)
        }
        
        // 100 到 0
        for speed in (0...100).reversed() {
            u8g2_ClearBuffer(u8g2)
            drawSpeedGauge(u8g2: u8g2, speed: speed)
            u8g2_SendBuffer(u8g2)
            Thread.sleep(forTimeInterval: 0.016)
        }
    }
    
    print("速度仪表盘动画完成")
}

