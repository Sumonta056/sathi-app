import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Day summary decoding")
struct DaySummaryDecodingTests {
    private func general(_ json: String) throws -> GeneralPrefs {
        try JSONDecoder().decode(GeneralPrefs.self, from: Data(json.utf8))
    }

    private func live(_ json: String) throws -> LiveState {
        try JSONDecoder().decode(LiveState.self, from: Data(json.utf8))
    }

    @Test func theDefaultTimeIsTenInTheEvening() {
        #expect(Limits.daySummaryMinutes == 1320)
        #expect(GeneralPrefs().daySummaryOn)
        #expect(GeneralPrefs().daySummaryMinutes == 1320)
    }

    @Test func oldPrefsWithoutTheKeysLoadTheDefaults() throws {
        let g = try general(#"{"name":"Asha","snoozeMinutes":10,"soundOn":false}"#)
        #expect(g.daySummaryOn)
        #expect(g.daySummaryMinutes == Limits.daySummaryMinutes)
        #expect(g.name == "Asha")
        #expect(g.snoozeMinutes == 10)
        #expect(!g.soundOn)
    }

    @Test func savedValuesLoad() throws {
        let g = try general(#"{"name":"Asha","daySummaryOn":false,"daySummaryMinutes":1260}"#)
        #expect(!g.daySummaryOn)
        #expect(g.daySummaryMinutes == 1260)
    }

    @Test(arguments: [0, 15, 1425])
    func aTimeInsideTheDayLoads(_ minutes: Int) throws {
        let g = try general(#"{"daySummaryOn":false,"daySummaryMinutes":\#(minutes)}"#)
        #expect(g.daySummaryMinutes == minutes)
    }

    @Test(arguments: [-1, -60, 1440, 5000])
    func aTimeOutsideTheDayLoadsTheDefault(_ minutes: Int) throws {
        let g = try general(#"{"name":"Asha","daySummaryOn":false,"daySummaryMinutes":\#(minutes)}"#)
        #expect(g.daySummaryMinutes == Limits.daySummaryMinutes)
        #expect(!g.daySummaryOn)
        #expect(g.name == "Asha")
    }

    @Test func aBadTimeValueKeepsTheOtherSettings() throws {
        let g = try general(#"{"name":"Asha","daySummaryOn":false,"daySummaryMinutes":"late"}"#)
        #expect(g.daySummaryMinutes == Limits.daySummaryMinutes)
        #expect(!g.daySummaryOn)
        #expect(g.name == "Asha")
    }

    @Test func prefsRoundTripKeepsTheSummarySettings() throws {
        var p = Prefs()
        p.general.daySummaryOn = false
        p.general.daySummaryMinutes = 21 * 60 + 45
        let back = try JSONDecoder().decode(Prefs.self, from: JSONEncoder().encode(p))
        #expect(back.general.daySummaryOn == false)
        #expect(back.general.daySummaryMinutes == 1305)
        #expect(back == p)
    }

    @Test func oldStateWithoutTheKeyLoadsNil() throws {
        let s = try live(#"{"bottleLevel":0.4}"#)
        #expect(s.lastDaySummary == nil)
        #expect(s.bottleLevel == 0.4)
    }

    @Test func aSavedDayLoads() throws {
        let s = try live(#"{"bottleLevel":0.4,"lastDaySummary":"2026-03-04"}"#)
        #expect(s.lastDaySummary == DayKey(raw: "2026-03-04"))
    }

    @Test(arguments: [#""not a day""#, #""2026-02-30""#, "42", "true"])
    func aBadValueLoadsNilAndKeepsTheRest(_ raw: String) throws {
        let s = try live(#"{"bottleLevel":0.4,"lastDaySummary":\#(raw)}"#)
        #expect(s.lastDaySummary == nil)
        #expect(s.bottleLevel == 0.4)
    }

    @Test func liveRoundTripKeepsTheDay() throws {
        var s = LiveState()
        s.bottleLevel = 0.5
        s.lastDaySummary = DayKey(raw: "2026-03-04")
        let back = try JSONDecoder().decode(LiveState.self, from: JSONEncoder().encode(s))
        #expect(back.lastDaySummary == DayKey(raw: "2026-03-04"))
        #expect(back == s)
    }
}
