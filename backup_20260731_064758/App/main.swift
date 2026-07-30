import AppKit

// 菜单栏应用，不显示 Dock 图标（由 Info.plist LSUIElement=true 控制）
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
