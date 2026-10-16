import Foundation
import SwiftUI

// 项目存储：JSON 持久化到 Documents/DylibLab/projects.json

@MainActor
final class ProjectStore: ObservableObject {
    @Published var projects: [DylibProject] = []

    private var fileURL: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("DylibLab", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("projects.json")
    }

    init() {
        load()
    }

    func project(_ id: UUID) -> DylibProject? {
        projects.first { $0.id == id }
    }

    @discardableResult
    func create(from template: ProjectTemplate, name: String) -> DylibProject {
        var p = template.build(projectName: name.isEmpty ? "未命名项目" : name)
        p.revision = UUID()
        projects.insert(p, at: 0)
        scheduleSave()
        return p
    }

    func delete(id: UUID) {
        projects.removeAll { $0.id == id }
        scheduleSave()
    }

    func clearAll() {
        projects = []
        scheduleSave()
    }

    @discardableResult
    func update(_ project: DylibProject) -> DylibProject {
        var p = project
        p.updatedAt = Date()
        p.revision = UUID()
        if let i = projects.firstIndex(where: { $0.id == p.id }) {
            projects[i] = p
        }
        scheduleSave()
        return p
    }

    @discardableResult
    func updateBlocks(projectID: UUID, blocks: [Block]) -> DylibProject? {
        guard var p = project(projectID) else { return nil }
        p.blocks = blocks
        return update(p)
    }

    @discardableResult
    func updateFile(projectID: UUID, fileID: UUID, content: String) -> DylibProject? {
        guard var p = project(projectID) else { return nil }
        if let i = p.files.firstIndex(where: { $0.id == fileID }) {
            p.files[i].content = content
        }
        return update(p)
    }

    private var saveWork: DispatchWorkItem?

    // 防抖保存：连续编辑（打字/拖积木）时合并写盘
    private func scheduleSave() {
        saveWork?.cancel()
        let w = DispatchWorkItem { [weak self] in
            self?.saveNow()
        }
        saveWork = w
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: w)
    }

    private func saveNow() {
        do {
            let data = try JSONEncoder().encode(projects)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("保存项目失败: \(error)")
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([DylibProject].self, from: data) else {
            projects = []
            return
        }
        projects = decoded
    }
}
