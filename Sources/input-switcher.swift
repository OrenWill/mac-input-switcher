import Carbon
import Foundation

// MARK: - 数据结构

struct InputSource: CustomStringConvertible {
    let name: String
    let id: String
    let source: TISInputSource

    var description: String { "\(name) (\(id))" }
}

// MARK: - 核心引擎

enum InputSwitcher {
    /// 获取所有可选择的输入法（键盘布局 + 输入模式如拼音/微信/搜狗等）
    static func all() -> [InputSource] {
        // 不加 type 过滤，获取全部输入源后在内存中筛掉不可选择的
        guard let raw = TISCreateInputSourceList(nil, false)?
            .takeRetainedValue() as? [TISInputSource]
        else { return [] }

        return raw.compactMap { source in
            // 只保留可选择的输入源
            guard let selectable = TISGetInputSourceProperty(source, kTISPropertyInputSourceIsSelectCapable) else {
                return nil
            }
            let isSelectable = Unmanaged<CFBoolean>.fromOpaque(selectable).takeUnretainedValue()
            guard CFBooleanGetValue(isSelectable) else { return nil }

            guard
                let np = TISGetInputSourceProperty(source, kTISPropertyLocalizedName),
                let ip = TISGetInputSourceProperty(source, kTISPropertyInputSourceID)
            else { return nil }

            return InputSource(
                name: Unmanaged<CFString>.fromOpaque(np).takeUnretainedValue() as String,
                id:   Unmanaged<CFString>.fromOpaque(ip).takeUnretainedValue() as String,
                source: source
            )
        }
    }

    /// 切换到指定输入法（先精确匹配名称，再模糊匹配名称/ID）
    static func `switch`(to target: String) -> (ok: Bool, msg: String) {
        let sources = all()
        guard !sources.isEmpty else {
            return (false, "❌ 未检测到任何输入法")
        }

        // 1. 精确匹配名称
        if let hit = sources.first(where: { $0.name == target }) {
            return select(hit)
        }

        // 2. 模糊匹配（名称包含 target，或 ID 包含 target）
        if let hit = sources.first(where: {
            $0.name.localizedCaseInsensitiveContains(target) ||
            $0.id.localizedCaseInsensitiveContains(target)
        }) {
            return select(hit)
        }

        // 3. 未找到，提示可用列表
        let names = sources.map { "  • \($0.name)" }.joined(separator: "\n")
        return (false, "❌ 未找到输入法「\(target)」\n\n当前可用输入法:\n\(names)")
    }

    private static func select(_ source: InputSource) -> (ok: Bool, msg: String) {
        let status = TISSelectInputSource(source.source)
        if status == noErr {
            return (true, "✅ 已切换到: \(source.name)")
        }
        return (false, "❌ 切换失败: \(source.name) (错误码: \(status))")
    }
}

// MARK: - 配置管理

struct Config {
    static let dir: URL =
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".input-switcher")

    static let file: URL = dir.appendingPathComponent("config.json")

    static let fallbackDefault = "微信输入法"

    /// 读取默认输入法名称
    static func defaultIME() -> String {
        guard let data = try? Data(contentsOf: file),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let ime  = json["default_input_method"] as? String
        else { return fallbackDefault }
        return ime
    }

    /// 保存默认输入法名称
    static func setDefaultIME(_ name: String) {
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let json: [String: Any] = ["default_input_method": name]
        guard let data = try? JSONSerialization.data(
            withJSONObject: json, options: .prettyPrinted
        ) else { return }
        try? data.write(to: file)
    }

    /// 初始化配置文件（如不存在）
    static func ensureExists() {
        if !FileManager.default.fileExists(atPath: file.path) {
            setDefaultIME(fallbackDefault)
        }
    }
}

// MARK: - CLI

func printHelp() {
    print("""
    🔤 Mac 输入法切换工具 v1.0  (M 系列芯片原生支持)

    用法:
      input-switcher                       使用默认输入法（微信输入法）
      input-switcher <名称>                 切换到指定输入法
      input-switcher -l  | --list           列出所有输入法
      input-switcher -s <名称> | --set <名称>  修改默认输入法
      input-switcher -h  | --help           显示本帮助

    示例:
      input-switcher                   → 切到微信输入法
      input-switcher ABC               → 切到 ABC
      input-switcher 搜狗               → 切到搜狗
      input-switcher --list            → 查看有哪些输入法
      input-switcher --set 百度        → 把百度设为默认
    """)
}

func main() {
    let args = CommandLine.arguments

    Config.ensureExists()

    switch args.count {
    case 1:
        let ime = Config.defaultIME()
        let r = InputSwitcher.switch(to: ime)
        print(r.msg)
        exit(r.ok ? 0 : 1)

    case 2:
        switch args[1] {
        case "-l", "--list":
            let sources = InputSwitcher.all()
            if sources.isEmpty {
                print("⚠️  未检测到任何输入法")
            } else {
                print("\n⌨️  当前可用输入法 (\(sources.count) 个):\n")
                for (i, s) in sources.enumerated() {
                    print("  \(i + 1). \(s.name)")
                    print("     ID: \(s.id)\n")
                }
            }

        case "-h", "--help":
            printHelp()

        default:
            let r = InputSwitcher.switch(to: args[1])
            print(r.msg)
            exit(r.ok ? 0 : 1)
        }

    case 3:
        if args[1] == "-s" || args[1] == "--set" {
            Config.setDefaultIME(args[2])
            print("✅ 默认输入法已设置为: \(args[2])")
        } else {
            printHelp()
            exit(1)
        }

    default:
        printHelp()
        exit(1)
    }
}

main()
