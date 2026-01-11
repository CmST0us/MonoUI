import MonoUI
import U8g2Kit
import CU8g2
#if canImport(Glibc)
import Glibc
#elseif canImport(Darwin)
import Darwin
#endif

// MARK: - Keyboard Input Handler

#if canImport(Glibc) || canImport(Darwin)
/// Handles non-blocking keyboard input on Linux/macOS
class KeyboardInputHandler {
    private var originalTermios: termios?
    private var originalFlags: Int32 = 0
    private var isTerminalConfigured = false
    
    init() {
        configureTerminal()
    }
    
    deinit {
        restoreTerminal()
    }
    
    /// Configures terminal for raw, non-blocking input
    private func configureTerminal() {
        var newTermios = termios()
        
        // Get current terminal settings
        guard tcgetattr(STDIN_FILENO, &newTermios) == 0 else {
            return
        }
        
        // Save original settings
        originalTermios = newTermios
        
        // Set raw mode: disable canonical mode and echo
        newTermios.c_lflag &= ~(UInt32(ICANON) | UInt32(ECHO))
        newTermios.c_cc.0 = 0  // VMIN: minimum number of characters
        newTermios.c_cc.1 = 0  // VTIME: timeout in deciseconds
        
        // Apply new settings
        guard tcsetattr(STDIN_FILENO, TCSANOW, &newTermios) == 0 else {
            return
        }
        
        // Get current file descriptor flags
        originalFlags = fcntl(STDIN_FILENO, F_GETFL, 0)
        
        // Set non-blocking mode
        let newFlags = originalFlags | O_NONBLOCK
        guard fcntl(STDIN_FILENO, F_SETFL, newFlags) == 0 else {
            return
        }
        
        isTerminalConfigured = true
    }
    
    /// Restores original terminal settings
    private func restoreTerminal() {
        if isTerminalConfigured {
            // Restore file descriptor flags
            _ = fcntl(STDIN_FILENO, F_SETFL, originalFlags)
            
            // Restore terminal attributes
            if let original = originalTermios {
                var termios = original
                _ = tcsetattr(STDIN_FILENO, TCSANOW, &termios)
            }
        }
    }
    
    /// Reads a key press non-blockingly
    /// - Returns: ASCII code of the pressed key, or -1 if no key was pressed
    func readKey() -> Int32 {
        guard isTerminalConfigured else { return -1 }
        
        var ch: UInt8 = 0
        let result = read(STDIN_FILENO, &ch, 1)
        
        if result == 1 {
            return Int32(ch)
        }
        
        // EAGAIN or EWOULDBLOCK means no data available (non-blocking)
        if errno == EAGAIN || errno == EWOULDBLOCK {
            return -1
        }
        
        return -1
    }
}
#endif

// MARK: - LinuxI2CApp

/// Application for Linux I2C device with SSD1306 display.
class LinuxI2CApp: Application {
    #if canImport(Glibc) || canImport(Darwin)
    private let keyboardHandler = KeyboardInputHandler()
    #endif
    
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
        
        // Handle keyboard input
        #if canImport(Glibc) || canImport(Darwin)
        let key = keyboardHandler.readKey()
        if key != -1 {
            router.handleInput(key: key)
        }
        #endif
    }
}

// MARK: - Main Entry Point

// Default I2C bus and address - adjust as needed
// Common SSD1306 I2C addresses: 0x3C (7-bit) or 0x3D (7-bit)
let i2cBus: Int32 = 8  // /dev/i2c-1 (adjust based on your system)
let i2cAddress = I2CAddress(address7Bit: 0x3C)  // Common SSD1306 address

let driver = LinuxI2CDeviceDriver(i2cBus: i2cBus, address: i2cAddress)
let screenSize = Size(width: 128, height: 64)
let context = Context(driver: driver, screenSize: screenSize)
let app = LinuxI2CApp(context: context)
app.run()
