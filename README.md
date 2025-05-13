# MonoUI

[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Linux-lightgrey.svg)]()

MonoUI is a lightweight, high-performance monochrome UI framework written in Swift. It's designed for embedded systems and displays that require efficient memory usage and fast rendering capabilities.

## Features

- 🎨 **Simple Color System**: Black, white, and transparent colors for monochrome displays
- 📐 **Vector Graphics**: Support for basic shapes, paths, and curves
- 🖌️ **Layer-based Rendering**: Efficient layer management for complex UIs
- ⚡ **High Performance**: Optimized for low-memory environments
- 🔌 **Backend Agnostic**: Easy to integrate with different display drivers
- 🛠️ **Extensible**: Simple to add new shapes and rendering features

## Requirements

- Swift 5.9+
- Linux

## Installation

### Swift Package Manager

Add MonoUI to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/CmST0us/MonoUI.git", branch: "main")
]
```

## Quick Start

```swift
import MonoUI

// Create a screen with SDL backend
let renderBackend = SDLRenderBackend()
let screen = Screen(width: 128, height: 64, backend: renderBackend)

// Create a circle
let circlePath = Path()
circlePath.addCircle(center: Point(x: 64, y: 32), radius: 20)

// Create a layer
let circleLayer = ShapeLayer(path: circlePath)
circleLayer.setFillColor(.white)
circleLayer.setStrokeColor(.black)

// Add layer to screen
screen.surface.addLayer(circleLayer)

// Render and update display
screen.surface.render()
screen.update()
```

## Examples

### Basic Shapes

```swift
// Rectangle
let rectPath = Path()
rectPath.addRoundedRect(Rect(origin: Point(x: 20, y: 20),
                            size: Size(width: 80, height: 40)),
                       cornerRadius: 10)

// Circle
let circlePath = Path()
circlePath.addCircle(center: Point(x: 64, y: 32), radius: 20)

// Arc
let arcPath = Path()
arcPath.addArc(center: Point(x: 64, y: 32),
               radius: 20,
               startAngle: 0,
               endAngle: .pi,
               clockwise: false)
```

### Custom Paths

```swift
let path = Path()
path.move(to: Point(x: 0, y: 0))
path.addLine(to: Point(x: 100, y: 0))
path.addQuadCurve(to: Point(x: 100, y: 100),
                 control: Point(x: 150, y: 50))
path.close()
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Inspired by various monochrome display libraries
- Thanks to all contributors who have helped shape this project 