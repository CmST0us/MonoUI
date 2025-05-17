import Foundation
import SwiftSTLinkV3Bridge
import MonoUI

class STLinkSSD1306RenderBackend: RenderBackend {
    private let device: SwiftSTLinkV3Bridge.Bridge
    private let address: I2CAddress
    private let width: Int = 128
    private let height: Int = 64
    private var buffer: [UInt8]
    
    init(device: SwiftSTLinkV3Bridge.Bridge, address: I2CAddress) {
        self.device = device
        self.address = address
        self.buffer = Array(repeating: 0, count: width * height)
        
        // 初始化 SSD1306
        initializeSSD1306()
    }
    
    private func initializeSSD1306() {
        // SSD1306 初始化命令序列
        let commands: [UInt8] = [
            0xAE,       // 关闭显示
            0xD5, 0x80, // 设置显示时钟分频比/振荡器频率
            0xA8, 0x3F, // 设置多路复用率
            0xD3, 0x00, // 设置显示偏移
            0x40,       // 设置显示起始行
            0x8D, 0x14, // 启用充电泵
            0x20, 0x02, // 设置内存寻址模式为页寻址
            0xA1,       // 设置段重定向 0xA0/0xA1
            0xC8,       // 设置COM扫描方向 0xC0/0xC8
            0xDA, 0x12, // 设置COM硬件配置
            0x81, 0xCF, // 设置对比度
            0xD9, 0xF1, // 设置预充电周期
            0xDB, 0x30, // 设置VCOMH取消选择级别
            0xA4,       // 全局显示开启
            0xA6,       // 设置正常显示
            0xAF        // 开启显示
        ]
        
        // 发送初始化命令
        for command in commands {
            device.writeI2C(addr: UInt16(address.address7Bit!), data: [0x00, command])
        }
    }
    
    func update(buffer: [UInt8], width: Int, height: Int) {
        // 将一维缓冲区转换为SSD1306的页面格式
        var pageBuffer = [UInt8](repeating: 0, count: 1024) // 128 * 8 = 1024
        
        for y in 0..<8 { // 8页
            for x in 0..<128 { // 128列
                var byte: UInt8 = 0
                for bit in 0..<8 { // 每页8位
                    let pixelY = y * 8 + bit
                    if pixelY < height {
                        let index = pixelY * width + x
                        if index < buffer.count && buffer[index] == 1 {
                            byte |= (1 << bit)
                        }
                    }
                }
                pageBuffer[y * 128 + x] = byte
            }
        }
        
        // 发送数据到SSD1306
        for page in 0..<8 {
            // 设置页面地址
            device.writeI2C(addr: UInt16(address.address7Bit!), data: [0x00, 0xB0 | UInt8(page)])
            // 设置列地址
            device.writeI2C(addr: UInt16(address.address7Bit!), data: [0x00, 0x00]) // 低列地址
            device.writeI2C(addr: UInt16(address.address7Bit!), data: [0x00, 0x10]) // 高列地址
            
            // 发送页面数据
            let pageData = Array(pageBuffer[page * 128..<(page + 1) * 128])
            device.writeI2C(addr: UInt16(address.address7Bit!), data: [0x40] + pageData)
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

// 创建渲染后端和屏幕
let renderBackend = STLinkSSD1306RenderBackend(device: device, address: address)
let uiScreen = Screen(width: 128, height: 64, backend: renderBackend)

// 创建仪表盘背景
let dialPath = Path()
dialPath.addArc(center: Point(x: 64, y: 64),
                radius: 50,
                startAngle: .pi * 0.75,
                endAngle: .pi * 2.25,
                clockwise: false)

// 创建刻度线
func createTickMarks() -> [ShapeLayer] {
    var tickLayers: [ShapeLayer] = []
    let center = Point(x: 64, y: 64)
    let outerRadius: Double = 50
    let innerRadius: Double = 45
    
    // 创建主刻度线
    for i in 0...8 {
        let angle = .pi * 0.75 + (.pi * 1.5 * Double(i) / 8.0)
        let tickPath = Path()
        let startPoint = Point(
            x: center.x + cos(angle) * innerRadius,
            y: center.y + sin(angle) * innerRadius
        )
        let endPoint = Point(
            x: center.x + cos(angle) * outerRadius,
            y: center.y + sin(angle) * outerRadius
        )
        tickPath.move(to: startPoint)
        tickPath.addLine(to: endPoint)
        
        let tickLayer = ShapeLayer(path: tickPath)
        tickLayer.setStrokeColor(.white)
        tickLayers.append(tickLayer)
    }
    
    return tickLayers
}

// 创建指针
func createNeedle(angle: Double) -> ShapeLayer {
    let needlePath = Path()
    let center = Point(x: 64, y: 64)
    let length: Double = 45
    
    needlePath.move(to: center)
    needlePath.addLine(to: Point(
        x: center.x + cos(angle) * length,
        y: center.y + sin(angle) * length
    ))
    
    let needleLayer = ShapeLayer(path: needlePath)
    needleLayer.setStrokeColor(.white)
    needleLayer.setLineWidth(2)
    return needleLayer
}

// 创建仪表盘图层
let dialLayer = ShapeLayer(path: dialPath)
dialLayer.setFillColor(.none)
dialLayer.setStrokeColor(.white)

// 添加刻度线
let tickLayers = createTickMarks()

// 添加所有图层到表面
uiScreen.surface.addLayer(dialLayer)
for tickLayer in tickLayers {
    uiScreen.surface.addLayer(tickLayer)
}

// 动画循环
var angle: Double = .pi * 0.75
let speed: Double = 0.05 // 旋转速度
var currentNeedle: ShapeLayer? = nil

while true {
    // 移除旧的指针
    if let oldNeedle = currentNeedle {
        uiScreen.surface.removeLayer(oldNeedle)
    }
    
    // 创建新的指针
    let needleLayer = createNeedle(angle: angle)
    uiScreen.surface.addLayer(needleLayer)
    currentNeedle = needleLayer
    
    // 更新角度
    angle += speed
    if angle > .pi * 2.25 {
        angle = .pi * 0.75
    }
    
    // 渲染和更新显示
    uiScreen.surface.render()
    uiScreen.update()
    
    // 控制动画速度
    Thread.sleep(forTimeInterval: 0.016)
}