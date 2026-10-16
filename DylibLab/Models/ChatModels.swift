import Foundation

// AI 助手相关模型

enum AIProvider: String, Codable, CaseIterable, Identifiable {
    case openai, deepseek, moonshot, custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .openai: return "OpenAI"
        case .deepseek: return "DeepSeek"
        case .moonshot: return "Moonshot (Kimi)"
        case .custom: return "自定义"
        }
    }

    var defaultBase: String {
        switch self {
        case .openai: return "https://api.openai.com/v1"
        case .deepseek: return "https://api.deepseek.com/v1"
        case .moonshot: return "https://api.moonshot.cn/v1"
        case .custom: return ""
        }
    }

    var defaultModel: String {
        switch self {
        case .openai: return "gpt-4o-mini"
        case .deepseek: return "deepseek-chat"
        case .moonshot: return "moonshot-v1-8k"
        case .custom: return ""
        }
    }

    var keyPlaceholder: String {
        switch self {
        case .openai: return "sk-..."
        case .deepseek: return "sk-..."
        case .moonshot: return "sk-..."
        case .custom: return "你的 API Key"
        }
    }
}

enum ChatRole: String, Codable {
    case system, user, assistant
}

struct ChatMessage: Identifiable, Codable {
    var id: UUID = UUID()
    var role: ChatRole
    var content: String
    var timestamp: Date = Date()
}

struct ChatAPIConfig {
    var baseURL: String
    var apiKey: String
    var model: String
}
