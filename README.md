# DevToolBoxCore

Pure-Swift logic shared by the [DevToolBox](https://github.com/KamalDGRT/DevToolBox) macOS app and
[dev-toolbox-mcp](https://github.com/KamalDGRT/dev-toolbox-mcp). No UI, no SwiftUI. If logic is needed by
both, it lives here.

## Contents

| Type | Purpose |
|---|---|
| `SRGBColor` | sRGB color (0...1). Parses `#RGB`/`#RGBA`/`#RRGGBB`/`#RRGGBBAA`, validated byte init, `hexString`, `rgbString`, `flattenedOnWhite`. |
| `ColorDistance` | CIE76 ΔE between two `SRGBColor`s. |
| `ColorAsset` | One `.colorset` (name, folder, catalog, color). |
| `ColorAssetCatalog` | Loads every `.colorset` under an `.xcassets` directory. Prefers the universal (non-dark) entry. |
| `NearestColorFinder` | Ranks assets by ΔE to a target color. |

## Install

Swift Package Manager:

```swift
.package(url: "https://github.com/KamalDGRT/DevToolBoxCore.git", from: "0.2.0")
// target dependency:
.product(name: "DevToolBoxCore", package: "DevToolBoxCore")
```

Requires macOS 13+, Swift 6 toolchain.

## Develop

```bash
swift build
swift test
```

Working on Core together with a consumer? Point the consumer at a local checkout instead of the tag
(`.package(path: "../DevToolBoxCore")` in SwiftPM, or drag the folder into the Xcode project to override
the remote reference). Switch back before committing.

## Versioning

[Semantic Versioning](https://semver.org), tagged `vX.Y.Z` on `main`. Pre-1.0: minor bump = new or changed
API, patch = fixes. Consumers pin `from: "X.Y.Z"`.

Release: land on `main`, then `git tag vX.Y.Z && git push origin main --tags`, then bump the `from:` in
consumers.

| Version | Notes |
|---|---|
| 0.2.0 | `SRGBColor` shorthand/alpha hex, validated byte init (now failable), `rgbString`, `flattenedOnWhite`, `Hashable`; `ColorAsset.displayFolderPath`. |
| 0.1.0 | Color math, xcassets catalog parsing, nearest-color search. |
