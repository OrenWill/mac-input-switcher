#!/bin/bash
set -e

# ──────────────────────────────────────────
#  输入法切换 — macOS 应用构建脚本
#  M 系列芯片原生 (arm64)
# ──────────────────────────────────────────

APP_NAME="输入法切换"
BUNDLE_NAME="InputSwitcher"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$PROJECT_DIR/App"
BUILD_DIR="$PROJECT_DIR/build"
BUNDLE="$BUILD_DIR/$APP_NAME.app"

echo "🔨 构建 $APP_NAME.app …"
echo "   目标平台: arm64-apple-macos13.0"

# ── 清理 ──
rm -rf "$BUILD_DIR"
mkdir -p "$BUNDLE/Contents/MacOS"
mkdir -p "$BUNDLE/Contents/Resources"

# ── 编译 ──
echo "   编译 Swift 源码 …"
swiftc \
    -target arm64-apple-macos13.0 \
    -framework AppKit \
    -framework Carbon \
    -framework ServiceManagement \
    -framework SwiftUI \
    -O \
    -o "$BUNDLE/Contents/MacOS/$BUNDLE_NAME" \
    "$APP_DIR/main.swift" \
    "$APP_DIR/InputMethodManager.swift" \
    "$APP_DIR/InputMethodViewModel.swift" \
    "$APP_DIR/AppDelegate.swift" \
    "$APP_DIR/SettingsView.swift" \
    "$APP_DIR/UpdateChecker.swift" \
    "$APP_DIR/UpdateAlertView.swift" \
    "$APP_DIR/PreferencesWindowController.swift"

echo "   ✅ 编译成功"
file "$BUNDLE/Contents/MacOS/$BUNDLE_NAME"

# ── Info.plist ──
cp "$APP_DIR/Info.plist" "$BUNDLE/Contents/Info.plist"

# ── 图标 ──
if [[ -f "$APP_DIR/AppIcon.icns" ]]; then
    cp "$APP_DIR/AppIcon.icns" "$BUNDLE/Contents/Resources/AppIcon.icns"
    echo "   应用图标已就位"
fi

# ── 菜单栏图标 ──
if [[ -f "$APP_DIR/menu_icon.png" ]]; then
    cp "$APP_DIR/menu_icon.png" "$BUNDLE/Contents/Resources/menu_icon.png"
    cp "$APP_DIR/menu_icon@2x.png" "$BUNDLE/Contents/Resources/menu_icon@2x.png"
    echo "   菜单栏图标已就位"
fi

# ── PkgInfo ──
echo -n "APPL????" > "$BUNDLE/Contents/PkgInfo"

# ── 代码签名 (ad-hoc) ──
echo "   代码签名 (ad-hoc) …"
codesign --force --deep --sign - "$BUNDLE"

# ── 清除隔离属性 ──
xattr -cr "$BUNDLE" 2>/dev/null || true

# ── 完成 ──
echo ""
echo "═════════════════════════════════"
echo "  ✅ 构建完成"
echo "═════════════════════════════════"
echo ""
echo "  📦 $BUNDLE"
echo ""
echo "  使用方式:"
echo "    1. 双击 $APP_NAME.app 启动"
echo "    2. 拖入 /Applications 以启用开机自启动"
echo ""
echo "  如需安装到 /Applications:"
echo "    cp -r '$BUNDLE' /Applications/"
echo ""

# ── 可选：直接安装 ──
if [[ "$1" == "--install" ]]; then
    echo "📥 安装到 /Applications …"
    rm -rf "/Applications/$APP_NAME.app"
    cp -r "$BUNDLE" "/Applications/"
    echo "✅ 已安装到 /Applications/"
    echo "   双击打开: open '/Applications/$APP_NAME.app'"
fi

# ── 可选：生成 DMG ──
if [[ "$1" == "--dmg" ]]; then
    echo ""
    "$APP_DIR/make-dmg.sh" "${2:-1.0.0}"
fi

# ── 一键构建 + 安装 + DMG ──
if [[ "$1" == "--all" ]]; then
    # 安装
    echo "📥 安装到 /Applications …"
    rm -rf "/Applications/$APP_NAME.app"
    cp -r "$BUNDLE" "/Applications/"
    echo "✅ 已安装到 /Applications/"
    # DMG
    echo ""
    "$APP_DIR/make-dmg.sh" "${2:-1.0.0}"
fi
