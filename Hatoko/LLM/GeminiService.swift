import Foundation

final class GeminiService: LLMService, Sendable {

    private let apiKey: String
    private let model: String
    private let session: URLSession

    init(apiKey: String, model: String = "gemini-2.5-flash-lite", session: URLSession = .shared) {
        self.apiKey = apiKey
        self.model = model
        self.session = session
    }

    func generate(messages: [LLMMessage], systemPrompt: String?) async throws -> String {
        let request = try buildRequest(messages: messages, systemPrompt: systemPrompt)
        let data = try await APIServiceHelper.execute(request: request, session: session)
        return try parseResponse(data: data)
    }

    // MARK: - Internal helpers exposed for testing

    func buildRequest(messages: [LLMMessage], systemPrompt: String?) throws -> URLRequest {
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent"
        guard let url = URL(string: urlString) else {
            throw LLMServiceError.invalidRequest(reason: "Invalid model name for URL: \(model)")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")

        var body: [String: Any] = [
            "contents": messages.map { message in
                [
                    "role": geminiRole(from: message.role),
                    "parts": [["text": message.content]],
                ] as [String: Any]
            },
        ]

        if let systemPrompt {
            body["systemInstruction"] = [
                "parts": [["text": systemPrompt]],
            ]
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    // MARK: - Private

    private func geminiRole(from role: LLMMessage.Role) -> String {
        switch role {
        case .user: "user"
        case .assistant: "model"
        }
    }

    private func parseResponse(data: Data) throws -> String {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String
        else {
            throw LLMServiceError.emptyContent
        }
        return text
    }
}
