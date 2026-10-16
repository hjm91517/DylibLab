import Foundation

// 积木模型：积木是 Tweak.xm 的可视化表示，可一键生成 Logos 代码。

enum BlockCategory: String, CaseIterable {
    case structure = "结构"
    case action = "动作"
    case logic = "逻辑"
    case data = "数据"
    case misc = "其他"

    var color: UInt32 {
        switch self {
        case .structure: return 0x8B7CF0
        case .action: return 0x4FD1C5
        case .logic: return 0xF5A623
        case .data: return 0xF472B6
        case .misc: return 0x64748B
        }
    }
}

enum BlockKind: String, Codable, CaseIterable, Identifiable {
    case hook, method
    case orig, log, setWallpaper, setBadge, setStatus, showBanner, callMethod
    case ifBlock, returnBlock
    case variable
    case comment

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .hook: return "Hook 类"
        case .method: return "方法"
        case .orig: return "调用原方法"
        case .log: return "打印日志"
        case .setWallpaper: return "设置壁纸"
        case .setBadge: return "设置角标"
        case .setStatus: return "设置状态栏"
        case .showBanner: return "弹出横幅"
        case .callMethod: return "调用方法"
        case .ifBlock: return "如果"
        case .returnBlock: return "返回"
        case .variable: return "变量"
        case .comment: return "注释"
        }
    }

    var icon: String {
        switch self {
        case .hook: return "link"
        case .method: return "function"
        case .orig: return "arrow.uturn.backward"
        case .log: return "terminal"
        case .setWallpaper: return "photo"
        case .setBadge: return "number.circle"
        case .setStatus: return "textformat.abc"
        case .showBanner: return "megaphone"
        case .callMethod: return "arrow.right.circle"
        case .ifBlock: return "arrow.triangle.branch"
        case .returnBlock: return "return"
        case .variable: return "cylinder"
        case .comment: return "text.bubble"
        }
    }

    var category: BlockCategory {
        switch self {
        case .hook, .method: return .structure
        case .orig, .log, .setWallpaper, .setBadge, .setStatus, .showBanner, .callMethod: return .action
        case .ifBlock, .returnBlock: return .logic
        case .variable: return .data
        case .comment: return .misc
        }
    }

    var desc: String {
        switch self {
        case .hook: return "hook 一个类，其内部方法会被替换"
        case .method: return "放在 Hook 类内部，替换原方法实现"
        case .orig: return "%orig; 调用原实现，避免破坏原有行为"
        case .log: return "%log; 打印调用日志，调试神器"
        case .setWallpaper: return "调用 DLSetWallpaper 修改主窗口背景"
        case .setBadge: return "调用 DLSetBadge 设置角标颜色"
        case .setStatus: return "调用 DLSetStatus 设置状态栏文字"
        case .showBanner: return "调用 DLShowBanner 弹出横幅提示"
        case .callMethod: return "向对象发送消息（ObjC 方法调用）"
        case .ifBlock: return "条件成立时执行内部积木"
        case .returnBlock: return "提前返回值并结束方法"
        case .variable: return "声明一个局部变量"
        case .comment: return "代码注释，不影响运行"
        }
    }

    var inputs: [InputDef] {
        switch self {
        case .hook: return [InputDef("类名", "className", "SpringBoard")]
        case .method: return [
            InputDef("返回", "returnType", "void"),
            InputDef("方法名", "name", "applicationDidFinishLaunching"),
            InputDef("参数", "args", ""),
        ]
        case .orig, .log: return []
        case .setWallpaper: return [InputDef("颜色", "color", "#14213D")]
        case .setBadge: return [InputDef("颜色", "color", "#F5A623")]
        case .setStatus: return [InputDef("文字", "text", "DylibLab 在线")]
        case .showBanner: return [InputDef("文字", "text", "Hello, DylibLab")]
        case .callMethod: return [InputDef("目标", "target", "self"), InputDef("方法", "method", "reloadData")]
        case .ifBlock: return [InputDef("条件", "condition", "YES")]
        case .returnBlock: return [InputDef("值", "value", "nil")]
        case .variable: return [InputDef("类型", "type", "NSString *"), InputDef("名称", "name", "text"), InputDef("初始值", "value", "@\"hi\"")]
        case .comment: return [InputDef("内容", "text", "这是一个注释")]
        }
    }
}

struct InputDef {
    let label: String
    let key: String
    let placeholder: String

    init(_ label: String, _ key: String, _ placeholder: String) {
        self.label = label
        self.key = key
        self.placeholder = placeholder
    }
}

struct Block: Identifiable, Codable {
    var id: UUID = UUID()
    var kind: BlockKind
    var inputs: [String: String] = [:]
    var children: [Block] = []

