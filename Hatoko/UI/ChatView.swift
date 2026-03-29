import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: ChatRole
    let text: String

    enum ChatRole {
        case user
        case assistant
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
            messageList
            inputArea
        }
        .frame(width: 340)
        .background(Color(nsColor: .windowBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }

    private var header: some View {
        HStack {
            Text("✦ Hatoko アシスト")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.pink)
            Spacer()
            Text("Esc で閉じる")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor))
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
        HStack {
            if message.role == .user { Spacer(minLength: 40) }
            VStack(alignment: .leading, spacing: 4) {
                if message.role == .assistant {
                    Text("✦ Claude")
                        .font(.system(size: 10))
                        .foregroundStyle(.pink)
                }
                Text(message.text)
                    .font(.system(size: 13))
                    .lineSpacing(3)
                if message.role == .assistant {
                    Button {
                        onUse(message.text)
                    } label: {
                        Text("これを使う")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(UseButtonStyle())
                }
            }
            .padding(8)
            .background(message.role == .user ? Color.pink : Color(nsColor: .controlBackgroundColor))
            .foregroundStyle(message.role == .user ? .white : .primary)
            .cornerRadius(10)
            if message.role == .assistant { Spacer(minLength: 40) }
        }
    }

    private var loadingBubble: some View {
        HStack {
            HStack(spacing: 4) {
                ProgressView()
                    .controlSize(.small)
                Text("考えています...")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .padding(8)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(10)
            Spacer(minLength: 40)
        }
    }

    private var inputArea: some View {
        HStack(spacing: 8) {
            TextField("追加の指示...", text: inputText)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .padding(6)
                .background(Color(nsColor: .textBackgroundColor))
                .cornerRadius(6)
                .onSubmit {
                    onSend()
                }
            Text("Enter")
                .font(.system(size: 10, design: .monospaced))
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(3)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}

private struct UseButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(configuration.isPressed ? Color.pink : Color.pink.opacity(0.15))
            .foregroundStyle(configuration.isPressed ? .white : .pink)
            .cornerRadius(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.pink.opacity(0.3), lineWidth: 1)
            )
    }
}
