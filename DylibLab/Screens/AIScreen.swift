import SwiftUI

// AI 助手：自配 API Key，流式对话，代码块可一键应用到项目文件

struct AIScreen: View {
    @EnvironmentObject var ai: AIStore
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var store: ProjectStore

    @State private var input = ""
    @State private var attachProject = true
    @State private var projectID: UUID?
    @State private var showSettings = false
    @State private var toast: String?
    @State private var applyTarget: (code: String, lang: String)?

    private var selectedProject: DylibProject? {
        if let id = projectID, let p = store.project(id) { return p }
        return store.projects.first
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            if settings.apiKey.isEmpty {
                apiKeyBanner
            }
            chatList
            inputBar
        }
        .toast($toast)
        .sheet(isPresented: $showSettings) {
            AISettingsView()
        }
        .confirmationDialog(
            "应用到哪个文件",
            isPresented: Binding(
                get: { applyTarget != nil },
                set: { if !$0 { applyTarget = nil } }
            ),
            titleVisibility: .visible,
            presenting: applyTarget
        ) { target in
            if let project = selectedProject {
                ForEach(project.files) { f in
                    Button(f.name) {
                        apply(code: target.code, to: project, file: f)
                    }
                }
            }
            Button("取消", role: .cancel) {}
        } message: { _ in
            Text("代码将写入所选文件（自动保存）")
        }
        .onAppear {
            if projectID == nil { projectID = store.projects.first?.id }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("AI 助手")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text("把项目发给 AI，让它帮你搭积木、写代码")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Theme.surface2))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 12)
    }

    private var apiKeyBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "key.fill")
                .foregroundStyle(Theme.accent)
            Text("尚未配置 API Key，AI 助手无法工作")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            Button("去配置") {
                showSettings = true
            }
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(Theme.accent)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Theme.accentSoft))
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }

    // MARK: 聊天列表

    private var chatList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 13) {
                    if ai.messages.isEmpty {
                        welcomeView
                    }
                    ForEach(ai.messages) { m in
                        MessageCell(message: m, onApplyCode: { code, lang in
                            applyTarget = (code, lang)
                        })
                    }
                    if ai.isStreaming {
                        HStack {
                            TypingDots()
                            Spacer()
                        }
                        .padding(.leading, 6)
                    }
                    if let err = ai.errorMessage {
                        errorBanner(err)
                    }
                }
                .padding(16)
            }
            .onChange(of: ai.messages.count) { _ in
                scrollToBottom(proxy)
            }
            .onChange(of: ai.isStreaming) { streaming in
                if streaming { scrollToBottom(proxy) }
            }
        }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        guard let last = ai.messages.last else { return }
        withAnimation(.easeOut(duration: 0.25)) {
            proxy.scrollTo(last.id, anchor: .bottom)
        }
    }

    private var welcomeView: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 44, height: 44)
                    .background(RoundedRectangle(cornerRadius: 13).fill(Theme.accentSoft))
                VStack(alignment: .leading, spacing: 3) {
                    Text("我是你的 dylib 开发搭子")
                        .font(.system(size: 15.5, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("附加项目后，我能看懂你的积木和代码")
                        .font(.system(size: 12.5))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            Text("试试这样问：")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.textFaint)
                .padding(.top, 2)
            VStack(spacing: 8) {
                quickPrompt("帮我解释 %hook 和 %orig 的关系")
                quickPrompt("给 SpringBoard 写一个改壁纸的 tweak")
                quickPrompt("Method Swizzling 和 Logos 是什么关系？")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(Theme.surface))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.border.opacity(0.7), lineWidth: 1))
    }

    private func quickPrompt(_ text: String) -> some View {
        Button {
            haptic(.light)
            send(text)
        } label: {
            HStack {
                Text(text)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Theme.textFaint)
            }
            .padding(11)
            .background(RoundedRectangle(cornerRadius: 11).fill(Theme.surface2))
        }
        .buttonStyle(.plain)
    }

    private func errorBanner(_ msg: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Theme.danger)
            Text(msg)
                .font(.system(size: 12.5, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
            Spacer()
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Theme.danger.opacity(0.1)))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.danger.opacity(0.4), lineWidth: 1))
    }

    // MARK: 输入栏

    private var inputBar: some View {
        VStack(spacing: 8) {
            if !store.projects.isEmpty {
                HStack(spacing: 10) {
                    Button {
                        haptic(.light)
                        withAnimation(Theme.spring) { attachProject.toggle() }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: attachProject ? "paperclip.circle.fill" : "paperclip")
                                .font(.system(size: 13, weight: .semibold))
                            Text(attachProject ? "已附加项目" : "附加项目")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(attachProject ? Theme.accent : Theme.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(attachProject ? Theme.accentSoft : Theme.surface2))
                    }

                    Menu {
                        ForEach(store.projects) { p in
                            Button {
                                projectID = p.id
                            } label: {
                                if projectID == p.id {
                                    Label(p.name, systemImage: "checkmark")
                                } else {
                                    Text(p.name)
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(selectedProject?.name ?? "选择项目")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Theme.textSecondary)
                                .lineLimit(1)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(Theme.textFaint)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Theme.surface2))
                    }
                    Spacer()
                    if !ai.messages.isEmpty {
                        Button {
                            ai.clear()
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 13))
                                .foregroundStyle(Theme.textFaint)
                        }
                    }
                }
            }

            HStack(alignment: .bottom, spacing: 10) {
                TextField("问点什么…", text: $input, axis: .vertical)
                    .lineLimit(1...4)
                    .font(.system(size: 14.5))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(RoundedRectangle(cornerRadius: 18).fill(Theme.surface2))
                    .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Theme.border, lineWidth: 1))

                Button {
                    if ai.isStreaming {
                        haptic(.medium)
                        ai.stop()
                    } else {
                        haptic(.medium)
                        send(input)
                    }
                } label: {
                    Image(systemName: ai.isStreaming ? "stop.circle.fill" : "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(ai.isStreaming ? Theme.danger : Theme.accent)
                }
                .disabled(!ai.isStreaming && input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(!ai.isStreaming && input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.4 : 1)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 10)
    }

    private func send(_ text: String) {
        let ctx: String? = attachProject ? selectedProject.flatMap { AIStore.projectContext($0) } : nil
        ai.send(userText: text, projectContext: ctx)
        input = ""
    }

    private func apply(code: String, to project: DylibProject, file: DylibFile) {
        store.updateFile(projectID: project.id, fileID: file.id, content: code)
        toast = "已应用到 \(file.name)"
        hapticNotify(.success)
    }
}

