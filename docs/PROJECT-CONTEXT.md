# Spindle · 项目背景

> 稳定事实的单一来源。任务流水、临时实验和未定方案不写在这里。
> Document updated at: 2026-11-13（初始提交 `800c7da` 之后的工作树）
> Last verified against: 本机实测，见「技术栈与运行方式」中的环境事实与「播放检测能力矩阵」的证据列。

## 产品定位

Spindle 是 Mac 桌面上的一台 CD 播放器摆件。它不播放音乐，只把"音乐正在响"这件外部事实，翻译成碟片的转动与停止。

它存在的理由是仪式感：每天上班打开电脑，看见碟片开始转，确认自己进入了工作状态。因此它必须**好看、安静、不需要操作**——用户永远不需要在它身上点第二下。

当前形态（已确认）：

- 复古 Discman 外观，约 320pt，始终浮在所有窗口之上。
- 主音乐源：网易云音乐（只能判断是否在播放）；Apple Music 作为精确通道补充。
- 极简交互：机身三键与菜单栏三项只负责 Apple Music 的上一曲/播放暂停/下一曲，不做其他控制。
- 开机自启：菜单栏「开机启动」勾选项，走系统登录项（`SMAppService`），默认关闭；不写 LaunchAgents、不申请额外权限。
- 碟面：能拿到封面（目前只有 Apple Music）时默认印专辑封面，可在菜单栏切回六种自有碟面；拿不到封面时菜单里不出现「专辑封面」，碟面回落上次手选的自有样式（默认银色压模）。

## 技术栈与运行方式

| 项 | 事实 |
| --- | --- |
| 目标平台 | macOS（仅本机，不发行到其他设备） |
| 本机系统 | macOS 27.0.1（Build 26A434），arm64 |
| 语言与工具链 | Apple Swift 6.4.2（swiftlang-6.4.2.1.9），`swift target arm64-apple-macosx27.0.0` |
| Xcode | `/Applications/Xcode.app/Contents/Developer`（`xcode-select -p` 实测） |
| Homebrew | `/opt/homebrew/bin/brew` 可用 |
| 已安装播放器 | `NeteaseMusic.app`、`Spotify.app`、`YesPlayMusic.app`（`/Applications`），Apple Music 为 `/System/Applications/Music.app` |
| 未安装 | `nowplaying-cli`、`media-control`（`which` 无输出） |
| 构建形态 | SwiftPM 可执行包，AppKit 管窗口 / SwiftUI 绘制，详见 ADR-0002 |
| 运行方式 | 已建立并实测：`swift build -c release` → `./scripts/build-app.sh` → `open .build/Spindle.app`；`./scripts/build-app.sh --install` 另装一份到 `~/Applications/Spindle.app`；评审图用 `.build/release/Spindle --render <path>`（688×688）。启动后窗口 344×344、`layer=3` 浮动、无 Dock 图标 |

关键入口：

- `Sources/Spindle/main.swift` — 应用入口、NSPanel 装配、菜单栏、`--render` 渲染模式。
- `Sources/Spindle/RotationModel.swift` — 角度累加与惯性停转。
- `Sources/Spindle/BodyView.swift` — 机身、仓盖、碟片、LCD、按键、贴纸的绘制。
- `Sources/Spindle/DesignTokens.swift` — 颜色、字号、圆角、间距、动效时长。
- `scripts/build-app.sh` — SwiftPM 产物 → `.build/Spindle.app`（中间产物，不进 dist）；`--install` 额外覆盖安装到 `~/Applications/Spindle.app`（不碰 `/Applications`）。

## 播放检测能力矩阵

矩阵中的结论全部来自本机实测，不是设计推测。任何未标"已证实"的能力不得进入验收标准。

