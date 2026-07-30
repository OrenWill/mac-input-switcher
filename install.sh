#!/bin/bash
set -e

# ──────────────────────────────────────────
#  Mac 输入法切换工具 — 一键安装脚本
#  适用于 M 系列芯片 (Apple Silicon)
# ──────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
SWIFT_SRC="$PROJECT_DIR/Sources/input-switcher.swift"
INSTALL_DIR="$HOME/.local/bin"
BINARY_NAME="input-switcher"

echo -e "${CYAN}🔤  Mac 输入法切换工具 — 安装程序${NC}"
echo "   芯片架构: $(uname -m)"

# ── 平台检查 ─────────────────────────────
ARCH=$(uname -m)
if [[ "$ARCH" != "arm64" ]]; then
    echo -e "${YELLOW}⚠️  当前架构为 $ARCH，非 M 系列芯片（arm64）${NC}"
    echo "   工具仍可编译使用，但未在此架构上测试。"
    read -p "   是否继续? [Y/n] " yn
    [[ "$yn" == "n" || "$yn" == "N" ]] && exit 0
fi

# ── 源码检查 ─────────────────────────────
if [[ ! -f "$SWIFT_SRC" ]]; then
    echo -e "${RED}❌ 未找到源文件: $SWIFT_SRC${NC}"
    exit 1
fi

# ── 编译 ─────────────────────────────────
echo -e "\n🔨 编译中..."
swiftc -framework Carbon -O -o "$PROJECT_DIR/$BINARY_NAME" "$SWIFT_SRC"

if [[ ! -f "$PROJECT_DIR/$BINARY_NAME" ]]; then
    echo -e "${RED}❌ 编译失败${NC}"
    exit 1
fi

echo -e "${GREEN}✅ 编译成功${NC}"
echo "   二进制: $PROJECT_DIR/$BINARY_NAME"
file "$PROJECT_DIR/$BINARY_NAME"

# ── 安装 ─────────────────────────────────
echo -e "\n📦 安装到 $INSTALL_DIR ..."
mkdir -p "$INSTALL_DIR"
cp "$PROJECT_DIR/$BINARY_NAME" "$INSTALL_DIR/$BINARY_NAME"
chmod +x "$INSTALL_DIR/$BINARY_NAME"

# ── 初始化配置 ───────────────────────────
CONFIG_DIR="$HOME/.input-switcher"
mkdir -p "$CONFIG_DIR"
CONFIG_FILE="$CONFIG_DIR/config.json"
if [[ ! -f "$CONFIG_FILE" ]]; then
    cat > "$CONFIG_FILE" << 'EOF'
{
  "default_input_method": "微信输入法"
}
EOF
    echo -e "${GREEN}✅ 已创建配置文件: $CONFIG_FILE${NC}"
else
    echo -e "${YELLOW}⚠️  配置文件已存在，跳过初始化${NC}"
fi

# ── PATH 检查 ────────────────────────────
if ! echo "$PATH" | grep -q "$INSTALL_DIR"; then
    echo -e "\n${YELLOW}⚠️  $INSTALL_DIR 不在 PATH 中${NC}"
    echo ""
    echo "   请将以下行��加到 ~/.zshrc 或 ~/.bash_profile:"
    echo ""
    echo -e "   ${CYAN}export PATH=\"\$HOME/.local/bin:\$PATH\"${NC}"
    echo ""
fi

# ── 完成 ─────────────────────────────────
echo ""
echo -e "${GREEN}══════════════════════════════════════${NC}"
echo -e "${GREEN}  🎉 安装完成！${NC}"
echo -e "${GREEN}══════════════════════════════════════${NC}"
echo ""
echo "  快速开始:"
echo "    input-switcher              切换到默认输入法（微信输入法）"
echo "    input-switcher --list       查看所有可用输入法"
echo "    input-switcher ABC          切换到 ABC 输入法"
echo "    input-switcher --set 搜狗    把搜狗设为默认"
echo ""
echo "  配置文件: $CONFIG_FILE"
echo "  二进制:   $INSTALL_DIR/$BINARY_NAME"
echo ""
