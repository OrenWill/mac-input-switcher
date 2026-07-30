# 输入法切换 (Mac Input Switcher)

macOS 菜单栏输入法快速切换工具，M 系列芯片原生支持。

## 功能

- 🖥️ **菜单栏常驻** — 点击菜单栏图标即可切换输入法
- ⚡ **自动切换** — 启动时自动切回你设定的默认输入法
- 🎛️ **偏好设置** — 页面化配置默认输入法，支持开机自启动
- 🧩 **模糊匹配** — 支持中英文名称模糊搜索输入法
- 📦 **一键安装** — 提供 DMG 安装包，拖入 Applications 即可

## 安装

### 方式一：DMG 安装（推荐）

1. 从 [Releases](../../releases) 下载 `输入法切换_v*.dmg`
2. 打开 DMG，将「输入法切换.app」拖入 Applications
3. 双击运行，菜单栏出现 ♨ 图标即启动成功

### 方式二：CLI 工具

```bash
cd App && ./build.sh --install
```

编译并安装命令行工具 `input-switcher` 到 `~/.local/bin/`：

```bash
input-switcher                  # 切换到默认输入法
input-switcher --list           # 列出所有输入法
input-switcher ABC              # 切换到 ABC
input-switcher --set 搜狗        # 设为默认
```

### 方式三：源码构建

```bash
# 构建 .app
cd App && ./build.sh --install

# 生成 DMG 安装包
./make-dmg.sh 1.0.0
```

## 技术栈

- Swift 5 + AppKit + SwiftUI
- Carbon TIS API（输入法切换）
- SMAppService（开机自启动）
- arm64 原生编译

## 系统要求

- macOS 13.0+
- Apple Silicon (M 系列芯片)

## 项目结构

```
mac-input-switcher/
├── App/
│   ├── main.swift                         # 应用入口
│   ├── AppDelegate.swift                  # 菜单栏 + 应用生命周期
│   ├── InputMethodManager.swift           # 输入法核心（Carbon TIS）
│   ├── InputMethodViewModel.swift         # SwiftUI ViewModel
│   ├── SettingsView.swift                 # 偏好设置面板
│   ├── PreferencesWindowController.swift  # 窗口控制器
│   ├── Info.plist                         # Bundle 配置
│   ├── build.sh                           # 构建脚本
│   └── make-dmg.sh                        # DMG 打包脚本
├── Sources/
│   └── input-switcher.swift               # CLI 工具源码
├── install.sh                             # CLI 安装脚本
└── config.default.json                    # 配置模板
```

## License

MIT
