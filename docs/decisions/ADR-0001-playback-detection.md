# ADR-0001：播放状态检测策略

Status: accepted（2026-11-13 标注「核心判据待复测」，见 Revision，未推翻前仍按本决策实现，但必须带降级路径）
Date: 2026-11-13
Owners: Shawn
Supersedes: none
Superseded by: none

## Context

产品只需要回答一个问题：现在有没有音乐在响。但"哪个应用在响"决定了能不能顺便拿到曲名与封面，进而决定碟面画什么。

本机实测（证据见 `PROJECT-CONTEXT.md`「播放检测能力矩阵」）：

1. **CoreAudio 进程音频活动可用且零权限**。通过 HAL 的 process object 列表可以逐进程读到 `isRunning`，播放音频的进程会被准确点亮。
2. **Apple Music 的 AppleScript 通道可用**，能拿到精确播放状态与完整元数据。
3. **网易云音乐没有脚本字典**（`sdef` 返回 -192），拿不到任何播放状态。
4. **MediaRemote 私有框架未证实**：无播放工况下返回 `nil`，无法判断是"确实没人播放"还是"调用者被 TCC 拦了"。在 macOS 27 上不可依赖。

约束：产品是桌面摆件，不能要求用户为它授权辅助功能、屏幕录制或输入监控；安装即用的仪式感不允许被权限弹窗打断。

## Decision

采用**分层 Provider**，主判据是 CoreAudio 进程音频活动：

- `PlaybackDetecting` 协议输出统一 `PlaybackSnapshot`（状态 `.playing / .paused / .idle / .unknown`、来源应用、可选元数据、采样时间）。
- **Provider A · AudioActivityProvider（主判据）**：监控白名单应用的进程音频活动（网易云、Spotify、Apple Music）。活跃即判 `.playing`，全部静默即判 `.idle`。零权限、通用。
- **Provider B · MusicAppleScriptProvider（精化）**：对 Apple Music 用 AppleScript 读精确 `player state` 与曲目信息，可把 A 通道的"出声"升级为"确实在播放 + 这歌叫什么"。
- **Provider C · MediaRemoteProvider（可选增强，默认关闭）**：仅作为未来补元数据的实验通道，feature flag 控制，不参与 v1 验收。
- 采样 1s 一轮，状态切换需连续 2 次同向采样（去抖动）。检测器异常统一降级为 `.unknown`，UI 保留上一次已确认状态。
- 排除清单：Spindle 自身、`afplay`、系统提示音进程不得触发播放态。

明确不采用：单独依赖 AppleScript（覆盖不了网易云）、单独依赖 MediaRemote（未证实且可能被 TCC 阻断）。

## Revision（2026-11-13，原型期实测）

原型落地后回头做了一次真实工况复核，出现与本文前提冲突的证据，记录在此，不代表决策已被推翻：

**事实**

- 2026-11-13 14:17，网易云音乐界面显示有曲目（mini 播放条），默认输出设备（外置耳机，id 141）的 `kAudioDevicePropertyDeviceIsRunningSomewhere = 1`，但网易云主进程 pid 24540 的 process object 读到 `isRunning = 0`。
- 同一次采样中唯一被点亮的输出进程是 iOS 模拟器的 `systemsoundserver-simd`；`kAudioDevicePropertyDeviceIsRunning` 始终为 `0`，说明只有 `IsRunningSomewhere` 有效。
- MediaRemote 在同一时段再次返回 `nil`。

**推断（未证实）**

- 若当时确实在播放，则 CoreAudio 进程归因对网易云不可靠，本文的"Provider A 主判据"不成立。
- 若当时是暂停，则进程归因可能仍成立，设备级的 `1` 只是模拟器音频服务在占用设备。

**由此确定的实现要求（无论上面哪条为真都成立）**

1. 检测层必须同时实现两条独立信号：进程归因（精确但可能失效）与设备活跃（粗但有信号），并由 `PlaybackDetecting` 做组合判定与降级。
2. 组合判据草案：白名单播放器进程在运行 **且** 输出设备 `IsRunningSomewhere = 1` → `.playing`；白名单应用都未运行 → `.idle`；其余情况 `.unknown` 并保留上一状态。
3. 必须记录"来源不确定"这一状态：当只有设备级信号时，LCD 显示通用文案，不臆造应用名。
4. 复测通过（播放/暂停两次采样同向）之前，任何文档不得声称"进程归因已可用"。

**复测计划**：网易云播放 → 采样 → 暂停 → 采样 → 退出应用 → 采样，三态各两次，记录 `isRunning` 与 `IsRunningSomewhere` 原始值。

## 落地实现（2026-11-13）

