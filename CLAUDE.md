# Hatoko - Project Guide

LLM-integrated IME for macOS. Provides kana-kanji conversion + Claude-powered text generation assist.

## Quick Reference

```bash
# Generate Xcode project
mint run xcodegen generate

# Build & install (requires sudo)
./install.sh

# Lint
mint run swiftlint lint --strict

# Test
xcodebuild -project Hatoko.xcodeproj -scheme Hatoko -destination 'platform=macOS' -skipMacroValidation test
```

## Architecture

```
Hatoko/
├── App/            # Entry point (main.swift, AppDelegate, HatokoApplication)
├── InputMethod/    # IMKInputController-based IME core
├── LLM/            # Claude API / CLI backends (protocol LLMService)
├── Conversion/     # AzooKeyKanaKanjiConverter wrapper
├── UI/             # SwiftUI (settings, inline suggestion, chat)
└── Utility/        # Keychain helper, etc.
```

### Input Modes

- **Japanese** (default): Romaji → kana-kanji conversion
- **Roman**: Direct input
- **LLM Prompt** (Ctrl+Space): Send prompt to Claude → inline suggestion or chat

### LLM Backends

Built around `protocol LLMService: Sendable`:
- `ClaudeService` — HTTP API (claude-sonnet-4-20250514)
- `CLIService` — Local `claude -p` command

`LLMBackend` enum acts as a factory via `createService()`.

## Coding Conventions

### Swift

- **Swift 6** / strict concurrency (`SWIFT_STRICT_CONCURRENCY: complete`)
- **Warnings as errors** (`SWIFT_TREAT_WARNINGS_AS_ERRORS: true`)
- File name = type name (e.g., `ClaudeService.swift` → `struct ClaudeService`)
- `@MainActor` on UI / window management classes
- `HatokoInputController` uses `@unchecked Sendable` — IMKInputController guarantees main-thread execution
- Async LLM calls start in `Task {}`, results applied via `MainActor.run {}`
- For passing IMKTextInput (non-Sendable) into Tasks: `nonisolated(unsafe) let capturedClient = client` pattern
- Force unwrap (`!`) is prohibited (enforced by SwiftLint)

### Testing

- Apple `Testing` framework (`@Suite`, `@Test`, `#expect`)
- UI layer tests are skipped
- Expose testable methods like `buildRequest()` for unit testing

### SwiftLint

Configured in `.swiftlint.yml`. Key limits:
- line_length: 150 (warning) / 200 (error)
- function_body_length: 50 (warning) / 80 (error)
- file_length: 600 (warning) / 800 (error)

### Commit Messages

```
<type>: <subject>

type: fix | feat | docs | chore | refactor
subject: imperative mood, lowercase, no period
```

## Build System

- **XcodeGen** (`project.yml`) generates `.xcodeproj` — `.xcodeproj` is gitignored
- **Mint** (`Mintfile`) manages build tools (XcodeGen, SwiftLint)
- External package: `AzooKeyKanaKanjiConverter` (SPM, branch: main)
- macOS 26.0+ / Xcode 26.0+

## IME-Specific Notes

- Bundle ID: `com.chigichan24.inputmethod.Hatoko`
- Install location: `/Library/Input Methods/`
- Sandbox disabled (required for IME operation)
- Hardened Runtime disabled
- `install.sh` handles TIS (Text Input Services) registration/deregistration via Carbon API
- To debug the IME: run `install.sh`, then switch input source
