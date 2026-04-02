import SwiftUI

struct ChatMessage: Identifiable, Sendable {
    let id = UUID()
    let role: ChatRole
    let text: String

    enum ChatRole: Sendable {
        case user
        case assistant

        var displayName: String {
            switch self {
            case .user: "あなた"
            case .assistant: "Hatoko"
            }
        }

        var bubbleColor: Color {
            switch self {
            case .user: Color.accentColor.opacity(0.15)
            case .assistant: Color.secondary.opacity(0.12)
            }
        }
    }
}

struct ChatView: View {

    let messages: [ChatMessage]
    let isLoading: Bool
    let pasteContext: PasteContext?
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
        .frame(width: 380)
        .glassEffect(.regular, in: .rect(cornerRadius: 10))
    }

    private var header: some View {
        HStack(spacing: 6) {
            hatokoAvatar(size: 20)
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
                VStack(spacing: 8) {
                    if let pasteContext {
                        contextBanner(pasteContext)
                    }
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
            .frame(maxHeight: 360)
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
        let isUser = message.role == .user
        return HStack(alignment: .top, spacing: 6) {
            if isUser { Spacer(minLength: 40) }
            if !isUser { hatokoAvatar(size: 24) }
            bubbleContent(message)
            if isUser { /* no avatar for user */ }
            if !isUser { Spacer(minLength: 40) }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(message.role.displayName): \(message.text)"
        )
    }

    private func bubbleContent(_ message: ChatMessage) -> some View {
        VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
            Text(message.text)
                .font(.body)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
            if message.role == .assistant {
                useButton(message.text)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(message.role.bubbleColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var loadingBubble: some View {
        HStack(alignment: .top, spacing: 6) {
            hatokoAvatar(size: 24)
            TypingIndicatorView()
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
                .background(ChatMessage.ChatRole.assistant.bubbleColor)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            Spacer(minLength: 40)
        }
        .accessibilityLabel("Hatokoが考えています")
    }

    private func hatokoAvatar(size: CGFloat) -> some View {
        Image(nsImage: NSApp.applicationIconImage)
            .resizable()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.25))
            .accessibilityHidden(true)
    }

    private func useButton(_ text: String) -> some View {
        Button("これを使う ⌘C") {
            onUse(text)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .accessibilityHint(
            "このテキストを入力欄に挿入し、クリップボードにもコピーします"
        )
    }

    private func contextBanner(_ context: PasteContext) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text(PasteContext.displayIcon)
            Text(context.text)
                .lineLimit(3)
                .font(.caption)
        }
        .foregroundStyle(.secondary)
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("コンテキスト: \(String(context.text.prefix(PasteContext.maxAccessibilityPreviewLength)))")
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
