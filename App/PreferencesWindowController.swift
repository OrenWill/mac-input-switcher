import AppKit
import SwiftUI

final class PreferencesWindowController: NSWindowController {

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 620),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "输入法切换 \u{00B7} 偏好设置"
        window.titlebarAppearsTransparent = false
        window.titleVisibility = .visible
        window.center()
        window.isReleasedWhenClosed = false

        self.init(window: window)

        let hostingView = NSHostingView(rootView: SettingsView())
        hostingView.frame = NSRect(x: 0, y: 0, width: 400, height: 620)
        hostingView.autoresizingMask = [.width, .height]
        window.contentView = hostingView
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        window?.center()
        window?.makeKeyAndOrderFront(sender)
        NSApp.activate(ignoringOtherApps: true)
    }
}
