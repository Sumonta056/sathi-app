import Carbon

@MainActor
package protocol HotkeyCarbonAPI: AnyObject {
    func register(keyCode: UInt32, modifiers: UInt32, onPress: @escaping @MainActor () -> Void) -> Bool
    func unregister()
}

@MainActor
package final class HotkeyCarbonSystem: HotkeyCarbonAPI {
    private static let signature: OSType = 0x5341_5448
    private static let hotkeyID: UInt32 = 1

    private var hotkey: EventHotKeyRef?
    private var handler: EventHandlerRef?
    private var onPress: (@MainActor () -> Void)?

    package nonisolated init() {}

    package func register(keyCode: UInt32, modifiers: UInt32, onPress: @escaping @MainActor () -> Void) -> Bool {
        unregister()
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let me = Unmanaged.passUnretained(self).toOpaque()
        let installed = InstallEventHandler(GetApplicationEventTarget(), { _, _, data in
            guard let data else { return noErr }
            let system = Unmanaged<HotkeyCarbonSystem>.fromOpaque(data).takeUnretainedValue()
            MainActor.assumeIsolated { system.onPress?() }
            return noErr
        }, 1, &spec, me, &handler)
        guard installed == noErr else { return false }
        let id = EventHotKeyID(signature: Self.signature, id: Self.hotkeyID)
        let registered = RegisterEventHotKey(keyCode, modifiers, id, GetApplicationEventTarget(), 0, &hotkey)
        guard registered == noErr else {
            unregister()
            return false
        }
        self.onPress = onPress
        return true
    }

    package func unregister() {
        if let hotkey { UnregisterEventHotKey(hotkey) }
        if let handler { RemoveEventHandler(handler) }
        hotkey = nil
        handler = nil
        onPress = nil
    }
}
