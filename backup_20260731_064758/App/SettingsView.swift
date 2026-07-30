import SwiftUI

// MARK: - 主视图

struct SettingsView: View {
    @StateObject private var vm = InputMethodViewModel()
    @State private var showInstallHint = false
    @State private var authorHovered = false

    var body: some View {
        VStack(spacing: 0) {
            defaultIMEDisplay
            Divider().padding(.horizontal, 16)
            imeListSection
            Divider().padding(.horizontal, 16)
            launchAtLoginSection
            Divider().padding(.horizontal, 16)
            footerSection
        }
        .frame(width: 400, height: 620)
        .onAppear { vm.load() }
        .alert("无法启用开机自启动", isPresented: $showInstallHint) {
            Button("知道了", role: .cancel) {}
        } message: {
            Text("""
            开机自启动要求应用位于 /Applications 文件夹中。

            请将「输入法切换.app」拖入 /Applications，
            然后重新打开并开启此选项。
            """)
        }
    }

    // MARK: - 当前默认输入法

    private var defaultIMEDisplay: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("当前默认输入法")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)

            HStack {
                Image(systemName: "keyboard.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.accentColor)
                Text(vm.defaultIME)
                    .font(.system(size: 15, weight: .medium))
                Spacer()
                if vm.currentSystemIME == vm.defaultIME {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                        Text("当前使用中")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                } else {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 6, height: 6)
                        Text("当前: \(vm.currentSystemIME)")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.accentColor.opacity(0.06))
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: - 输入法列表

    private var imeListSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("切换默认输入法（点击即切换）")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)

            ScrollView {
                VStack(spacing: 2) {
                    ForEach(vm.sources, id: \.id) { source in
                        IMEListRow(
                            name: source.name,
                            id: source.id,
                            isSelected: vm.isCurrentDefault(source.name),
                            isCurrentSystem: source.name == vm.currentSystemIME
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            vm.switchDefault(to: source.name)
                        }
                    }
                }
            }
            .frame(height: 400)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(nsColor: .separatorColor).opacity(0.3), lineWidth: 1)
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: - 开机自启动

    private var launchAtLoginSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("开机自动启动")
                    .font(.system(size: 13, weight: .medium))
                Text("登录 Mac 时自动运行")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { vm.launchAtLogin },
                set: { newValue in
                    vm.launchAtLogin = newValue
                    if newValue && !vm.toggleLaunchAtLogin() {
                        vm.launchAtLogin = false
                        showInstallHint = true
                    }
                }
            ))
            .toggleStyle(.switch)
            .labelsHidden()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: - 底部

    private var footerSection: some View {
        HStack {
            Text("@OrenWill")
                .font(.system(size: 12))
                .foregroundColor(authorHovered ? .accentColor : .secondary.opacity(0.5))
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        authorHovered = hovering
                    }
                }
                .onTapGesture {
                    if let url = URL(string: "https://github.com/OrenWill/mac-input-switcher") {
                        NSWorkspace.shared.open(url)
                    }
                }
            Spacer()
            Button(action: { NSApp.terminate(nil) }) {
                Text("退出应用")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

// MARK: - 输入法列表行

struct IMEListRow: View {
    let name: String
    let id: String
    let isSelected: Bool
    let isCurrentSystem: Bool

    var body: some View {
        HStack(spacing: 10) {
            // 选中标记
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 14))
                .foregroundColor(isSelected ? .accentColor : .secondary.opacity(0.5))

            // 输入法名称
            VStack(alignment: .leading, spacing: 1) {
                Text(name)
                    .font(.system(size: 13, weight: isSelected ? .medium : .regular))
                Text(id)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // 当前系统输入法标识
            if isCurrentSystem {
                Text("使用中")
                    .font(.system(size: 10))
                    .foregroundColor(.green)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.green.opacity(0.1))
                    )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.accentColor.opacity(0.08) : Color.clear)
        )
    }
}

// MARK: - 预览
#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
#endif
