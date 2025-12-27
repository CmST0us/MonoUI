import SDL2
import MonoUI
import CU8g2SDL
import U8g2Kit
import CU8g2
#if canImport(Glibc)
import Glibc
#elseif canImport(Darwin)
import Darwin
#endif

class SDL2Driver: Driver {
    init() {
        super.init(u8g2_SetupBuffer_SDL_128x64, &U8g2Kit.u8g2_cb_r0)
    }
}


class SDL2SimulatorApp: Application {

    let router = Router()

    override init(context: Context) {
        super.init(context: context)
    }
    
    override func setup() {
        // 设置根页面
        let homePage = HomePage()
        router.setRoot(homePage)
    }

    override func loop() {
        driver.withUnsafeU8g2 { u8g2 in
            u8g2_ClearBuffer(u8g2)
            u8g2_SetBitmapMode(u8g2, 1) // 开启透明模式
            u8g2_SetFontMode(u8g2, 1)

            // 绘制 Router (包含 Pages)
            router.draw(u8g2: u8g2)
            
            u8g2_SendBuffer(u8g2)
        }

        // 输入处理
        let key = u8g_sdl_get_key()
        if key != -1 {
            router.handleInput(key: key)
        }
    }
}

// @main
struct MonoUISDLSimulator {
    static func main() {
        let context = Context(driver: SDL2Driver())
        let app = SDL2SimulatorApp(context: context)
        app.run()
    }
}

// Top level code to run
MonoUISDLSimulator.main()
