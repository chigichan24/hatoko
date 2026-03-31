# Hatoko

<p align="center">
  <img src="Hatoko/Resources/Assets.xcassets/AppIcon.appiconset/icon_512x512@2x.png" alt="Hatoko" width="200">
</p>

> A macOS IME where keystrokes meet intelligence.

[![CI](https://github.com/chigichan24/hatoko/actions/workflows/ci.yml/badge.svg)](https://github.com/chigichan24/hatoko/actions/workflows/ci.yml)

[日本語](README.ja.md)

Hatoko is an Input Method Engine (IME) for macOS. It provides Japanese kana-kanji conversion along with LLM-assisted text input powered by Claude.

## Features

- **Japanese Input** — Kana-kanji conversion from romaji input
- **LLM-Assisted Input** — Switch to Claude-powered text generation with Ctrl+Space
  - Inline suggestion: Popup near cursor with thinking animation and generated candidates
  - Chat window: Iteratively refine text through conversation
- **Two LLM Backends** — Choose between Claude API (claude-sonnet-4-20250514) or Claude CLI
- **Liquid Glass UI** — Native macOS 26 glass morphism for suggestion and chat panels
- **Settings UI** — Manage API key and CLI path via GUI

## Requirements

- macOS 26.0+
- Xcode 26.0+
- Swift 6

## Setup

### Prerequisites

- [Mint](https://github.com/yonaskolb/Mint)

```bash
brew install mint
```

### Build & Install

```bash
# Install dependency tools via Mint
mint bootstrap

# Build & install (requires admin privileges)
./install.sh
```

After installation, select Hatoko from the input sources in the menu bar. If it doesn't appear, try logging out and back in.

## Usage

| Mode | Shortcut | Description |
|------|----------|-------------|
| Japanese Input | Default | Romaji input → kana-kanji conversion (Space to convert, Enter to commit) |
| LLM Assist | Ctrl+Space | Type a prompt → Enter to send to Claude → Enter to accept / Tab to open chat |

Open the settings via Ctrl+Click on the input source menu.

## Project Structure

```
Hatoko/
├── App/                    # Application entry point
├── InputMethod/            # IME controller & input mode management
├── LLM/                    # Claude API / CLI backends
├── Conversion/             # Kana-kanji conversion (AzooKeyKanaKanjiConverter)
├── UI/                     # SwiftUI settings, chat & suggestion UI
└── Utility/                # Keychain helper, etc.
```

## Acknowledgements

This project is built on top of the following open-source project.

### AzooKeyKanaKanjiConverter

Hatoko's kana-kanji conversion is powered by [AzooKeyKanaKanjiConverter](https://github.com/azooKey/AzooKeyKanaKanjiConverter). We are deeply grateful to the [azooKey](https://github.com/azooKey) project for publishing such a high-quality kana-kanji conversion engine as open-source software.

Without AzooKeyKanaKanjiConverter, it would have been extremely difficult for Hatoko to achieve kana-kanji conversion. It is an outstanding library in both accuracy and performance, and serves as an indispensable foundation for IME development.

- azooKey — MIT License, Copyright (c) 2020-2023 Keita Miwa (ensan)
- AzooKeyKanaKanjiConverter — MIT License, Copyright (c) 2023 Miwa / Ensan

## License

MIT License — See [LICENSE](LICENSE) for details.

For dependency licenses, see the Acknowledgements section above.
