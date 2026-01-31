# CLAUDE.md - MonoUI Framework

A lightweight UI framework for monochrome displays, designed for Embedded Swift on microcontrollers.

## Build Commands

```bash
# Test build for Embedded Swift
./build_embedded.sh

# macOS SDL Simulator (if available)
swift run MonoUISDLSimulator
```

## Project Structure

```
Sources/MonoUI/
├── Application.swift      # Base Application class
├── Context.swift          # Global context, animation management
├── Animation/
│   └── AnimationValue.swift  # @AnimationValue property wrapper
├── Core/
│   └── Types.swift        # Point, Size, Rect, etc.
├── Layout/
│   ├── View.swift         # Base View class
│   └── ScrollView.swift   # Scrollable container
├── Navigation/
│   ├── Page.swift         # Full-screen view base class
│   └── Router.swift       # Navigation stack management
└── Views/
    ├── ModalView.swift    # Modal dialog base class
    ├── ProgressView.swift # Value slider modal
    ├── ListView.swift     # Scrollable list
    ├── MenuView.swift     # Menu with items
    ├── TileMenuView.swift # Grid-based tile menu
    └── MenuItem.swift     # Menu item types
```

## Architecture

### Application Lifecycle

```swift
class MyApp: Application {
    override func setup() {
        // Initialize UI, set root page
        router.setRoot(HomePage())
    }

    override func loop() {
        // Called every frame
        // Handle input, update state
    }

    // For embedded platforms:
    override func getCurrentTime() -> Double { ... }
    override func sleepMicroseconds(_ us: UInt32) { ... }
}
```

### Page Navigation

```swift
// Router manages navigation stack
router.push(DetailPage())      // Push new page
router.pop()                   // Go back
router.replace(NewPage())      // Replace current
router.setRoot(HomePage())     // Reset stack

// Modal presentation
router.present(ProgressView(...))  // Show modal
router.dismissModal()              // Dismiss modal
```

### Page Lifecycle

```swift
class MyPage: Page {
    override func onEnter() { }      // Called when page becomes active
    override func onExit() { }       // Called when page is deactivated
    override func animateIn() { }    // Setup entrance animation
    override func animateOut() { }   // Setup exit animation

    override func handleInput(key: Int32) -> Bool {
        // Return true if input was handled
    }
}
```

### Animation System

The `@AnimationValue` property wrapper provides smooth interpolation:

```swift
class MyView: View {
    @AnimationValue var offsetY: Double = 0

    func slideUp() {
        offsetY = -100  // Will animate smoothly
    }
}

// Configure animation speed
_offsetY.speed = 25.0  // Lower = faster

// Set value immediately without animation
$offsetY.setCurrentValue(0)
```

**How it works:**
1. `AnimationValue` registers itself with `Context` on init
2. Each frame, `Context.updateAnimations()` calls `update()` on all values
3. Values interpolate toward target using exponential decay

### View Hierarchy

```
View (base class)
├── Page (full-screen view)
├── ScrollView (scrollable container)
├── ListView (vertical list)
├── MenuView (menu with items)
├── TileMenuView (grid menu)
└── ModalView (modal dialog base)
    └── ProgressView (value slider)
```

### Drawing

Views use U8g2 graphics library:

```swift
override func draw(u8g2: UnsafeMutablePointer<u8g2_t>?, origin: Point) {
    guard let u8g2 = u8g2 else { return }

    let absX = origin.x + frame.origin.x
    let absY = origin.y + frame.origin.y

    // Draw using U8g2 functions
    u8g2_SetDrawColor(u8g2, 1)
    u8g2_DrawBox(u8g2, u8g2_uint_t(absX), u8g2_uint_t(absY), 10, 10)
}
```

## Embedded Swift Constraints

### No Protocol Existential Types

The animation system originally used `[AnimationUpdateable]` protocol array, which doesn't work in Embedded Swift:

```swift
// BAD - protocol existential (won't compile in Embedded Swift)
protocol AnimationUpdateable { func update() }
private var animationValues: [AnimationUpdateable] = []

// GOOD - use base class instead
class AnimationUpdater { func update() {} }
private var animationValues: [AnimationUpdater] = []
```

**Current implementation uses `AnimationUpdateable` protocol**, which works when the array is `[any AnimationUpdateable]` or when using class constraint. If you encounter issues, convert to base class pattern.

### No `weak` References

Closures cannot use `[weak self]`:

```swift
// BAD
menuItem.onSelect = { [weak self] in self?.handle() }

// GOOD
menuItem.onSelect = { self.handle() }
```

### No Runtime Type Checking

Use polymorphism instead of `as?` or `is`:

```swift
// BAD
if let modal = view as? ModalView { modal.dismiss() }

// GOOD - use virtual method
class View {
    var canDismiss: Bool { false }
    func dismiss(completion: @escaping () -> Void) { completion() }
}
class ModalView: View {
    override var canDismiss: Bool { true }
    override func dismiss(completion: @escaping () -> Void) { ... }
}
```

## Common Patterns

### MenuItem with Modal

```swift
// Create menu item that shows a progress view
let brightnessItem = ValueMenuItem(
    icon: Icons.brightness,
    title: "Brightness",
    value: 50,
    onSelect: { [self] in
        let progressView = ProgressView(
            title: "Brightness",
            value: Double(brightnessItem.value),
            minimum: 0, maximum: 100, step: 5
        )
        progressView.onValueChanged = { newValue in
            brightnessItem.value = Int(newValue)
        }
        router.present(progressView)
    }
)
```

### ModalView Color Modes

```swift
// Normal: black background, white border
progressView.colorMode = .normal

// Inverse: white background, black border
progressView.colorMode = .inverse
```

Border visibility fix: use opposite color for border vs background:
```swift
u8g2_SetDrawColor(u8g2, colorMode.rawValue)  // Background
u8g2_DrawRBox(...)

let borderColor: UInt8 = colorMode == .normal ? 1 : 0  // Opposite color
u8g2_SetDrawColor(u8g2, borderColor)
u8g2_DrawRFrame(...)
```

## Conditional Compilation

Use `Embedded` trait for platform-specific code:

```swift
#if hasFeature(Embedded)
// Embedded Swift specific code
#else
// Desktop/simulator code
import Foundation
#endif
```

In Package.swift:
```swift
.target(
    name: "MonoUI",
    dependencies: [...],
    swiftSettings: [
        .enableExperimentalFeature("Embedded", .when(traits: ["Embedded"]))
    ]
)
```
