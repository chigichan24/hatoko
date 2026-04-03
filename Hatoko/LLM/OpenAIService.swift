import Foundation

final class OpenAIService: LLMService, Sendable {

    private let apiKey: String
    private let model: String
    private let session: URLSession

    init(apiKey: String, model: String = "gpt-4o", session: URLSession = .shared) {
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

    private static let apiURL: URL = {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            fatalError("Invalid API URL literal")
        }
        return url
    }()

    func buildRequest(messages: [LLMMessage], systemPrompt: String?) throws -> URLRequest {
        var request = URLRequest(url: Self.apiURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        var apiMessages: [[String: String]] = []

        if let systemPrompt {
            apiMessages.append(["role": "system", "content": systemPrompt])
        }

        for message in messages {
            apiMessages.append(["role": message.role.rawValue, "content": message.content])
        }

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 1024,
            "messages": apiMessages,
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    private func parseResponse(data: Data) throws -> String {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String
        else {
            throw LLMServiceError.emptyContent
        }
        return content
    }
}
