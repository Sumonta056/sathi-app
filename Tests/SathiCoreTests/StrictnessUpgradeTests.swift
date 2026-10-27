import Foundation
@testable import SathiCore
import Testing

@Suite("Strictness upgrade")
struct StrictnessUpgradeTests {
    private func decode(_ json: String) throws -> Prefs {
        try JSONDecoder().decode(Prefs.self, from: Data(json.utf8))
    }

    @Test func oldStrictReadingAndGymBecomeNudgy() throws {
        let p = try decode(#"{"reading":{"strictness":"strict"},"gym":{"strictness":"strict"}}"#)
        #expect(p.reading.strictness == .persistent)
        #expect(p.gym.strictness == .persistent)
    }

    @Test func oldStrictWaterAndMeditationStayStrict() throws {
        let p = try decode(#"{"water":{"strictness":"strict"},"meditation":{"strictness":"strict"}}"#)
        #expect(p.water.strictness == .strict)
        #expect(p.meditation.strictness == .strict)
    }

    @Test(arguments: [Strictness.friendly, .persistent])
    func oldGentleAndNudgyStayTheSame(_ s: Strictness) throws {
        let p = try decode(#"{"reading":{"strictness":"\#(s.rawValue)"},"gym":{"strictness":"\#(s.rawValue)"}}"#)
        #expect(p.reading.strictness == s)
        #expect(p.gym.strictness == s)
    }

    @Test(arguments: [true, false])
    func newFileKeepsStrict(_ close: Bool) throws {
        let section = #"{"strictness":"strict","showsCloseButton":\#(close)}"#
        let p = try decode(#"{"reading":\#(section),"gym":\#(section)}"#)
        #expect(p.reading.strictness == .strict)
        #expect(p.gym.strictness == .strict)
    }

    @Test func strictPickedAfterTheUpgradeSurvivesARoundTrip() throws {
        var p = try decode(#"{"reading":{"strictness":"strict"},"gym":{"strictness":"strict"}}"#)
        p.reading.strictness = .strict
        p.gym.strictness = .strict
        let back = try JSONDecoder().decode(Prefs.self, from: JSONEncoder().encode(p))
        #expect(back.reading.strictness == .strict)
        #expect(back.gym.strictness == .strict)
    }

    @Test func upgradeKeepsTheOtherSettings() throws {
        let p = try decode(#"{"reading":{"strictness":"strict","sessionMinutes":25},"gym":{"strictness":"strict","intervalMinutes":90}}"#)
        #expect(p.reading.sessionMinutes == 25)
        #expect(p.gym.intervalMinutes == 90)
        #expect(p.reading.showsCloseButton)
        #expect(p.gym.showsCloseButton)
    }
}
