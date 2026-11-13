# 项目协作规则

> 适用于 Spindle 仓库根目录及全部子目录；更深目录的 `AGENTS.md` 只补充局部差异。
> 规则只写长期有效、可执行、可验证的约束。一次性提醒写进任务记录，不进本文件。

## 适用范围

- 开始新任务前，先读本文件与 `docs/PROJECT-CONTEXT.md`；涉及外观、尺寸、动效时再读 `docs/design/visual-spec.md`。
- 涉及播放检测的改动，先读 `docs/decisions/ADR-0001-playback-detection.md`；涉及窗口、渲染、打包的改动，先读 `ADR-0002-tech-stack-and-window.md`。

## 工作前检查

    git status --short
    git diff --stat
    git log --oneline -10

- 当前工作树优先于交接记录；不覆盖、回退、隐藏或提交归属不明的修改。
- 文档中需要提交身份时，分别记录 `Last verified against`（内容实际核对到的提交）与 `Document updated at`（文档自身修订的提交）；两者不必相等，差异需能解释。
- 当前阶段仓库可能尚无提交，此时以"working tree"记录基线，不伪造提交号。

## 项目边界

- 产品定位：桌面装饰性的 CD 播放器，唯一的职责是把外部音乐播放器的"是否在出声"翻译成碟片转/停。定位与非目标以 `docs/PROJECT-CONTEXT.md`「产品定位」「非目标」为单一来源。
- **只读原则**：Spindle 绝不调用第三方播放器的控制接口（不播放、不暂停、不切歌、不调音量），也不写入其状态文件。检测链路只能读。
- **无网络原则**：运行时零网络请求。曲名、封面等元数据只允许来自本机已运行的播放器或其本地缓存；不向任何在线服务补全。
- 技术栈：Swift 6 + SwiftPM，AppKit 管窗口、SwiftUI 负责绘制，见 `ADR-0002`。
- 唯一播放状态来源：`PlaybackDetecting` 协议背后的 Provider 集合，见 `ADR-0001`。不得在 UI 层直接调用 CoreAudio、AppleScript 或 MediaRemote。
- 明确非目标：见 `docs/PROJECT-CONTEXT.md`「非目标」；不得以"顺手实现"为由扩大范围。

## 播放检测硬规则

- 所有检测器实现 `PlaybackDetecting`，输出统一的 `PlaybackSnapshot`（状态、来源应用、可选元数据、采样时间）。UI 只消费该快照。
- 采样默认 1s 一轮；状态切换必须经过去抖动（连续 2 次同向采样才切换），避免碟片转动频繁启停。
- 系统自身或被忽略的进程不得触发播放态：`afplay`、Spindle 自身、系统提示音必须排除。
- 检测器失败必须降级为 `.unknown` 并保持上一次已确认的可见状态，不得抛出到 UI 或让界面闪成待机。
- 未验证的能力不得写入验收标准。MediaRemote 通道当前状态为"未证实"，只能以 feature flag 形式存在，且在默认配置下关闭。
- 不得为"让检测看起来更准"而引入辅助功能、屏幕录制或输入监控权限。零额外权限是产品约束，不是可选项。

## 视觉硬规则

- 写任何界面代码前，必须先读 `docs/design/visual-spec.md`；规范未覆盖的尺寸、颜色、时长，先补规范再实现，不允许临时硬编码。
- 颜色、字号、圆角、间距、动画时长一律走 `DesignTokens`（随骨架一同建立），禁止在 View 里写字面量。
- 碟片旋转必须由"播放中"状态驱动并累加角度；暂停时惯性减速至停（2.2s）、停在该时刻的角度，不做角度归位、不做回弹、不做淡出。
- 外观规格变更属产品变更：先改 `visual-spec.md`，再改实现；两者不一致时以规范为准并记录差异。
- 窗口必须不抢焦点、不出现在 Dock、不进入 ⌘-Tab 切换列表、不随 Mission Control 移动位置（参数见 `ADR-0002`）。

## 验证

- 已跑通（2026-11-13，macOS 27.0.1 / Swift 6.4.2 实测）：

      swift build -c release                  # 编译
      ./scripts/build-app.sh                  # 组装 dist/Spindle.app（Info.plist 含 LSUIElement）
      ./scripts/build-app.sh --install        # 另装到 ~/Applications/Spindle.app（不动 /Applications）
      open dist/Spindle.app                   # 启动：窗口 344×344、layer=3 浮动、无 Dock 图标
      .build/release/Spindle --render <path>  # 渲染评审图，688×688，不依赖屏幕截图

- 检测链路尚未接入，因此"播放 → 暂停 → 退出播放器"的三态回归**尚未验证**，接入后必须补跑。
- 人工验场景：碟片旋转无频闪、暂停 2.2s 内停住且角度不回位、点击按键无视觉反馈、切换 Space 后窗口不移动。
- 验证梯度（目标形态，按风险选择层级）：① `swift build` ② 检测器单测（假 Provider + 固定采样序列）③ 三态真机回归 ④ 人工验收外观与手感。
- 优先只读检查；未实际运行的检查不得声称通过，未做的人工验证写明"未验证"。

## 行动与授权

- 回答、审查、诊断类请求默认只读；诊断不自动附带修复。
- 实现类请求持续推进到可运行、可交付状态，并完成与风险相称的验证。
- 未经明确授权，不 commit、不 push、不建 PR/tag/release、不打包发布、不移入 `/Applications`。
- 首次 `git init`、本地构建、本地运行属于任务范围内的可逆动作，可直接执行并在交付时说明。
- 删除、覆盖历史产物、修改外部应用或其配置前，先说明精确范围。
- 子代理策略：**禁止主动委派**。任务需要拆分时先提出，由用户决定。

## 命名

- 产品展示名：`Spindle`（README、窗口标题、菜单栏、关于面板一致使用该拼写）。
- 本地目录与仓库名：`spindle`。
- Bundle ID：`com.seanli.spindle`；后续测试 target 为 `com.seanli.spindle.tests`。
- 代码标识遵循 Swift 生态：类型 `PascalCase`、方法与属性 `camelCase`、文件名与类型同名。
- 新增 Skill 时按其规范使用小写连字符命名，不复用产品名。

## 文档一致性

- 稳定背景与技术事实的唯一来源：`docs/PROJECT-CONTEXT.md`；其他文档只摘要并链接，不复制。
- 长期取舍写入 `docs/decisions/ADR-NNNN-<slug>.md`，序号由主协调者统一分配。
- 视觉规则唯一来源：`docs/design/visual-spec.md`。
- 产品行为变化 → 更新 `PROJECT-CONTEXT.md` 的行为章节；架构或检测策略变化 → 新增或替代 ADR；仅实现细节变化 → 由代码与提交表达，不复制到文档。
- 暂不建立 PRD 与 `.ai-sync`：单会话开发、需求边界清晰时，这两层只会增加维护成本。出现并行任务或多会话交接时再引入 `.ai-sync/CURRENT.md` 与任务文件。

## 安全

- 不记录密钥、Token、Cookie、`.env` 内容或个人隐私数据。
- 不上传用户本机的音乐播放记录、曲名、封面到任何外部服务。
