# DylibLab — 积木化 iOS dylib 开发工坊

用「像搭积木一样」的方式学习 iOS dylib / tweak 开发：左侧编辑器、右侧实时模拟预览，积木与代码双模式自由切换，内置新手到高级教程和可自配 API Key 的 AI 助手。

> 仅供学习研究。请在合法范围内使用，遵守当地法律与相关软件服务条款。

## 功能

- **积木编辑**：13 种积木（Hook 类、方法、%orig、%log、设壁纸/角标/状态栏、弹横幅、条件、变量等），拖拽搭建、实时校验层级
- **代码编辑**：Logos / ObjC / C 语法高亮，自动保存
- **一键生成**：积木 → 完整 `Tweak.xm`（含 `DylibHelpers.h` 辅助实现，可直接进 theos 编译）
- **实时预览**：右侧模拟 iPhone 桌面，解析代码中的 `DLSetWallpaper` / `DLShowBanner` / `%log` 等标记，把 tweak 效果「演」出来，可交互、带运行日志
- **教程中心**：15 课（新手→进阶→高级），每课带随堂测验，进度自动保存
- **AI 助手**：自配 OpenAI 兼容 API（OpenAI / DeepSeek / Moonshot / 自定义 base URL），流式对话；附加项目上下文后，AI 生成的代码块可一键写入任意项目文件
- **项目模板**：空白 / 壁纸美化 / 状态栏大师 / 应用注入，每个项目自带 Tweak.xm、DylibHelpers.h、Makefile、control 四件套

## 界面结构

- iPad：编辑器（左）与预览（右）并排；iPhone：编辑 / 预览分段切换
- 底部浮动标签栏：项目 / 教程 / AI 助手 / 设置

## 构建

### 方式一：GitHub Actions（零配置出 IPA）

Push 到 `main` 或手动触发 `Build IPA` workflow，自动产出 `DylibLab-unsigned.ipa`（Artifacts）。

### 方式二：本地

```bash
brew install xcodegen        # 需要 Xcode
xcodegen generate            # 生成 DylibLab.xcodeproj
open DylibLab.xcodeproj      # 选自己的 Team 后 Run
```

### 侧载安装（unsigned IPA）

1. 下载 workflow 产出的 `DylibLab-unsigned.ipa`
2. 用 [Sideloadly](https://sideloadly.io/) 或 [AltStore](https://altstore.io/) 以 Apple ID 签名安装（7 天有效期）
3. 首次启动在「设置 → 通用 → VPN与设备管理」信任证书

## AI 助手配置

设置 → AI 配置，选服务商并填 API Key（仅存本机，优先 Keychain）：

| 服务商 | 默认 API 地址 | 默认模型 |
| --- | --- | --- |
| OpenAI | `https://api.openai.com/v1` | `gpt-4o-mini` |
| DeepSeek | `https://api.deepseek.com/v1` | `deepseek-chat` |
| Moonshot | `https://api.moonshot.cn/v1` | `moonshot-v1-8k` |
| 自定义 | 任意 OpenAI 兼容地址（含 Ollama 等） | 自填 |

## 把项目变成真正的 tweak

1. 在 App 里用积木搭好，点「生成代码」，切代码模式检查 `Tweak.xm`
2. 把四个文件拷到 theos 项目目录（环境搭建见教程第 4 课）
3. `make package` 编译打包，`make install` 安装

## 目录

```
DylibLab/
├── project.yml                     # XcodeGen 工程定义
├── .github/workflows/build-ipa.yml # CI：编译 + 打包 IPA
├── Tools/gen_icon.py               # 图标生成脚本
└── DylibLab/
    ├── App/        # 入口、主题、根视图
    ├── Models/     # 项目、积木+代码生成器、教程、AI 模型
    ├── Stores/     # 项目/设置/AI 状态、流式客户端
    ├── Editors/    # 语法高亮、代码编辑器、积木编辑器、编辑主界面
    ├── Preview/    # 效果解析引擎、模拟预览面板
    ├── Screens/    # 项目/教程/AI/设置界面、Markdown 渲染
    └── Components/ # 通用组件
```

SwiftUI · iOS 16+ · 零第三方依赖。