| 通道 | 能拿到什么 | 获取方式 | 实测证据 | 状态 |
| --- | --- | --- | --- | --- |
| CoreAudio 进程音频活动 | 任意进程当前是否在输出音频（含网易云、Spotify、浏览器） | HAL 的 `kAudioHardwarePropertyProcessObjectList` + `kAudioProcessPropertyPID` + `kAudioProcessPropertyIsRunning` | ① `afplay` 播放测试音频时读到 `isRunning=1`，其余为 0；② 14:17 网易云暂停态 → `isRunning=0`（用户确认当时为暂停）；③ 14:24 网易云播放态 → `isRunning=1`，同刻 `deviceRunningSomewhere=1`。两次异态采样同向 | **已证实可用，零权限**：状态随播放/暂停翻转，可作为主判据 |
| Apple Music AppleScript | 精确播放状态、曲名、艺人、专辑封面 | `osascript -e 'tell application "Music" to get player state'` | 返回 `stopped`（未播放时），通道通畅 | **已证实可用**；首次调用会触发 macOS 自动化授权弹窗 |
| 网易云 AppleScript | — | `sdef /Applications/NeteaseMusic.app` | 返回 error -192，无脚本字典 | **不可用**，只能靠上层通道 |
| 系统 Now Playing（MediaRemote） | 播放应用、曲名、艺人、封面、播放速率 | `dlopen` 私有框架 `MediaRemote` 调 `MRMediaRemoteGetNowPlayingInfo` | 两次实测（含疑似播放工况）均返回 `nil`，用 `nowplaying-cli`/`media-control` 也不在本机 | **本机不可用**，不得作为检测来源 |
| 输出设备活跃状态 | 系统当前有没有任何音频在输出（无来源归因） | `kAudioHardwarePropertyDefaultOutputDevice` + `kAudioDevicePropertyDeviceIsRunningSomewhere` | 播放工况读到 `1`（默认输出为「外置耳机」id 141）；`kAudioDevicePropertyDeviceIsRunning` 为 `0`，说明只有 `Somewhere` 这个判据有效 | **已证实可读，零权限**；粒度粗，会被会议、视频、提示音触发 |

由此形成的当前判断（2026-11-13 修订，不再是 v1 的乐观版本）：

- **没有一条通道能同时满足「零权限 + 能归因到网易云」**。进程级归因在网易云上至少一次未点亮；设备级能证明"有声音在走"但不知道是谁；MediaRemote 在本机不可用。
- "在放哪首歌"只有 Apple Music 稳定可读。网易云工况下必须能在没有曲名与封面的前提下成立——这对视觉规格是硬约束（碟面自带通用方案）。
- 检测策略需要在 ADR-0001 的修订里重新定：候选是「白名单应用在运行 + 输出设备活跃」的组合判据，代价是会误判会议与视频。

| 浏览器网页音频 | 网页是否在出声（Chrome / Safari / Edge / Firefox） | HAL 进程列表 + 可执行路径识别 | 2026-11-13 实测：Chrome 播放时点亮的是 `Google Chrome Helper (Aperitif)`（pid 82286），`isRunning=1`；同刻 iOS 模拟器的 `systemsoundserver-simd` 也常亮，必须排除 | **可用，但只能判断"在出声"**：拿不到网站、曲名、封面 |

**关键坑**：`Google Chrome Helper (Aperitif)` 这类音频辅助进程没有 App 包装，`NSRunningApplication(processIdentifier:)` 返回 nil。用 bundle id 认人的实现会直接漏判浏览器。必须改用 `proc_pidpath` 按可执行路径识别（实现里已改）。

## 已完成的一次复测（2026-11-13）

原计划"播放 → 暂停 → 退出"三态各两次。已完成前两态：

| 时刻 | 网易云 | 进程 `isRunning` | 设备 `IsRunningSomewhere` | 结论 |
| --- | --- | --- | --- | --- |
| 14:17 | 暂停（用户确认） | 0 | 1（来自 iOS 模拟器的音频服务） | 暂停态不点亮，符合预期 |
| 14:24 | 播放 | 1 | 1 | 播放态点亮，进程归因成立 |

因此 **ADR-0001 的"进程归因作为主判据"前提成立**，14:17 那次不是反证。仍缺的一态是"退出播放器"：需确认退出后 process object 是否会消失（应判 `.idle` 而非 `.unknown`）。

已知语义误差（需在设计上接受，不是待修 Bug）：

- CoreAudio 只能证明"该进程在输出音频"，不能区分是主播放还是试听、提示音、加载音效。
- 采样是轮询的，最长有约 1 个采样周期的延迟；暂停与停转之间允许 ≤3s 的误差。
- 多个播放器同时出声时，本产品只回答"有没有在出声"，来源应用取白名单中第一个活跃者。

