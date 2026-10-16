import SwiftUI

// 项目列表

struct ProjectsScreen: View {
    @EnvironmentObject var store: ProjectStore
    @State private var showCreate = false
    @State private var editing: DylibProject?

    var body: some View {
        VStack(spacing: 0) {
            header
            if store.projects.isEmpty {
                EmptyStateView(
                    icon: "square.grid.2x2",
                    title: "还没有项目",
                    subtitle: "从模板开始，用积木搭建你的第一个 tweak",
                    actionTitle: "新建项目"
                ) {
                    showCreate = true
                }
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 270), spacing: 14)], spacing: 14) {
                        ForEach(store.projects) { p in
                            projectCard(p)
                        }
                    }
                    .padding(16)
                }
            }
        }
        .sheet(isPresented: $showCreate) {
            CreateProjectSheet { newProject in
                editing = newProject
            }
        }
        .fullScreenCover(item: $editing) { project in
            EditorScreen(projectID: project.id)
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("我的项目")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text("积木搭建 · 代码精修 · 即时预览")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            PillButton("新建项目", icon: "plus") {
                showCreate = true
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 12)
    }

    private func projectCard(_ p: DylibProject) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "hammer.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 34, height: 34)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Theme.accentSoft))
                Spacer()
                Menu {
                    Button(role: .destructive) {
                        withAnimation { store.delete(id: p.id) }
                    } label: {
                        Label("删除项目", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.textFaint)
                        .frame(width: 28, height: 28)
                }
            }
            Text(p.name)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
            HStack(spacing: 6) {
                Label(p.targetApp, systemImage: "scope")
                Spacer()
                Text(p.updatedAt.formatted(date: .abbreviated, time: .shortened))
            }
            .font(.system(size: 11.5))
            .foregroundStyle(Theme.textFaint)
            HStack(spacing: 8) {
                tag("\(p.blocks.count) 积木", icon: "cube", color: Theme.violet)
                tag("\(p.files.count) 文件", icon: "doc", color: Theme.mint)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                .fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                .strokeBorder(Theme.border.opacity(0.8), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .pressable {
            editing = p
        }
    }

    private func tag(_ text: String, icon: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 9.5, weight: .bold))
            Text(text).font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(color.opacity(0.12)))
    }
}

// 新建项目（模板选择）

struct CreateProjectSheet: View {
    var onCreated: (DylibProject) -> Void

    @EnvironmentObject var store: ProjectStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var selectedTemplateID = ProjectTemplates.all[0].id

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("新建项目")
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

            VStack(alignment: .leading, spacing: 8) {
                Text("项目名称")
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
                TextField("例如：我的第一个 Tweak", text: $name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Theme.surface2))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.border, lineWidth: 1))
            }
            .padding(.horizontal, 18)

            VStack(alignment: .leading, spacing: 10) {
                Text("选择模板")
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(ProjectTemplates.all) { t in
                        templateCard(t)
                    }
                }
            }
            .padding(18)

            Spacer()

            PillButton("创建并开始搭建", icon: "arrow.right") {
                haptic(.medium)
                let template = ProjectTemplates.all.first { $0.id == selectedTemplateID } ?? ProjectTemplates.all[0]
                let project = store.create(from: template, name: name)
                onCreated(project)
                dismiss()
            }
            .padding(.bottom, 20)
        }
        .background(Theme.bg)
    }

    private func templateCard(_ t: ProjectTemplate) -> some View {
        let isSel = selectedTemplateID == t.id
        return VStack(alignment: .leading, spacing: 8) {
            Image(systemName: t.icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color(hex: t.tint))
                .frame(width: 36, height: 36)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(hex: t.tint).opacity(0.15)))
            Text(t.name)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text(t.subtitle)
                .font(.system(size: 11))
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14).fill(isSel ? Theme.surface2 : Theme.surface))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(isSel ? Theme.accent : Theme.border, lineWidth: isSel ? 1.5 : 1)
        )
        .contentShape(Rectangle())
        .pressable {
            selectedTemplateID = t.id
        }
    }
}