- `Playback/CoreAudioReader`：HAL 进程列表 → 每个进程的 bundle id 与 `kAudioProcessPropertyIsRunning`。
- `Playback/PlaybackMonitor`：1s 采样，连续两次同向才切换（去抖动）；白名单命中且进程在出声 → `.playing`；白名单应用在运行但不出声 → `.paused`；白名单应用都不在 → `.idle`。
- `Playback/MusicBridge`：仅当 Apple Music 在运行时查询，取曲名、艺人，并在曲目变化时导出封面原始数据。
- 白名单：`com.netease.163music` / `com.spotify.client` / `com.apple.Music` / `com.electron.yesplaymusic`。
- **认人靠可执行路径，不靠 bundle id**。Chrome 的音频由 `Google Chrome Helper (Aperitif)` 输出，该进程没有 App 包装、`NSRunningApplication` 查不到，只能 `proc_pidpath` 取路径匹配；同样排除 `simruntime` / `systemsoundserver` 这类系统噪声。
- **浏览器只参与"是否在出声"，不参与"暂停/待机"判定**。否则 Chrome 常年开着，碟片永远不会进待机。
- 实测：Chrome 网页播放 → LCD `▶ BROWSER · PLAYING`，碟片转动。
- 实测：网易云暂停 → LCD `II PAUSE`、碟片停住；网易云播放 → `▶ NETEASE · PLAYING`、碟片转动。

## Consequences

收益：

- 覆盖网易云这条主要路径，且不需要任何额外授权。
- Apple Music 工况下自动获得曲名与封面，碟面可印真实专辑图。
- 检测层与 UI 解耦，未来换通道不影响窗口与动画。

代价与风险：

- 网易云工况下可能只有状态、没有曲名封面——**视觉规格必须内建通用碟面方案**，不能把"有封面"当默认。
- "在出声"不等于"在播放"：试听、加载音效、系统声音都可能触发。用白名单 + 排除清单 + 去抖动降低误判，但接受残余误差。
- 轮询带来最多约 1 个采样周期的延迟，暂停到停转为 ≤3s 的体验目标。
- Apple Music 首次读取会弹一次自动化授权；用户拒绝时该通道静默失效，退回 A 通道，不得报错弹窗。
- 授权弹窗的前提是 `Info.plist` 里有 `NSAppleEventsUsageDescription`。缺这一条时 tccd 直接 `Refusing TCCAccessRequestIndirect`，连弹框都不会出现，表现为"曲名和封面全空、状态照常"——排查时先看 `log show --predicate 'process == "tccd"'` 有没有这条拒绝。

## Alternatives considered

- **只读 MediaRemote**：能同时拿到应用与元数据，理论上最优。但本机在 macOS 27 上未证实可用，且历史上该私有 API 多次被系统收紧密封。不可作为唯一依赖。
- **读播放器自身缓存或配置文件**：网易云缓存格式未公开、随版本变动，且属于未授权读取第三方应用内部数据。放弃。
- **UI 自动化 / OCR 读界面**：需要辅助功能与屏幕录制权限，违反零权限约束，且窗口布局变动即失效。放弃。
- **音频路由到虚拟设备做静音检测**：需要安装驱动、改变系统音频输出，破坏"安静摆件"的定位。放弃。
- **只看系统静音/输出设备是否被占用**：粒度太粗，视频与会议软件都会触发冷启动动画。仅在 A 通道不可用时作为兜底，暂不实现。

## Validation / review

## 控制通道（2026-11-13 追加，唯一例外）

检测链路仍然只读。为让机身三键能用，追加一条受控的写入通道：

- 范围：**只有 Apple Music** 的 `playpause` / `next track` / `previous track`，命令走 `PlaybackControlling`（实现 `MusicController`），与检测器同处 Playback 层；UI 只发命令。
- 触发：只能由用户显式点击（机身按键、菜单栏）触发，不得由定时器、状态变化或任何自动逻辑调用。
- 守卫：Music 未运行时不发命令、不拉起；网易云/Spotify 工况下命令不可达。
- 权限：与元数据读取同属 AppleEvents 自动化授权，不需要新权限；被拒绝时静默失效。
- 仍禁止：调音量、播放指定曲目、读歌单、写播放器状态文件、模拟快捷键（那要辅助功能权限）。
- 命令执行后强制采一次样并跳过当次去抖动，否则最长 1–2s 才看到碟片响应；300ms 内的重复点击直接丢弃，避免 AppleScript 排队。

- 用假 Provider 与固定采样序列做单测：去抖动、降级保留、排除清单。
- 三态人工回归：网易云播放 → 暂停 → 退出应用，每步观测停转时延。
- Apple Music 回归：播放 → 检查曲名与封面是否出现；拒绝授权后再跑一次，确认静默降级。
- 当 macOS 版本升级导致 `kAudioProcessPropertyIsRunning` 行为变化，或 MediaRemote 被证实可用时，重新评估本 ADR。
