import UIKit
import SwiftUI

// Logos / ObjC / C 语法高亮（后台线程执行，不阻塞输入）

enum SyntaxHighlighter {
    static let markerKey = NSAttributedString.Key("dl.styled")
    static let font = UIFont(name: "Menlo", size: 13) ?? UIFont.monospacedSystemFont(ofSize: 13, weight: .regular)
    static let boldFont = UIFont(name: "Menlo-Bold", size: 13) ?? UIFont.monospacedSystemFont(ofSize: 13, weight: .bold)

    private static let comment = UIColor(red: 0.42, green: 0.50, blue: 0.58, alpha: 1)
    private static let string  = UIColor(red: 0.31, green: 0.82, blue: 0.77, alpha: 1)
    private static let number  = UIColor(red: 0.96, green: 0.65, blue: 0.14, alpha: 1)
    private static let pink    = UIColor(red: 0.96, green: 0.45, blue: 0.71, alpha: 1)
    private static let violet  = UIColor(red: 0.55, green: 0.49, blue: 0.94, alpha: 1)
    private static let blue    = UIColor(red: 0.36, green: 0.55, blue: 0.94, alpha: 1)

    private static let keywordPattern = "\\b(?:hook|end|orig|log|new|ctor|group|init|class|subclass|interface|implementation|property|selector|self|super|return|if|else|for|while|do|switch|case|break|continue|id|void|int|float|double|BOOL|char|long|short|unsigned|static|const|typedef|struct|enum|union|nil|NULL|YES|NO|true|false|TRUE|FALSE|import|include|define|sizeof)\\b"

    private static let patterns: [(NSRegularExpression, [NSAttributedString.Key: Any])] = [
        (try! NSRegularExpression(pattern: "/\\*[\\s\\S]*?\\*/"),
         [.foregroundColor: comment, .obliqueness: 0.12]),
        (try! NSRegularExpression(pattern: "//[^\\n]*"),
         [.foregroundColor: comment, .obliqueness: 0.12]),
        (try! NSRegularExpression(pattern: "@?\"(?:\\\\.|[^\"\\\\\\n])*\""),
         [.foregroundColor: string]),
        (try! NSRegularExpression(pattern: "(?m)^[ \\t]*#[^\\n]*"),
         [.foregroundColor: pink]),
        (try! NSRegularExpression(pattern: "%[A-Za-z]+"),
         [.foregroundColor: violet, .font: boldFont]),
        (try! NSRegularExpression(pattern: "(?<![A-Za-z0-9_])[0-9]+(?:\\.[0-9]+)?(?![A-Za-z0-9_])"),
         [.foregroundColor: number]),
        (try! NSRegularExpression(pattern: keywordPattern),
         [.foregroundColor: blue, .font: boldFont]),
    ]

    static func highlight(_ text: String) -> NSAttributedString {
        let out = NSMutableAttributedString(string: text, attributes: [
            .font: font,
            .foregroundColor: UIColor(Theme.textPrimary),
        ])
        guard !text.isEmpty else { return out }
        let ns = text as NSString
        let full = NSRange(location: 0, length: ns.length)

        for (regex, attrs) in patterns {
            for match in regex.matches(in: text, range: full) {
                let r = match.range
                guard r.length > 0 else { continue }
                var marked = false
                out.enumerateAttribute(markerKey, in: r, options: []) { value, _, stop in
                    if value != nil {
                        marked = true
                        stop.pointee = true
                    }
                }
                if marked { continue }
                out.addAttributes(attrs, range: r)
                out.addAttribute(markerKey, value: true, range: r)
            }
        }
        return out
    }
}
