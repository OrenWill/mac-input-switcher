import AppKit
import Carbon

// MARK: - 状态栏自定义视图（支持红点）

private final class StatusItemView: NSView {
    var showRedDot = false { didSet { needsDisplay = true } }

    override var intrinsicContentSize: NSSize { NSSize(width: 24, height: 22) }

    override func draw(_ dirtyRect: NSRect) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 14),
            .foregroundColor: NSColor.textColor
        ]
        let text = "\u{2668}" as NSString
        let textSize = text.size(withAttributes: attrs)
        let x = (bounds.width - textSize.width) / 2
        let y = (bounds.height - textSize.height) / 2 - 1
        text.draw(at: NSPoint(x: x, y: y), withAttributes: attrs)

        if showRedDot {
            let dotSize: CGFloat = 8
            let dotRect = NSRect(
                x: bounds.width - dotSize - 2,
                y: bounds.height - dotSize - 2,
                width: dotSize, height: dotSize
            )
            NSColor.systemRed.setFill()
            NSBezierPath(ovalIn: dotRect).fill()
        }
    }
}

// MARK: - AppDelegate

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {

    private var statusItem: NSStatusItem!
    private let statusView = StatusItemView()
    private let menu = NSMenu()
    private let manager = InputMethodManager.shared
    private lazy var prefsWC = PreferencesWindowController()
    private var updateAvailable = false
    private var autoCheckTimer: Timer?

    // MARK: - 应用启动

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupMenu()
        startObserving()
        applyDefaultIME()
        startAutoCheck()
    }

    // MARK: - 状态栏

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.addSubview(statusView)
        statusView.frame = NSRect(x: 0, y: 0, width: 24, height: 22)
        statusItem.button?.frame = statusView.frame
        statusItem.menu = menu
    }

    // MARK: - 菜单

    private func setupMenu() {
        menu.delegate = self
        menu.autoenablesItems = false
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        // 点击菜单栏 → 隐藏状态栏红点
        statusView.showRedDot = false

        menu.removeAllItems()
        buildInputMethodItems(in: menu)
        menu.addItem(.separator())
        buildCheckUpdateItem(in: menu)
        menu.addItem(makeMenuItem("偏好设置...", action: #selector(openPreferences), key: ","))
        menu.addItem(.separator())
        menu.addItem(makeMenuItem("退出", action: #selector(quitApp), key: "q"))
    }

    private func buildInputMethodItems(in menu: NSMenu) {
        let sources = manager.allSources()
        let currentID = manager.currentSource()?.id
        for src in sources {
            let item = NSMenuItem(title: src.name, action: #selector(switchToInputMethod(_:)), keyEquivalent: "")
            item.representedObject = src
            item.target = self
            item.state = (src.id == currentID) ? .on : .off
            item.isEnabled = true
            menu.addItem(item)
        }
    }

    private func buildCheckUpdateItem(in menu: NSMenu) {
        let item = NSMenuItem(title: "", action: #selector(checkUpdate), keyEquivalent: "")
        item.target = self

        if updateAvailable {
            let attr = NSMutableAttributedString(string: "检查更新  ●")
            attr.addAttribute(.foregroundColor, value: NSColor.systemRed,
                              range: NSRange(location: attr.length - 1, length: 1))
            attr.addAttribute(.foregroundColor, value: NSColor.textColor,
                              range: NSRange(location: 0, length: 4))
            item.attributedTitle = attr
        } else {
            item.title = "检查更新"
        }
        menu.addItem(item)
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

    // MARK: - 检查更新

    @objc private func checkUpdate() {
        // 点击检查更新 → 隐藏菜单红点
        updateAvailable = false
        UpdateChecker.check { [weak self] info in
            UpdateAlertController.show(info: info)
            // 检查完后刷新状态（可能已是最新版）
            self?.updateAvailable = false
        }
    }

    // MARK: - 自动检查更新

    private func startAutoCheck() {
        // 启动 30 秒后首次检查，之后每 24 小时一次
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) { [weak self] in
            self?.performAutoCheck()
        }
        autoCheckTimer = Timer.scheduledTimer(withTimeInterval: 86400, repeats: true) { [weak self] _ in
            self?.performAutoCheck()
        }
    }

    private func performAutoCheck() {
        UpdateChecker.check { [weak self] info in
            if info.hasUpdate {
                self?.updateAvailable = true
                self?.statusView.showRedDot = true
            }
        }
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
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(systemIMEChanged),
                                                            name: name, object: nil)
    }

    @objc private func systemIMEChanged() {}
}
