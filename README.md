# GuidanceMac

Islamic prayer times app for macOS — a lightweight menu bar app that shows daily prayer times based on your location.

![macOS](https://img.shields.io/badge/macOS-12%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![Build](https://github.com/batoulapps/GuidanceMac/actions/workflows/build.yml/badge.svg)

## Features

- Shows all five daily prayer times in the menu bar
- Automatic location detection
- Supports multiple calculation methods and madhabs
- Displays accurate Hijri (Islamic) date
- Lightweight — lives in your menu bar

## Requirements

- macOS 12.0 or later
- Xcode 15 or later (to build from source)

## Building

1. Clone the repo:
   ```bash
   git clone https://github.com/batoulapps/GuidanceMac.git
   cd GuidanceMac
   ```
2. Open `Guidance.xcodeproj` in Xcode — Swift Package Manager dependencies resolve automatically.
3. Build & Run (`⌘R`).

> **Note:** The app requires location access to calculate accurate prayer times for your area.

## Dependencies

- [adhan-swift](https://github.com/batoulapps/adhan-swift) — Prayer time calculation library
- [Then](https://github.com/devxoul/Then) — Syntactic sugar for Swift initializers

## Contributing

Pull requests are welcome! Please open an issue first to discuss major changes.

## License

See [LICENSE](LICENSE).
