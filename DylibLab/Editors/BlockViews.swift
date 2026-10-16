import SwiftUI
import UniformTypeIdentifiers

// 积木编辑器：左侧积木面板（拖出），右侧画布（拖入排序）

struct BlockPill: View {
    let kind: BlockKind
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: kind.icon)
                .font(.system(size: compact ? 10 : 11, weight: .bold))
            Text(kind.displayName)
                .font(.system(size: compact ? 11.5 : 12.5, weight: .semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, compact ? 9 : 12)
        .padding(.vertical, compact ? 6 : 9)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(hex: kind.category.color))
        )
        .shadow(color: .black.opacity(0.25), radius: 3, y: 2)
    }
}

struct BlockEditorView: View {
    @Binding var blocks: [Block]
    var onGenerate: () -> Void

    @State private var selectedID: UUID?
    @State private var targetedIndex: Int?
    @State private var showClearConfirm = false

    var body: some View {
        HStack(spacing: 0) {
            palette
            Rectangle().fill(Theme.border).frame(width: 1)
            canvas
        }
    }

    // MARK: 积木面板

    private var palette: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Label("积木面板", systemImage: "shippingbox")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
            }
            .padding(14)

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(BlockCategory.allCases, id: \.self) { cat in
                        let kinds = BlockKind.allCases.filter { $0.category == cat }
                        if !kinds.isEmpty {
                            Text(cat.rawValue)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Theme.textFaint)
                                .padding(.leading, 2)
                            VStack(spacing: 8) {
                                ForEach(kinds, id: \.self) { kind in
                                    paletteItem(kind)
                                }
                            }
                        }
                    }
                    Text("提示：按住积木拖到右侧画布")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textFaint)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 8)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 20)
            }
        }
        .frame(width: 232)
        .background(Theme.surface)
    }

    private func paletteItem(_ kind: BlockKind) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            BlockPill(kind: kind, compact: true)
            Text(kind.desc)
                .font(.system(size: 10.5))
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.bg)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Theme.border.opacity(0.8), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .onDrag {
            NSItemProvider(object: DragPayload.copy(Block.new(kind)) as NSString)
        }
    }

    // MARK: 画布

    private var canvas: some View {
        VStack(spacing: 0) {
            toolbar
            Rectangle().fill(Theme.border).frame(height: 1)
            ScrollView {
                LazyVStack(spacing: 10) {
                    if blocks.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "hand.draw")
                                .font(.system(size: 30))
                                .foregroundStyle(Theme.textFaint)
                            Text("从左侧拖一块「Hook 类」进来开始搭建")
                                .font(.system(size: 13))
                                .foregroundStyle(Theme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 70)
                    }
                    ForEach(Array(blocks.enumerated()), id: \.element.id) { idx, block in
                        BlockRowView(
                            block: block,
                            depth: 0,
                            isSelected: selectedID == block.id,
                            isTargeted: targetedIndex == idx,
                            onSelect: { selectedID = block.id },
                            onUpdate: { updated in
                                blocks[idx] = updated
                            }
                        )
                        .onDrag {
                            NSItemProvider(object: DragPayload.move(block) as NSString)
                        }
                        .onDrop(of: [.text], delegate: RowDropDelegate(
                            index: idx,
                            onEnter: { targetedIndex = idx },
                            onExit: { if targetedIndex == idx { targetedIndex = nil } },
                            onInsert: { i, payload in
                                insert(at: i, payload: payload)
                            }
                        ))
                    }

                    // 尾部插入区
                    Color.clear
                        .frame(height: 90)
                        .overlay {
                            if targetedIndex == blocks.count {
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(Theme.accent, style: StrokeStyle(lineWidth: 2, dash: [6]))
                            }
                        }
                        .contentShape(Rectangle())
                        .onDrop(of: [.text], delegate: RowDropDelegate(
                            index: blocks.count,
                            onEnter: { targetedIndex = blocks.count },
                            onExit: { if targetedIndex == blocks.count { targetedIndex = nil } },
                            onInsert: { i, payload in
                                insert(at: i, payload: payload)
                            }
                        ))
                }
                .padding(16)
            }
            .onTapGesture { selectedID = nil }
        }
        .background(Theme.bg)
    }

    private var toolbar: some View {
        HStack(spacing: 10) {
            Menu {
                ForEach(BlockKind.allCases, id: \.self) { kind in
                    Button {
                        var b = Block.new(kind)
                        b.id = UUID()
                        blocks.append(b)
                        selectedID = b.id
                    } label: {
                        Label(kind.displayName, systemImage: kind.icon)
                    }
                }
            } label: {
                Label("添加积木", systemImage: "plus")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(Theme.surface2))
            }

            toolbarButton("复制", icon: "doc.on.doc", disabled: selectedID == nil) {
                guard let i = blocks.firstIndex(where: { $0.id == selectedID }) else { return }
                var copy = blocks[i]
                copy.id = UUID()
                blocks.insert(copy, at: i + 1)
            }
            toolbarButton("删除", icon: "trash", disabled: selectedID == nil) {
                guard let i = blocks.firstIndex(where: { $0.id == selectedID }) else { return }
                blocks.remove(at: i)
                selectedID = nil
            }
            toolbarButton("清空", icon: "xmark.bin", disabled: blocks.isEmpty) {
                showClearConfirm = true
            }

            Spacer()

            PillButton("生成代码", icon: "wand.and.stars") {
                haptic(.medium)
                onGenerate()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Theme.surface)
        .confirmationDialog("清空所有积木？此操作不可撤销。", isPresented: $showClearConfirm, titleVisibility: .visible) {
            Button("清空", role: .destructive) {
                blocks = []
                selectedID = nil
            }
            Button("取消", role: .cancel) {}
        }
    }

    private func toolbarButton(_ title: String, icon: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            haptic(.light)
            action()
        } label: {
            Label(title, systemImage: icon)
                .font(.system(size: 12.5, weight: .medium))
                .foregroundStyle(disabled ? Theme.textFaint : Theme.textSecondary)
                .padding(.horizontal, 9)
                .padding(.vertical, 7)
                .background(Capsule().fill(Theme.surface2.opacity(disabled ? 0.5 : 1)))
        }
        .disabled(disabled)
    }

    private func insert(at index: Int, payload: (mode: String, id: UUID?, block: Block)) {
        var block = payload.block
        withAnimation(Theme.spring) {
            if payload.mode == "m", let srcID = payload.id,
               let srcIndex = blocks.firstIndex(where: { $0.id == srcID }) {
                blocks.remove(at: srcIndex)
                let adjusted = index > srcIndex ? index - 1 : index
                blocks.insert(block, at: min(max(adjusted, 0), blocks.count))
            } else {
                block.id = UUID()
                blocks.insert(block, at: min(max(index, 0), blocks.count))
            }
            targetedIndex = nil
        }
        haptic(.medium)
    }
}

