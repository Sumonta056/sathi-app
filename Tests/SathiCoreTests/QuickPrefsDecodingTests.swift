import Foundation
import SathiCore
import Testing

@Suite("Quick prefs decoding")
struct QuickPrefsDecodingTests {
    private func quick(_ json: String) throws -> QuickPrefs {
        try JSONDecoder().decode(QuickPrefs.self, from: Data(json.utf8))
    }

    @Test func quickPrefsDefaults() throws {
        let q = try quick("{}")
        #expect(q.strictness == .persistent)
        #expect(q.showsCloseButton)
        #expect(q == QuickPrefs())
    }

    @Test func quickPrefsUnknownStrictness() throws {
        let q = try quick(#"{"strictness":"wild","showsCloseButton":false}"#)
        #expect(q.strictness == .persistent)
        #expect(!q.showsCloseButton)
    }

    @Test func savedValuesLoad() throws {
        let q = try quick(#"{"strictness":"strict","showsCloseButton":false}"#)
        #expect(q.strictness == .strict)
        #expect(!q.showsCloseButton)
    }

    @Test func prefsWithoutQuickKeyKeepsOthers() throws {
        let p = try JSONDecoder().decode(Prefs.self, from: Data(#"{"water":{"intervalMinutes":45},"general":{"name":"Asha"}}"#.utf8))
        #expect(p.quick == QuickPrefs())
        #expect(p.water.intervalMinutes == 45)
        #expect(p.general.name == "Asha")
    }

    @Test func prefsKeepOtherSettingsWhenQuickIsBad() throws {
        let p = try JSONDecoder().decode(Prefs.self, from: Data(#"{"quick":"oops","water":{"intervalMinutes":45}}"#.utf8))
        #expect(p.quick == QuickPrefs())
        #expect(p.water.intervalMinutes == 45)
    }

    @Test func prefsRoundTripKeepsQuick() throws {
        var p = Prefs()
        p.quick.strictness = .strict
        p.quick.showsCloseButton = false
        let back = try JSONDecoder().decode(Prefs.self, from: JSONEncoder().encode(p))
        #expect(back.quick == p.quick)
    }
}
