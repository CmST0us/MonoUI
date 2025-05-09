import SDL2
import MonoUI


class App {
    struct WindowConfig {
        static let Width = 128
        static let Height = 64
        static let Multiple = 3
    }

    var screen: UnsafeMutablePointer<SDL_Surface>!
    var window: OpaquePointer!

    lazy var blackColor: UInt32 = {
        return SDL_MapRGB(screen.pointee.format, 0, 0, 0)
    }()

    lazy var whiteColor: UInt32 = {
        return SDL_MapRGB(screen.pointee.format, 255, 255, 255)
    }()

    private func setupSDL() {
        guard SDL_Init(UInt32(SDL_INIT_VIDEO)) == 0 else {
            print("无法初始化SDL: \(String(cString: SDL_GetError()))")
            exit(1)
        }
        
        // 创建窗口
        window = SDL_CreateWindow(
            "MonoUI SDL Simulator",
            Int32(0),
            Int32(0),
            Int32(WindowConfig.Width * WindowConfig.Multiple),
            Int32(WindowConfig.Height * WindowConfig.Multiple),
            0
        )
        
        guard let window = window else {
            print("无法创建窗口: \(String(cString: SDL_GetError()))")
            exit(1)
        }
        
        // 获取窗口表面
        screen = SDL_GetWindowSurface(window)
        
        guard let _ = screen else {
            print("无法创建屏幕表面: \(String(cString: SDL_GetError()))")
            exit(1)
        }

        // 更新窗口表面
        SDL_UpdateWindowSurface(window)
        
        // 注册退出处理
        atexit {
            SDL_Quit()
        }
    }

    func setup() {
        setupSDL()
    }

    func handleEvents() {
        var event = SDL_Event()
        while SDL_PollEvent(&event) != 0 {
            switch event.type {
            case SDL_QUIT.rawValue:
                SDL_Quit()
                exit(0)
                
            case SDL_MOUSEBUTTONDOWN.rawValue:
                break
                
            default:
                break
            }
        }
    }

    func update() {
        // 用SDL 在 screen 中心绘制一个矩形
        var rect = SDL_Rect(x: 0, y: 0, w: 128, h: 64)
        let color = whiteColor
        SDL_FillRect(screen, &rect, color)

    }

    func render() {
        // 更新显示
        SDL_UpdateWindowSurface(window)
        
        // 控制帧率
        SDL_Delay(16) // 约60FPS
    }

    func run() {
        setup()
        while true {
            handleEvents()
            update()
            render()
        }
    }
}

@main
struct MonoUISDLSimulator {
    static func main() {
        let app = App()
        app.run()
    }
}
