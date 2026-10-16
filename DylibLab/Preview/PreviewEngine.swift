import SwiftUI
import Foundation

// 预览引擎：解析生成代码中的辅助函数调用，模拟 tweak 生效后的视觉效果

struct PreviewEffects {
    var wallpaper: Color = Color(hex: 0x1B2A4A)
    var badge: Color = Color(hex: 0xFF3B30)
    var statusText: String = "9:41"
    var bannerText: String?
    var hookedClasses: [String] = []
    var hasLog = false
}

enum PreviewEngine {
    static func parse(_ code: String) -> PreviewEffects {
        var e = PreviewEffects()
        e.hasLog = code.contains("%log")
        e.hookedClasses = matches(code, "%hook\\s+(\\w+)")

        if let s = matches(code, "DLSetWallpaper\\(@\"([^\"]*)\"\\)").last,
           let c = Color(hexString: s) {
            e.wallpaper = c
        }
        if let s = matches(code, "DLSetBadge\\(@\"([^\"]*)\"\\)").last,
           let c = Color(hexString: s) {
            e.badge = c
        }
        if let s = matches(code, "DLSetStatus\\(@\"([^\"]*)\"\\)").last {
            e.statusText = s
        }
        if let s = matches(code, "DLShowBanner\\(@\"([^\"]*)\"\\)").last {
            e.bannerText = s
        }
        return e
    }

    private static func matches(_ code: String, _ pattern: String) -> [String] {
        guard let re = try? NSRegularExpression(pattern: pattern) else { return [] }
        let ns = code as NSString
        return re.matches(in: code, range: NSRange(location: 0, length: ns.length)).compactMap { m in
            m.numberOfRanges > 1 ? ns.substring(with: m.range(at: 1)) : nil
        }
    }
}
