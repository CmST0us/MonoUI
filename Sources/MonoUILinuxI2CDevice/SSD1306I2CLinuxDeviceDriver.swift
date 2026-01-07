import MonoUI
import CU8g2
import U8g2Kit
#if canImport(Glibc)
import Glibc
#elseif canImport(Darwin)
import Darwin
#endif

// Linux I2C ioctl constant
#if canImport(Glibc)
private let I2C_SLAVE: UInt = 0x0703

// Direct ioctl call using @_silgen_name
@_silgen_name("ioctl")
private func ioctl(_ fd: Int32, _ request: UInt, _ argp: UnsafeMutableRawPointer?) -> Int32
#endif

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
    private var i2cFileDescriptor: Int32 = -1
    
    private var transferData: [UInt8] = []
    private var isTransferring = false
    
    /// Initializes a new Linux I2C device driver.
    /// - Parameters:
    ///   - i2cBus: The I2C bus number (e.g., 1 for /dev/i2c-1)
    ///   - address: The I2C device address (7-bit)
    init(i2cBus: Int32, address: I2CAddress) {
        self.i2cBus = i2cBus
        self.address = address
        super.init(u8g2_Setup_ssd1306_i2c_128x64_noname_f, &U8g2Kit.u8g2_cb_r0)
        
        // Open I2C device
        openI2CDevice()
    }
    
    deinit {
        closeI2CDevice()
    }
    
    private func openI2CDevice() {
        #if canImport(Glibc)
        let filename = "/dev/i2c-\(i2cBus)"
        filename.withCString { cString in
            i2cFileDescriptor = open(cString, O_RDWR)
        }
        
        guard i2cFileDescriptor >= 0 else {
            print("Failed to open I2C device /dev/i2c-\(i2cBus)")
            return
        }
        
        guard let addr = address.address7Bit else {
            print("Invalid I2C address")
            return
        }
        
        // Set I2C slave address using system call
        // ioctl(fd, I2C_SLAVE, addr) - we need to use a C wrapper or direct syscall
        // For now, we'll use a helper function
        let result = setI2CSlaveAddress(i2cFileDescriptor, UInt(addr))
        guard result >= 0 else {
            print("Failed to set I2C slave address")
            close(i2cFileDescriptor)
            i2cFileDescriptor = -1
            return
        }
        #endif
    }
    
    #if canImport(Glibc)
    // Helper function to call ioctl for I2C_SLAVE
    private func setI2CSlaveAddress(_ fd: Int32, _ addr: UInt) -> Int32 {
        var addrValue = addr
        return withUnsafePointer(to: &addrValue) { ptr in
            return ioctl(fd, I2C_SLAVE, UnsafeMutableRawPointer(mutating: ptr))
        }
    }
    #endif
    
    private func closeI2CDevice() {
        if i2cFileDescriptor >= 0 {
            close(i2cFileDescriptor)
            i2cFileDescriptor = -1
        }
    }
    
    private func writeI2C(data: [UInt8]) -> Bool {
        guard i2cFileDescriptor >= 0 else { return false }
        guard !data.isEmpty else { return true }
        
        #if canImport(Glibc)
        let result = data.withUnsafeBytes { bytes in
            write(i2cFileDescriptor, bytes.baseAddress, data.count)
        }
        return result == data.count
        #else
        return false
        #endif
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

