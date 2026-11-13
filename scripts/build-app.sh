#!/usr/bin/env bash
# 把 SwiftPM 产物组装成可运行的 .app。
# 用法：默认只出 dist/Spindle.app；--install 装到 ~/Applications；
#      --package 出通用二进制（Intel + Apple 芯片）并打 zip，给同事直接解压即用。
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="release"
INSTALL=0
PACKAGE=0
UNIVERSAL=0
for arg in "$@"; do
  case "$arg" in
    --install) INSTALL=1 ;;
    --package) PACKAGE=1; UNIVERSAL=1 ;;
    --universal) UNIVERSAL=1 ;;
    debug|release) CONFIG="$arg" ;;
    *) echo "unknown argument: $arg" >&2; exit 2 ;;
  esac
done
APP="$ROOT/dist/Spindle.app"
# 安装副本放用户目录，不碰 /Applications（见 AGENTS「行动与授权」）
DEST="$HOME/Applications/Spindle.app"

if [ "$UNIVERSAL" = 1 ]; then
  # 通用二进制：同事的机器可能是 Intel，arm64 单架构会直接跑不起来。
  # x86_64 在 macOS 27 SDK 上会有 deprecation 警告，不影响产物。
  swift build -c "$CONFIG" --arch arm64 --arch x86_64 --package-path "$ROOT"
else
  swift build -c "$CONFIG" --package-path "$ROOT"
fi

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$ROOT/.build/$CONFIG/Spindle" "$APP/Contents/MacOS/Spindle"

# 打包碟面素材
if [ -d "$ROOT/Assets" ]; then
  cp -R "$ROOT/Assets/." "$APP/Contents/Resources/"
fi

# 应用图标：自绘碟片线稿 → icns（每次构建重渲染，配色改 AppIconScheme）
ICONSET="$ROOT/.build/AppIcon.iconset"
rm -rf "$ICONSET"
mkdir -p "$ICONSET"
"$ROOT/.build/$CONFIG/Spindle" --render-app-icon "$ICONSET" >/dev/null
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key><string>Spindle</string>
  <key>CFBundleIdentifier</key><string>com.seanli.spindle</string>
  <key>CFBundleName</key><string>Spindle</string>
  <key>CFBundleDisplayName</key><string>Spindle</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>0.1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>LSUIElement</key><true/>
  <key>NSHighResolutionCapable</key><true/>
  <!-- Apple Music 元数据通道要发 AppleScript；缺这条 tccd 会直接拒绝而不会弹授权框 -->
  <key>NSAppleEventsUsageDescription</key><string>读取 Apple Music 的播放状态、曲名与封面，用于驱动碟片显示。</string>
</dict>
</plist>
PLIST

codesign --force --sign - "$APP" >/dev/null 2>&1 || true

if [ "$INSTALL" = 1 ]; then
  # 覆盖一个正在运行的 bundle 会把进程的半张二进制抽掉，先退出所有实例。
  # 不用 pkill：它在受限环境里取不到进程列表（sysmon: Cannot get process list），
  # pgrep + kill 在同一台机上更稳。
  for pid in $(pgrep -f "Spindle.app/Contents/MacOS/Spindle" 2>/dev/null || true); do
    kill "$pid" 2>/dev/null || true
  done
  sleep 1
  mkdir -p "$(dirname "$DEST")"
  rm -rf "$DEST"
  ditto "$APP" "$DEST"
  echo "$DEST"
  open "$DEST"
else
  echo "$APP"
fi

if [ "$PACKAGE" = 1 ]; then
  VERSION="$(plutil -extract CFBundleShortVersionString raw "$APP/Contents/Info.plist")"
  STAGE="$ROOT/dist/package"
  ZIP="$ROOT/dist/Spindle-$VERSION.zip"
  rm -rf "$STAGE"
  mkdir -p "$STAGE"
  ditto "$APP" "$STAGE/Spindle.app"

  cat > "$STAGE/首次打开必读.txt" <<'TXT'
Spindle 首次打开必读

1. 解压后把 Spindle.app 拖到「应用程序」或任意固定位置（不必非放 /Applications）。
2. 第一次打开：Finder 里右键点 Spindle.app →「打开」→ 弹窗里再点「打开」。
   直接双击可能提示"Apple 无法检查是否包含恶意软件"——这是没做公证的正常现象，不是坏了。
   若右键菜单里没有「打开」，终端执行：
       xattr -dr com.apple.quarantine /Applications/Spindle.app
3. 打开后不会出现在 Dock，也不在 ⌘-Tab 列表里；它只在屏幕顶部菜单栏有个小碟片图标，
   点它就能看状态、换碟面、退出。
4. 第一次放 Apple Music 时，系统会问"Spindle 想控制 音乐"，点「允许」。
   允许后才能读到曲名与封面；拒绝也能用，只是没有歌名和封面。
5. 需要 macOS 14 或更新；Intel 与 Apple 芯片（M 系列）都可以。
6. 它不联网，也不控制播放器——只读取"是否在出声"，用来驱动碟片转/停。
7. 只支持 Apple Music 的歌名与封面；网易云、Spotify 目前只有转/停状态。
TXT

  rm -f "$ZIP"
  ( cd "$STAGE" && zip -rq "$ZIP" . )
  rm -rf "$STAGE"
  echo "$ZIP"
fi
