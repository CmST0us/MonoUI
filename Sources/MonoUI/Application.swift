import U8g2Kit
import CU8g2
import Glibc

open class Application {

    private let context: Context
    private var frameRate: Double = 60.0
    private var lastFrameTime: Double = 0

    public static var shared: Application!

    public var driver: Driver {
        return context.driver
    }

    public init(context: Context) {
        self.context = context
        Application.shared = self
    }

    public func setFrameRate(_ rate: Double) {
        frameRate = rate
    }

    open func setup() {
        
    }

    open func loop() {
        
    }

    public func run() {
        context.setup()
        setup()
        
        var ts = timespec()
        clock_gettime(CLOCK_MONOTONIC, &ts)
        lastFrameTime = Double(ts.tv_sec) + Double(ts.tv_nsec) / 1_000_000_000.0
        
        while true {
            clock_gettime(CLOCK_MONOTONIC, &ts)
            let currentTime = Double(ts.tv_sec) + Double(ts.tv_nsec) / 1_000_000_000.0
            let deltaTime = currentTime - lastFrameTime
            
            if deltaTime >= 1.0 / frameRate {
                context.loop()
                loop()
                lastFrameTime = currentTime
            }
            
            // 计算到下一帧的剩余时间并休眠
            let timeToNextFrame = (1.0 / frameRate) - (currentTime - lastFrameTime)
            if timeToNextFrame > 0 {
                usleep(UInt32(timeToNextFrame * 1_000_000))
            }
        }
    }

}