import Foundation
import MonoUI
import CU8g2
import U8g2Kit
import PeripheryKit

/// I2C address wrapper for 7-bit addresses
public struct I2CAddress {
    public let address7Bit: UInt8?
    
    public init(address7Bit: UInt8) {
        self.address7Bit = address7Bit
    }
}

class LinuxI2CDeviceDriver: U8g2Kit.Driver {
    private let i2cBus: Int32
    private let address: I2CAddress
    private let i2c: I2C
    
    private var transferData: [UInt8] = []
    private var isTransferring = false
    
    /// Initializes a new Linux I2C device driver.
    /// - Parameters:
    ///   - i2cBus: The I2C bus number (e.g., 1 for /dev/i2c-1)
    ///   - address: The I2C device address (7-bit)
    init(i2cBus: Int32, address: I2CAddress) {
        self.i2cBus = i2cBus
        self.address = address
        
        // Initialize PeripheryKit I2C
        let i2cPath = "/dev/i2c-\(i2cBus)"
        self.i2c = I2C(chip: .i2c(i2cPath))
        
        super.init(u8g2_Setup_ssd1306_i2c_128x64_noname_f, &U8g2Kit.u8g2_cb_r0)
        
        // Open I2C device
        openI2CDevice()
    }
    
    deinit {
        closeI2CDevice()
    }
    
    private func openI2CDevice() {
        guard i2c.open() else {
            print("Failed to open I2C device /dev/i2c-\(i2cBus)")
            return
        }
    }
    
    private func closeI2CDevice() {
        _ = i2c.close()
    }
    
    private func writeI2C(data: [UInt8]) -> Bool {
        guard !data.isEmpty else { return true }
        guard let addr = address.address7Bit else {
            print("Invalid I2C address")
            return false
        }
        
        // Convert 7-bit address to UInt16 for PeripheryKit
        let i2cAddress = UInt16(addr)
        
        // Create I2C request with data
        let request = I2C.Request(
            address: i2cAddress,
            flags: .NONE,
            data: Data(data)
        )
        
        // Transfer data
        let responses = i2c.tranfer(requests: [request])
        return !responses.isEmpty
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
            
            // If not in transfer mode, write immediately (for compatibility)
            if !isTransferring {
                _ = writeI2C(data: transferData)
                transferData.removeAll()
            }
            return 1
            
        case U8X8_MSG_BYTE_START_TRANSFER:
            transferData = []
            isTransferring = true
            return 1
            
        case U8X8_MSG_BYTE_END_TRANSFER:
            _ = writeI2C(data: transferData)
            transferData.removeAll()
            isTransferring = false
            return 1
            
        default:
            return 1
        }
    }
    
    override func onGpioAndDelay(msg: UInt8, arg_int: UInt8, arg_ptr: UnsafeMutableRawPointer?) -> UInt8 {
        // Handle delay if needed
        // For now, just return success
        return 1
    }
}

