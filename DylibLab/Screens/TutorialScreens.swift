import SwiftUI

// 教程列表与详情（含测验）

struct TutorialListScreen: View {
    @EnvironmentObject var settings: SettingsStore
    @State private var selected: Tutorial?

    private var levels: [(TutorialLevel, [Tutorial])] {
        TutorialLevel.allCases.map { level in
            (level, TutorialStore.all.filter { $0.level == level })
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(levels, id: \.0.rawValue) { level, tutorials in
                        levelSection(level, tutorials)
                    }
                }
                .padding(16)
                .padding(.bottom, 30)
            }
        }
        .fullScreenCover(item: $selected) { t in
            TutorialDetailScreen(tutorial: t)
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("教程中心")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text("从零到高级 · \(TutorialStore.all.count) 课 · 每课带测验")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text("已完成")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textFaint)
                Text("\(settings.completedLessons.count)/\(TutorialStore.all.count)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Theme.accent)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 12)
    }

    private func levelSection(_ level: TutorialLevel, _ tutorials: [Tutorial]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Circle().fill(Color(hex: level.color)).frame(width: 9, height: 9)
                Text(level.rawValue)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text("\(tutorials.count) 课")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textFaint)
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: 12)], spacing: 12) {
                ForEach(tutorials) { t in
                    tutorialCard(t)
                }
            }
        }
    }

    private func tutorialCard(_ t: Tutorial) -> some View {
        let done = settings.completedLessons.contains(t.id)
        return HStack(spacing: 13) {
            Image(systemName: t.icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color(hex: t.level.color))
                .frame(width: 42, height: 42)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: t.level.color).opacity(0.14))
                )
            VStack(alignment: .leading, spacing: 4) {
                Text(t.title)
                    .font(.system(size: 14.5, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                Text(t.summary)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(2)
            }
            Spacer()
            Image(systemName: done ? "checkmark.circle.fill" : "chevron.right")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(done ? Theme.mint : Theme.textFaint)
        }
        .padding(13)
        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.surface))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.border.opacity(0.8), lineWidth: 1))
        .contentShape(Rectangle())
        .pressable {
            selected = t
        }
    }
}

// MARK: 详情

struct TutorialDetailScreen: View {
    let tutorial: Tutorial

    @EnvironmentObject var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss

    @State private var quizChoice: Int?
    @State private var quizSubmitted = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                ForEach(Array(tutorial.sections.enumerated()), id: \.offset) { i, section in
                    sectionView(i + 1, section)
                }
                quizCard
            }
            .padding(18)
            .padding(.bottom, 40)
        }
        .background(Theme.bg.ignoresSafeArea())
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(Theme.surface2))
                }
                Spacer()
                Text("第 \(tutorial.id) 课")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.textFaint)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Theme.surface2))
            }
            HStack(spacing: 12) {
                Image(systemName: tutorial.icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color(hex: tutorial.level.color))
                    .frame(width: 50, height: 50)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: tutorial.level.color).opacity(0.14)))
                VStack(alignment: .leading, spacing: 4) {
                    Text(tutorial.title)
                        .font(.system(size: 21, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(tutorial.level.rawValue + " · " + tutorial.summary)
                        .font(.system(size: 12.5))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
    }

    private func sectionView(_ index: Int, _ section: TutorialSection) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("\(index)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 20, height: 20)
                    .background(Circle().fill(Theme.accentSoft))
                Text(section.title)
                    .font(.system(size: 15.5, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
            }
            MarkdownText(source: section.body)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(Theme.surface))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.border.opacity(0.7), lineWidth: 1))
    }

    private var quizCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.mint)
                Text("随堂测验")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                if quizSubmitted && settings.completedLessons.contains(tutorial.id) {
                    Label("已完成", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.mint)
                }
            }

            Text(tutorial.quiz.question)
                .font(.system(size: 14.5, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(Array(tutorial.quiz.options.enumerated()), id: \.offset) { i, option in
                let state = optionState(i)
                Button {
                    guard !quizSubmitted else { return }
                    haptic(.light)
                    quizChoice = i
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: state.icon)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(state.color)
                        Text(option)
                            .font(.system(size: 13.5, weight: .medium))
                            .foregroundStyle(Theme.textPrimary)
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(state.bg))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(state.border, lineWidth: state.selected ? 1.5 : 1)
                    )
                }
                .buttonStyle(.plain)
            }

            if !quizSubmitted {
                PillButton("提交答案", icon: "paperplane") {
                    guard let choice = quizChoice else { return }
                    withAnimation(Theme.spring) { quizSubmitted = true }
                    if choice == tutorial.quiz.answer {
                        hapticNotify(.success)
                        settings.completedLessons.insert(tutorial.id)
                    } else {
                        hapticNotify(.error)
                    }
                }
                .disabled(quizChoice == nil)
                .opacity(quizChoice == nil ? 0.5 : 1)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text(quizChoice == tutorial.quiz.answer ? "回答正确 🎉" : "再想想：正确答案是「\(tutorial.quiz.options[tutorial.quiz.answer])」")
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundStyle(quizChoice == tutorial.quiz.answer ? Theme.mint : Theme.accent)
                    Text(tutorial.quiz.explanation)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textSecondary)
                        .lineSpacing(4)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 12).fill(Theme.surface2))
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Theme.surface))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.border.opacity(0.7), lineWidth: 1))
    }

    private func optionState(_ i: Int) -> (icon: String, color: Color, bg: Color, border: Color, selected: Bool) {
        let isChosen = quizChoice == i
        if !quizSubmitted {
            return isChosen
                ? ("circle.inset.filled", Theme.accent, Theme.accentSoft, Theme.accent, true)
                : ("circle", Theme.textFaint, Theme.bg, Theme.border, false)
        }
        if i == tutorial.quiz.answer {
            return ("checkmark.circle.fill", Theme.mint, Theme.mint.opacity(0.12), Theme.mint, isChosen)
        }
        if isChosen {
            return ("xmark.circle.fill", Theme.danger, Theme.danger.opacity(0.12), Theme.danger, true)
        }
        return ("circle", Theme.textFaint, Theme.bg, Theme.border, false)
    }
}
