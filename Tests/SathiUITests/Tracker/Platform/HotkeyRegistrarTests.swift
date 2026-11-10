import SathiCore
@testable import SathiUI
import Testing

@MainActor
@Suite("CarbonHotkeyRegistrar")
struct HotkeyRegistrarTests {
    private final class FakeAPI: HotkeyCarbonAPI {
        var registered: [(UInt32, UInt32)] = []
        var unregisters = 0
        var succeeds = true
        var refusedKeyCode: UInt32?
        var press: (@MainActor () -> Void)?

        func register(keyCode: UInt32, modifiers: UInt32, onPress: @escaping @MainActor () -> Void) -> Bool {
            registered.append((keyCode, modifiers))
            if keyCode == refusedKeyCode { return false }
            press = onPress
            return succeeds
        }

        func unregister() { unregisters += 1 }
    }

    @Test("the default shortcut registers key 49 with control, option and command flags")
    func defaultShortcut() {
        let api = FakeAPI()
        let registrar = CarbonHotkeyRegistrar(api: api)
        #expect(registrar.register(.trackerDefault) {})
        #expect(api.registered.first?.0 == 49)
        #expect(api.registered.first?.1 == UInt32(6400))
    }

    @Test("a press reaches the callback")
    func pressFires() {
        let api = FakeAPI()
        let registrar = CarbonHotkeyRegistrar(api: api)
        var presses = 0
        registrar.register(.trackerDefault) { presses += 1 }
        api.press?()
        #expect(presses == 1)
    }

    @Test("a shortcut with no modifiers is refused without touching the system")
    func noModifiers() {
        let api = FakeAPI()
        let registrar = CarbonHotkeyRegistrar(api: api)
        let bare = KeyShortcut(keyCode: 49, modifiers: [], keyName: "Space")
        #expect(!registrar.register(bare) {})
        #expect(api.registered.isEmpty)
    }

    @Test("a system failure returns false")
    func failure() {
        let api = FakeAPI()
        api.succeeds = false
        #expect(!CarbonHotkeyRegistrar(api: api).register(.trackerDefault) {})
    }

    @Test("a failed new shortcut puts the previous one back")
    func failureKeepsOld() {
        let api = FakeAPI()
        let registrar = CarbonHotkeyRegistrar(api: api)
        var presses = 0
        registrar.register(.trackerDefault) { presses += 1 }
        api.refusedKeyCode = 12
        let other = KeyShortcut(keyCode: 12, modifiers: [.command], keyName: "Q")
        #expect(!registrar.register(other) {})
        #expect(api.registered.last?.0 == 49)
        api.press?()
        #expect(presses == 1)
    }

    @Test("registering again unregisters the old shortcut first, and unregister passes through")
    func replaces() {
        let api = FakeAPI()
        let registrar = CarbonHotkeyRegistrar(api: api)
        registrar.register(.trackerDefault) {}
        registrar.register(.trackerDefault) {}
        #expect(api.unregisters == 2)
        registrar.unregister()
        #expect(api.unregisters == 3)
    }

    @Test("all four modifiers map to their Carbon flags")
    func flags() {
        #expect(HotkeyModifiers.carbonFlags([.command]) == 256)
        #expect(HotkeyModifiers.carbonFlags([.shift]) == 512)
        #expect(HotkeyModifiers.carbonFlags([.option]) == 2048)
        #expect(HotkeyModifiers.carbonFlags([.control]) == 4096)
        #expect(HotkeyModifiers.carbonFlags([]) == 0)
    }
}
