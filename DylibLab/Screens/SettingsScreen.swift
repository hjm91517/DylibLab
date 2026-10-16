import SwiftUI

// 设置页 + AI 配置页

struct SettingsScreen: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var store: ProjectStore
    @State private var showAI = false
    @State private var showClearConfirm = false
    @State private var toast: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("设置")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.top, 6)

                // AI 配置
                Card {
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Theme.accent)
                            .frame(width: 40, height: 40)
                            .background(RoundedRectangle(cornerRadius: 11).fill(Theme.accentSoft))
                        VStack(alignment: .leading, spacing: 3) {
                            Text("AI 助手")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(Theme.textPrimary)
                            Text(settings.apiKey.isEmpty ? "未配置 API Key" : "\(settings.provider.displayName) · \(settings.model)")
                                .font(.system(size: 12.5))
                                .foregroundStyle(settings.apiKey.isEmpty ? Theme.danger : Theme.textSecondary)
                        }
                        Spacer()
                        PillButton("配置", icon: "gearshape", filled: false) {
                            showAI = true
                        }
                    }
                }

                // 学习进度
                Card {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Label("学习进度", systemImage: "graduationcap")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            Text("\(settings.completedLessons.count)/\(TutorialStore.all.count)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Theme.accent)
                        }
                        ProgressView(value: Double(settings.completedLessons.count), total: Double(TutorialStore.all.count))
                            .tint(Theme.accent)
                    }
                }

                // 数据
                Card {
                    HStack {
                        Label("项目数据", systemImage: "folder")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        PillButton("清空项目", icon: "trash", filled: false, tint: Theme.danger) {
                            showClearConfirm = true
                        }
                    }
                }

                // 关于
                Card {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("关于 DylibLab", systemImage: "hammer.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                        Text("版本 1.0.0 · 积木化 iOS dylib 学习工坊")
                            .font(.system(size: 12.5))
                            .foregroundStyle(Theme.textSecondary)
                        Text("免责声明：本应用仅用于学习动态链接与 Runtime 技术，请在合法范围内使用，遵守当地法律与相关软件服务条款。")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textFaint)
                            .lineSpacing(4)
                    }
                }
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .sheet(isPresented: $showAI) {
            AISettingsView()
        }
        .confirmationDialog("清空所有项目？此操作不可撤销。", isPresented: $showClearConfirm, titleVisibility: .visible) {
            Button("清空", role: .destructive) {
                store.clearAll()
                toast = "已清空所有项目"
            }
            Button("取消", role: .cancel) {}
        }
        .toast($toast)
    }
}

// AI 配置页

struct AISettingsView: View {
    @EnvironmentObject var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss

    @State private var showKey = false
    @State private var testing = false
    @State private var testResult: String?
    @State private var testOK = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("AI 配置")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(Theme.surface2))
                }
            }
            .padding(18)

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    field("服务商") {
                        HStack(spacing: 8) {
                            ForEach(AIProvider.allCases) { p in
                                let isSel = settings.provider == p
                                Button {
                                    haptic(.light)
                                    settings.provider = p
                                    settings.applyProviderPreset()
                                } label: {
                                    Text(p.displayName)
                                        .font(.system(size: 12.5, weight: .semibold))
                                        .foregroundStyle(isSel ? Theme.accent : Theme.textSecondary)
                                        .padding(.horizontal, 11)
                                        .padding(.vertical, 7)
                                        .background(
                                            Capsule().fill(isSel ? Theme.accentSoft : Theme.surface2)
                                        )
                                }
                            }
                        }
                    }

                    field("API 地址") {
                        TextField("https://api.example.com/v1", text: $settings.baseURL)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundStyle(Theme.textPrimary)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Theme.surface2))
                            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.border, lineWidth: 1))
                    }

                    field("API Key") {
                        HStack {
                            Group {
                                if showKey {
                                    TextField(settings.provider.keyPlaceholder, text: $settings.apiKey)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled()
                                } else {
                                    SecureField(settings.provider.keyPlaceholder, text: $settings.apiKey)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled()
                                }
                            }
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundStyle(Theme.textPrimary)

                            Button {
                                showKey.toggle()
                            } label: {
                                Image(systemName: showKey ? "eye.slash" : "eye")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Theme.textFaint)
                            }
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Theme.surface2))
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.border, lineWidth: 1))
                    }

                    field("模型名称") {
                        TextField(settings.provider.defaultModel, text: $settings.model)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundStyle(Theme.textPrimary)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Theme.surface2))
                            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.border, lineWidth: 1))
                    }

                    PillButton(testing ? "测试中…" : "测试连接", icon: "bolt") {
                        Task {
                            testing = true
                            testResult = nil
                            let result = await StreamingClient.quickTest(config: settings.activeConfig)
                            switch result {
                            case .success(let msg):
                                testOK = true
                                testResult = msg
                            case .failure(let err):
                                testOK = false
                                testResult = err.localizedDescription
                            }
                            testing = false
                        }
                    }
                    .disabled(testing)

                    if let testResult {
                        Label(testResult, systemImage: testOK ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundStyle(testOK ? Theme.mint : Theme.danger)
                            .lineSpacing(3)
                    }

                    Text("Key 仅保存在本机（优先 Keychain）。支持所有 OpenAI 兼容接口：OpenAI、DeepSeek、Moonshot、Ollama、本地代理等。")
                        .font(.system(size: 11.5))
                        .foregroundStyle(Theme.textFaint)
                        .lineSpacing(4)
                }
                .padding(18)
            }
        }
        .background(Theme.bg)
    }

    private func field(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
            content()
        }
    }
}
