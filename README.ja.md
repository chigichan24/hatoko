# Hatoko

<p align="center">
  <img src="Hatoko/Resources/Assets.xcassets/AppIcon.appiconset/icon_512x512@2x.png" alt="Hatoko" width="200">
</p>

> A macOS IME where keystrokes meet intelligence.

[![CI](https://github.com/chigichan24/hatoko/actions/workflows/ci.yml/badge.svg)](https://github.com/chigichan24/hatoko/actions/workflows/ci.yml)

[English](README.md)

Hatoko は macOS 向けの Input Method Engine (IME) です。日本語のかな漢字変換に加え、Claude を活用した LLM アシスト入力をサポートします。

## 特徴

- **日本語入力** — ローマ字入力からのかな漢字変換
- **LLM アシスト入力** — Ctrl+Space で Claude による文章生成モードに切り替え
  - インラインサジェスト: 思考アニメーション付きのポップアップでカーソル付近に候補を表示
  - チャットウィンドウ: 対話的に文章を推敲
- **2つの LLM バックエンド** — Claude API (claude-sonnet-4-20250514) または Claude CLI を選択可能
- **Liquid Glass UI** — macOS 26 ネイティブのガラスモーフィズムによるサジェスト・チャットパネル
- **設定画面** — API キー・CLI パスの設定を GUI で管理

## 動作環境

- macOS 26.0+
- Xcode 26.0+
- Swift 6

## セットアップ

### 必要なツール

- [Mint](https://github.com/yonaskolb/Mint)

```bash
brew install mint
```

### ビルド & インストール

```bash
# Mint で依存ツールをインストール
mint bootstrap

# ビルド & インストール (管理者権限が必要)
./install.sh
```

インストール後、メニューバーの入力ソースから Hatoko を選択してください。表示されない場合は一度ログアウト・ログインしてください。

## 使い方

| モード | 切り替え | 説明 |
|--------|----------|------|
| 日本語入力 | デフォルト | ローマ字入力 → かな漢字変換 (Space で変換、Enter で確定) |
| LLM アシスト | Ctrl+Space | プロンプトを入力 → Enter で Claude に送信 → Enter で確定 / Tab でチャットへ |

設定画面は入力ソースメニューの Ctrl+クリックから開けます。

## プロジェクト構成

```
Hatoko/
├── App/                    # アプリケーションエントリポイント
├── InputMethod/            # IME コントローラ・入力モード管理
├── LLM/                    # Claude API / CLI バックエンド
├── Conversion/             # かな漢字変換 (AzooKeyKanaKanjiConverter)
├── UI/                     # SwiftUI による設定・チャット・サジェスト UI
└── Utility/                # Keychain ヘルパーなど
```

## 謝辞

このプロジェクトは以下のオープンソースプロジェクトに大きく支えられています。

### AzooKeyKanaKanjiConverter

Hatoko のかな漢字変換は [AzooKeyKanaKanjiConverter](https://github.com/azooKey/AzooKeyKanaKanjiConverter) を利用しています。macOS / iOS 向けの高品質なかな漢字変換エンジンを OSS として公開してくださっている [azooKey](https://github.com/azooKey) プロジェクトに深く感謝します。

AzooKeyKanaKanjiConverter がなければ、Hatoko がかな漢字変換を実現することは極めて困難でした。変換精度・パフォーマンスの両面で非常に優れたライブラリであり、IME 開発の基盤として不可欠な存在です。

- azooKey — MIT License, Copyright (c) 2020-2023 Keita Miwa (ensan)
- AzooKeyKanaKanjiConverter — MIT License, Copyright (c) 2023 Miwa / Ensan

## ライセンス

MIT License — 詳細は [LICENSE](LICENSE) を参照してください。

依存ライブラリのライセンスについては上記「謝辞」セクションを参照してください。
