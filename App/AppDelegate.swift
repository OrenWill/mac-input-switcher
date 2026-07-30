import AppKit
import Carbon

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {

    private var statusItem: NSStatusItem!
    private let menu = NSMenu()
    private let manager = InputMethodManager.shared
    private lazy var prefsWC = PreferencesWindowController()

    // MARK: - 应用启动

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupMenu()
        startObserving()
        applyDefaultIME()
    }

    // MARK: - 状态栏

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.font = NSFont.systemFont(ofSize: 14)
            button.title = "\u{2668}"
            button.imagePosition = .imageLeft
            button.toolTip = "输入法切换"
        }
        statusItem.menu = menu
    }

    // MARK: - 菜单

    private func setupMenu() {
        menu.delegate = self
        menu.autoenablesItems = false
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        buildInputMethodItems(in: menu)
        menu.addItem(.separator())
        menu.addItem(makeMenuItem("偏好设置...", action: #selector(openPreferences), key: ","))
        menu.addItem(.separator())
        menu.addItem(makeMenuItem("退出", action: #selector(quitApp), key: "q"))
    }

    private func buildInputMethodItems(in menu: NSMenu) {
        let sources = manager.allSources()
        let currentID = manager.currentSource()?.id

        for src in sources {
            let item = NSMenuItem(
                title: src.name,
                action: #selector(switchToInputMethod(_:)),
                keyEquivalent: ""
            )
            item.representedObject = src
            item.target = self
            item.state = (src.id == currentID) ? .on : .off
            item.isEnabled = true
            menu.addItem(item)
        }
    }

    private func makeMenuItem(_ title: String, action: Selector, key: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        return item
    }

    // MARK: - 切换输入法

    @objc private func switchToInputMethod(_ sender: NSMenuItem) {
        guard let src = sender.representedObject as? InputSource else { return }
        _ = manager.switchTo(source: src)
    }

    private func applyDefaultIME() {
        let defaults = UserDefaults.standard
        let ime = defaults.string(forKey: "default_input_method") ?? "\u{5FAE}\u{4FE1}\u{8F93}\u{5165}\u{6CD5}"
        _ = manager.switchTo(name: ime)
    }

    // MARK: - 偏好设置

    @objc private func openPreferences() {
        prefsWC.showWindow(nil)
    }

    // MARK: - 退出

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    // MARK: - 监听系统输入法变化

    private func startObserving() {
        let name = Notification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String)
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(systemIMEChanged),
            name: name,
            object: nil
        )
    }

    @objc private func systemIMEChanged() {
        // 图标不变，无需更新文字标题
    }
}
