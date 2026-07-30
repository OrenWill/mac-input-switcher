import Combine
import Carbon
import ServiceManagement

final class InputMethodViewModel: ObservableObject {

    // MARK: - 发布属性

    @Published var defaultIME: String = "微信输入法"
    @Published var sources: [InputSource] = []
    @Published var currentSystemIME: String = ""
    @Published var launchAtLogin: Bool = false

    private let manager = InputMethodManager.shared
    private var observers: Set<AnyCancellable> = []

    // MARK: - 初始化

    init() {
        load()
        startObserving()
    }

    // MARK: - 数据加载

    func load() {
        let defaults = UserDefaults.standard
        defaultIME = defaults.string(forKey: "default_input_method") ?? "微信输入法"
        launchAtLogin = SMAppService.mainApp.status == .enabled
        sources = manager.allSources()
        currentSystemIME = manager.currentSource()?.name ?? ""

        // 打开设置时自动切回已保存的默认输入法，确保展示一致
        if !defaultIME.isEmpty && currentSystemIME != defaultIME {
            let ok = manager.switchTo(name: defaultIME)
            currentSystemIME = ok ? (manager.currentSource()?.name ?? defaultIME) : currentSystemIME
        }
    }

    // MARK: - 操作

    /// 切换默认输入法（立即生效 + 持久化）
    func switchDefault(to name: String) {
        defaultIME = name
        UserDefaults.standard.set(name, forKey: "default_input_method")
        _ = manager.switchTo(name: name)
        currentSystemIME = name
    }

    @discardableResult
    func toggleLaunchAtLogin(to enable: Bool) -> Bool {
        if !enable {
            do {
                try SMAppService.mainApp.unregister()
                launchAtLogin = false
                UserDefaults.standard.set(false, forKey: "launch_at_login")
                return true
            } catch {
                launchAtLogin = false
                return true
            }
        } else {
            do {
                try SMAppService.mainApp.register()
                launchAtLogin = true
                UserDefaults.standard.set(true, forKey: "launch_at_login")
                return true
            } catch {
                launchAtLogin = false
                return false
            }
        }
    }

    /// 检查当前选中的输入法 ID
    func isCurrentDefault(_ name: String) -> Bool {
        return defaultIME == name
    }

    // MARK: - 监听系统输入法变化

    private func startObserving() {
        let name = Notification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String)
        DistributedNotificationCenter.default()
            .publisher(for: name)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.currentSystemIME = self?.manager.currentSource()?.name ?? ""
            }
            .store(in: &observers)
    }
}
