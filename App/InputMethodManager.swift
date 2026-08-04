import Carbon
import Foundation
import CoreGraphics

// MARK: - 输入法源

struct InputSource: Hashable {
    let name: String
    let id: String
    let source: TISInputSource

    var shortName: String {
        if let first = name.first, first.isASCII {
            let parts = name.split(separator: " ")
            if parts.count > 1 {
                return parts.map { String($0.prefix(1)) }.joined()
            }
            return String(name.prefix(3))
        }
        let cleaned = name.replacingOccurrences(of: "输入法", with: "")
        return String(cleaned.prefix(2))
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: InputSource, rhs: InputSource) -> Bool { lhs.id == rhs.id }
}

// MARK: - 输入法管理器

final class InputMethodManager {
    static let shared = InputMethodManager()

    private init() {}

    // ── 查询所有可切换的输入法 ──
    func allSources() -> [InputSource] {
        // 系统工具类输入源，非文本输入法，需隐藏
        let excludedIDs: Set<String> = [
            "com.apple.PressAndHold",             // 长按重音符号
            "com.apple.inputmethod.ironwood",     // 听写
            "com.apple.CharacterPaletteIM",       // 表情与符号
        ]

        guard let raw = TISCreateInputSourceList(nil, false)?
            .takeRetainedValue() as? [TISInputSource]
        else { return [] }

        return raw.compactMap { source in
            guard let sel = TISGetInputSourceProperty(source, kTISPropertyInputSourceIsSelectCapable)
            else { return nil }
            let isSelectable = Unmanaged<CFBoolean>.fromOpaque(sel).takeUnretainedValue()
            guard CFBooleanGetValue(isSelectable) else { return nil }

            guard
                let np = TISGetInputSourceProperty(source, kTISPropertyLocalizedName),
                let ip = TISGetInputSourceProperty(source, kTISPropertyInputSourceID)
            else { return nil }

            let id = Unmanaged<CFString>.fromOpaque(ip).takeUnretainedValue() as String

            // 过滤系统工具
            if excludedIDs.contains(id) { return nil }

            return InputSource(
                name: Unmanaged<CFString>.fromOpaque(np).takeUnretainedValue() as String,
                id:   id,
                source: source
            )
        }
    }

    // ── 当前选中的输入法 ──
    func currentSource() -> InputSource? {
        guard let raw = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue(),
              let np = TISGetInputSourceProperty(raw, kTISPropertyLocalizedName),
              let ip = TISGetInputSourceProperty(raw, kTISPropertyInputSourceID)
        else { return nil }

        return InputSource(
            name: Unmanaged<CFString>.fromOpaque(np).takeUnretainedValue() as String,
            id:   Unmanaged<CFString>.fromOpaque(ip).takeUnretainedValue() as String,
            source: raw
        )
    }

    // ── 切换到指定输入法 ──
    func switchTo(name: String) -> Bool {
        let sources = allSources()

        // 精确匹配
        if let hit = sources.first(where: { $0.name == name }) {
            return TISSelectInputSource(hit.source) == noErr
        }
        // 模糊匹配
        if let hit = sources.first(where: {
            $0.name.localizedCaseInsensitiveContains(name) ||
            $0.id.localizedCaseInsensitiveContains(name)
        }) {
            return TISSelectInputSource(hit.source) == noErr
        }
        return false
    }

    func switchTo(source: InputSource) -> Bool {
        return TISSelectInputSource(source.source) == noErr
    }

    /// CGEvent 强切：模拟 Cmd+Space，穿透系统对话框沙盒
    /// 需要辅助功能权限，无权限时回退到 TISSelectInputSource
    func forceSwitchTo(targetName: String) -> Bool {
        let ok = switchTo(name: targetName)
        guard ok else { return false }

        // 已达标则无需 CGEvent
        if let cur = currentSource(), cur.name == targetName { return true }

        // 无辅助功能权限时 CGEvent 无效，直接返回
        guard AXIsProcessTrusted() else { return ok }

        let source = CGEventSource(stateID: .hidSystemState)
        let vkSpace: CGKeyCode = 0x31

        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vkSpace, keyDown: true)
        keyDown?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)

        usleep(80000)

        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vkSpace, keyDown: false)
        keyUp?.post(tap: .cghidEventTap)

        return true
    }
}
