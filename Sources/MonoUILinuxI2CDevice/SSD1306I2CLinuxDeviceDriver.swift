import Foundation
import MonoUI
import CU8g2
import U8g2Kit
import PeripheryKit
#if canImport(Glibc)
import Glibc
#endif

/// I2C address wrapper for 7-bit addresses
public struct I2CAddress {
    public let address7Bit: UInt8?
    
    public init(address7Bit: UInt8) {
        self.address7Bit = address7Bit
    }
}

/// Result of I2C device scan
public struct I2CDeviceScanResult {
    public let bus: Int32
    public let address: UInt8
    
    public init(bus: Int32, address: UInt8) {
        self.bus = bus
        self.address = address
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
    
    // MARK: - Static I2C Scan Methods
    
    /// Scans all available I2C buses for SSD1306 devices.
    /// - Returns: Array of scan results containing bus number and address, or empty array if none found
    public static func scanForSSD1306() -> [I2CDeviceScanResult] {
        var results: [I2CDeviceScanResult] = []
        
        // Common SSD1306 I2C addresses (7-bit)
        let ssd1306Addresses: [UInt8] = [0x3C, 0x3D]
        
        // Scan I2C buses from 0 to 10 (common range)
        for busNum in 0..<10 {
            let i2cPath = "/dev/i2c-\(busNum)"
            
            // Check if device exists
            #if canImport(Glibc)
            guard access(i2cPath, F_OK) == 0 else {
                continue
            }
            #endif
            
            // Try to scan this bus
            for address in ssd1306Addresses {
                if detectDeviceOnBus(bus: Int32(busNum), address: address) {
                    results.append(I2CDeviceScanResult(bus: Int32(busNum), address: address))
                    print("Found SSD1306 on /dev/i2c-\(busNum) at address 0x\(String(address, radix: 16, uppercase: true))")
                }
            }
        }
        
        return results
    }
    
    /// Detects if a device exists at the given address on the specified bus.
    /// - Parameters:
    ///   - bus: The I2C bus number
    ///   - address: The 7-bit I2C address to check
    /// - Returns: True if device responds, false otherwise
    private static func detectDeviceOnBus(bus: Int32, address: UInt8) -> Bool {
        let i2cPath = "/dev/i2c-\(bus)"
        let i2c = I2C(chip: .i2c(i2cPath))
        
        guard i2c.open() else {
            return false
        }
        
        defer {
            _ = i2c.close()
        }
        
        // Try to write a control byte to detect device
        // SSD1306 uses a control byte (0x00 for command, 0x40 for data)
        // We'll try to send a simple command to see if device ACKs
        let i2cAddress = UInt16(address)
        
        // Try sending a simple write (control byte 0x00 followed by a command)
        // This is a safe command that won't harm the display
        let testData = Data([0x00, 0xAE]) // Display OFF command (safe)
        let request = I2C.Request(
            address: i2cAddress,
            flags: .NONE,
            data: testData
        )
        
        let responses = i2c.tranfer(requests: [request])
        
        // If transfer succeeds (no error), device is present
        return !responses.isEmpty
    }
    
    /// Creates a driver instance by automatically scanning for SSD1306.
    /// - Returns: A driver instance if SSD1306 is found, nil otherwise
    public static func createByScanning() -> LinuxI2CDeviceDriver? {
        let results = scanForSSD1306()
        
        guard let firstResult = results.first else {
            print("No SSD1306 device found on any I2C bus")
            return nil
        }
        
        print("Using SSD1306 on /dev/i2c-\(firstResult.bus) at address 0x\(String(firstResult.address, radix: 16, uppercase: true))")
        
        let address = I2CAddress(address7Bit: firstResult.address)
        return LinuxI2CDeviceDriver(i2cBus: firstResult.bus, address: address)
    }
}

