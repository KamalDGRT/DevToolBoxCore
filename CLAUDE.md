# CLAUDE.md

Shared Swift package used by DevToolBox (macOS app) and dev-toolbox-mcp. See [README.md](README.md).

## Rules
- Logic reused by app and MCP belongs here. Never duplicate it in a consumer.
- No UI imports (no SwiftUI/AppKit). Consumers wrap Core types for UI (e.g. `ColorInfo` in the app).
- Public API is semver-governed: any change to a public signature needs a version bump (see README).
- Named constants, no magic numbers. Every public function has a test in `Tests/DevToolBoxCoreTests`.
- Verify with `swift test` before committing.
- Trunk: `main`. No co-author trailers on commits.
