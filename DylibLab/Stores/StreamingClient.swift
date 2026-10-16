import Foundation

// OpenAI 兼容 API 的流式客户端（SSE）

enum AIError: LocalizedError {
    case noAPIKey
    case server(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .noAPIKey: return "请先在「设置」中配置 API Key"
        case .server(let msg): return "服务端错误：\(msg)"
        case .invalidResponse: return "无法解析服务端响应"
        }
    }
}

enum StreamingClient {
    static func stream(config: ChatAPIConfig, messages: [(role: String, content: String)]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    guard !config.apiKey.isEmpty else { throw AIError.noAPIKey }
                    let base = config.baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                    guard let url = URL(string: base + "/chat/completions") else {
                        throw AIError.invalidResponse
                    }
                    var req = URLRequest(url: url)
                    req.httpMethod = "POST"
                    req.timeoutInterval = 120
                    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    req.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
                    let body: [String: Any] = [
                        "model": config.model,
                        "messages": messages.map { ["role": $0.role, "content": $0.content] },
                        "stream": true,
                    ]
                    req.httpBody = try JSONSerialization.data(withJSONObject: body)

                    let (bytes, response) = try await URLSession.shared.bytes(for: req)
                    if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                        var errText = ""
                        for try await line in bytes.lines {
                            errText += line
                            if errText.count > 1200 { break }
                        }
                        throw AIError.server("HTTP \(http.statusCode)：\(errText.prefix(400))")
                    }

                    for try await line in bytes.lines {
                        guard line.hasPrefix("data:") else { continue }
                        let payload = line.dropFirst(5).trimmingCharacters(in: .whitespaces)
                        if payload == "[DONE]" {
                            continuation.finish()
                            return
                        }
                        guard let data = payload.data(using: .utf8),
                              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                              let choices = json["choices"] as? [[String: Any]],
                              let delta = choices.first?["delta"] as? [String: Any],
                              let content = delta["content"] as? String else { continue }
                        continuation.yield(content)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    static func quickTest(config: ChatAPIConfig) async -> Result<String, Error> {
        do {
            guard !config.apiKey.isEmpty else { return .failure(AIError.noAPIKey) }
            let base = config.baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            guard let url = URL(string: base + "/chat/completions") else {
                return .failure(AIError.invalidResponse)
            }
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.timeoutInterval = 30
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
            let body: [String: Any] = [
                "model": config.model,
                "messages": [["role": "user", "content": "ping"]],
                "max_tokens": 1,
                "stream": false,
            ]
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await URLSession.shared.data(for: req)
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                let text = String(data: data, encoding: .utf8) ?? ""
                return .failure(AIError.server("HTTP \(http.statusCode)：\(text.prefix(300))"))
            }
            return .success("连接成功，模型 \(config.model) 可用")
        } catch {
            return .failure(error)
        }
    }
}
