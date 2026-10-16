import Foundation

// 项目模型

struct DylibProject: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var targetApp: String
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var revision: UUID = UUID()
    var files: [DylibFile]
    var blocks: [Block]
    var activeFileID: UUID

    func file(named: String) -> DylibFile? {
        files.first { $0.name == named }
    }

    func file(id: UUID) -> DylibFile? {
        files.first { $0.id == id }
    }
}

struct DylibFile: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var content: String
}

// 项目模板
struct ProjectTemplate: Identifiable {
    let id: String
    let name: String
    let subtitle: String
    let icon: String
    let tint: UInt32
    let targetApp: String
    let makeFiles: ([String: String]) -> [DylibFile]
    let makeBlocks: () -> [Block]

    func build(projectName: String) -> DylibProject {
        let files = makeFiles(["{NAME}": sanitized(projectName)])
        let blocks = makeBlocks()
        var generated: [DylibFile] = []
        for f in files {
            if f.name == "Tweak.xm" {
                generated.append(DylibFile(name: "Tweak.xm", content: BlockCodeGenerator.fullFile(projectName: projectName, blocks: blocks)))
            } else {
                generated.append(f)
            }
        }
        return DylibProject(
            name: projectName,
            targetApp: targetApp,
            files: generated,
            blocks: blocks,
            activeFileID: generated.first(where: { $0.name == "Tweak.xm" })?.id ?? generated[0].id
        )
    }

    private func sanitized(_ s: String) -> String {
        let filtered = s.lowercased().filter { $0.isLetter || $0.isNumber }
        return filtered.isEmpty ? "mytweak" : filtered
    }
}

// 内置辅助头文件（积木对应的真实实现，可随 theos 一起编译）
enum BuiltinFiles {
    static let helpersHeader = """
// DylibHelpers.h — 由 DylibLab 提供，与积木一一对应
// 在 theos 中编译时，请确保 Tweak.xm 顶部 #import "DylibHelpers.h"
#ifndef DYLIBLAB_HELPERS_H
#define DYLIBLAB_HELPERS_H

#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static inline UIColor *DLColorFromHex(NSString *hex) {
    NSString *s = [hex hasPrefix:@"#"] ? [hex substringFromIndex:1] : hex;
    unsigned int r = 0, g = 0, b = 0;
    sscanf([s UTF8String], "%02x%02x%02x", &r, &g, &b);
    return [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:1.0f];
}

// 积木「设置壁纸」：修改主窗口背景色
static inline void DLSetWallpaper(NSString *hex) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *w = [UIApplication sharedApplication].keyWindow;
        w.rootViewController.view.backgroundColor = DLColorFromHex(hex);
    });
}

// 积木「设置角标」：演示用，实际 hook 需自行定位角标视图
static inline void DLSetBadge(NSString *hex) {
    [[NSUserDefaults standardUserDefaults] setObject:hex forKey:@"DLBadgeColor"];
}

// 积木「设置状态栏」：演示用
static inline void DLSetStatus(NSString *text) {
    [[NSUserDefaults standardUserDefaults] setObject:text forKey:@"DLStatusText"];
}

// 积木「弹出横幅」
static inline void DLShowBanner(NSString *text) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *w = [UIApplication sharedApplication].keyWindow;
        UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(24, 70, [UIScreen mainScreen].bounds.size.width - 48, 46)];
        l.text = text;
        l.textColor = [UIColor whiteColor];
        l.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.85];
        l.textAlignment = NSTextAlignmentCenter;
        l.font = [UIFont boldSystemFontOfSize:15];
        l.layer.cornerRadius = 14;
        l.layer.masksToBounds = YES;
        l.alpha = 0;
        [w addSubview:l];
        [UIView animateWithDuration:0.25 animations:^{ l.alpha = 1; }];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.25 animations:^{ l.alpha = 0; } completion:^(BOOL f){ [l removeFromSuperview]; }];
        });
    });
}

#endif
"""

    static func makefile(for name: String) -> String {
        """
        TARGET := iphone:clang:latest:14.0
        INSTALL_TARGET_PROCESSES = SpringBoard
        ARCHS = arm64 arm64e

        include $(THEOS)/makefiles/common.mk

        TWEAK_NAME = \(name)
        \(name)_FILES = Tweak.xm
        \(name)_CFLAGS = -fobjc-arc

        include $(THEOS_MAKE_PATH)/tweak.mk
        """
    }

    static func control(for name: String) -> String {
        """
        Package: com.example.\(name)
        Name: \(name)
        Version: 1.0.0
        Architecture: iphoneos-arm
        Description: 用 DylibLab 搭建的 tweak
        Maintainer: DylibLab User
        Section: Tweaks
        Depends: mobilesubstrate
        """
    }

