import SwiftUI
import AppKit

// MARK: - 弹框控制器

final class UpdateAlertController {

    private static var alertWindow: NSWindow?

    static func show(info: UpdateInfo) {
        // 关闭已有的弹框
        alertWindow?.close()

        let contentView = UpdateAlertView(info: info, dismiss: {
            alertWindow?.orderOut(nil)
            alertWindow = nil
            // 弹框关闭后取消应用激活，避免其他窗口（如偏好设置）被意外拉出
            DispatchQueue.main.async {
                if NSApp.mainWindow == nil, NSApp.keyWindow == nil {
                    NSApp.hide(nil)
                }
            }
        })
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 380, height: 230)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 230),
            styleMask: info.hasUpdate ? [.titled, .closable] : [.titled],
            backing: .buffered,
            defer: false
        )
        window.title = ""
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.contentView = hostingView
        window.center()
        window.level = .modalPanel
        window.isReleasedWhenClosed = false
        alertWindow = window

        let delegate = AlertWindowDelegate {
            alertWindow = nil
        }
        window.delegate = delegate
        objc_setAssociatedObject(window, "d", delegate, .OBJC_ASSOCIATION_RETAIN)

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

private class AlertWindowDelegate: NSObject, NSWindowDelegate {
    let onClose: () -> Void
    init(onClose: @escaping () -> Void) { self.onClose = onClose }
    func windowWillClose(_ notification: Notification) { onClose() }
}

// MARK: - 圓角按钮样式

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
                .padding(.bottom, 20)
            } else {
                Button(action: { dismiss() }) {
                    Text(countdown > 0 ? "好（\(countdown)s）" : "好")
                        .font(.system(size: 13, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                }
                .buttonStyle(RoundedButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
                .onAppear { startCountdown() }
            }
        }
        .frame(width: 380, height: 230)
    }

    // MARK: - 倒计时

    private func startCountdown() {
        countdown = 5
        // 递归方式：每 1 秒更新，归零时关闭
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
