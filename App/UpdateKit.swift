import Foundation
import AppKit
import SwiftUI

// MARK: - 更新信息模型

struct UpdateInfo {
    let hasUpdate: Bool
    let currentVersion: String
    let latestVersion: String
    let downloadURL: String
}

// MARK: - UpdateKit 主入口

final class UpdateKit {

    static let shared = UpdateKit()

    // ------- 可配置属性 -------
    private var repoOwner: String = ""
    private var repoName: String = ""
    private var appName: String = ""

    // ------- 运行时状态 -------
    private var updateAvailable = false
    private var autoCheckTimer: Timer?
    private var alertWindow: NSWindow?
    weak var statusButton: NSStatusBarButton?
    private var statusView: StatusDotView?

    private init() {}

    // MARK: - 配置

    /// 使用前必须调用：`UpdateKit.shared.configure(repo: "OrenWill/输入法切换", appName: "Input Switcher")`
    func configure(repo: String, appName: String) {
        let parts = repo.split(separator: "/")
        self.repoOwner = String(parts.first ?? "")
        self.repoName  = String(parts.last ?? "")
        self.appName   = appName
    }

    // MARK: - 自动检查更新

    func startAutoCheck() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            self?.performAutoCheck()
        }
        autoCheckTimer = Timer.scheduledTimer(withTimeInterval: 86400, repeats: true) { [weak self] _ in
            self?.performAutoCheck()
        }
    }

    // MARK: - 菜单栏红点绑定

    func bindStatusItem(_ button: NSStatusBarButton) {
        statusButton = button
        let view = StatusDotView(frame: NSRect(x: 0, y: 0, width: 24, height: 22))
        statusView = view
        button.addSubview(view)
        button.frame = view.frame
    }

    // MARK: - 菜单项注入

    func addMenuItem(to menu: NSMenu, target: AnyObject, action: Selector) {
        let item = NSMenuItem(title: "检查更新", action: action, keyEquivalent: "")
        item.target = target

        if updateAvailable {
            let titleStr = "检查更新\t●" as NSString
            let attr = NSMutableAttributedString(string: titleStr as String)
            let dotRange = NSRange(location: titleStr.length - 1, length: 1)
            let textRange = NSRange(location: 0, length: titleStr.length - 1)
            attr.addAttribute(.foregroundColor, value: NSColor.textColor, range: textRange)
            attr.addAttribute(.foregroundColor, value: NSColor.systemRed, range: dotRange)
            attr.addAttribute(.font, value: NSFont.menuFont(ofSize: 10), range: dotRange)
            attr.addAttribute(.baselineOffset, value: NSNumber(value: 1), range: dotRange)
            item.attributedTitle = attr
        }
        menu.addItem(item)
    }

    /// 菜单展开时调用，隐藏状态栏红点
    func menuDidOpen() {
        statusView?.showRedDot = false
    }

    // MARK: - 手动检查更新

    func manualCheck() {
        updateAvailable = false
        check { [weak self] info in
            self?.showAlert(info: info)
        }
    }

    // MARK: - 内部实现

    private func performAutoCheck() {
        check { [weak self] info in
            if info.hasUpdate {
                self?.updateAvailable = true
                self?.statusView?.showRedDot = true
            }
        }
    }

    private func check(completion: @escaping (UpdateInfo) -> Void) {
        let apiURL = "https://api.github.com/repos/\(repoOwner)/\(repoName)/releases/latest"
        let downloadPage = "https://github.com/\(repoOwner)/\(repoName)/releases/latest"

        guard let url = URL(string: apiURL) else {
            completion(UpdateInfo(hasUpdate: false, currentVersion: currentVersion,
                                  latestVersion: "", downloadURL: ""))
            return
        }

        var req = URLRequest(url: url, timeoutInterval: 10)
        req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        req.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")

        URLSession.shared.dataTask(with: req) { [weak self] data, _, _ in
            guard let self = self else { return }
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let tag = json["tag_name"] as? String {
                let latest = tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
                let cur = self.currentVersion
                let has = self.compareVersions(latest, cur) > 0
                let info = UpdateInfo(hasUpdate: has, currentVersion: cur,
                                      latestVersion: latest, downloadURL: downloadPage)
                DispatchQueue.main.async { completion(info) }
            } else {
                DispatchQueue.main.async {
                    completion(UpdateInfo(hasUpdate: false, currentVersion: self.currentVersion,
                                          latestVersion: "", downloadURL: ""))
                }
            }
        }.resume()
    }

    private var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private func compareVersions(_ a: String, _ b: String) -> Int {
        let pa = a.split(separator: ".").compactMap { Int($0) }
        let pb = b.split(separator: ".").compactMap { Int($0) }
        for i in 0..<max(pa.count, pb.count) {
            let va = i < pa.count ? pa[i] : 0
            let vb = i < pb.count ? pb[i] : 0
            if va > vb { return 1 }
            if va < vb { return -1 }
        }
        return 0
    }

    // MARK: - 弹框

    private func showAlert(info: UpdateInfo) {
        alertWindow?.close()
        alertWindow = nil

        let width: CGFloat = 380
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: width, height: 200),
                              styleMask: info.hasUpdate ? [.titled, .closable] : [.titled],
                              backing: .buffered, defer: false)
        alertWindow = window

        let alertView = UpdateAlertView(info: info, appName: appName, dismiss: { [weak window] in
            window?.orderOut(nil)
        })

        let hostingView = NSHostingView(rootView: AnyView(alertView))
        hostingView.frame = NSRect(x: 0, y: 0, width: width, height: 200)
        hostingView.layoutSubtreeIfNeeded()
        let fitHeight = hostingView.fittingSize.height

        window.setContentSize(NSSize(width: width, height: fitHeight))
        hostingView.frame = NSRect(x: 0, y: 0, width: width, height: fitHeight)
        window.contentView = hostingView
        window.title = ""
        window.styleMask.insert(.fullSizeContentView)
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.center()
        window.level = NSWindow.Level.modalPanel
        window.isReleasedWhenClosed = false

        window.makeKeyAndOrderFront(nil as Any?)
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - 状态栏红点视图

