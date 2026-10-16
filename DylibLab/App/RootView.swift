import SwiftUI

struct RootView: View {
    enum Tab: String, CaseIterable {
        case projects, tutorials, ai, settings

        var title: String {
            switch self {
            case .projects: return "项目"
            case .tutorials: return "教程"
            case .ai: return "AI 助手"
            case .settings: return "设置"
            }
        }

        var icon: String {
            switch self {
            case .projects: return "square.grid.2x2"
            case .tutorials: return "graduationcap"
            case .ai: return "sparkles"
            case .settings: return "gearshape"
            }
        }
    }

    @State private var tab: Tab = .projects
    @Namespace private var ns

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch tab {
                case .projects: ProjectsScreen()
                case .tutorials: TutorialListScreen()
                case .ai: AIScreen()
                case .settings: SettingsScreen()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, 74)

            FloatingTabBar(selection: $tab, ns: ns)
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
        }
        .background(Theme.bg.ignoresSafeArea())
        .animation(.easeOut(duration: 0.15), value: tab)
    }
}

struct FloatingTabBar: View {
    @Binding var selection: RootView.Tab
    let ns: Namespace.ID

    var body: some View {
        HStack(spacing: 4) {
            ForEach(RootView.Tab.allCases, id: \.self) { t in
                let isSel = selection == t
                Button {
                    haptic(.light)
                    withAnimation(Theme.spring) { selection = t }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: t.icon)
                            .font(.system(size: 18, weight: .semibold))
                        Text(t.title)
                            .font(.system(size: 10.5, weight: .semibold))
                    }
                    .foregroundStyle(isSel ? Theme.accent : Theme.textFaint)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background {
                        if isSel {
                            Capsule()
                                .fill(Theme.accentSoft)
                                .matchedGeometryEffect(id: "tab", in: ns)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(5)
        .background(
            Capsule().fill(Theme.surface)
        )
        .overlay(
            Capsule().strokeBorder(Theme.border, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.5), radius: 18, y: 8)
    }
}
