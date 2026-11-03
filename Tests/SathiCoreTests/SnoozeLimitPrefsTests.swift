import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Snooze limit prefs")
struct SnoozeLimitPrefsTests {
    private func decode(_ json: String) throws -> GeneralPrefs {
        try JSONDecoder().decode(GeneralPrefs.self, from: Data(json.utf8))
    }

    @Test func theLimitRangeIsOneToFifteen() {
        #expect(Limits.snoozeLimits == 1 ... 15)
    }

    @Test func thereIsNoLimitByDefault() {
        #expect(GeneralPrefs().snoozeLimit == nil)
        #expect(Prefs().general.snoozeLimit == nil)
    }

    @Test func aMissingKeyDecodesToNoLimitAndKeepsTheOtherFields() throws {
        let g = try decode(#"{"name":"Asha","snoozeMinutes":10,"ignoreMinutes":3,"soundOn":false}"#)
        #expect(g.snoozeLimit == nil)
        #expect(g.name == "Asha")
        #expect(g.snoozeMinutes == 10)
        #expect(g.ignoreMinutes == 3)
        #expect(!g.soundOn)
    }

    @Test(arguments: [1, 3, 15])
    func aLimitSurvivesARoundTrip(_ limit: Int) throws {
        var p = Prefs()
        p.general.snoozeLimit = limit
        let back = try JSONDecoder().decode(Prefs.self, from: JSONEncoder().encode(p))
        #expect(back.general.snoozeLimit == limit)
        #expect(back == p)
    }

    @Test func noLimitSurvivesARoundTrip() throws {
        let back = try JSONDecoder().decode(Prefs.self, from: JSONEncoder().encode(Prefs()))
        #expect(back.general.snoozeLimit == nil)
    }

    @Test(arguments: [(0, 1), (-4, 1), (16, 15), (99, 15), (7, 7)])
    func aSavedLimitIsClampedIntoTheRange(_ row: (Int, Int)) throws {
        let g = try decode(#"{"name":"Asha","snoozeLimit":\#(row.0)}"#)
        #expect(g.snoozeLimit == row.1)
        #expect(g.name == "Asha")
    }
}
