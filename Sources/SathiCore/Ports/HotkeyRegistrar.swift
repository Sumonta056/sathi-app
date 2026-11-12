import Foundation

@MainActor
package protocol HotkeyRegistrar: AnyObject {
    @discardableResult
    func register(_ shortcut: KeyShortcut, onPress: @escaping @MainActor () -> Void) -> Bool
    func unregister()
}

@MainActor
package final class NoHotkeyRegistrar: HotkeyRegistrar {
    package nonisolated init() {}

    @discardableResult
    package func register(_ shortcut: KeyShortcut, onPress: @escaping @MainActor () -> Void) -> Bool { false }
    package func unregister() {}
}
