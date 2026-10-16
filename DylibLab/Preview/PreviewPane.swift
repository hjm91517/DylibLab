import SwiftUI

// 预览面板：模拟 iPhone 桌面，把 tweak 效果「演」出来，可交互

struct PreviewPane: View {
    let effects: PreviewEffects
    let targetApp: String

    @State private var logs: [PreviewLog] = []
    @State private var showBanner = false
    @State private var bannerTask: Task<Void, Never>?

    struct PreviewLog: Identifiable {
        let id = UUID()
        let time: String
        let text: String
    }

    private let apps: [(name: String, icon: String, color: UInt32)] = [
        ("信息", "message.fill", 0x34C759),
        ("相机", "camera.fill", 0x5856D6),
        ("照片", "photo.on.rectangle", 0xFF9500),
        ("设置", "gearshape.fill", 0x8E8E93),
        ("Safari", "safari.fill", 0x007AFF),
        ("音乐", "music.note", 0xFF2D55),
        ("邮件", "envelope.fill", 0x1AD6FD),
        ("时钟", "clock.fill", 0x171717),
    ]

    private var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }

    var body: some View {
        VStack(spacing: 12) {
            header
            device
            controls
            console
        }
        .padding(14)
        .background(Theme.surface)
    }

    // MARK: 头部

    private var header: some View {
        HStack(spacing: 8) {
            chip(targetApp, icon: "scope", color: Theme.blue)
            ForEach(effects.hookedClasses.prefix(3), id: \.self) { cls in
                chip(cls, icon: "link", color: Theme.violet)
            }
            if effects.hasLog {
                chip("日志开启", icon: "terminal", color: Theme.mint)
            }
            Spacer()
        }
    }

    private func chip(_ text: String, icon: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 10, weight: .bold))
            Text(text).font(.system(size: 11.5, weight: .semibold))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(color.opacity(0.12)))
        .overlay(Capsule().strokeBorder(color.opacity(0.35), lineWidth: 1))
    }

    // MARK: 模拟设备

    private var device: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 46, style: .continuous)
                .fill(Color(hex: 0x05070A))
            VStack(spacing: 0) {
                statusBar
                screen
            }
            .padding(7)
        }
        .frame(width: 264, height: 520)
        .shadow(color: .black.opacity(0.45), radius: 18, y: 10)
    }

    private var statusBar: some View {
        HStack {
            Text(effects.statusText)
                .font(.system(size: 11.5, weight: .bold))
                .foregroundStyle(.white)
            Spacer()
            HStack(spacing: 3) {
                Image(systemName: "cellularbars").font(.system(size: 9))
                Image(systemName: "wifi").font(.system(size: 9))
                Image(systemName: "battery.75").font(.system(size: 10))
            }
            .foregroundStyle(.white)
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 5)
        .background(Color(hex: 0x0A0D12))
    }

    private var screen: some View {
        ZStack {
            LinearGradient(
                colors: [effects.wallpaper, effects.wallpaper.opacity(0.72)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack {
                Spacer()
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 14) {
                    ForEach(0..<8, id: \.self) { i in appIcon(i, showBadge: i == 1) }
                }
                .padding(.horizontal, 14)

                HStack(spacing: 14) {
                    ForEach(0..<4, id: \.self) { i in appIcon(i, showBadge: false) }
                }
                .padding(.vertical, 11)
                .padding(.horizontal, 14)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.white.opacity(0.16))
                )
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }

            if showBanner, let text = effects.bannerText {
                Text(text)
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.black.opacity(0.85))
                    )
                    .padding(.horizontal, 12)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.top, 10)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 40, style: .continuous))
        .overlay(alignment: .top) {
            Capsule()
                .fill(.black)
                .frame(width: 82, height: 21)
                .padding(.top, 8)
        }
    }

    private func appIcon(_ i: Int, showBadge: Bool) -> some View {
        let app = apps[i % apps.count]
        return Button {
            haptic(.light)
            simulateTap(app)
        } label: {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: app.color), Color(hex: app.color).opacity(0.72)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Image(systemName: app.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white)
                    if showBadge {
                        Text("3")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Circle().fill(effects.badge))
                            .offset(x: 5, y: -5)
                    }
                }
                .frame(width: 42, height: 42)
                Text(app.name)
                    .font(.system(size: 8.5, weight: .medium))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
    }

    private func simulateTap(_ app: (name: String, icon: String, color: UInt32)) {
        appendLog("\(targetApp): 用户点击了「\(app.name)」")
        if effects.hasLog {
            appendLog("%log → -[\(targetApp) applicationDidFinishLaunching] (参数: notification)")
        }
    }

    // MARK: 控制条

    private var controls: some View {
        HStack(spacing: 10) {
            PillButton("触发横幅", icon: "megaphone", filled: false, tint: Theme.mint) {
                triggerBanner()
            }
            PillButton("模拟点击", icon: "hand.tap", filled: false, tint: Theme.blue) {
                simulateTap(apps.randomElement() ?? apps[0])
            }
            Spacer()
            PillButton("清空日志", icon: "trash", filled: false, tint: Theme.textFaint) {
                withAnimation { logs = [] }
            }
        }
    }

    private func triggerBanner() {
        guard let text = effects.bannerText else {
            appendLog("⚠️ 代码里还没有 DLShowBanner，先添加「弹出横幅」积木")
            return
        }
        bannerTask?.cancel()
        withAnimation(Theme.spring) { showBanner = true }
        bannerTask = Task {
            try? await Task.sleep(nanoseconds: 2_600_000_000)
            if !Task.isCancelled {
                withAnimation(Theme.spring) { showBanner = false }
            }
        }
        appendLog("DLShowBanner: \(text)")
    }

    // MARK: 控制台

    private var console: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Label("运行日志", systemImage: "terminal")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Text("\(logs.count) 条")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textFaint)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Rectangle().fill(Theme.border).frame(height: 1)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 5) {
                        if logs.isEmpty {
                            Text("暂无日志 — 点击下方按钮与桌面图标进行交互")
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.textFaint)
                                .padding(.top, 8)
                        }
                        ForEach(logs) { log in
                            HStack(alignment: .top, spacing: 8) {
                                Text(log.time)
                                    .foregroundStyle(Theme.textFaint)
                                Text(log.text)
                                    .foregroundStyle(Theme.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .font(.system(size: 11, design: .monospaced))
                        }
                    }
                    .padding(12)
                }
                .onChange(of: logs.count) { _ in
                    if let last = logs.last {
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
        }
        .frame(maxHeight: 150)
        .background(Theme.bg)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Theme.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func appendLog(_ text: String) {
        logs.append(PreviewLog(time: timeFormatter.string(from: Date()), text: text))
        if logs.count > 120 {
            logs.removeFirst(logs.count - 120)
        }
    }
}
