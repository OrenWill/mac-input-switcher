import SwiftUI
import AppKit

// MARK: - 弹框控制器

final class UpdateAlertController {

    static func show(info: UpdateInfo) {
        let contentView = UpdateAlertView(info: info)
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 380, height: 220)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 220),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = ""
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.contentView = hostingView
        window.center()
        window.level = .modalPanel
        window.isReleasedWhenClosed = true

        // 关闭窗口时的回调
        let delegate = AlertWindowDelegate()
        window.delegate = delegate
        // 保持 delegate 不被释放
        objc_setAssociatedObject(window, "alert_delegate", delegate, .OBJC_ASSOCIATION_RETAIN)

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

private class AlertWindowDelegate: NSObject, NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {}
}

// MARK: - SwiftUI 弹框视图

struct UpdateAlertView: View {
    let info: UpdateInfo

    @State private var countdown = 5
    @State private var timer: Timer? = nil

    var body: some View {
        VStack(spacing: 0) {
            // 图标 + 文字区域
            HStack(alignment: .top, spacing: 14) {
                if let appIcon = NSApp.applicationIconImage {
                    Image(nsImage: appIcon)
                        .resizable()
                        .frame(width: 52, height: 52)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(info.hasUpdate
                         ? "新版本的 Input Switcher 可以安装啦！"
                         : "您使用的就是最新版！")
                        .font(.system(size: 14, weight: .bold))
                        .fixedSize(horizontal: false, vertical: true)

                    Text(info.hasUpdate
                         ? "Input Switcher 最新的版本是 v\(info.latestVersion)"
                         : "Input Switcher v\(info.currentVersion) 是当前最新版本")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 20)

            Spacer()

            // 按钮区域
            if info.hasUpdate {
                // 有更新：「去下载」
                Button(action: {
                    if let url = URL(string: info.downloadURL) {
                        NSWorkspace.shared.open(url)
                    }
                    closeAlert()
                }) {
                    Text("去下载")
                        .font(.system(size: 13, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            } else {
                // 无更新：倒计时按钮
                Button(action: { closeAlert() }) {
                    Text("好（\(countdown)s）")
                        .font(.system(size: 13, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
                .onAppear { startCountdown() }
                .onDisappear { stopCountdown() }
            }
        }
        .frame(width: 380, height: 220)
    }

    private func startCountdown() {
        timer?.invalidate()
        countdown = 5
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { t in
            countdown -= 1
            if countdown <= 0 {
                t.invalidate()
                closeAlert()
            }
        }
    }

    private func stopCountdown() {
        timer?.invalidate()
        timer = nil
    }

    private func closeAlert() {
        stopCountdown()
        if let window = NSApplication.shared.windows.first(where: {
            $0.contentView?.subviews.first is NSHostingView<UpdateAlertView>
        }) {
            window.close()
        }
    }
}
