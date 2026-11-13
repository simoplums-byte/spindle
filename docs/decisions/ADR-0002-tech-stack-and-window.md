# ADR-0002：技术栈、窗口层级与渲染

Status: accepted
Date: 2026-11-13
Owners: Shawn
Supersedes: none
Superseded by: none

## Context

产品是一个常驻桌面的摆件：无边框、固定尺寸（约 320pt）、始终浮在最上层、不抢焦点、不进 Dock、不进 ⌘-Tab、不随 Mission Control 换位置。主体画面是持续旋转的碟片与静态机身，需要稳定 60fps 且长时间运行不发热。

本机工具链已具备：Swift 6.4.2 与完整 Xcode，可直接构建原生可执行包；无需为这个单一摆件引入额外的运行时。

## Decision

- **工程形态**：SwiftPM 可执行包（`swift-tools-version` 对齐本机 Swift 6.4），产物为 `.app` 包，由本地脚本组装 `Contents/MacOS/Spindle` 与 `Info.plist`。不引入 Xcode 工程文件，避免摆件类小项目被工程配置绑架。
- **窗口**：AppKit 管窗口，`NSPanel` + `styleMask: .borderless`，`level = .floating`，`collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]`，`isMovableByWindowBackground = true`（可拖动位置并持久化），`hidesOnDeactivate = false`，`becomesKeyOnlyIfNeeded = true`（不抢焦点）。窗口位置与尺寸写入 `UserDefaults`。
- **应用形态**：`LSUIElement = true`（无 Dock 图标、无 ⌘-Tab）。退出入口放在菜单栏图标菜单里；菜单栏只提供"退出 / 显示或隐藏"，不提供任何播放控制。
- **绘制**：SwiftUI 负责机身、LCD、按键；碟片的连续旋转用角度累加状态机驱动（只有 `.playing` 时按角速度累加，暂停时角速度衰减到 0 后停在当前角度），配合 `TimelineView(.animation)` 或 `CVDisplayLink`。不使用一次性 `rotationEffect` 无限动画——它无法在中途减速，也无法停在任意角度。
- **检测与 UI 的边界**：检测在后台队列/独立 actor，主线程只做状态回写；回写前校验采样代际，旧采样不得覆盖新状态。

明确不采用：Electron/Tauri（为一张旋转的碟引入 100MB+ 运行时、额外权限模型与更差的热表现不划算）。

## Consequences

收益：

- 单文件可执行、启动秒开、空闲功耗低，符合"摆件"要求。
- 窗口行为可精确控制，满足不抢焦点、不进 Dock、跨 Space 常驻。
- 与 Shawn 现有 macOS/iOS Swift 工具链一致，维护成本低。

代价与风险：

- 无 Xcode 工程即没有 Storyboard/预览的便利；界面调整依赖重新构建，迭代比 SwiftUI Preview 慢。可接受：产品只有一块画面。
- 自构建的 `.app` 未签名公证，首次运行可能触发 Gatekeeper 提示；本机自用无需处理，但**不得**把该产物当作可分发安装包。
- SwiftPM 打包 `.app` 需要脚本维护 `Info.plist`，一旦漏项（如 `LSUIElement`）会出现意外 Dock 图标；脚本必须纳入验证。
- 若未来需要 App Store 分发，本方案需重做为 Xcode 工程 + 签名，属独立决策。

## Alternatives considered

- **Xcode 工程 + SwiftUI App**：预览方便，但对本产品的主要收益（窗口层级控制）没有帮助，反而引入 `.xcodeproj` 的合并与版本噪声。
- **纯 AppKit 手绘（无 SwiftUI）**：动画控制最直接，但机身与 LCD 的布局、文字、渐变全部要手写，迭代成本高于收益。
- **Electron**：跨平台便利，但体积、空闲内存与动画功耗均不匹配"常驻桌面的安静摆件"。
- **菜单栏弹窗形态**：更省桌面空间，但与"始终可见、看着它转"的仪式感冲突。已由用户明确选择悬浮置顶。

## Validation / review

- 构建后检查 `.app` 的 `Info.plist` 含 `LSUIElement=true`，运行后 Dock 与 ⌘-Tab 中均不出现。
- 实机确认：切换 Space 后仍在原位置；全屏应用上方仍可见；点击不夺焦。
- 长时间运行 8 小时观测 CPU 与内存，对照 `PROJECT-CONTEXT.md` 的"轻"底线。
- 若未来确需分发或需要 App Store，重新评估工程形态与签名方案。
