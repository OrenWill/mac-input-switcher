# 输入法自动切换 (Mac Input Switcher)

<p align="center">
  <img src="icon.png" width="120" alt="输入法切换图标" />
</p>

## 你每天还在为切换输入法抓狂吗？

在 Mac 上，无论你当前用的是什么输入法，只要切换到新应用（或新建标签页），系统总会**强行跳回"原生英文输入法"**。于是你每天不得不反复按下 `Command + Space` 或 `Control Space` 几十上百次——写代码、回消息、搜资料，每切换一次窗口就打断一次思路。

**这种无意义的重复，本不该由你来承担。**

## 这个应用做了什么？

它守在你的系统后台，**自动记住你为每个应用设定的首选输入法**。一旦检测到输入焦点切换，它会悄无声息地把输入法恢复成你指定的那一个——全程无需任何手动操作。

> 安装后，你可以为各个应用设置固定输入法，从此，**Mac 默认输入法由你说了算**。

## 效果立竿见影

- ✅ 每天省下几十次无效切换动作  
- ✅ 再也不会在中文模式下敲出乱码命令  
- ✅ 专注工作流，不再被输入法打断心流  

**一句话：装上它，输入法切换这件事就从你的大脑中彻底删掉。**

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

## 作者

[@OrenWill](https://github.com/OrenWill) · WeChat: wanggh92

## License

MIT
