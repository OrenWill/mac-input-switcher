import SwiftUI
import AppKit

// MARK: - 弹框控制器

final class UpdateAlertController {

    private static var alertWindow: NSWindow?

    static func show(info: UpdateInfo) {
        alertWindow?.close()
        alertWindow = nil

        // 先创建一个占位大小的窗口
        let width: CGFloat = 380
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: width, height: 200),
            styleMask: info.hasUpdate ? [.titled, .closable] : [.titled],
            backing: .buffered,
            defer: false
        )
        alertWindow = window

        let contentView = UpdateAlertView(info: info, dismiss: { [weak window] in
            window?.orderOut(nil)
            if alertWindow === window {
                alertWindow = nil
            }
            DispatchQueue.main.async {
                if NSApp.mainWindow == nil, NSApp.keyWindow == nil {
                    NSApp.hide(nil)
                }
            }
        })

        let hostingView = NSHostingView(rootView: AnyView(contentView))
        hostingView.frame = NSRect(x: 0, y: 0, width: width, height: 200)
        hostingView.layoutSubtreeIfNeeded()
        let fitHeight = hostingView.fittingSize.height

        window.setContentSize(NSSize(width: width, height: fitHeight))
        hostingView.frame = NSRect(x: 0, y: 0, width: width, height: fitHeight)
        window.contentView = hostingView
        window.title = ""
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.center()
        window.level = NSWindow.Level.modalPanel
        window.isReleasedWhenClosed = false

        let delegate = AlertWindowDelegate { [weak window] in
            if alertWindow === window {
                alertWindow = nil
            }
        }
        window.delegate = delegate
        objc_setAssociatedObject(window, "d", delegate, .OBJC_ASSOCIATION_RETAIN)

        window.makeKeyAndOrderFront(nil as Any?)
        NSApp.activate(ignoringOtherApps: true)
    }
}

private class AlertWindowDelegate: NSObject, NSWindowDelegate {
    let onClose: () -> Void
    init(onClose: @escaping () -> Void) { self.onClose = onClose }
    func windowWillClose(_ notification: Notification) { onClose() }
}

// MARK: - 圆角按钮样式

struct RoundedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.accentColor)
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .foregroundColor(.white)
    }
}

// MARK: - SwiftUI 弹框视图

struct UpdateAlertView: View {
    let info: UpdateInfo
    let dismiss: () -> Void

    @State private var countdown = 5

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 14) {
                if let appIcon = NSApp.applicationIconImage {
                    Image(nsImage: appIcon)
                        .resizable()
                        .frame(width: 48, height: 48)
                }

                VStack(alignment: .leading, spacing: 4) {
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
            .padding(.top, 10)
            .padding(.bottom, 14)

            if info.hasUpdate {
                Button(action: {
                    if let url = URL(string: info.downloadURL) {
                        NSWorkspace.shared.open(url)
                    }
                    dismiss()
                }) {
                    Text("去下载")
                        .font(.system(size: 13, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                }
                .buttonStyle(RoundedButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            } else {
                Button(action: { dismiss() }) {
                    Text(countdown > 0 ? "好（\(countdown)s）" : "好")
                        .font(.system(size: 13, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                }
                .buttonStyle(RoundedButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                .onAppear { startCountdown() }
            }
        }
        .frame(width: 380)
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - 倒计时

    private func startCountdown() {
        countdown = 5
        func tick() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                if countdown > 1 {
                    countdown -= 1
                    tick()
                } else if countdown == 1 {
                    countdown = 0
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        dismiss()
                    }
                }
            }
        }
        tick()
    }
}