    static let blankTweak = """
    // 在积木模式中搭建你的 hook，或直接在这里编写 Logos 代码
    // 提示：%@ 是「hook 目标」，%orig 调用原实现，%log 打印调用日志
    """
}

enum ProjectTemplates {
    static let all: [ProjectTemplate] = [
        ProjectTemplate(
            id: "blank",
            name: "空白项目",
            subtitle: "从零开始搭建你的第一个 tweak",
            icon: "square.dashed",
            tint: 0x5B8DEF,
            targetApp: "SpringBoard",
            makeFiles: { v in
                [
                    DylibFile(name: "Tweak.xm", content: BuiltinFiles.blankTweak),
                    DylibFile(name: "DylibHelpers.h", content: BuiltinFiles.helpersHeader),
                    DylibFile(name: "Makefile", content: BuiltinFiles.makefile(for: v["{NAME}"] ?? "mytweak")),
                    DylibFile(name: "control", content: BuiltinFiles.control(for: v["{NAME}"] ?? "mytweak")),
                ]
            },
            makeBlocks: { [] }
        ),
        ProjectTemplate(
            id: "wallpaper",
            name: "壁纸美化",
            subtitle: "hook SpringBoard 改壁纸 + 弹横幅",
            icon: "photo.on.rectangle.angled",
            tint: 0x4FD1C5,
            targetApp: "SpringBoard",
            makeFiles: { v in
                [
                    DylibFile(name: "Tweak.xm", content: BuiltinFiles.blankTweak),
                    DylibFile(name: "DylibHelpers.h", content: BuiltinFiles.helpersHeader),
                    DylibFile(name: "Makefile", content: BuiltinFiles.makefile(for: v["{NAME}"] ?? "mytweak")),
                    DylibFile(name: "control", content: BuiltinFiles.control(for: v["{NAME}"] ?? "mytweak")),
                ]
            },
            makeBlocks: {
                var hook = Block.new(.hook, ["className": "SpringBoard"])
                var method = Block.new(.method, ["name": "applicationDidFinishLaunching"])
                method.children = [
                    Block.new(.showBanner, ["text": "DylibLab 注入成功 ✨"]),
                    Block.new(.setWallpaper, ["color": "#14213D"]),
                    Block.new(.log),
                ]
                hook.children = [method]
                return [hook]
            }
        ),
        ProjectTemplate(
            id: "statusbar",
            name: "状态栏大师",
            subtitle: "改状态栏文字与角标颜色",
            icon: "chart.bar.xaxis",
            tint: 0xF5A623,
            targetApp: "SpringBoard",
            makeFiles: { v in
                [
                    DylibFile(name: "Tweak.xm", content: BuiltinFiles.blankTweak),
                    DylibFile(name: "DylibHelpers.h", content: BuiltinFiles.helpersHeader),
                    DylibFile(name: "Makefile", content: BuiltinFiles.makefile(for: v["{NAME}"] ?? "mytweak")),
                    DylibFile(name: "control", content: BuiltinFiles.control(for: v["{NAME}"] ?? "mytweak")),
                ]
            },
            makeBlocks: {
                var hook = Block.new(.hook, ["className": "SpringBoard"])
                var method = Block.new(.method, ["name": "applicationDidFinishLaunching"])
                method.children = [
                    Block.new(.setStatus, ["text": "DylibLab 在线"]),
                    Block.new(.setBadge, ["color": "#F5A623"]),
                    Block.new(.log),
                ]
                hook.children = [method]
                return [hook]
            }
        ),
        ProjectTemplate(
            id: "appinject",
            name: "应用注入",
            subtitle: "hook UIViewController 观察所有页面",
            icon: "app.badge",
            tint: 0x8B7CF0,
            targetApp: "任意 App",
            makeFiles: { v in
                [
                    DylibFile(name: "Tweak.xm", content: BuiltinFiles.blankTweak),
                    DylibFile(name: "DylibHelpers.h", content: BuiltinFiles.helpersHeader),
                    DylibFile(name: "Makefile", content: BuiltinFiles.makefile(for: v["{NAME}"] ?? "mytweak")),
                    DylibFile(name: "control", content: BuiltinFiles.control(for: v["{NAME}"] ?? "mytweak")),
                ]
            },
            makeBlocks: {
                var hook = Block.new(.hook, ["className": "UIViewController"])
                var method = Block.new(.method, ["name": "viewDidLoad"])
                var ifb = Block.new(.ifBlock, ["condition": "self.view.backgroundColor == nil"])
                ifb.children = [
                    Block.new(.setWallpaper, ["color": "#1F2A44"]),
                ]
                method.children = [
                    Block.new(.log),
                    ifb,
                    Block.new(.showBanner, ["text": "页面已加载 🎉"]),
                ]
                hook.children = [method]
                return [hook]
            }
        ),
    ]
}
