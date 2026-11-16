# Spindle

一台住在 Mac 桌面上的 CD 播放器。它不播放音乐——它只是把"音乐响起来了"这件事，变成每天早上开机的一次仪式。

网易云音乐或 Apple Music 开始出声，Spindle 的碟片开始转；音乐停下，碟片停在原地。它没有播放按钮，也不抢你的键盘。

## 现在是什么

v0.2 · **播放检测已接入**。香槟银机身、仓盖、碟片、蓝色 LCD、三个静态按键，碟片的转与停由真实播放状态驱动：播放时转、暂停时惯性减速停住、播放器退出后待机。Apple Music 还能给出曲名、艺人与真实封面；网易云只给得出状态，LCD 退回 `NETEASE · PLAYING`，碟面用丝印。

```
swift build -c release          # 编译
./scripts/build-app.sh          # 组装 .build/Spindle.app
open .build/Spindle.app         # 启动（无 Dock 图标，菜单栏有退出入口）

# 想让它出现在 Launchpad / 聚焦搜索里：装一份到 ~/Applications（不碰 /Applications）
./scripts/build-app.sh --install

# 给同事：通用二进制（Intel + Apple 芯片）+ 首次打开说明，输出 dist/Spindle-<版本>.zip
./scripts/build-app.sh --package
```

评审图可离线渲染，不依赖截图：

```
.build/release/Spindle --render docs/design/renders/prototype-playing@2x.png
```

皮肤可切换：菜单栏「皮肤」子菜单（香槟银 / 石墨黑 / 白色塑料 / 拉丝钢）。碟面样式同样在菜单里切（银色压模 / 全息彩虹 / 印刷标签 / 透明水晶 / 金碟 / 吉卜李）。能拿到封面时（目前只有 Apple Music）默认选「专辑封面」，把这张专辑直接印在盘上；切到任一自有碟面后就按自己的选择走，不会被下一首的封面抢回去。拿不到封面时菜单里不出现「专辑封面」，碟面回落到上次手选的自有样式（默认银色压模）。「吉卜李」是把用户自己的卡通形象预压成 `Assets/disc-jibuli.png` 的纯图案盘：整盘只有一张画、头像居中，不带文字与中心孔；构建时会自动拷进 `Contents/Resources/`。离线渲染对照：

```
.build/release/Spindle --render-skins docs/design/renders/skins
.build/release/Spindle --render-discs docs/design/renders/discs
.build/release/Spindle --artwork <封面图> --render out.png    # 带封面的评审图
python3 scripts/make-disc-contact-sheet.py       # 六款碟面拼成一张对照图
```

下一阶段：三态验收（播放 / 暂停 / 待机已各自观测过，还缺「退出播放器 → STANDBY」这一态）与视觉打磨。检测通道的实测结论见 `docs/PROJECT-CONTEXT.md`「播放检测能力矩阵」「元数据能力」。

## 形态（已确认）

- **外观**：复古 Discman。香槟银金属机身、蓝色 LCD、机械按键、贴纸标签。
- **尺寸**：约 320pt。
- **层级**：始终浮在所有窗口之上。
- **图标**：菜单栏默认「转动残影」，可在菜单里换风格；应用图标与菜单栏同一套自绘碟片线稿（闭合细环版），定稿石墨黑配色，构建时生成 `AppIcon.icns`，四套方案对照见 `docs/design/renders/appicon/`。
- **音乐源**：网易云音乐为主（仅能判断是否在播放，可能没有曲名与封面）；Apple Music 作为精确通道补充。

## 不做什么

- 不做播放器：不选歌、不切歌、不调音量、不写回任何第三方 App 的状态。
- 不联网、不登录、不读歌单、不读历史记录。
- 不做手机端、不做账号、不做云同步。
- 不做"多个播放器同时播放"的复杂仲裁——只回答"现在有没有在出声"。

## 目录

| 路径 | 内容 |
| --- | --- |
| `AGENTS.md` | 协作规则、边界、授权与验证要求 |
| `docs/PROJECT-CONTEXT.md` | 稳定项目背景、技术栈、播放检测能力矩阵、非目标 |
| `docs/decisions/` | 长期技术决策（ADR） |
| `docs/design/visual-spec.md` | 视觉规格与 token（v1.9） |
| `docs/design/renders/` | 离线渲染的评审图 |
| `Sources/Spindle/` | 应用源码 |
| `scripts/build-app.sh` | 组装 `.app`；`--install` 装到 `~/Applications`；`--package` 出通用二进制 zip |

## 运行

尚未实现。构建与运行命令会在首个可运行骨架落地、且实际跑通后写入 `docs/PROJECT-CONTEXT.md`「技术栈与运行方式」——本文件不预先声明未验证的命令。

## 文档权威

- 产品行为与验收口径：`docs/PROJECT-CONTEXT.md`。
- 长期技术取舍：`docs/decisions/`。
- 视觉规则：`docs/design/visual-spec.md`。
- 协作规则与授权：`AGENTS.md`。
