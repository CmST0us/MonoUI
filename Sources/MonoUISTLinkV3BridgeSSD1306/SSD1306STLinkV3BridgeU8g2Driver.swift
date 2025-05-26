import MonoUI
import CU8g2
import U8g2Kit
import SwiftSTLinkV3Bridge

class SSD1306STLinkV3BridgeU8g2Driver: U8g2Kit.Driver {
    private let device: SwiftSTLinkV3Bridge.Bridge
    private let address: I2CAddress

    private var transferData: [UInt8] = []

    private var isTransferring = false

    init(device: SwiftSTLinkV3Bridge.Bridge, address: I2CAddress) {
        self.device = device
        self.address = address
        super.init(u8g2_Setup_ssd1306_i2c_128x64_noname_f, &U8g2Kit.u8g2_cb_r0)
    }


    override func onByte(msg: UInt8, arg_int: UInt8, arg_ptr: UnsafeMutableRawPointer?) -> UInt8 {
        switch Int32(msg) {
        case U8X8_MSG_BYTE_SEND:
            guard let dataPtr = arg_ptr?.assumingMemoryBound(to: UInt8.self) else { return 0 }
            var count = Int(arg_int)
            var src = dataPtr
            while count > 0 {
                transferData.append(src.pointee)
                src = src.advanced(by: 1)
                count -= 1
            }

            if !isTransferring {
                device.writeI2C(addr: UInt16(address.address7Bit!), data: transferData)
            }
            return 1

        case U8X8_MSG_BYTE_START_TRANSFER:
            transferData = []
            isTransferring = true
            return 1

        case U8X8_MSG_BYTE_END_TRANSFER:
            device.writeI2C(addr: UInt16(address.address7Bit!), data: transferData)
            isTransferring = false
            return 1

        default:
            return 1
        }
    }

    override func onGpioAndDelay(msg: UInt8, arg_int: UInt8, arg_ptr: UnsafeMutableRawPointer?) -> UInt8 {
        return 1
    }
    
}
