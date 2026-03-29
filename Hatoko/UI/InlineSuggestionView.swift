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
        .background(Color(nsColor: .windowBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }

    private var header: some View {
        HStack {
            Text("✦ Claude")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.pink)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func suggestionBody(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .lineSpacing(4)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var loadingBody: some View {
        HStack(spacing: 4) {
            ProgressView()
                .controlSize(.small)
            Text("生成中...")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var footer: some View {
        HStack(spacing: 16) {
            keyHint("Enter", action: "確定", primary: true)
            keyHint("Tab", action: "チャットで調整")
            keyHint("Esc", action: "キャンセル")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func keyHint(_ key: String, action: String, primary: Bool = false) -> some View {
        HStack(spacing: 3) {
            Text(key)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(3)
            Text(action)
                .font(.system(size: 10))
        }
        .foregroundStyle(primary ? .pink : .secondary)
    }
}
