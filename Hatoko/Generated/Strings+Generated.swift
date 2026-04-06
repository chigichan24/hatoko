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
    internal enum FoundationModels {
      /// Apple Intelligenceのオンデバイスモデルを使用。macOS 26+
      internal static let description = L10n.tr("Localizable", "backend.foundationModels.description", fallback: "Apple Intelligenceのオンデバイスモデルを使用。macOS 26+")
      /// Foundation Models (Apple Intelligence)
      internal static let name = L10n.tr("Localizable", "backend.foundationModels.name", fallback: "Foundation Models (Apple Intelligence)")
      /// Apple Intelligenceに関する注意: オンデバイスのFoundation Modelsバックエンドは完全にデバイス上で動作し、APIキーは不要ですが、IMEとしての利用におけるモデルの品質には顕著な制限があります。クラウドベースのLLMと比較して、回答のニュアンスや文脈の正確さが不足する場合があります。品質よりもプライバシーを優先する場合の選択肢として検討してください。
      internal static let note = L10n.tr("Localizable", "backend.foundationModels.note", fallback: "Apple Intelligenceに関する注意: オンデバイスのFoundation Modelsバックエンドは完全にデバイス上で動作し、APIキーは不要ですが、IMEとしての利用におけるモデルの品質には顕著な制限があります。クラウドベースのLLMと比較して、回答のニュアンスや文脈の正確さが不足する場合があります。品質よりもプライバシーを優先する場合の選択肢として検討してください。")
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
      /// Codex CLIを使用（Experimental）。npm install -g @openai/codex
      internal static let description = L10n.tr("Localizable", "backend.openaiCLI.description", fallback: "Codex CLIを使用（Experimental）。npm install -g @openai/codex")
      /// Codex CLI (Experimental)
      internal static let name = L10n.tr("Localizable", "backend.openaiCLI.name", fallback: "Codex CLI (Experimental)")
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
  internal enum DangerousRead {
    /// アクセシビリティ権限が必要です。システム設定 > プライバシーとセキュリティ > アクセシビリティ でアクセスを許可してください。
    internal static let accessibilityNotTrusted = L10n.tr("Localizable", "dangerousRead.accessibilityNotTrusted", fallback: "アクセシビリティ権限が必要です。システム設定 > プライバシーとセキュリティ > アクセシビリティ でアクセスを許可してください。")
    internal enum Consent {
      /// キャンセル
      internal static let cancel = L10n.tr("Localizable", "dangerousRead.consent.cancel", fallback: "キャンセル")
      /// このモードは、画面の内容（フォーカス中のアプリケーション、ウィンドウタイトル、カーソル周辺のテキスト）を定期的に読み取り、LLMにコンテキストとして送信します。
      /// 
      /// データは設定されたLLMバックエンドに送信されます。セッションは設定された時間が経過すると自動的に終了します。
      /// 
      /// 続行しますか？
      internal static let message = L10n.tr("Localizable", "dangerousRead.consent.message", fallback: "このモードは、画面の内容（フォーカス中のアプリケーション、ウィンドウタイトル、カーソル周辺のテキスト）を定期的に読み取り、LLMにコンテキストとして送信します。\n\nデータは設定されたLLMバックエンドに送信されます。セッションは設定された時間が経過すると自動的に終了します。\n\n続行しますか？")
      /// 理解した上で有効化
      internal static let start = L10n.tr("Localizable", "dangerousRead.consent.start", fallback: "理解した上で有効化")
      /// デンジャラス読み取りモードを有効にしますか？
      internal static let title = L10n.tr("Localizable", "dangerousRead.consent.title", fallback: "デンジャラス読み取りモードを有効にしますか？")
    }
    internal enum Indicator {
      /// 画面読み取り中
      internal static let active = L10n.tr("Localizable", "dangerousRead.indicator.active", fallback: "画面読み取り中")
    }
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
    /// Hatoko 設定...
    internal static let menuItem = L10n.tr("Localizable", "settings.menuItem", fallback: "Hatoko 設定...")
    /// Hatoko 設定
    internal static let windowTitle = L10n.tr("Localizable", "settings.windowTitle", fallback: "Hatoko 設定")
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
    internal enum DangerousRead {
      /// アクセシビリティ権限を確認
      internal static let checkPermission = L10n.tr("Localizable", "settings.dangerousRead.checkPermission", fallback: "アクセシビリティ権限を確認")
      /// 自動停止までの時間
      internal static let duration = L10n.tr("Localizable", "settings.dangerousRead.duration", fallback: "自動停止までの時間")
      /// デンジャラス読み取りモードを有効化
      internal static let enable = L10n.tr("Localizable", "settings.dangerousRead.enable", fallback: "デンジャラス読み取りモードを有効化")
      /// キャプチャ間隔
      internal static let interval = L10n.tr("Localizable", "settings.dangerousRead.interval", fallback: "キャプチャ間隔")
      /// 権限付与済み
      internal static let permissionGranted = L10n.tr("Localizable", "settings.dangerousRead.permissionGranted", fallback: "権限付与済み")
      /// 権限が必要です
      internal static let permissionNotGranted = L10n.tr("Localizable", "settings.dangerousRead.permissionNotGranted", fallback: "権限が必要です")
      /// 警告: このモードは画面の内容（フォーカス中のアプリ、ウィンドウタイトル、テキスト）を定期的に読み取り、LLMにコンテキストとして送信します。プライバシーへの影響を理解した上で有効化してください。
      internal static let warning = L10n.tr("Localizable", "settings.dangerousRead.warning", fallback: "警告: このモードは画面の内容（フォーカス中のアプリ、ウィンドウタイトル、テキスト）を定期的に読み取り、LLMにコンテキストとして送信します。プライバシーへの影響を理解した上で有効化してください。")
    }
    internal enum Keybinding {
      /// Ctrl + Shift + Space: デンジャラス読み取りモード切替
      internal static let dangerousRead = L10n.tr("Localizable", "settings.keybinding.dangerousRead", fallback: "Ctrl + Shift + Space: デンジャラス読み取りモード切替")
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
      /// デンジャラス読み取りモード
      internal static let dangerousRead = L10n.tr("Localizable", "settings.sectionHeader.dangerousRead", fallback: "デンジャラス読み取りモード")
      /// キーバインド
      internal static let keybinding = L10n.tr("Localizable", "settings.sectionHeader.keybinding", fallback: "キーバインド")
      /// LLM バックエンド
      internal static let llmBackend = L10n.tr("Localizable", "settings.sectionHeader.llmBackend", fallback: "LLM バックエンド")
    }
  }
  internal enum Thinking {
    /// 提案を生成中
    internal static let generatingAccessibility = L10n.tr("Localizable", "thinking.generatingAccessibility", fallback: "提案を生成中")
    /// 構成を考えています
    internal static let phrase0 = L10n.tr("Localizable", "thinking.phrase0", fallback: "構成を考えています")
    /// 言い回しを調整中
    internal static let phrase1 = L10n.tr("Localizable", "thinking.phrase1", fallback: "言い回しを調整中")
    /// もう少しで書けそう
    internal static let phrase2 = L10n.tr("Localizable", "thinking.phrase2", fallback: "もう少しで書けそう")
    /// いい表現を探しています
    internal static let phrase3 = L10n.tr("Localizable", "thinking.phrase3", fallback: "いい表現を探しています")
    /// 下書きを推敲中
    internal static let phrase4 = L10n.tr("Localizable", "thinking.phrase4", fallback: "下書きを推敲中")
    /// 文脈を整理しています
    internal static let phrase5 = L10n.tr("Localizable", "thinking.phrase5", fallback: "文脈を整理しています")
    /// ちょっと待ってくださいね
    internal static let phrase6 = L10n.tr("Localizable", "thinking.phrase6", fallback: "ちょっと待ってくださいね")
    /// もうすぐまとまります
    internal static let phrase7 = L10n.tr("Localizable", "thinking.phrase7", fallback: "もうすぐまとまります")
    /// 表現を練っています
    internal static let phrase8 = L10n.tr("Localizable", "thinking.phrase8", fallback: "表現を練っています")
    /// 最後の仕上げ中
    internal static let phrase9 = L10n.tr("Localizable", "thinking.phrase9", fallback: "最後の仕上げ中")
    /// 提案: %@
    internal static func suggestionAccessibility(_ p1: Any) -> String {
      return L10n.tr("Localizable", "thinking.suggestionAccessibility", String(describing: p1), fallback: "提案: %@")
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
