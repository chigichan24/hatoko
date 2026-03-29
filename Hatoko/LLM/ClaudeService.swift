import Foundation

enum ClaudeServiceError: Error, Sendable {
    case invalidResponse
    case apiError(statusCode: Int, message: String)
    case emptyContent
}

final class ClaudeService: LLMService, Sendable {

    private let apiKey: String
    private let model: String
    private let session: URLSession

    init(apiKey: String, model: String = "claude-sonnet-4-20250514", session: URLSession = .shared) {
        self.apiKey = apiKey
        self.model = model
        self.session = session
    }

    func generate(messages: [LLMMessage], systemPrompt: String?) async throws -> String {
        let request = try buildRequest(messages: messages, systemPrompt: systemPrompt)
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClaudeServiceError.invalidResponse
        }

        if !(200..<300).contains(httpResponse.statusCode) {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw ClaudeServiceError.apiError(statusCode: httpResponse.statusCode, message: body)
        }

        return try parseResponse(data: data)
    }

    // MARK: - Internal helpers exposed for testing

    private static let apiURL: URL = {
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            fatalError("Invalid API URL literal")
        }
        return url
    }()

    func buildRequest(messages: [LLMMessage], systemPrompt: String?) throws -> URLRequest {
        var request = URLRequest(url: Self.apiURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        var body: [String: Any] = [
            "model": model,
            "max_tokens": 1024,
            "messages": messages.map { ["role": $0.role.rawValue, "content": $0.content] },
        ]

        if let systemPrompt {
            body["system"] = systemPrompt
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    private func parseResponse(data: Data) throws -> String {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstBlock = content.first,
              let text = firstBlock["text"] as? String
        else {
            throw ClaudeServiceError.emptyContent
        }
        return text
    }
}
