import SDL2
import MonoUI

class SDLRenderBackend: RenderBackend {
    struct WindowConfig {
        static let Width = 128
        static let Height = 64
        static let Multiple = 1
    }
    
    private var screen: UnsafeMutablePointer<SDL_Surface>!
    private var window: OpaquePointer!
    private let blackColor: UInt32
    private let whiteColor: UInt32
    
    init() {
        guard SDL_Init(UInt32(SDL_INIT_VIDEO)) == 0 else {
            print("无法初始化SDL: \(String(cString: SDL_GetError()))")
            exit(1)
        }
        
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
        
        screen = SDL_GetWindowSurface(window)
        
        guard let _ = screen else {
            print("无法创建屏幕表面: \(String(cString: SDL_GetError()))")
            exit(1)
        }

        SDL_UpdateWindowSurface(window)
        
        atexit {
            SDL_Quit()
        }
        
        self.blackColor = SDL_MapRGB(screen.pointee.format, 0, 0, 0)
        self.whiteColor = SDL_MapRGB(screen.pointee.format, 255, 255, 255)
    }
    
    func update(buffer: [UInt8], width: Int, height: Int) {
        let pitch = screen.pointee.pitch
        let pixels = screen.pointee.pixels
        
        for y in 0..<height {
            for x in 0..<width {
                let bufferIndex = y * width + x
                let pixelIndex = y * Int(pitch) + x * 4
                
                let color = buffer[bufferIndex] == 0 ? blackColor : whiteColor
                pixels?.advanced(by: pixelIndex).assumingMemoryBound(to: UInt32.self).pointee = color
            }
        }
        
        SDL_UpdateWindowSurface(window)
    }
    
    func handleEvents() {
        var event = SDL_Event()
        while SDL_PollEvent(&event) != 0 {
            switch event.type {
            case SDL_QUIT.rawValue:
                SDL_Quit()
                exit(0)
            default:
                break
            }
        }
    }
    
    func delay() {
        SDL_Delay(16) // 约60FPS
    }
}

class App {
    var renderBackend: SDLRenderBackend!
    var uiScreen: MonoUI.Screen!
    
    func setup() {
        renderBackend = SDLRenderBackend()
        uiScreen = MonoUI.Screen(width: SDLRenderBackend.WindowConfig.Width, 
                               height: SDLRenderBackend.WindowConfig.Height, 
                               backend: renderBackend)
        
        // 创建多边形
        let polygonPath = Path()
        polygonPath.move(to: Point(x: 64, y: 10))  // 顶点
        polygonPath.addLine(to: Point(x: 20, y: 54))  // 左下角
        polygonPath.addLine(to: Point(x: 108, y: 54)) // 右下角
        polygonPath.addLine(to: Point(x: 43, y: 45))  // 顶点
        polygonPath.close()
        
        // 创建多边形图层
        let polygonLayer = ShapeLayer(path: polygonPath)
        polygonLayer.setFillColor(.none)
        polygonLayer.setStrokeColor(.white)
        
        // 创建一个圆弧路径
        let arcPath = Path()
        arcPath.addArc(center: Point(x: 100, y: 32),
                      radius: 20,
                      startAngle: 0,
                      endAngle: .pi / 2,
                      clockwise: false)
        
        // 创建圆弧图层
        let arcLayer = ShapeLayer(path: arcPath)
        arcLayer.setFillColor(.none)
        arcLayer.setStrokeColor(.white)
        arcLayer.setLineWidth(5)
        
        // 创建一个圆角矩形路径
        let roundedRectPath = Path()
        roundedRectPath.addRoundedRect(
            Rect(origin: Point(x: 15, y: 5), size: Size(width: 50, height: 50)),
            cornerRadius: 10)
        
        // 创建圆角矩形图层
        let roundedRectLayer = ShapeLayer(path: roundedRectPath)
        roundedRectLayer.setFillColor(.white)
        roundedRectLayer.setStrokeColor(.white)
        
        // 添加所有图层到表面
        uiScreen.surface.addLayer(polygonLayer)
        uiScreen.surface.addLayer(arcLayer)
        uiScreen.surface.addLayer(roundedRectLayer)
        
        // 渲染所有图层
        uiScreen.surface.render()
    }

    func update() {
        renderBackend.handleEvents()
    }

    func render() {
        uiScreen.update()
        renderBackend.delay()
    }

    func run() {
        setup()
        while true {
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
