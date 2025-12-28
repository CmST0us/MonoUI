import U8g2Kit
import CU8g2
#if canImport(Glibc)
import Glibc
#elseif canImport(Darwin)
import Darwin
#endif

/// The base class for the application.
/// Manages the main run loop, frame rate, and context.
open class Application {

    private let context: Context
    private var frameRate: Double = 60.0
    private var lastFrameTime: Double = 0

    /// The shared singleton instance of the Application.
    /// Warning: This is implicitly unwrapped.
    public static var shared: Application!

    /// The display driver associated with the application context.
    public var driver: Driver {
        return context.driver
    }

    /// Initializes a new Application with the specified context.
    /// - Parameter context: The application context.
    public init(context: Context) {
        self.context = context
        Application.shared = self
    }

    /// Sets the target frame rate for the application.
    /// - Parameter rate: The target frames per second.
    public func setFrameRate(_ rate: Double) {
        frameRate = rate
    }

    /// Called once during initialization.
    /// Override this method to perform initial setup.
    open func setup() {
        
    }

    /// Called every frame.
    /// Override this method to perform per-frame logic (rendering, input handling).
    open func loop() {
        
    }

    /// Starts the application's main run loop.
    /// This method does not return.
    public func run() {
        context.setup()
        setup()
        
        lastFrameTime = getCurrentTime()
        
        while true {
            let currentTime = getCurrentTime()
            let deltaTime = currentTime - lastFrameTime
            
            if deltaTime >= 1.0 / frameRate {
                context.loop()
                loop()
                lastFrameTime = currentTime
            }
            
            // Calculate time to sleep to maintain frame rate
            let timeToNextFrame = (1.0 / frameRate) - (getCurrentTime() - lastFrameTime)
            if timeToNextFrame > 0 {
                sleepMicroseconds(UInt32(timeToNextFrame * 1_000_000))
            }
        }
    }
    
    // MARK: - Platform Methods (Override for Embedded Platforms)
    
    /// Sleeps for the specified number of microseconds.
    ///
    /// Override this method in subclasses to provide platform-specific sleep implementation.
    /// Default implementation uses `usleep` if available, otherwise busy-waits.
    ///
    /// - Parameter microseconds: The number of microseconds to sleep.
    open func sleepMicroseconds(_ microseconds: UInt32) {
        #if canImport(Glibc)
        usleep(microseconds)
        #elseif canImport(Darwin)
        usleep(microseconds)
        #else
        // Embedded Swift fallback: busy wait
        let startTime = getCurrentTime()
        let targetTime = startTime + Double(microseconds) / 1_000_000.0
        while getCurrentTime() < targetTime {
            // Busy wait - override this method for efficient platform-specific sleep
        }
        #endif
    }
    
    /// Gets the current monotonic time in seconds.
    ///
    /// Override this method in subclasses to provide platform-specific timing.
    /// Default implementation uses `clock_gettime` if available.
    ///
    /// - Returns: The current time in seconds since an arbitrary starting point.
    open func getCurrentTime() -> Double {
        #if canImport(Glibc) || canImport(Darwin)
        var ts = timespec()
        clock_gettime(CLOCK_MONOTONIC, &ts)
        return Double(ts.tv_sec) + Double(ts.tv_nsec) / 1_000_000_000.0
        #else
        // Embedded Swift: Subclasses must override this method
        fatalError("getCurrentTime() must be overridden in Embedded Swift platforms")
        #endif
    }

}
