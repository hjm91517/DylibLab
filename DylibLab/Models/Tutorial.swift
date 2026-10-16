import Foundation

// 教程模型与内置课程

enum TutorialLevel: String, Codable {
    case beginner = "新手"
    case intermediate = "进阶"
    case advanced = "高级"

    var color: UInt32 {
        switch self {
        case .beginner: return 0x4FD1C5
        case .intermediate: return 0xF5A623
        case .advanced: return 0xF87171
        }
    }
}

struct TutorialSection {
    let title: String
    let body: String
}

struct Quiz {
    let question: String
    let options: [String]
    let answer: Int
    let explanation: String
}

struct Tutorial: Identifiable {
    let id: Int
    let title: String
    let level: TutorialLevel
    let icon: String
    let summary: String
    let sections: [TutorialSection]
    let quiz: Quiz
}

enum TutorialStore {
    static let all: [Tutorial] = [
        // MARK: 新手
        Tutorial(
            id: 1, title: "认识 dylib：iOS 的动态库", level: .beginner, icon: "books.vertical",
            summary: "dylib 是什么？它和 .a、framework 有什么区别？",
            sections: [
                TutorialSection(title: "什么是 dylib", body: """
**dylib** 是 *dynamic library*（动态链接库）的缩写。iOS 系统本身就是一个巨大的动态库集合——你每天用的 UIKit、Foundation、SpringBoard 底层能力，都以 dylib 的形式存放在 `/usr/lib` 与 `/System/Library/Frameworks` 里。

App 启动时，系统加载器 **dyld** 会读取二进制里的依赖清单，把需要的动态库逐个映射进内存。所以 dylib 不是「打包进 App」，而是「运行时才链接」。
"""),
                TutorialSection(title: "动态库 vs 静态库", body: """
- **静态库 `.a`**：编译时直接复制进你的二进制，包变大，改一行代码要全部重编。
- **动态库 `.dylib`**：运行时加载，多个进程可以共享同一份，还能单独更新。
- **Framework**：一个「包装盒」，里面通常也包含一个 dylib。

对 tweak 开发来说，动态库最大的魅力在于：**可以被注入**——在别人进程启动时，把我们的代码塞进去。
"""),
                TutorialSection(title: "为什么 iOS 不让你随便加载", body: """
iOS 有严格的签名与平台限制，普通 App 无法随意加载任意 dylib。要运行自定义 dylib，常见途径有：

1. **越狱环境**（Substrate / Substitute 注入）
2. **给 App 打补丁**：向 Mach-O 插入 `LC_LOAD_DYLIB` 并重签
3. **自签侧载**（配合签名工具）

DylibLab 的「预览」功能不真正注入系统，而是**模拟** tweak 运行后的视觉效果，帮你在写代码前先看到结果。
"""),
            ],
            quiz: Quiz(
                question: "dylib 的全称是什么？",
                options: ["Dynamic Library（动态链接库）", "Data Link Library（数据链接库）", "Dynamic Linker（动态链接器）", "Database Library（数据库）"],
                answer: 0,
                explanation: "dylib = dynamic library，中文一般叫「动态链接库」，是运行时才被加载的代码库。"
            )
        ),
        Tutorial(
            id: 2, title: "注入是怎么发生的", level: .beginner, icon: "arrow.triangle.branch",
            summary: "dyld、Load Commands 与三种主流注入方式",
            sections: [
                TutorialSection(title: "dyld 的加载流程", body: """
App 启动时，内核把控制权交给 **dyld**。dyld 读取 Mach-O 文件头的 **Load Commands**（加载命令），其中 `LC_LOAD_DYLIB` 列出了所有依赖的动态库，然后逐一加载、重定位、绑定符号。

这给了我们一个思路：**只要能改变「加载清单」，就能改变「谁被加载」**。
"""),
                TutorialSection(title: "三种主流注入方式", body: """
1. **环境变量注入**：macOS 上设置 `DYLD_INSERT_LIBRARIES` 即可插入任意 dylib；iOS 上被系统禁用（有防护）。

2. **Substrate / Substitute**：越狱后由 MobileLoader 统一把 `/Library/MobileSubstrate/DynamicLibraries` 下的 dylib 注入所有进程。这是 tweak 开发最常用的方式。

3. **Mach-O 补丁**：用 `insert_dylib`、`optool` 等工具，直接给 App 二进制追加一条 `LC_LOAD_DYLIB`，再重签名。不越狱也能用，但每个 App 都要单独处理。
"""),
                TutorialSection(title: "DylibLab 的预览", body: """
真实的注入发生在别人的进程里，App 内无法完整模拟。因此 DylibLab 的右侧预览是一个**沙盒模拟器**：

- 解析你生成的代码中的 `DLSetWallpaper`、`DLShowBanner`、`%log` 等标记
- 在一个模拟的 iOS 桌面里把它们「演」出来
- 交互操作（点击图标、触发通知）会触发模拟日志

这样你可以在真机注入之前，就把逻辑和视觉调好。
"""),
            ],
            quiz: Quiz(
                question: "macOS 上用来注入动态库的环境变量是？",
                options: ["DYLD_INSERT_LIBRARIES", "LD_PRELOAD", "PATH", "DYLD_LIBRARY_INJECT"],
                answer: 0,
                explanation: "macOS 使用 DYLD_INSERT_LIBRARIES；LD_PRELOAD 是 Linux 的机制。iOS 则禁用了这一变量。"
            )
        ),
        Tutorial(
            id: 3, title: "Tweak 是什么", level: .beginner, icon: "hammer",
            summary: "插件、deb 包与第一个 tweak 的结构",
            sections: [
                TutorialSection(title: "Tweak 的定义", body: """
**Tweak** 是指以 hook 方式修改其他进程行为的插件。它本身就是一个 dylib，但多了两样东西：

- **过滤配置**：声明要注入哪些进程（比如只注入 SpringBoard）
- **打包格式**：以 deb 包分发，方便安装、卸载
"""),
                TutorialSection(title: "一个 tweak 的三件套", body: """
```
MyTweak/
├── Tweak.xm        ← 核心代码（Logos 语法）
├── Makefile        ← 编译规则（theos）
└── control         ← 包信息（名称、依赖、维护者）
```
编译后会生成 `MyTweak.dylib` + `MyTweak.plist`，再打包成 `com.example.mytweak.deb`。

DylibLab 创建的每个项目都自带这三件套，`Tweak.xm` 可以直接用积木生成。
"""),
                TutorialSection(title: "Tweak 能做什么", body: """
- 美化：改壁纸、改状态栏、改图标角标
- 增强：给 App 加功能、去广告、改默认行为
- 学习：观察系统方法的调用时机和参数

**注意**：一切以学习为目的。作弊、盗版、侵犯隐私都属于越界行为。
"""),
            ],
            quiz: Quiz(
                question: "一个 theos tweak 项目里，核心代码文件通常叫什么？",
                options: ["Tweak.xm", "main.swift", "index.html", "setup.py"],
                answer: 0,
                explanation: "Tweak.xm 使用 Logos 语法（在 ObjC 之上加 %hook 等指令），是 tweak 的核心文件。"
            )
        ),
        Tutorial(
            id: 8, title: "DylibLab 积木速查", level: .beginner, icon: "cube",
            summary: "每块积木对应什么代码，怎么搭出第一个效果",
            sections: [
                TutorialSection(title: "积木 ↔ 代码对照表", body: """
| 积木 | 生成的代码 |
| --- | --- |
| Hook 类 | `%hook SpringBoard` ... `%end` |
| 方法 | `- (void)xxx { ... }` |
| 调用原方法 | `%orig;` |
| 打印日志 | `%log;` |
| 设置壁纸 | `DLSetWallpaper(@"#14213D");` |
| 弹出横幅 | `DLShowBanner(@"Hello");` |
| 如果 | `if (YES) { ... }` |
| 返回 | `return nil;` |
"""),
                TutorialSection(title: "搭建规则", body: """
积木有层级规则，和真实代码一样：

1. **Hook 类**在最外层，内部放**方法**积木
2. **方法**内部放动作、逻辑积木
3. 放到错误位置的积木，生成代码时会变成 `⚠️` 注释提醒你

搭好之后点「生成代码」，右侧预览会立刻根据新代码更新效果。
"""),
                TutorialSection(title: "动手：5 块积木做出第一个效果", body: """
1. 从左侧拖入 **Hook 类**，类名填 `SpringBoard`
2. 选中它，点 `+` 添加子积木 → **方法**
3. 方法名填 `applicationDidFinishLaunching`
4. 再给方法添加子积木：**弹出横幅**、**设置壁纸**、**打印日志**
5. 点「生成代码」，切到右侧预览看看发生了什么

然后切到「代码」模式，对照积木和代码，理解每一块积木的本质。
"""),
            ],
            quiz: Quiz(
                question: "「设置壁纸」积木生成的代码调用了哪个辅助函数？",
                options: ["DLSetWallpaper", "setWallpaper:", "UIWallpaper", "DLChangeBg"],
                answer: 0,
                explanation: "积木依赖 DylibHelpers.h 里的 DLSetWallpaper 等辅助函数，预览引擎也靠解析这些函数名来模拟效果。"
            )
        ),
        Tutorial(
            id: 15, title: "法律与安全边界", level: .beginner, icon: "shield",
            summary: "哪些能做、哪些坚决不能做",
            sections: [
                TutorialSection(title: "允许做什么", body: """
- 在自己的设备上学习、实验
- 修改自己开发的 App
- 公开分享技术教程与开源代码
- 参与安全研究（遵守漏洞披露流程）
"""),
                TutorialSection(title: "不能做什么", body: """
- 制作游戏外挂、抢单脚本等**破坏公平**的工具
- 绕过付费、盗版、破解内购
- 窃取他人隐私、制作恶意程序
- 在未授权设备上注入
"""),
                TutorialSection(title: "提醒", body: """
不同国家和地区的法律对「修改设备」的规定不同，请遵守当地法律与你使用的软件的服务条款。DylibLab 的定位是**教育工具**——教会你动态链接、Runtime 与逆向的基础知识，而不是攻击工具。
"""),
            ],
            quiz: Quiz(
                question: "以下哪种用法是恰当的？",
                options: [
                    "在自己设备上学习 hook 技术",
                    "给热门游戏写外挂并出售",
                    "破解商业软件的授权",
                    "窃取他人设备上的数据",
                ],
                answer: 0,
                explanation: "学习与自研是正当用途；作弊、破解、侵犯隐私都属于越界甚至违法行为。"
            )
        ),

        // MARK: 进阶
        Tutorial(
            id: 4, title: "搭建 theos 环境", level: .intermediate, icon: "terminal",
            summary: "theos 安装、SDK 配置与 Makefile 解读",
            sections: [
                TutorialSection(title: "安装 theos", body: """
theos 是 iOS tweak 开发的构建系统。安装步骤：

```bash
# 1. 克隆 theos（建议放到 ~/theos）
git clone --recursive https://github.com/theos/theos.git ~/theos

# 2. 设置环境变量（写入 ~/.zshrc）
export THEOS=~/theos
export PATH=$THEOS/bin:$PATH
```
"""),
                TutorialSection(title: "准备 SDK", body: """
theos 编译需要 iOS SDK。最简单的方式是从 Xcode 里取：

```bash
# 查看 Xcode 自带的 SDK 路径
xcrun --sdk iphoneos --show-sdk-path
# 例如输出：/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk

# 链接到 theos 的 sdks 目录
mkdir -p $THEOS/sdks
ln -s "$(xcrun --sdk iphoneos --show-sdk-path)" $THEOS/sdks/iPhoneOS.sdk
```
"""),
                TutorialSection(title: "Makefile 逐行解读", body: """
```makefile
TARGET := iphone:clang:latest:14.0   # 目标平台与最低系统版本
INSTALL_TARGET_PROCESSES = SpringBoard # 安装后重启的进程
ARCHS = arm64 arm64e                 # 目标架构
include $(THEOS)/makefiles/common.mk # theos 公共规则
TWEAK_NAME = MyTweak                 # 项目名
MyTweak_FILES = Tweak.xm             # 源文件
MyTweak_CFLAGS = -fobjc-arc          # 开启 ARC
include $(THEOS_MAKE_PATH)/tweak.mk  # tweak 编译规则
```
DylibLab 每个项目都会为你生成这份 Makefile，改个名字就能用。
"""),
            ],
            quiz: Quiz(
                question: "THEOS 环境变量指向什么？",
                options: ["theos 的安装目录", "SDK 的路径", "编译输出目录", "签名证书"],
                answer: 0,
                explanation: "THEOS 指向 theos 安装目录，Makefile 通过 $(THEOS) 引用它。"
            )
        ),
        Tutorial(
            id: 5, title: "你的第一个 Tweak", level: .intermediate, icon: "sparkles",
            summary: "hook SpringBoard，弹出你的第一个横幅",
            sections: [
                TutorialSection(title: "编写 Tweak.xm", body: """
在 DylibLab 里新建「壁纸美化」项目，切换到代码模式，你会看到：

```logos
#import "DylibHelpers.h"

%hook SpringBoard
- (void)applicationDidFinishLaunching {
    DLShowBanner(@"DylibLab 注入成功 ✨");
    DLSetWallpaper(@"#14213D");
    %log;
}
%end
```

`%hook SpringBoard` 表示「我要替换 SpringBoard 类的方法」，`%end` 结束替换。
"""),
                TutorialSection(title: "理解每一行", body: """
- `%hook` / `%end`：成对出现，标记 hook 范围
- 方法签名必须与原来**完全一致**，否则 hook 不生效
- `%log`：Logos 的日志魔法，自动打印类名、方法名和参数
- `%orig`：调用原实现。这个例子里没写，意味着启动流程被我们「吃掉」了——生产代码里几乎都要调用它
"""),
                TutorialSection(title: "编译与安装", body: """
```bash
# 在项目目录下
make package          # 编译并打成 deb
make install          # 安装（需要设备可连接）
```
安装后 SpringBoard 自动重启，横幅就会出现。回到 DylibLab，对比预览里的效果——它们是一致的，这就是预览的意义。
"""),
            ],
            quiz: Quiz(
                question: "忘记调用 %orig 通常会导致什么？",
                options: ["原方法逻辑被跳过，可能引发崩溃或功能异常", "编译失败", "自动调用原方法", "没有任何影响"],
                answer: 0,
                explanation: "hook 会完全替换原实现，不调用 %orig 意味着原有逻辑不再执行。"
            )
        ),
        Tutorial(
            id: 6, title: "Logos 语法全解", level: .intermediate, icon: "curlybraces",
            summary: "%hook、%orig、%log、%new、%ctor、%group",
            sections: [
                TutorialSection(title: "核心指令", body: """
```logos
%hook ClassName
// 在这里重写方法
%end
```

在方法体内：
- `%orig;` 调用原实现
- `%orig(arg1, arg2);` 修改参数后调用原实现
- `%log;` 打印日志（类、方法、参数、返回值）
"""),
                TutorialSection(title: "添加新方法与构造器", body: """
```logos
%hook SpringBoard
%new
- (void)myCustomMethod {
    NSLog(@"这是 SpringBoard 里原本不存在的方法！");
}
%end

%ctor {
    NSLog(@"tweak 被加载时执行一次，可在这里做初始化");
}
```
`%new` 声明下面的方法是「新增的」；`%ctor` 在 dylib 加载时执行，适合初始化。
"""),
                TutorialSection(title: "分组管理", body: """
```logos
%group iOS15
%hook SpringBoard
- (void)applicationDidFinishLaunching { %orig; }
%end
%end

%ctor {
    if (@available(iOS 15, *)) {
        %init(iOS15);
    }
}
```
`%group` 让你把 hook 分组，在 `%ctor` 里按条件 `%init`，实现「不同系统版本不同行为」。
"""),
            ],
            quiz: Quiz(
                question: "%ctor 里的代码在什么时候执行？",
                options: ["dylib 被加载时", "每次 hook 生效时", "App 进入前台时", "编译时"],
                answer: 0,
                explanation: "%ctor 生成构造函数，在动态库加载进进程时执行一次。"
            )
        ),
        Tutorial(
            id: 7, title: "Objective-C Runtime 入门", level: .intermediate, icon: "gearshape.2",
            summary: "消息发送、Method Swizzling 与 hook 的本质",
            sections: [
                TutorialSection(title: "消息发送", body: """
Objective-C 的方法调用本质是**消息发送**：

```objc
[obj doSomething];
// 等价于
objc_msgSend(obj, @selector(doSomething));
```
`objc_msgSend` 在运行时查找方法的函数指针（IMP）并调用。这意味着：**方法是可以被替换的**。
"""),
                TutorialSection(title: "Method Swizzling", body: """
```objc
#import <objc/runtime.h>

Method original = class_getInstanceMethod([SpringBoard class], @selector(applicationDidFinishLaunching));
Method swizzled = class_getInstanceMethod([self class], @selector(dl_applicationDidFinishLaunching));
method_exchangeImplementations(original, swizzled);
```
交换两个方法的 IMP 后，调用原方法会走到我们的实现。**Logos 的 %hook 就是 swizzling 的语法糖**——底层一模一样。
"""),
                TutorialSection(title: "运行时 API 工具箱", body: """
- `class_getInstanceMethod` / `class_getClassMethod`：拿方法
- `objc_getClass`：按名字找类
- `class_addMethod`：给类添加方法
- `objc_setAssociatedObject`：给对象挂自定义数据
- `class_copyMethodList`：列出类的全部方法（逆向利器）

在 DylibLab 的 AI 助手里，你可以直接问「怎么 hook 一个私有方法」，它会结合项目上下文给出代码。
"""),
            ],
            quiz: Quiz(
                question: "Method Swizzling 交换的是什么？",
                options: ["方法的函数指针 IMP", "类名", "实例变量", "方法的名称"],
                answer: 0,
                explanation: "swizzle 交换两个 Method 的 IMP（函数指针），从而改变方法的行为。"
            )
        ),
        Tutorial(
            id: 11, title: "调试技巧", level: .intermediate, icon: "magnifyingglass",
            summary: "日志、FLEX 与 frida-trace",
            sections: [
                TutorialSection(title: "日志三板斧", body: """
```logos
%log;                    // 自动打印完整调用信息
NSLog(@"值 = %@", value); // 手动打印
os_log(OS_LOG_DEFAULT, "分类：%{public}@", value); // 系统日志，性能更好
```
设备连接后，用 Xcode 的 Console 或 `idevicesyslog`（libimobiledevice）实时查看。
"""),
                TutorialSection(title: "FLEX：运行时透视镜", body: """
[FLEX](https://github.com/FLEXTool/FLEX) 是 iOS 的运行时调试工具，集成后摇晃设备即可打开：

- 浏览当前界面的**视图层级**
- 查看任意对象的属性、修改值
- 查看所有类、所有方法

它回答的问题是：「这个界面到底是什么类、什么属性？」——hook 之前先搞清楚目标。
"""),
                TutorialSection(title: "frida-trace", body: """
```bash
frida-trace -U -m "-[SpringBoard *]" SpringBoard
```
可以追踪一个进程里所有匹配的方法调用，参数和返回值一目了然。配合 class-dump 导出的头文件，是定位 hook 点最快的方式。
"""),
            ],
            quiz: Quiz(
                question: "FLEX 的主要用途是？",
                options: ["运行时查看界面层级与对象属性", "编译 tweak", "给 dylib 签名", "抓网络包"],
                answer: 0,
                explanation: "FLEX 是运行时调试工具，帮你实时检查视图与对象，找到要 hook 的目标。"
            )
        ),

        // MARK: 高级
        Tutorial(
            id: 9, title: "给 App 注入 dylib", level: .advanced, icon: "app.badge",
            summary: "Mach-O、insert_dylib 与重签",
            sections: [
                TutorialSection(title: "Mach-O 结构", body: """
每个 iOS 可执行文件都是 **Mach-O** 格式：

```
Header          ← 魔数、CPU 类型
Load Commands   ← 依赖哪些 dylib（LC_LOAD_DYLIB）、段信息
Data            ← 代码与数据
```
所谓「注入」，就是往 Load Commands 里**追加一条** `LC_LOAD_DYLIB`，指向我们的 dylib。
"""),
                TutorialSection(title: "insert_dylib 实操", body: """
```bash
# 1. 编译出我们的 dylib（可以是 DylibLab 项目导出的代码）
make package

# 2. 给 App 注入
insert_dylib @executable_path/Frameworks/MyTweak.dylib MyApp.app/MyApp --all-yes

# 3. 把 dylib 放进 App
mkdir -p MyApp.app/Frameworks
cp MyTweak.dylib MyApp.app/Frameworks/

# 4. 重签名
codesign -f -s "证书名" MyApp.app/Frameworks/MyTweak.dylib
codesign -f -s "证书名" --entitlements entitlements.plist MyApp.app
```
`@executable_path` 是相对于可执行文件的路径，保证换设备也能找到。
"""),
                TutorialSection(title: "常见坑", body: """
- dylib 必须与 App **架构一致**（arm64/arm64e）
- 注入后必须重签，否则启动即闪退
- 被注入的 App 若有完整性校验，可能检测到改动
- UI 相关操作要切到**主线程**
"""),
            ],
            quiz: Quiz(
                question: "LC_LOAD_DYLIB 是什么？",
                options: ["Mach-O 里声明动态库依赖的加载命令", "一种签名算法", "一个越狱工具", "系统日志"],
                answer: 0,
                explanation: "LC_LOAD_DYLIB 是 Mach-O 的加载命令，告诉 dyld 该进程需要加载哪些动态库。"
            )
        ),
        Tutorial(
            id: 10, title: "签名与重签", level: .advanced, icon: "signature",
            summary: "ldid、codesign 与侧载",
            sections: [
                TutorialSection(title: "iOS 签名链", body: """
iOS 要求可执行代码经过签名：证书（谁写的）+ 描述文件（能在哪些设备跑）。tweak 的 dylib 也要签名，只是越狱环境要求宽松。

- `codesign`：苹果官方签名工具
- `ldid`：社区轻量签名工具，越狱环境常用（假签）
"""),
                TutorialSection(title: "常用命令", body: """
```bash
# ldid 签名（越狱）
ldid -S MyTweak.dylib

# codesign 重签 App
codesign -f -s "Apple Development: xxx" --entitlements entitlements.plist MyApp.app

# 查看签名信息
codesign -dvvv MyApp.app
```
"""),
                TutorialSection(title: "侧载 DylibLab 本体", body: """
DylibLab 的 GitHub Actions 会产出 **unsigned IPA**，用以下工具签名安装：

1. **Sideloadly** / **AltStore**：用你的 Apple ID 免费签名，7 天有效期
2. 拖入 `DylibLab-unsigned.ipa`，填入 Apple ID，等待安装完成
3. 首次启动需在「设置 → 通用 → VPN与设备管理」信任证书
"""),
            ],
            quiz: Quiz(
                question: "ldid 的作用是？",
                options: ["给二进制文件（假）签名", "编译 dylib", "安装 deb", "调试网络"],
                answer: 0,
                explanation: "ldid 是越狱环境常用的签名工具，给 dylib 等文件做签名。"
            )
        ),
        Tutorial(
            id: 12, title: "Substrate 与 Substitute", level: .advanced, icon: "arrow.merge",
            summary: "两大注入框架与 rootless 时代",
            sections: [
                TutorialSection(title: "Cydia Substrate", body: """
由 Saurik 开发的经典注入框架（MobileSubstrate），十几年来 tweak 生态的地基：

- **MobileLoader**：进程启动时，根据 plist 过滤规则注入 dylib
- **MSHookFunction / MSHookMessageEx**：底层的 hook API
- Logos 的 `%hook` 最终就编译成 MSHookMessageEx 调用
"""),
                TutorialSection(title: "Substitute", body: """
unc0ver 等项目使用的替代实现，目标是与 Substrate 兼容：

- 提供兼容层，老 tweak 不用改代码
- 更轻量，支持 rootless 环境
- 同样实现 MSHook 系列 API
"""),
                TutorialSection(title: "Rootless 时代", body: """
现代越狱（Dopamine 等）默认 **rootless**：tweak 不再安装到根文件系统，而是：

```
/var/jb/Library/MobileSubstrate/DynamicLibraries/
```

路径变了，但开发方式不变。Makefile 里 `THEOS_PACKAGE_SCHEME = rootless` 即可适配。
"""),
            ],
            quiz: Quiz(
                question: "rootless 越狱环境下，tweak 一般安装在？",
                options: ["/var/jb 下对应的 MobileSubstrate 目录", "/System/Library", "/usr/bin", "/Applications"],
                answer: 0,
                explanation: "rootless 环境把系统数据隔离在 /var/jb，tweak 路径随之改变。"
            )
        ),
        Tutorial(
            id: 13, title: "常见崩溃与排查", level: .advanced, icon: "exclamationmark.triangle",
            summary: "签名不匹配、循环调用与 crash log",
            sections: [
                TutorialSection(title: "崩溃原因 Top 3", body: """
1. **方法签名不匹配**：hook 的签名与真实方法不同（参数个数、类型），arm64e 上尤其严格
2. **忘记 %orig**：把系统关键流程吃掉，导致状态错乱
3. **线程问题**：在后台线程操作 UI，或反过来阻塞主线程
"""),
                TutorialSection(title: "读 crash log", body: """
```
Exception Type: EXC_BAD_ACCESS (SIGSEGV)
Terminating Process: SpringBoard
```
- `EXC_BAD_ACCESS`：访问了野指针，多半是签名不匹配或对象已释放
- `unrecognized selector`：方法不存在，检查类名与 selector
- 用 `atos` 或 Xcode 符号化崩溃栈，定位到具体方法
"""),
                TutorialSection(title: "防御性写法", body: """
```logos
%hook SpringBoard
- (void)applicationDidFinishLaunching {
    %orig;
    @try {
        DLShowBanner(@"Hello");
    } @catch (NSException *e) {
        NSLog(@"我的 tweak 出错了：%@", e);
    }
}
%end
```
先把 `%orig` 放在最前面，再用 `@try` 隔离自己的代码，tweak 稳定性会大幅提升。
"""),
            ],
            quiz: Quiz(
                question: "EXC_BAD_ACCESS 崩溃通常意味着？",
                options: ["访问了无效内存（野指针等）", "磁盘空间不足", "网络超时", "签名过期"],
                answer: 0,
                explanation: "EXC_BAD_ACCESS 是内存访问错误，tweak 开发中常由签名不匹配或对象提前释放导致。"
            )
        ),
        Tutorial(
            id: 14, title: "实战：状态栏美化", level: .advanced, icon: "paintbrush",
            summary: "定位目标 → hook → 用 DylibLab 模拟",
            sections: [
                TutorialSection(title: "第一步：定位目标", body: """
先用工具找到状态栏相关类：

```bash
# 导出 SpringBoard 的头文件
class-dump -H SpringBoard -o headers/
# 搜索 statusBar
grep -ri "statusBar" headers/ | head -20
```
常见目标：`UIStatusBar`、`UIStatusBarWindow`、`SBStatusBarManager`。
"""),
                TutorialSection(title: "第二步：写 hook", body: """
```logos
%hook UIStatusBar
- (void)setAlpha:(CGFloat)alpha {
    %orig(1.0); // 让状态栏永远不透明
}
%end
```
先用 DylibLab 的「状态栏大师」模板在预览里搭一遍，理解效果，再上真机。
"""),
                TutorialSection(title: "第三步：迭代", body: """
真机效果不对时，回到 DylibLab：

1. 把实际代码粘进项目
2. 让 AI 助手分析：「为什么会这样？帮我加 %orig 和空值检查」
3. 把 AI 给的代码一键应用到 Tweak.xm
4. 重新 make package 验证
"""),
            ],
            quiz: Quiz(
                question: "class-dump 的作用是？",
                options: ["导出类的头文件（接口信息）", "编译代码", "签名", "注入 dylib"],
                answer: 0,
                explanation: "class-dump 从 Mach-O 中恢复类的声明，是定位 hook 目标的第一步。"
            )
        ),
    ]
}
