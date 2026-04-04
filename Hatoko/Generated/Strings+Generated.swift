// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
  internal enum Backend {
    internal enum ClaudeAPI {
      /// Anthropic API経由。API Keyが必要
      internal static let description = L10n.tr("Localizable", "backend.claudeAPI.description", fallback: "Anthropic API経由。API Keyが必要")
      /// Claude API
      internal static let name = L10n.tr("Localizable", "backend.claudeAPI.name", fallback: "Claude API")
    }
    internal enum ClaudeCLI {
      /// ローカルのClaude CLIを使用。API Key不要
      internal static let description = L10n.tr("Localizable", "backend.claudeCLI.description", fallback: "ローカルのClaude CLIを使用。API Key不要")
      /// Claude CLI (claude -p)
      internal static let name = L10n.tr("Localizable", "backend.claudeCLI.name", fallback: "Claude CLI (claude -p)")
    }
    internal enum Disabled {
      /// LLM機能を使用しません
      internal static let description = L10n.tr("Localizable", "backend.disabled.description", fallback: "LLM機能を使用しません")
      /// 無効 (Disabled)
      internal static let name = L10n.tr("Localizable", "backend.disabled.name", fallback: "無効 (Disabled)")
    }
    internal enum GeminiAPI {
      /// Google Gemini API経由。API Keyが必要
      internal static let description = L10n.tr("Localizable", "backend.geminiAPI.description", fallback: "Google Gemini API経由。API Keyが必要")
      /// Gemini API
      internal static let name = L10n.tr("Localizable", "backend.geminiAPI.name", fallback: "Gemini API")
    }
    internal enum GeminiCLI {
      /// gemini CLIを使用（Experimental）。gemini-cliが必要
      internal static let description = L10n.tr("Localizable", "backend.geminiCLI.description", fallback: "gemini CLIを使用（Experimental）。gemini-cliが必要")
      /// Gemini CLI (Experimental)
      internal static let name = L10n.tr("Localizable", "backend.geminiCLI.name", fallback: "Gemini CLI (Experimental)")
    }
    internal enum OpenaiAPI {
      /// OpenAI API経由。API Keyが必要
      internal static let description = L10n.tr("Localizable", "backend.openaiAPI.description", fallback: "OpenAI API経由。API Keyが必要")
      /// OpenAI API
      internal static let name = L10n.tr("Localizable", "backend.openaiAPI.name", fallback: "OpenAI API")
    }
    internal enum OpenaiCLI {
      /// openai CLIを使用（Experimental）。Pythonパッケージが必要
      internal static let description = L10n.tr("Localizable", "backend.openaiCLI.description", fallback: "openai CLIを使用（Experimental）。Pythonパッケージが必要")
      /// OpenAI CLI (Experimental)
      internal static let name = L10n.tr("Localizable", "backend.openaiCLI.name", fallback: "OpenAI CLI (Experimental)")
    }
  }
  internal enum Chat {
    /// Escapeキーでウィンドウを閉じる
    internal static let closeAccessibility = L10n.tr("Localizable", "chat.closeAccessibility", fallback: "Escapeキーでウィンドウを閉じる")
    /// Esc で閉じる
    internal static let closeHint = L10n.tr("Localizable", "chat.closeHint", fallback: "Esc で閉じる")
    /// コンテキスト: %@
    internal static func contextAccessibility(_ p1: Any) -> String {
      return L10n.tr("Localizable", "chat.contextAccessibility", String(describing: p1), fallback: "コンテキスト: %@")
    }
    /// Hatoko アシスト
    internal static let header = L10n.tr("Localizable", "chat.header", fallback: "Hatoko アシスト")
    /// 追加の指示を入力
    internal static let inputAccessibility = L10n.tr("Localizable", "chat.inputAccessibility", fallback: "追加の指示を入力")
    /// 追加の指示...
    internal static let inputPlaceholder = L10n.tr("Localizable", "chat.inputPlaceholder", fallback: "追加の指示...")
    /// Hatokoが考えています
    internal static let thinkingAccessibility = L10n.tr("Localizable", "chat.thinkingAccessibility", fallback: "Hatokoが考えています")
    /// これを使う ⌘C
    internal static let useButton = L10n.tr("Localizable", "chat.useButton", fallback: "これを使う ⌘C")
    /// このテキストを入力欄に挿入し、クリップボードにもコピーします
    internal static let useButtonAccessibility = L10n.tr("Localizable", "chat.useButtonAccessibility", fallback: "このテキストを入力欄に挿入し、クリップボードにもコピーします")
    /// あなた
    internal static let userRole = L10n.tr("Localizable", "chat.userRole", fallback: "あなた")
  }
  internal enum Error {
    /// 設定エラー: バックエンドの構成を確認してください。
    internal static let config = L10n.tr("Localizable", "error.config", fallback: "設定エラー: バックエンドの構成を確認してください。")
    /// エラーが発生しました。もう一度お試しください。
    internal static let generic = L10n.tr("Localizable", "error.generic", fallback: "エラーが発生しました。もう一度お試しください。")
    /// リクエストが多すぎます。少し待ってからお試しください。
    internal static let rateLimit = L10n.tr("Localizable", "error.rateLimit", fallback: "リクエストが多すぎます。少し待ってからお試しください。")
    /// メッセージが長すぎます。短くしてください。
    internal static let tooLong = L10n.tr("Localizable", "error.tooLong", fallback: "メッセージが長すぎます。短くしてください。")
  }
  internal enum Inline {
    /// コンテキスト付き
    internal static let contextAccessibility = L10n.tr("Localizable", "inline.contextAccessibility", fallback: "コンテキスト付き")
    /// %@キーで%@
    internal static func keyAction(_ p1: Any, _ p2: Any) -> String {
      return L10n.tr("Localizable", "inline.keyAction", String(describing: p1), String(describing: p2), fallback: "%@キーで%@")
    }
    internal enum Action {
      /// キャンセル
      internal static let cancel = L10n.tr("Localizable", "inline.action.cancel", fallback: "キャンセル")
      /// チャットで調整
      internal static let chat = L10n.tr("Localizable", "inline.action.chat", fallback: "チャットで調整")
      /// 確定
      internal static let confirm = L10n.tr("Localizable", "inline.action.confirm", fallback: "確定")
    }
  }
  internal enum Settings {
    internal enum Backend {
      /// API Key
      internal static let apiKey = L10n.tr("Localizable", "settings.backend.apiKey", fallback: "API Key")
      /// %@ API キー
      internal static func apiKeyAccessibility(_ p1: Any) -> String {
        return L10n.tr("Localizable", "settings.backend.apiKeyAccessibility", String(describing: p1), fallback: "%@ API キー")
      }
      /// %@ パス
      internal static func pathAccessibility(_ p1: Any) -> String {
        return L10n.tr("Localizable", "settings.backend.pathAccessibility", String(describing: p1), fallback: "%@ パス")
      }
      /// パス
      internal static let pathLabel = L10n.tr("Localizable", "settings.backend.pathLabel", fallback: "パス")
      /// 自動検出
      internal static let pathPlaceholder = L10n.tr("Localizable", "settings.backend.pathPlaceholder", fallback: "自動検出")
      /// 保存
      internal static let save = L10n.tr("Localizable", "settings.backend.save", fallback: "保存")
      /// 保存しました
      internal static let saved = L10n.tr("Localizable", "settings.backend.saved", fallback: "保存しました")
      internal enum Disabled {
        /// LLM機能は無効です。Ctrl+Spaceは動作しません。
        internal static let description = L10n.tr("Localizable", "settings.backend.disabled.description", fallback: "LLM機能は無効です。Ctrl+Spaceは動作しません。")
        /// LLM 無効
        internal static let title = L10n.tr("Localizable", "settings.backend.disabled.title", fallback: "LLM 無効")
      }
    }
    internal enum Keybinding {
      /// Ctrl + Space: LLMアシストモード
      internal static let llmAssist = L10n.tr("Localizable", "settings.keybinding.llmAssist", fallback: "Ctrl + Space: LLMアシストモード")
      /// Ctrl + Space (LLM入力中): 日本語/英語切替
      internal static let toggleLanguage = L10n.tr("Localizable", "settings.keybinding.toggleLanguage", fallback: "Ctrl + Space (LLM入力中): 日本語/英語切替")
    }
    internal enum Picker {
      /// バックエンド
      internal static let backend = L10n.tr("Localizable", "settings.picker.backend", fallback: "バックエンド")
    }
    internal enum SectionHeader {
      /// キーバインド
      internal static let keybinding = L10n.tr("Localizable", "settings.sectionHeader.keybinding", fallback: "キーバインド")
      /// LLM バックエンド
      internal static let llmBackend = L10n.tr("Localizable", "settings.sectionHeader.llmBackend", fallback: "LLM バックエンド")
    }
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg..., fallback value: String) -> String {
    let format = BundleToken.bundle.localizedString(forKey: key, value: value, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
