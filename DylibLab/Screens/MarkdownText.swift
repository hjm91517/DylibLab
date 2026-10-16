import SwiftUI

// 轻量 Markdown 渲染器：标题 / 段落 / 列表 / 代码块 / 行内加粗与行内代码

struct MDBlock: Identifiable {
    let id = UUID()
    enum Kind {
        case heading(Int, String)
        case para(String)
        case bullet(String)
        case code(String, String)
    }
    var kind: Kind
}

struct MarkdownText: View {
    let source: String

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            ForEach(Self.parse(source)) { b in
                blockView(b)
            }
        }
    }

    @ViewBuilder
    private func blockView(_ b: MDBlock) -> some View {
        switch b.kind {
        case .heading(let level, let text):
            Self.inline(text)
                .font(.system(size: level == 1 ? 19 : 16, weight: .bold))
                .foregroundColor(Theme.textPrimary)
                .padding(.top, level == 1 ? 8 : 4)
        case .para(let text):
            Self.inline(text)
                .font(.system(size: 14.5))
                .foregroundColor(Theme.textSecondary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        case .bullet(let text):
            HStack(alignment: .top, spacing: 8) {
                Circle()
                    .fill(Theme.accent)
                    .frame(width: 5, height: 5)
                    .padding(.top, 8)
                Self.inline(text)
                    .font(.system(size: 14.5))
                    .foregroundColor(Theme.textSecondary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        case .code(let code, let lang):
            CodeBlockView(code: code, lang: lang.isEmpty ? nil : lang)
        }
    }

    // 解析块级结构
    static func parse(_ src: String) -> [MDBlock] {
        var blocks: [MDBlock] = []
        var lines = src.components(separatedBy: "\n")
        var i = 0
        var para: [String] = []

        func flushPara() {
            if !para.isEmpty {
                blocks.append(MDBlock(kind: .para(para.joined(separator: " "))))
                para = []
            }
        }

        while i < lines.count {
            let line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if line.hasPrefix("```") {
                flushPara()
                let lang = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                var code: [String] = []
                i += 1
                while i < lines.count && !lines[i].hasPrefix("```") {
                    code.append(lines[i])
                    i += 1
                }
                i += 1
                blocks.append(MDBlock(kind: .code(code.joined(separator: "\n"), lang)))
                continue
            }
            if line.hasPrefix("### ") {
                flushPara()
                blocks.append(MDBlock(kind: .heading(3, String(line.dropFirst(4)))))
            } else if line.hasPrefix("## ") {
                flushPara()
                blocks.append(MDBlock(kind: .heading(2, String(line.dropFirst(3)))))
            } else if line.hasPrefix("# ") {
                flushPara()
                blocks.append(MDBlock(kind: .heading(1, String(line.dropFirst(2)))))
            } else if line.hasPrefix("- ") {
                flushPara()
                blocks.append(MDBlock(kind: .bullet(String(line.dropFirst(2)))))
            } else if line.hasPrefix("* ") {
                flushPara()
                blocks.append(MDBlock(kind: .bullet(String(line.dropFirst(2)))))
            } else if trimmed.isEmpty {
                flushPara()
            } else {
                para.append(trimmed)
            }
            i += 1
        }
        flushPara()
        return blocks
    }

    // 解析行内 **加粗** 与 `行内代码`
    static func inline(_ s: String) -> Text {
        var result = Text("")
        var i = s.startIndex
        while i < s.endIndex {
            let rest = s[i...]
            if rest.hasPrefix("**") {
                let after = s.index(i, offsetBy: 2)
                if let range = s[after...].firstRange(of: "**") {
                    let inner = String(s[after..<range.lowerBound])
                    result = result + Text(inner).bold().foregroundColor(Theme.textPrimary)
                    i = range.upperBound
                    continue
                }
            }
            if s[i] == "`" {
                let after = s.index(after: i)
                if let end = s[after...].firstIndex(of: "`") {
                    let inner = String(s[after..<end])
                    result = result + Text(inner)
                        .font(.system(size: 12.5, design: .monospaced))
                        .foregroundColor(Theme.accent)
                    i = s.index(after: end)
                    continue
                }
            }
            result = result + Text(String(s[i]))
            i = s.index(after: i)
        }
        return result
    }
}
