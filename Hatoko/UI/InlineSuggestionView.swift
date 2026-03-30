import SwiftUI

struct InlineSuggestionView: View {

    let suggestion: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            if let suggestion {
                suggestionBody(suggestion)
            } else {
                loadingBody
            }
            footer
        }
        .frame(minWidth: 320, maxWidth: 480)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
        )
    }

    private var header: some View {
        HStack {
            Text("Hatoko")
                .font(.headline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func suggestionBody(_ text: String) -> some View {
        Text(text)
            .font(.body)
            .lineSpacing(4)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityLabel("提案: \(text)")
    }

    private var loadingBody: some View {
        HStack(spacing: 8) {
            ProgressView()
                .controlSize(.small)
            Text("生成中...")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .accessibilityLabel("提案を生成中")
    }

    private var footer: some View {
        HStack(spacing: 16) {
            keyHint("Enter", action: "確定", primary: true)
            keyHint("Tab", action: "チャットで調整")
            keyHint("Esc", action: "キャンセル")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.regularMaterial)
    }

    private func keyHint(_ key: String, action: String, primary: Bool = false) -> some View {
        HStack(spacing: 4) {
            Text(key)
                .font(.caption2.monospaced().weight(.medium))
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(.quaternary)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            Text(action)
                .font(.caption2)
        }
        .foregroundStyle(primary ? .primary : .secondary)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(key)キーで\(action)")
    }
}
