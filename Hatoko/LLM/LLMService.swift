struct LLMMessage: Sendable, Equatable {
    enum Role: String, Sendable {
        case user
        case assistant
    }

    let role: Role
    let content: String
}

protocol LLMService: Sendable {
    func generate(messages: [LLMMessage], systemPrompt: String?) async throws -> String
}

enum LLMServiceError: Error, Sendable {
    case invalidResponse
    case apiError(statusCode: Int, message: String)
    case emptyContent
}

import Foundation

enum APIServiceHelper {
    static func execute(request: URLRequest, session: URLSession) async throws -> Data {
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMServiceError.invalidResponse
        }
        if !(200..<300).contains(httpResponse.statusCode) {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw LLMServiceError.apiError(statusCode: httpResponse.statusCode, message: body)
        }
        return data
    }
}