## 元数据能力（2026-11-13 播放态实测）

目标是曲名、艺人、专辑封面。在网易云**正在播放**的工况下逐条试过，结论如下：

| 通道 | 结果 | 说明 |
| --- | --- | --- |
| MediaRemote（私有框架 NowPlayingInfo） | 播放态仍返回 `nil` | 网易云不向系统注册 Now Playing，此路彻底不通 |
| 辅助功能 AX 树 | 窗口可读（err=0），但全树仅 42 个节点且**无任何文字节点** | Electron 未开启 renderer accessibility，界面文本不暴露 |
| CGWindowList 窗口标题 | 13 个窗口 title 全为空 | 网易云不设窗口标题；读标题还需屏幕录制权限 |
| 网易云本地文件 | 播放期间 container 与 Group Container 均无新写入，无状态文件 | 无本地 now-playing 落盘 |
| AppleScript / sdef | error -192，无脚本字典 | 走不通 |
| 屏幕捕捉 + OCR | **可行**：悬浮播放条 334×50（@2x 668×100）内含封面缩略图、曲名、艺人 | 需屏幕录制权限，且封面源图仅 80×80 |

**Apple Music 的对照结论（同一轮实测）**：

| 通道 | 结果 |
| --- | --- |
| AppleScript（`player state` / `name` / `artist` / `album`） | 可用，返回真实值 |
| AppleScript 导出 `data of artwork 1 of current track` | 可用，得到封面原始字节，可直接解成图片 |

代价是首次调用弹一次「控制 Music」的自动化授权；且只在 Music 已在运行时才查询，Spindle 不主动拉起它。

**结论**：网易云工况下，零权限拿不到任何曲名或封面；唯一可得的通道是截取它自己的悬浮播放条。封面源图 80×80，放大到碟面（Ø200pt @2x = 400px）为 5 倍插值，需要视觉处理掩盖。

## 质量底线

| 维度 | 底线 | 验证方式 |
| --- | --- | --- |
| 零权限 | 除 Apple Music 的自动化授权外，不申请辅助功能、屏幕录制、输入监控 | 首次运行与设置面板检查，授权条目应为 0 新增 |
| 默认只读 | 除 Apple Music 的播放/暂停/切歌外，任何代码路径都不调用播放器控制接口，也不写播放器状态文件 | 静态检查 + 人工确认无其他控制类调用 |
| 零网络 | 运行时无出站请求 | 网络监控或代码审查；无 URLSession/网络依赖 |
| 安静 | 不抢焦点、不进 Dock、不进 ⌘-Tab、不遮挡输入 | 实机确认窗口行为参数 |
| 稳 | 检测失败降级为保留上一状态，界面不闪 | 假 Provider 单测 + 手动杀掉检测通道 |
| 轻 | 空闲 CPU 目标 <3%，内存目标 <100MB | Activity Monitor 实测；**目标值，尚未测** |
| 准 | 暂停 → 停转 ≤3s；退出播放器 → 待机 ≤3s | 三态人工回归 |

## 非目标

- 不做完整播放器：不调音量、不读歌单、不搜歌、不写回任何播放器状态文件。
- 唯一的控制例外是 Apple Music 的上一曲/播放暂停/下一曲，只能由用户点击机身按键或菜单栏触发，不得自动调用，也不得把未运行的播放器拉起来。
- 不做在线元数据补全：不请求网易云或任何 API 去换曲名与封面。
- 不做历史与统计：不记录每天听了什么，不做周报。
- 不做多屏复杂布局、不做主题商店、不做手机端与同步。
- 不做分发：不签名公证、不上架、不提供安装包给他人。

## 文档地图

| 文档 | 职责 |
| --- | --- |
| `README.md` | 对外一句话说明、当前阶段、目录与权威指向 |
| `AGENTS.md` | 协作规则、边界、授权、验证要求、命名 |
| `docs/PROJECT-CONTEXT.md` | 本文档：稳定背景、环境事实、能力矩阵、质量底线、非目标 |
| `docs/decisions/ADR-0001-playback-detection.md` | 播放状态如何判定、为什么这样判定 |
| `docs/decisions/ADR-0002-tech-stack-and-window.md` | 技术栈、窗口层级与渲染方案 |
| `docs/design/visual-spec.md` | 视觉与 token 的唯一来源（已定稿 v1） |

