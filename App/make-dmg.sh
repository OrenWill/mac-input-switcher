#!/bin/bash
set -e

# ──────────────────────────────────────────
#  输入法切换 — DMG 安装包生成脚本
# ──────────────────────────────────────────

APP_NAME="输入法切换"
VERSION="${1:-1.0.0}"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
APP_PATH="$BUILD_DIR/$APP_NAME.app"
DMG_PATH="$BUILD_DIR/${APP_NAME}_v${VERSION}.dmg"
TMP_DIR="$BUILD_DIR/dmg_tmp"
VOL_NAME="$APP_NAME v$VERSION"

echo "📦 生成 DMG 安装包 …"
echo "   版本: $VERSION"

# ── 检查 .app 是否存在 ──
if [[ ! -d "$APP_PATH" ]]; then
    echo "❌ 未找到 .app，请先运行 build.sh"
    exit 1
fi

# ── 准备 DMG 内容 ──
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"
cp -R "$APP_PATH" "$TMP_DIR/"

# 创建 /Applications 快捷方式
ln -s /Applications "$TMP_DIR/Applications"

echo "   内容就位: $TMP_DIR"

# ── 创建临时 DMG (可读写) ──
TEMP_DMG="$BUILD_DIR/temp.dmg"
rm -f "$TEMP_DMG" "$DMG_PATH"

SIZE_MB=$(( $(du -sm "$TMP_DIR" | cut -f1) + 20 ))
hdiutil create -size ${SIZE_MB}m -fs HFS+ -volname "$VOL_NAME" "$TEMP_DMG" >/dev/null 2>&1

# ── 挂载 DMG 并复制内容 ──
MOUNT_POINT="/Volumes/$VOL_NAME"
# 清理可能的旧挂载
hdiutil detach "$MOUNT_POINT" 2>/dev/null || true

DEVICE=$(hdiutil attach -readwrite -noverify -noautoopen "$TEMP_DMG" 2>/dev/null | egrep '^/dev/' | sed 1q | awk '{print $1}')
if [[ -z "$DEVICE" ]]; then
    echo "❌ 挂载 DMG 失败"
    exit 1
fi

echo "   已挂载: $DEVICE → $MOUNT_POINT"
sleep 0.5

# 复制文件到 DMG
cp -R "$TMP_DIR"/* "$MOUNT_POINT/"
sleep 0.5

# ── 设置 Finder 窗口布局（GUI 环境下优化安装体验）──
echo "   设置安装窗口布局 …"

# 先卸载再重启 Finder 设置（避免 Finder 占用问题）
hdiutil detach "$DEVICE" -force >/dev/null 2>&1 || true
sleep 1

# 重新挂载
DEVICE=$(hdiutil attach -readwrite -noverify -noautoopen "$TEMP_DMG" 2>/dev/null | egrep '^/dev/' | sed 1q | awk '{print $1}')
sleep 0.5

# 尝试设置窗口布局，非 GUI 环境会静默失败
osascript 2>/dev/null <<EOF || true
tell application "Finder"
    tell disk "$VOL_NAME"
        open
        delay 0.8
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {200, 200, 560, 430}
        set theViewOptions to the icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to 80
        set position of item "$APP_NAME.app" of container window to {80, 80}
        set position of item "Applications" of container window to {280, 80}
        update without registering applications
        delay 0.3
        close
    end tell
end tell
EOF

echo "   窗口布局设置完成"

# 等待 Finder 完成
sleep 1

# ── 卸载并转换为压缩 DMG ──
echo "   卸载并压缩 …"
hdiutil detach "$DEVICE" -force >/dev/null 2>&1
sleep 0.5

hdiutil convert "$TEMP_DMG" -format UDZO -imagekey zlib-level=9 -o "$DMG_PATH" >/dev/null 2>&1

# 清理
rm -f "$TEMP_DMG"
rm -rf "$TMP_DIR"

# ── 结果 ──
echo ""
echo "═════════════════════════════════"
echo "  ✅ DMG 安装包已生成"
echo "═════════════════════════════════"
echo ""
echo "  📦 $DMG_PATH"
echo "  📏 大小: $(du -sh "$DMG_PATH" | cut -f1)"
echo ""
echo "  使用方法:"
echo "    1. 将 $APP_NAME.app 拖入 Applications 文件夹"
echo "    2. 双击 Applications 中的 $APP_NAME 启动"
echo ""
open "$BUILD_DIR"
