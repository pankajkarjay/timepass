import Foundation

final class AIClassifierService {
    private struct ChatCompletionRequest: Encodable {
        struct Message: Encodable {
            let role: String
            let content: String
        }

        let model: String
        let messages: [Message]
        let temperature: Double
        let response_format: ResponseFormat

        struct ResponseFormat: Encodable {
            let type: String
        }
    }

    private struct ChatCompletionResponse: Decodable {
        struct Choice: Decodable {
            struct Message: Decodable {
                let content: String
            }

            let message: Message
        }

        let choices: [Choice]
    }

    private let session: URLSession
    private let endpoint: URL
    private let model: String

    init(
        session: URLSession = .shared,
        endpoint: URL = URL(string: "https://api.openai.com/v1/chat/completions")!,
        model: String = "gpt-4o-mini"
    ) {
        self.session = session
        self.endpoint = endpoint
        self.model = model
    }

    func classifyText(_ text: String) async throws -> ClassificationResult {
        guard let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !apiKey.isEmpty else {
            throw AppError.missingAPIKey
        }

        let prompt = """
        You are an information classifier for iOS screenshot OCR text.
        Return strictly valid JSON using this exact schema and no additional keys:
        {
          "type": "receipt | tweet | travel | recipe | shopping | finance | note | other",
          "title": "string",
          "summary": "string",
          "important_data": {
            "amount": "string",
            "date": "string",
            "company": "string",
            "location": "string"
          },
          "tags": ["string"]
        }

        If a value is unknown, set an empty string.
        Text:
        \(text)
        """

        let body = ChatCompletionRequest(
            model: model,
            messages: [
                .init(role: "system", content: "You classify OCR text into structured personal knowledge cards."),
                .init(role: "user", content: prompt)
            ],
            temperature: 0.2,
            response_format: .init(type: "json_object")
        )

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let responseText = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AppError.networkFailure(responseText)
        }

        let completion = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        guard let content = completion.choices.first?.message.content,
              let contentData = content.data(using: .utf8) else {
            throw AppError.invalidResponse
        }

        do {
            return try JSONDecoder().decode(ClassificationResult.self, from: contentData)
        } catch {
            throw AppError.invalidResponse
        }
    }
}
