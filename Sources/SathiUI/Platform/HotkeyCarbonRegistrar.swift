import SathiCore

@MainActor
package final class CarbonHotkeyRegistrar: HotkeyRegistrar {
    private let api: HotkeyCarbonAPI
    private var current: (shortcut: KeyShortcut, onPress: @MainActor () -> Void)?

    package init(api: HotkeyCarbonAPI = HotkeyCarbonSystem()) {
        self.api = api
    }

    @discardableResult
    package func register(_ shortcut: KeyShortcut, onPress: @escaping @MainActor () -> Void) -> Bool {
        guard !shortcut.modifiers.isEmpty else { return false }
        api.unregister()
        let previous = current
        current = nil
        if attempt(shortcut, onPress) {
            current = (shortcut, onPress)
            return true
        }
        if let previous, attempt(previous.shortcut, previous.onPress) { current = previous }
        return false
    }

    package func unregister() {
        current = nil
        api.unregister()
    }

    private func attempt(_ shortcut: KeyShortcut, _ onPress: @escaping @MainActor () -> Void) -> Bool {
        api.register(
            keyCode: shortcut.keyCode,
            modifiers: HotkeyModifiers.carbonFlags(shortcut.modifiers),
            onPress: onPress
        )
    }
}