// MARK: 消息气泡

struct MessageCell: View {
    let message: ChatMessage
    var onApplyCode: (String, String) -> Void

    private var isUser: Bool { message.role == .user }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 40) }
            VStack(alignment: isUser ? .trailing : .leading, spacing: 8) {
                if isUser {
                    Text(message.content)
                        .font(.system(size: 14.5))
                        .foregroundStyle(.white)
                        .textSelection(.enabled)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Theme.blue)
                        )
                } else {
                    ForEach(FenceParser.parse(message.content)) { seg in
                        if seg.isCode {
                            CodeBlockView(
                                code: seg.text,
                                lang: seg.lang.isEmpty ? nil : seg.lang,
                                onApply: { onApplyCode(seg.text, seg.lang) }
                            )
                        } else {
                            Text(seg.text)
                                .font(.system(size: 14.5))
                                .foregroundStyle(Theme.textPrimary)
                                .textSelection(.enabled)
                                .lineSpacing(4)
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Theme.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Theme.border.opacity(0.7), lineWidth: 1)
                    )
                }
            }
            if !isUser { Spacer(minLength: 40) }
        }
    }
}

// 解析消息中的代码块
struct FenceSegment: Identifiable {
    let id = UUID()
    let isCode: Bool
    let text: String
    let lang: String
}

enum FenceParser {
    static func parse(_ s: String) -> [FenceSegment] {
        var segs: [FenceSegment] = []
        let lines = s.components(separatedBy: "\n")
        var buffer: [String] = []
        var i = 0

        func flush() {
            if !buffer.isEmpty {
                segs.append(FenceSegment(isCode: false, text: buffer.joined(separator: "\n"), lang: ""))
                buffer = []
            }
        }

        while i < lines.count {
            let line = lines[i]
            if line.hasPrefix("```") {
                flush()
                let lang = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                var code: [String] = []
                i += 1
                while i < lines.count && !lines[i].hasPrefix("```") {
                    code.append(lines[i])
                    i += 1
                }
                i += 1
                segs.append(FenceSegment(isCode: true, text: code.joined(separator: "\n"), lang: lang))
            } else {
                buffer.append(line)
                i += 1
            }
        }
        flush()
        return segs
    }
}

struct TypingDots: View {
    @State private var anim = false

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Theme.textFaint)
                    .frame(width: 6, height: 6)
                    .offset(y: anim ? -3 : 3)
                    .animation(
                        .easeInOut(duration: 0.45)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.13),
                        value: anim
                    )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 16).fill(Theme.surface))
        .onAppear { anim = true }
    }
}
