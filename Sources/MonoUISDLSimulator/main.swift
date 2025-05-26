import SDL2
import MonoUI
import CU8g2SDL
import U8g2Kit
import CU8g2
import Glibc

class SDL2Driver: Driver {
    init() {
        super.init(u8g2_SetupBuffer_SDL_128x64, &U8g2Kit.u8g2_cb_r0)
    }
}


class SDL2SimulatorApp: Application {

    @AnimationValue var x: Double = 0
    @AnimationValue var y: Double = 0

    override func setup() {
        
    }

    override func loop() {
        driver.withUnsafeU8g2 { u8g2 in
            u8g2_ClearBuffer(u8g2)
            u8g2_DrawRBox(u8g2, u8g2_uint_t(x), u8g2_uint_t(y), 30, 30, 4)
        }

        driver.withUnsafeU8g2 { u8g2 in
            u8g2_SendBuffer(u8g2)
        }

        var key: Int32 = -1
        key = u8g_sdl_get_key()
        if key == 119 {
            x = 85
        }
        if key == 113 {
            x = 0
        }


    }
}

@main
struct MonoUISDLSimulator {
    static func main() {
        let context = Context(driver: SDL2Driver())
        let app = SDL2SimulatorApp(context: context)
        app.run()
    }
}