private final class StatusDotView: NSView {
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
            let dotSize: CGFloat = 6
            let dotRect = NSRect(x: bounds.width - dotSize - 2, y: bounds.height - dotSize - 2,
                                 width: dotSize, height: dotSize)
            NSColor.systemRed.setFill()
            NSBezierPath(ovalIn: dotRect).fill()
        }
    }
}

// MARK: - SwiftUI 弹框

private struct RoundedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(RoundedRectangle(cornerRadius: 8)
                .fill(Color.accentColor).opacity(configuration.isPressed ? 0.8 : 1.0))
            .foregroundColor(.white)
    }
}

private struct UpdateAlertView: View {
    let info: UpdateInfo
    let appName: String
    let dismiss: () -> Void
    @State private var countdown = 5
    @State private var countdownCancelled = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 14) {
                if let appIcon = NSApp.applicationIconImage {
                    Image(nsImage: appIcon).resizable().frame(width: 48, height: 48)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(info.hasUpdate
                         ? "新版本的 \(appName) 可以安装啦！"
                         : "您使用的就是最新版！")
                        .font(.system(size: 14, weight: .bold))
                        .fixedSize(horizontal: false, vertical: true)
                    Text(info.hasUpdate
                         ? "\(appName) 最新的版本是 v\(info.latestVersion)"
                         : "\(appName) v\(info.currentVersion) 是当前最新版本")
                        .font(.system(size: 12)).foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }
            .padding(.horizontal, 24).padding(.top, 10).padding(.bottom, 20)

            if info.hasUpdate {
                Button(action: {
                    if let url = URL(string: info.downloadURL) { NSWorkspace.shared.open(url) }
                    dismiss()
                }) {
                    Text("去下载").font(.system(size: 13, weight: .medium))
                        .frame(maxWidth: .infinity).frame(height: 32)
                }
                .buttonStyle(RoundedButtonStyle()).padding(.horizontal, 24).padding(.bottom, 16)
            } else {
                Button(action: { countdownCancelled = true; dismiss() }) {
                    Text(countdown > 0 ? "好（\(countdown)s）" : "好")
                        .font(.system(size: 13, weight: .medium))
                        .frame(maxWidth: .infinity).frame(height: 32)
                }
                .buttonStyle(RoundedButtonStyle()).padding(.horizontal, 24).padding(.bottom, 16)
                .onAppear { startCountdown() }
                .onDisappear { countdownCancelled = true }
            }
        }
        .frame(width: 380).fixedSize(horizontal: false, vertical: true)
    }

    private func startCountdown() {
        countdown = 5
        countdownCancelled = false
        func tick() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                guard !countdownCancelled else { return }
                if countdown > 1 { countdown -= 1; tick() }
                else if countdown == 1 { countdown = 0
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        guard !countdownCancelled else { return }
                        dismiss()
                    }
                }
            }
        }
        tick()
    }
}