## 变更记录

- 2026-11-13：建立项目记忆。完成播放检测通道实测（CoreAudio 与 Apple Music 可用、网易云脚本不可用、MediaRemote 未证实），据此定下 ADR-0001 / ADR-0002。尚未有源码。
- 2026-11-13：检测复核。用户确认 14:17 网易云为暂停态，14:24 播放态复测读到进程 `isRunning=1`；两次异态采样同向，进程归因主判据成立，撤回当日早间的"反证"表述。
- 2026-11-13：落地首个可运行骨架（`Sources/Spindle` + `scripts/build-app.sh`）：静态机身、碟片旋转与惯性停转、LCD 两态文案。`swift build -c release`、`--render` 渲染 688×688、`open dist/Spindle.app` 三项实测通过；窗口实测 `layer=3`、344×344、无 Dock 图标。检测尚未接入。
- 2026-11-13：按用户确认的四项方向（香槟银 / LCD 曲名跑马灯 / 无封面用 SPINDLE 丝印碟面 / 按键完全静态）定稿 `docs/design/visual-spec.md` v1，并把暂停行为从"瞬时冻结"修正为"惯性减速后停在原角度"，同步 AGENTS 与 ADR-0002。
- 2026-11-13：碟面新增「专辑封面」并设为有封面时的默认（`DiscStyle.albumArt` + `DiscToken.autoArtwork`），自有碟面手选后不被封面顶掉；拿不到封面的曲目菜单中不出现该项，并清掉旧封面避免残留。规格见 `visual-spec.md` v1.8，渲染实测通过，真机 Apple Music 工况未验证。
- 2026-11-16：菜单栏新增「开机启动」勾选项，走 `SMAppService` 系统登录项，默认关闭；注册/注销与系统状态同步。规格见 `visual-spec.md` v1.11。
- 2026-11-13：机身三键改为可操作（左 上一曲 / 中 播放暂停 / 右 下一曲），只对 Apple Music 生效，按压无视觉反馈；同时改写「只读原则」为「默认只读 + 一个显式例外」。规格见 `visual-spec.md` v1.10。
- 2026-11-13：`build-app.sh` 增加 `--package`，出 `arm64+x86_64` 通用二进制的 `dist/Spindle-<版本>.zip`（含「首次打开必读」），供同事直接解压使用；签名仍为 ad-hoc，首次打开需右键或去隔离属性。
- 2026-11-13：`build-app.sh` 增加 `--install`（覆盖安装到 `~/Applications`，供 Launchpad/聚焦找到）；退出运行中实例改用 `pgrep`+`kill`，`pkill` 在受限环境取不到进程列表。
- 2026-11-13：修掉 `Info.plist` 缺 `NSAppleEventsUsageDescription` 导致 Apple Music 元数据全空的问题（tccd 直接拒绝、不弹授权框）。补上后授权生效，封面导出实测 800×800 PNG；重建 app 不会重复要授权。见 ADR-0001 的权限说明。
- 2026-11-13：菜单栏图标默认改为「转动残影」；应用图标落地为同一套碟片线稿（闭合细环版），定稿石墨黑配色（`AppIconScheme.graphite`），四套方案对照图见 `docs/design/renders/appicon/`；`build-app.sh` 构建时自动生成 `AppIcon.icns`。规格见 `visual-spec.md` v1.9。
- 2026-11-13：皮肤化（graphite / bone / steel）与碟面五款（silver / hologram / label / crystal / gold）落地，菜单栏加「皮肤」「碟面」子菜单；状态栏图标改为自绘线稿并支持三风格 × 三状态，随播放状态变化。
- 2026-11-13：新增第六款碟面「吉卜李」（`DiscStyle.jibuli`），题材为预压的 `Assets/disc-jibuli.png`（800×800，原图按正方形裁切、头像居中，纯图案无文字），构建时拷入 `Contents/Resources/`；修掉中央高光灰雾、轴环灰斑等表层干扰，终版按用户要求去掉全部文字、轴环与中心孔。`--render-discs` 出六张，对照图由 `scripts/make-disc-contact-sheet.py` 生成。
