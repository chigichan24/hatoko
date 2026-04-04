import SwiftUI

struct InlineSuggestionView: View {

    let suggestion: String?
    let hasContext: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            ThinkingAnimationView(
                suggestion: suggestion,
                onRevealComplete: {}
            )
            footer
        }
        .frame(minWidth: 320, maxWidth: 480)
        .glassEffect(.regular, in: .rect(cornerRadius: 10))
    }

    private var header: some View {
        HStack {
            Text("Hatoko")
                .font(.headline)
                .foregroundStyle(.secondary)
            if hasContext {
                Text(PasteContext.displayIcon)
                    .accessibilityLabel(L10n.Inline.contextAccessibility)
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var footer: some View {
        HStack(spacing: 16) {
            keyHint("Enter", action: L10n.Inline.Action.confirm, primary: true)
            keyHint("Tab", action: L10n.Inline.Action.chat)
            keyHint("Esc", action: L10n.Inline.Action.cancel)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
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
        .accessibilityLabel(L10n.Inline.keyAction(key, action))
    }
}
