import Foundation
import SwiftUI

// AI 助手状态管理

@MainActor
final class AIStore: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isStreaming = false
    @Published var errorMessage: String?

    let settings: SettingsStore
    private var streamTask: Task<Void, Never>?

    static let systemPrompt = """
你是一名 iOS dylib / tweak 开发专家，服务于 DylibLab（一个积木化 dylib 学习工具）的学习者。

规则：
1. 用户可能是新手，解释要循序渐进，先讲思路再给代码。
2. 用户可能附带项目上下文（积木 JSON + 文件内容），请基于它回答问题；若代码有问题，直接指出并给出修正版。
3. 代码用 Markdown 代码块包裹：Logos/ObjC 用 ```logos 或 ```objc，Swift 用 ```swift，Makefile 用 ```makefile。
4. 回答代码改动时，尽量给出完整的文件内容或明确的「替换哪一段」，方便一键应用到项目。
5. 涉及越狱/注入的内容仅限学习与授权范围，不提供作弊、破解、盗版、恶意代码相关帮助。
6. 用简体中文回答，代码注释也用中文。
"""

    init(settings: SettingsStore) {
        self.settings = settings
    }

    func send(userText: String, projectContext: String?) {
        guard !isStreaming else { return }
        let trimmed = userText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        errorMessage = nil
        messages.append(ChatMessage(role: .user, content: trimmed))

        var requestMessages: [(role: String, content: String)] = [
            ("system", Self.systemPrompt),
        ]
        for m in messages.prefix(messages.count - 1) {
            requestMessages.append((m.role.rawValue, m.content))
        }
        if let ctx = projectContext {
            let wrapped = """
            以下是我的项目上下文，请基于它回答：
            ```json
            \(ctx)
            ```
            """
            requestMessages.append(("user", wrapped))
        }
        requestMessages.append(("user", trimmed))

        isStreaming = true
        var replyID = UUID()
        messages.append(ChatMessage(role: .assistant, content: "", timestamp: Date()))
        replyID = messages[messages.count - 1].id

        let config = settings.activeConfig
        streamTask = Task { [weak self] in
            guard let self else { return }
            var full = ""
            do {
                let stream = StreamingClient.stream(config: config, messages: requestMessages)
                for try await chunk in stream {
                    if Task.isCancelled { break }
                    full += chunk
                    if let idx = self.messages.firstIndex(where: { $0.id == replyID }) {
                        self.messages[idx].content = full
                    }
                }
            } catch {
                if let idx = self.messages.firstIndex(where: { $0.id == replyID }) {
                    if self.messages[idx].content.isEmpty {
                        self.messages.remove(at: idx)
                    }
                }
                self.errorMessage = error.localizedDescription
            }
            self.isStreaming = false
        }
    }

    func stop() {
        streamTask?.cancel()
        streamTask = nil
        isStreaming = false
    }

    func clear() {
        stop()
        messages = []
        errorMessage = nil
    }

    // 构建项目上下文（供发送时附带）
    static func projectContext(_ project: DylibProject) -> String? {
        var dict: [String: Any] = [
            "项目名称": project.name,
            "目标进程": project.targetApp,
            "积木": project.blocks.map { blockDict($0) },
        ]
        var files: [String: String] = [:]
        for f in project.files {
            files[f.name] = String(f.content.prefix(4000))
        }
        dict["文件"] = files
        guard let data = try? JSONSerialization.data(withJSONObject: dict, options: []),
              let str = String(data: data, encoding: .utf8) else { return nil }
        return str
    }

    private static func blockDict(_ b: Block) -> [String: Any] {
        [
            "kind": b.kind.rawValue,
            "inputs": b.inputs,
            "children": b.children.map { blockDict($0) },
        ]
    }
}
