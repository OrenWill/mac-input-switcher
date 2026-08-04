import AppKit
import Carbon

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {

    private var statusItem: NSStatusItem!
    private let menu = NSMenu()
    private let manager = InputMethodManager.shared
    private lazy var prefsWC = PreferencesWindowController()

    // MARK: - 应用启动

    func applicationDidFinishLaunching(_ notification: Notification) {
        UpdateKit.shared.configure(repo: "OrenWill/mac-input-switcher", appName: "Input Switcher")

        setupStatusItem()
        setupMenu()
        startObserving()
        // 立即执行一次，确保启动后立刻生效
        applyDefaultIME()
        // 延迟再次确认，兜底系统输入法服务未完全就绪的情况
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.applyDefaultIME()
        }
        UpdateKit.shared.startAutoCheck()
    }

    // MARK: - 状态栏

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            UpdateKit.shared.bindStatusItem(button)
        }
        statusItem.menu = menu
    }

    // MARK: - 菜单

    private func setupMenu() {
        menu.delegate = self
        menu.autoenablesItems = false
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        UpdateKit.shared.menuDidOpen()

        menu.removeAllItems()
        buildInputMethodItems(in: menu)
        menu.addItem(.separator())
        UpdateKit.shared.addMenuItem(to: menu, target: self, action: #selector(checkUpdate))
        menu.addItem(makeMenuItem("偏好设置...", action: #selector(openPreferences), key: ","))
        menu.addItem(.separator())
        menu.addItem(makeMenuItem("退出", action: #selector(quitApp), key: "q"))
    }

    private func buildInputMethodItems(in menu: NSMenu) {
        let sources = manager.allSources()
        let currentID = manager.currentSource()?.id
        for src in sources {
            let item = NSMenuItem(title: src.name, action: #selector(switchToInputMethod(_:)), keyEquivalent: "")
            item.representedObject = src; item.target = self
            item.state = (src.id == currentID) ? .on : .off
            item.isEnabled = true; menu.addItem(item)
        }
    }

    private func makeMenuItem(_ title: String, action: Selector, key: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self; return item
    }

    // MARK: - 切换输入法

    @objc private func switchToInputMethod(_ sender: NSMenuItem) {
        guard let src = sender.representedObject as? InputSource else { return }
        _ = manager.switchTo(source: src)
        // 持久化为全局默认输入法
        UserDefaults.standard.set(src.name, forKey: "default_input_method")
    }

    private func applyDefaultIME() {
        let d = UserDefaults.standard
        let ime = d.string(forKey: "default_input_method") ?? "\u{5FAE}\u{4FE1}\u{8F93}\u{5165}\u{6CD5}"
        _ = manager.forceSwitchTo(targetName: ime)
    }

    // MARK: - 检查更新

    @objc private func checkUpdate() {
        UpdateKit.shared.manualCheck()
    }

    // MARK: - 偏好设置 / 退出

    @objc private func openPreferences() { prefsWC.showWindow(nil) }

    @objc private func quitApp() { NSApp.terminate(nil) }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    // MARK: - 监听

    private func startObserving() {
        // 系统输入法被其他方式改变时通知
        let imeName = Notification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String)
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(systemIMEChanged),
                                                            name: imeName, object: nil)

        // 应用前后台切换时自动恢复默认输入法
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(appDidActivate),
            name: NSWorkspace.didActivateApplicationNotification, object: nil
        )
    }

    // MARK: - 输入法恢复（含多次重试）

    @objc private func appDidActivate(_ notif: Notification) {
        // 高频重试，覆盖"切到应用 → 打开弹窗/面板 → 输入法又被系统改掉"的场景
        applyDefaultIME()
        let retryDelays: [Double] = [0.5, 1.5, 3.0, 6.0]
        for delay in retryDelays {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.applyDefaultIME()
            }
        }
    }

    @objc private func systemIMEChanged() {}
}