struct RowDropDelegate: DropDelegate {
    let index: Int
    var onEnter: (() -> Void)?
    var onExit: (() -> Void)?
    let onInsert: (Int, (mode: String, id: UUID?, block: Block)) -> Void

    func dropEntered(info: DropInfo) { onEnter?() }

    func dropExited(info: DropInfo) { onExit?() }

    func performDrop(info: DropInfo) -> Bool {
        guard let provider = info.itemProviders(for: [.text]).first else { return false }
        provider.loadObject(ofClass: NSString.self) { obj, _ in
            guard let s = obj as? String, let payload = DragPayload.decode(s) else { return }
            DispatchQueue.main.async {
                onInsert(index, payload)
            }
        }
        return true
    }
}

// MARK: 积木行

struct BlockRowView: View {
    let block: Block
    let depth: Int
    let isSelected: Bool
    let isTargeted: Bool
    var onSelect: () -> Void
    var onUpdate: (Block) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            mainRow
            if !block.children.isEmpty {
                HStack(alignment: .top, spacing: 10) {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color(hex: block.kind.category.color).opacity(0.6))
                        .frame(width: 3)
                        .padding(.top, 4)
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(block.children.indices, id: \.self) { i in
                            BlockRowView(
                                block: block.children[i],
                                depth: depth + 1,
                                isSelected: false,
                                isTargeted: false,
                                onSelect: {},
                                onUpdate: { updated in
                                    var b = block
                                    b.children[i] = updated
                                    onUpdate(b)
                                }
                            )
                        }
                    }
                }
                .padding(.leading, 10)
            }
        }
        .overlay(alignment: .top) {
            if isTargeted {
                Rectangle()
                    .fill(Theme.accent)
                    .frame(height: 2.5)
                    .offset(y: -6)
                    .cornerRadius(2)
            }
        }
    }

    private var mainRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white.opacity(0.5))

            HStack(spacing: 7) {
                Image(systemName: block.kind.icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                ForEach(Array(block.kind.inputs.enumerated()), id: \.offset) { _, def in
                    HStack(spacing: 3) {
                        Text(def.label)
                            .font(.system(size: 9.5, weight: .medium))
                            .foregroundStyle(.white.opacity(0.65))
                        TextField(def.placeholder, text: Binding(
                            get: { block.inputs[def.key] ?? "" },
                            set: { v in
                                var b = block
                                b.inputs[def.key] = v
                                onUpdate(b)
                            }
                        ))
                        .font(.system(size: 11.5, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.black.opacity(0.28)))
                        .frame(width: inputWidth(for: def.key))
                    }
                }
                if block.kind == .method {
                    // 实例/类方法切换
                    Menu {
                        Button("实例方法 (-)") { setMethodType("-") }
                        Button("类方法 (+)") { setMethodType("+") }
                    } label: {
                        Text((block.inputs["isClass"] == "+") ? "+" : "-")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.black.opacity(0.28)))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(hex: block.kind.category.color))
            )

            Menu {
                ForEach(BlockKind.allCases, id: \.self) { kind in
                    Button {
                        var b = block
                        b.children.append(Block.new(kind))
                        onUpdate(b)
                    } label: {
                        Label(kind.displayName, systemImage: kind.icon)
                    }
                }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(.leading, CGFloat(depth) * 4)
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .strokeBorder(isSelected ? Theme.accent : .clear, lineWidth: 1.5)
        )
    }

    private func inputWidth(for key: String) -> CGFloat {
        switch key {
        case "className", "name": return 130
        case "condition": return 90
        case "text": return 100
        case "value": return 70
        case "method": return 90
        default: return 70
        }
    }

    private func setMethodType(_ type: String) {
        var b = block
        b.inputs["isClass"] = type
        onUpdate(b)
    }
}
