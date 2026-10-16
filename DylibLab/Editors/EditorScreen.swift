import SwiftUI

// 编辑主界面：左侧编辑器（积木/代码切换），右侧实时预览
// iPad 分屏并排；iPhone 用「编辑 / 预览」分段切换

struct EditorScreen: View {
    let projectID: UUID

    @EnvironmentObject var store: ProjectStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var hSizeClass

    enum EditorMode { case blocks, code }
    enum EditorPane { case editor, preview }

    @State private var draft: DylibProject?
    @State private var mode: EditorMode = .blocks
    @State private var pane: EditorPane = .editor
    @State private var activeFileID: UUID?
    @State private var toast: String?

    var body: some View {
        Group {
            if let project = draft {
                content(project)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .toast($toast)
        .onAppear { load() }
        .onReceive(store.$projects) { _ in sync() }
    }

    // MARK: 数据同步

    private func load() {
        draft = store.project(projectID)
    }

    private func sync() {
        if let p = store.project(projectID), p.revision != draft?.revision {
            draft = p
        }
    }

    // MARK: 布局

    @ViewBuilder
    private func content(_ project: DylibProject) -> some View {
        VStack(spacing: 0) {
            topBar(project)
            Rectangle().fill(Theme.border).frame(height: 1)
            if hSizeClass == .compact {
                compactBody(project)
            } else {
                splitBody(project)
            }
        }
    }

    private func topBar(_ project: DylibProject) -> some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Theme.surface2))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(project.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text("目标进程 \(project.targetApp) · 更新于 \(project.updatedAt.formatted(date: .omitted, time: .shortened))")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textFaint)
            }

            Spacer()

            // 文件切换
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(project.files) { f in
                        let isActive = (activeFileID ?? project.activeFileID) == f.id
                        Button {
                            haptic(.light)
                            activeFileID = f.id
                        } label: {
                            Text(f.name)
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .foregroundStyle(isActive ? Theme.accent : Theme.textSecondary)
                                .padding(.horizontal, 11)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule().fill(isActive ? Theme.accentSoft : Theme.surface2)
                                )
                        }
                    }
                }
            }
            .frame(maxWidth: 280)

            Segmented(["积木", "代码"], icons: ["cube", "chevron.left.forwardslash.chevron.right"], selection: modeBinding)
                .frame(width: 180)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Theme.surface)
    }

    private var modeBinding: Binding<Int> {
        Binding(
            get: { mode == .blocks ? 0 : 1 },
            set: { mode = $0 == 0 ? .blocks : .code }
        )
    }

    private var paneBinding: Binding<Int> {
        Binding(
            get: { pane == .editor ? 0 : 1 },
            set: { pane = $0 == 0 ? .editor : .preview }
        )
    }

    private func splitBody(_ project: DylibProject) -> some View {
        HStack(spacing: 0) {
            editorPane(project)
                .frame(minWidth: 340, maxWidth: .infinity, maxHeight: .infinity)
            Rectangle().fill(Theme.border).frame(width: 1)
            PreviewPane(effects: previewEffects(project), targetApp: project.targetApp)
                .frame(width: 430)
        }
    }

    private func compactBody(_ project: DylibProject) -> some View {
        VStack(spacing: 0) {
            HStack {
                Segmented(["编辑", "预览"], icons: ["pencil", "eye"], selection: paneBinding)
                    .frame(width: 210)
                Spacer()
            }
            .padding(8)
            .background(Theme.surface)

            if pane == .editor {
                editorPane(project)
            } else {
                ScrollView {
                    PreviewPane(effects: previewEffects(project), targetApp: project.targetApp)
                }
            }
        }
    }

    // MARK: 编辑器

    private func editorPane(_ project: DylibProject) -> some View {
        VStack(spacing: 0) {
            switch mode {
            case .blocks:
                BlockEditorView(blocks: blocksBinding, onGenerate: generateCode)
            case .code:
                CodeEditorView(text: fileBinding)
            }
            footer(project)
        }
    }

    @ViewBuilder
    private func footer(_ project: DylibProject) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Rectangle().fill(Theme.border).frame(height: 1)
            HStack(spacing: 8) {
                if mode == .blocks {
                    Label("积木是源文件的可视化视图，点「生成代码」写入 Tweak.xm", systemImage: "info.circle")
                } else {
                    if isStale(project) {
                        Label("积木有未同步的改动，回积木模式点「生成代码」更新此文件", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(Theme.accent)
                    } else {
                        Label("直接编辑代码，修改自动保存", systemImage: "info.circle")
                    }
                }
                Spacer()
                Text(fileName)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Theme.textFaint)
            }
            .font(.system(size: 11.5))
            .foregroundStyle(Theme.textFaint)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(Theme.surface)
    }

    private var fileName: String {
        guard let p = draft else { return "" }
        let fid = activeFileID ?? p.activeFileID
        return p.file(id: fid)?.name ?? ""
    }

    private func isStale(_ project: DylibProject) -> Bool {
        let generated = BlockCodeGenerator.fullFile(projectName: project.name, blocks: project.blocks)
        guard let tweak = project.file(named: "Tweak.xm") else { return false }
        let fid = activeFileID ?? project.activeFileID
        guard fid == tweak.id else { return false }
        return tweak.content != generated
    }

    // MARK: 绑定与动作

    private var blocksBinding: Binding<[Block]> {
        Binding(
            get: { draft?.blocks ?? [] },
            set: { newValue in
                guard var p = draft else { return }
                p.blocks = newValue
                draft = store.update(p)
            }
        )
    }

    private var fileBinding: Binding<String> {
        Binding(
            get: {
                guard let p = draft else { return "" }
                let fid = activeFileID ?? p.activeFileID
                return p.file(id: fid)?.content ?? ""
            },
            set: { newValue in
                guard var p = draft else { return }
                let fid = activeFileID ?? p.activeFileID
                if let i = p.files.firstIndex(where: { $0.id == fid }) {
                    p.files[i].content = newValue
                    draft = store.update(p)
                }
            }
        )
    }

    private func generateCode() {
        guard var p = draft else { return }
        let code = BlockCodeGenerator.fullFile(projectName: p.name, blocks: p.blocks)
        if let i = p.files.firstIndex(where: { $0.name == "Tweak.xm" }) {
            p.files[i].content = code
            p.activeFileID = p.files[i].id
        } else {
            let f = DylibFile(name: "Tweak.xm", content: code)
            p.files.append(f)
            p.activeFileID = f.id
        }
        draft = store.update(p)
        activeFileID = p.activeFileID
        withAnimation(Theme.spring) { mode = .code }
        toast = "已从积木生成 Tweak.xm"
    }

    private func previewEffects(_ project: DylibProject) -> PreviewEffects {
        let source: String
        if mode == .blocks {
            source = BlockCodeGenerator.fullFile(projectName: project.name, blocks: project.blocks)
        } else {
            let fid = activeFileID ?? project.activeFileID
            source = project.file(id: fid)?.content ?? ""
        }
        return PreviewEngine.parse(source)
    }
}
