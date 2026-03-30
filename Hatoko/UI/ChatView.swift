import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: ChatRole
    let text: String

    enum ChatRole {
        case user
        case assistant

        var displayName: String {
            switch self {
            case .user: "あなた"
            case .assistant: "アシスタント"
            }
        }
    }
}

struct ChatView: View {

    let messages: [ChatMessage]
    let isLoading: Bool
    let inputText: Binding<String>
    let onSend: () -> Void
    let onUse: (String) -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            messageList
            Divider()
            inputArea
        }
        .frame(width: 340)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
        )
    }

    private var header: some View {
        HStack {
            Text("Hatoko アシスト")
                .font(.headline)
                .foregroundStyle(.primary)
            Spacer()
            Text("Esc で閉じる")
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityLabel("Escapeキーでウィンドウを閉じる")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(messages) { message in
                        messageBubble(message)
                            .id(message.id)
                    }
                    if isLoading {
                        loadingBubble
                    }
                }
                .padding(12)
            }
            .frame(maxHeight: 280)
            .onChange(of: messages.count) {
                if let last = messages.last {
                    withAnimation {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private func messageBubble(_ message: ChatMessage) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(message.role.displayName)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(message.text)
                .font(.body)
                .lineSpacing(3)
                .textSelection(.enabled)
                .accessibilityLabel("\(message.role.displayName): \(message.text)")
            if message.role == .assistant {
                Button("これを使う") {
                    onUse(message.text)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .accessibilityHint("このテキストを入力欄に挿入します")
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            message.role == .user
                ? Color.accentColor.opacity(0.08)
                : Color.clear
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var loadingBubble: some View {
        HStack(spacing: 8) {
            ProgressView()
                .controlSize(.small)
            Text("考えています...")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityLabel("アシスタントが考えています")
    }

    private var inputArea: some View {
        HStack(spacing: 8) {
            TextField("追加の指示...", text: inputText)
                .textFieldStyle(.roundedBorder)
                .font(.body)
                .accessibilityLabel("追加の指示を入力")
                .onSubmit {
                    onSend()
                }
            Text("Enter")
                .font(.caption2.monospaced().weight(.medium))
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(.quaternary)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .foregroundStyle(.secondary)
        }
        .padding(12)
    }
}