    static func new(_ kind: BlockKind, _ inputs: [String: String] = [:]) -> Block {
        var b = Block(kind: kind)
        for def in kind.inputs {
            b.inputs[def.key] = inputs[def.key] ?? def.placeholder
        }
        return b
    }
}

// 拖拽载荷：从积木面板拷贝 / 在画布内移动
enum DragPayload {
    static func copy(_ block: Block) -> String {
        "c|" + (try! JSONEncoder().encode(block).base64EncodedString())
    }

    static func move(_ block: Block) -> String {
        "m|" + block.id.uuidString + "|" + (try! JSONEncoder().encode(block).base64EncodedString())
    }

    static func decode(_ s: String) -> (mode: String, id: UUID?, block: Block)? {
        let parts = s.components(separatedBy: "|")
        guard parts.count >= 2, let data = Data(base64Encoded: parts.last ?? ""),
              let block = try? JSONDecoder().decode(Block.self, from: data) else { return nil }
        if parts[0] == "m", parts.count >= 3, let id = UUID(uuidString: parts[1]) {
            return ("m", id, block)
        }
        return ("c", nil, block)
    }
}

// 积木 → Logos 代码生成器
enum BlockCodeGenerator {
    static func fullFile(projectName: String, blocks: [Block]) -> String {
        """
        // Tweak.xm — \(projectName)（由 DylibLab 积木生成）
        #import "DylibHelpers.h"

        \(generate(blocks))
        """
    }

    static func generate(_ blocks: [Block], depth: Int = 0) -> String {
        var out = ""
        let ind = String(repeating: "    ", count: depth)
        for b in blocks {
            switch b.kind {
            case .hook:
                out += ind + "%hook \(b.inputs["className"] ?? "SpringBoard")\n"
                for child in b.children {
                    if child.kind == .method {
                        out += generateMethod(child, depth: depth + 1)
                    } else if child.kind == .comment {
                        out += ind + "    // \(child.inputs["text"] ?? "")\n"
                    } else if child.kind == .hook {
                        out += ind + "    // ⚠️ %hook 不能嵌套在 %hook 内\n"
                    } else {
                        out += ind + "    // ⚠️ 「\(child.kind.displayName)」请放进「方法」积木内\n"
                    }
                }
                out += ind + "%end\n"
            case .comment:
                out += ind + "// \(b.inputs["text"] ?? "")\n"
            default:
                out += ind + "// ⚠️ 「\(b.kind.displayName)」请先放进一个 %hook 的方法里\n"
            }
        }
        return out
    }

    static func generateMethod(_ b: Block, depth: Int) -> String {
        let ind = String(repeating: "    ", count: depth)
        let prefix = (b.inputs["isClass"] == "+") ? "+" : "-"
        let ret = (b.inputs["returnType"] ?? "void").trimmingCharacters(in: .whitespaces)
        let name = b.inputs["name"] ?? "method"
        let args = (b.inputs["args"] ?? "").trimmingCharacters(in: .whitespaces)
        var sig = "\(prefix) (\(ret))\(name)"
        if !args.isEmpty { sig += ":\(args)" }
        var out = ind + sig + " {\n"
        out += statements(b.children, depth: depth + 1)
        out += ind + "}\n"
        return out
    }

    static func statements(_ blocks: [Block], depth: Int) -> String {
        var out = ""
        let ind = String(repeating: "    ", count: depth)
        for b in blocks {
            switch b.kind {
            case .orig:
                out += ind + "%orig;\n"
            case .log:
                out += ind + "%log;\n"
            case .setWallpaper:
                out += ind + "DLSetWallpaper(@\"\(b.inputs["color"] ?? "#14213D")\");\n"
            case .setBadge:
                out += ind + "DLSetBadge(@\"\(b.inputs["color"] ?? "#F5A623")\");\n"
            case .setStatus:
                out += ind + "DLSetStatus(@\"\(b.inputs["text"] ?? "DylibLab")\");\n"
            case .showBanner:
                out += ind + "DLShowBanner(@\"\(b.inputs["text"] ?? "Hello")\");\n"
            case .callMethod:
                out += ind + "[\(b.inputs["target"] ?? "self") \(b.inputs["method"] ?? "reloadData")];\n"
            case .variable:
                out += ind + "\(b.inputs["type"] ?? "id") \(b.inputs["name"] ?? "v") = \(b.inputs["value"] ?? "nil");\n"
            case .ifBlock:
                out += ind + "if (\(b.inputs["condition"] ?? "YES")) {\n"
                out += statements(b.children, depth: depth + 1)
                out += ind + "}\n"
            case .returnBlock:
                out += ind + "return \(b.inputs["value"] ?? "nil");\n"
            case .comment:
                out += ind + "// \(b.inputs["text"] ?? "")\n"
            default:
                out += ind + "// ⚠️ 该积木无法放在此处\n"
            }
        }
        return out
    }
}
