import SwiftUI
import UIKit

// 设计系统：深色「工坊」风格。颜色、圆角、动效全部从这里控制。
enum Theme {
    // 背景层级
    static let bg        = Color(hex: 0x0D1016)
    static let surface   = Color(hex: 0x151A22)
    static let surface2  = Color(hex: 0x1D232E)
    static let border    = Color(hex: 0x29303D)

    // 文本
    static let textPrimary   = Color(hex: 0xE9EDF4)
    static let textSecondary = Color(hex: 0x8B96A8)
    static let textFaint     = Color(hex: 0x5A6472)

    // 强调色（琥珀）
    static let accent     = Color(hex: 0xF5A623)
    static let accentSoft = Color(hex: 0xF5A623).opacity(0.16)
    static let mint       = Color(hex: 0x4FD1C5)
    static let blue       = Color(hex: 0x5B8DEF)
    static let violet     = Color(hex: 0x8B7CF0)
    static let pink       = Color(hex: 0xF472B6)
    static let danger     = Color(hex: 0xF87171)

    static let radius: CGFloat = 16

    static let spring = Animation.spring(response: 0.32, dampingFraction: 0.82)
    static let quick  = Animation.easeOut(duration: 0.18)
}

func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
    UIImpactFeedbackGenerator(style: style).impactOccurred()
}

func hapticNotify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
    UINotificationFeedbackGenerator().notificationOccurred(type)
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }

    init?(hexString: String) {
        var s = hexString.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = UInt32(s, radix: 16) else { return nil }
        self.init(hex: v)
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    func pressable(_ action: @escaping () -> Void) -> some View {
        Button(action: {
            haptic(.light)
            action()
        }) { self }
        .buttonStyle(PressableButtonStyle())
    }
}

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.965 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}
