import Foundation
import SwiftUI
import Security

// API Key 安全存储：优先 Keychain，失败回退 UserDefaults

enum SecureStore {
    private static let service = "com.dyliblab.studio.apikey"

    static func save(_ value: String) {
        guard !value.isEmpty else { remove(); return }
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecValueData as String: data,
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            // 无签名环境 Keychain 可能不可用，回退 UserDefaults
            UserDefaults.standard.set(value, forKey: "dl.apikey.fallback")
        }
    }

    static func load() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        if SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
           let data = item as? Data,
           let str = String(data: data, encoding: .utf8) {
            return str
        }
        return UserDefaults.standard.string(forKey: "dl.apikey.fallback")
    }

    static func remove() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
        ]
        SecItemDelete(query as CFDictionary)
        UserDefaults.standard.removeObject(forKey: "dl.apikey.fallback")
    }
}

// 设置存储

@MainActor
final class SettingsStore: ObservableObject {
    @Published var provider: AIProvider {
        didSet { UserDefaults.standard.set(provider.rawValue, forKey: "dl.provider") }
    }
    @Published var baseURL: String {
        didSet { UserDefaults.standard.set(baseURL, forKey: "dl.baseurl") }
    }
    @Published var apiKey: String {
        didSet { SecureStore.save(apiKey) }
    }
    @Published var model: String {
        didSet { UserDefaults.standard.set(model, forKey: "dl.model") }
    }
    @Published var completedLessons: Set<Int> {
        didSet {
            UserDefaults.standard.set(Array(completedLessons), forKey: "dl.completed")
        }
    }

    init() {
        let defs = UserDefaults.standard
        let raw = defs.string(forKey: "dl.provider") ?? AIProvider.deepseek.rawValue
        let prov = AIProvider(rawValue: raw) ?? .deepseek
        provider = prov
        baseURL = defs.string(forKey: "dl.baseurl") ?? prov.defaultBase
        apiKey = SecureStore.load() ?? ""
        model = defs.string(forKey: "dl.model") ?? prov.defaultModel
        completedLessons = Set(defs.array(forKey: "dl.completed") as? [Int] ?? [])
    }

    // 当前生效的 API 配置
    var activeConfig: ChatAPIConfig {
        let base: String
        let mdl: String
        if provider == .custom {
            base = baseURL
            mdl = model
        } else {
            base = baseURL.isEmpty ? provider.defaultBase : baseURL
            mdl = model.isEmpty ? provider.defaultModel : model
        }
        return ChatAPIConfig(baseURL: base, apiKey: apiKey, model: mdl)
    }

    func applyProviderPreset() {
        baseURL = provider.defaultBase
        model = provider.defaultModel
    }
}
