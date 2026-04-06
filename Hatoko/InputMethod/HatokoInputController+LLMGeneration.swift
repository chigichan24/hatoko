import Cocoa
@preconcurrency import InputMethodKit

extension HatokoInputController {

    func buildSystemPromptWithScreenContext(
        base: LocalizedPrompt,
        pasteContext: PasteContext?,
        language: InstructionLanguage
    ) -> String {
        let screenCtx = dangerousReadController.isActive
            ? dangerousReadController.currentScreenContext
            : nil
        let baseText = screenCtx != nil
            ? base.text(for: language) + "\n"
                + SystemPromptProvider.screenContextInstruction.text(for: language)
            : base.text(for: language)
        return PasteContext.buildSystemPrompt(
            base: baseText,
            context: pasteContext,
            screenContext: screenCtx,
            language: language
        )
    }

    func requestLLMGeneration(prompt: String, cursorRect: NSRect, pasteContext: PasteContext? = nil) {
        let backend = LLMBackend.current
        let language = backend.instructionLanguage
        let systemPrompt = buildSystemPromptWithScreenContext(
            base: SystemPromptProvider.inline,
            pasteContext: pasteContext,
            language: language
        )
        Task {
            let service: any LLMService
            do {
                service = try await backend.createService()
            } catch {
                NSLog("[Hatoko] LLM backend configuration error: \(error)")
                await MainActor.run {
                    NSSound.beep()
                    self.inlineSuggestionWindow.hide()
                    self.resetLLMState()
                }
                return
            }
            guard await Self.inlineRateLimiter.tryAcquire() else {
                NSLog("[Hatoko] LLM request rate limited")
                await MainActor.run {
                    self.inlineSuggestionWindow.hide()
                    self.resetLLMState()
                }
                return
            }
            do {
                let result = try await service.generate(
                    messages: [LLMMessage(role: .user, content: prompt)],
                    systemPrompt: systemPrompt
                )
                await MainActor.run {
                    self.llmSuggestion = result
                    self.inlineSuggestionWindow.show(
                        suggestion: result, cursorRect: cursorRect, hasContext: pasteContext != nil
                    )
                }
            } catch {
                NSLog("[Hatoko] LLM generation failed: \(error)")
                await MainActor.run {
                    self.inlineSuggestionWindow.hide()
                    self.resetLLMState()
                }
            }
        }
    }

    func sendChatMessage(chatHistory: [ChatMessage]) {
        guard let lastMessage = chatHistory.last, lastMessage.role == .user else {
            assertionFailure("[Hatoko] sendChatMessage called without trailing user message")
            return
        }
        guard validateChatMessage(lastMessage.text) else { return }

        let llmMessages = Self.buildLLMMessages(from: chatHistory)
        let backend = LLMBackend.current
        let language = backend.instructionLanguage
        let systemPrompt = buildSystemPromptWithScreenContext(
            base: SystemPromptProvider.chat,
            pasteContext: pasteContext,
            language: language
        )

        Task {
            let service: any LLMService
            do {
                service = try await backend.createService()
            } catch {
                NSLog("[Hatoko] LLM backend configuration error: \(error)")
                await MainActor.run {
                    self.chatWindowController.addAssistantMessage(L10n.Error.config)
                }
                return
            }
            guard await Self.chatRateLimiter.tryAcquire() else {
                NSLog("[Hatoko] LLM chat request rate limited")
                await MainActor.run {
                    self.chatWindowController.addAssistantMessage(L10n.Error.rateLimit)
                }
                return
            }
            do {
                let result = try await service.generate(
                    messages: llmMessages,
                    systemPrompt: systemPrompt
                )
                await MainActor.run {
                    self.llmSuggestion = result
                    self.chatWindowController.addAssistantMessage(result)
                }
            } catch {
                NSLog("[Hatoko] LLM chat generation failed: \(error)")
                await MainActor.run {
                    self.chatWindowController.addAssistantMessage(L10n.Error.generic)
                }
            }
        }
    }
}
