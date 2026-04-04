# Contributing to Hatoko

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

## Project Structure

```
Hatoko/
├── App/                    # Application entry point
├── InputMethod/            # IME controller & input mode management
├── LLM/                    # LLM backends (Claude, OpenAI, Gemini)
├── Conversion/             # Kana-kanji conversion (AzooKeyKanaKanjiConverter)
├── UI/                     # SwiftUI settings, chat & suggestion UI
└── Utility/                # Keychain helper, etc.
```
