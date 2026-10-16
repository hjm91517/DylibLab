import SwiftUI
import UIKit

// 通用小组件：卡片、胶囊按钮、分段选择器、代码块、空状态等。

struct Card<Content: View>: View {
    var padding: CGFloat = 16
    let content: Content

    init(padding: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                    .fill(Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                    .strokeBorder(Theme.border.opacity(0.7), lineWidth: 1)
            )
    }
}

struct PillButton: View {
    let title: String
    let icon: String?
    var filled: Bool = true
    var tint: Color = Theme.accent
    let action: () -> Void

    init(_ title: String, icon: String? = nil, filled: Bool = true, tint: Color = Theme.accent, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.filled = filled
        self.tint = tint
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon { Image(systemName: icon).font(.system(size: 13, weight: .semibold)) }
                Text(title).font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(filled ? Color(hex: 0x14100A) : tint)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                Capsule().fill(filled ? tint : tint.opacity(0.12))
            )
            .overlay(Capsule().strokeBorder(tint.opacity(filled ? 0 : 0.4), lineWidth: 1))
        }
        .buttonStyle(PressableButtonStyle())
    }
}

struct Segmented: View {
    let options: [String]
    let icons: [String]
    @Binding var selection: Int
    @Namespace private var ns

    init(_ options: [String], icons: [String] = [], selection: Binding<Int>) {
        self.options = options
        self.icons = icons.isEmpty ? Array(repeating: "", count: options.count) : icons
        _selection = selection
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(options.indices, id: \.self) { i in
                Button {
                    haptic(.light)
                    withAnimation(Theme.spring) { selection = i }
                } label: {
                    HStack(spacing: 5) {
                        if !icons[i].isEmpty {
                            Image(systemName: icons[i]).font(.system(size: 12, weight: .semibold))
                        }
                        Text(options[i]).font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(selection == i ? Theme.textPrimary : Theme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background {
                        if selection == i {
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(Theme.surface2)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                                        .strokeBorder(Theme.border, lineWidth: 1)
                                )
                                .matchedGeometryEffect(id: "seg", in: ns)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.bg))
    }
}

struct CodeBlockView: View {
    let code: String
    var lang: String? = nil
    var onApply: (() -> Void)? = nil
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                if let lang, !lang.isEmpty {
                    Text(lang)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.accent)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Theme.accentSoft))
                }
                Spacer()
                Button {
                    UIPasteboard.general.string = code
                    withAnimation { copied = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                        withAnimation { copied = false }
                    }
                    haptic(.light)
                } label: {
                    Label(copied ? "已复制" : "复制", systemImage: copied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                }
                if let onApply {
                    Button {
                        haptic(.medium)
                        onApply()
                    } label: {
                        Label("应用到项目", systemImage: "wand.and.stars")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.accent)
                    }
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(.system(size: 12.5, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary)
                    .textSelection(.enabled)
                    .padding(.bottom, 2)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(hex: 0x0B0E13))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Theme.border.opacity(0.6), lineWidth: 1)
        )
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Theme.surface)
                    .frame(width: 88, height: 88)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .strokeBorder(Theme.border, lineWidth: 1)
                    )
                Image(systemName: icon)
                    .font(.system(size: 34, weight: .medium))
                    .foregroundStyle(Theme.accent)
            }
            VStack(spacing: 6) {
                Text(title).font(.system(size: 17, weight: .bold)).foregroundStyle(Theme.textPrimary)
                Text(subtitle)
                    .font(.system(size: 13.5))
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            if let actionTitle, let action {
                PillButton(actionTitle, icon: "plus", action: action)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

struct ToastView: View {
    let message: String
    var body: some View {
        Label(message, systemImage: "checkmark.circle.fill")
            .font(.system(size: 13.5, weight: .semibold))
            .foregroundStyle(Theme.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .background(
                Capsule().fill(Theme.surface2)
            )
            .overlay(
                Capsule().strokeBorder(Theme.border, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.4), radius: 14, y: 6)
    }
}

extension View {
    func toast(_ message: Binding<String?>) -> some View {
        overlay(alignment: .bottom) {
            if let msg = message.wrappedValue {
                ToastView(message: msg)
                    .padding(.bottom, 28)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(Theme.spring, value: message.wrappedValue)
    }
}
