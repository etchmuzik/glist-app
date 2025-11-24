# Repository Guidelines

## Project Structure & Module Organization
- App source lives in `Glist/` (SwiftUI views, managers, theming). Tests live in `GlistTests/` and `GlistUITests/`. Shared assets and entitlements are under `Glist/Assets*` and `Glist.entitlements`. Public docs (privacy/terms/support) sit in `docs/`.
- Primary scheme/targets: `Glist` (app), `GlistTests`, `GlistUITests`.

## Build, Test, and Development Commands
- Open and run in Xcode: `open Glist.xcodeproj`, select the **Glist** scheme, run on a simulator or device (camera features need a physical device).
- CLI build: `xcodebuild -scheme Glist -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16' build`.
- Unit/UI tests: `xcodebuild -scheme Glist -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16' test`.
- Firebase deps: ensure pods/SPM packages are resolved in Xcode before first build.

## Coding Style & Naming Conventions
- Swift/SwiftUI with 4-space indentation; prefer `struct` + `View` suffix for UI components (e.g., `CheckoutView`, `TableCard`). Use `Theme.Fonts` and `Color.theme` helpers for typography/colors to keep the look consistent.
- Favor immutable `let` where possible and `@State`/`@Binding` for UI state. Keep view bodies small; extract subviews when they exceed ~150 lines.
- Lint/format: use Xcode’s default Swift formatting; keep trailing whitespace out and align modifiers vertically for readability.

## Testing Guidelines
- Frameworks: `XCTest` (classic) and `Testing` (async-friendly). Add new tests in `GlistTests/` with filenames ending in `Tests.swift` and methods beginning with `test`.
- Aim for meaningful assertions around QR generation (`QRCodeGenerator`), booking flows, and any validation logic in managers. Add UI tests to `GlistUITests/` for navigation and scan flows when feasible.
- Run `xcodebuild ... test` before opening PRs; capture failing seeds or device/OS combos in the PR if applicable.

## Commit & Pull Request Guidelines
- Commit messages: keep a single concise summary in sentence/imperative style (recent history uses descriptive summaries like “Implement Guest List Rewards & Bans system”). Avoid multi-line bodies unless needed for context.
- PRs should include: what changed, why, screenshots for UI changes (simulator + device if camera/QR is involved), and test results/commands run. Link issues or tickets when available.
- Keep diffs focused; separate refactors from feature work where possible.

## Security & Configuration Tips
- Camera/QR features need a physical device and correct camera permissions; verify `NSCameraUsageDescription` remains meaningful.
- Protect Firebase/API keys—no secrets should appear in source. Use Xcode build settings or `.xcconfig` for environment-specific values.
