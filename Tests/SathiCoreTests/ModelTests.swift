import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Model")
struct ModelTests {
    @Test func scheduleKeyIgnoresNonScheduleFields() {
        var p = Prefs()
        let key = p.scheduleKey
        p.general.name = "Other"
        p.general.soundOn.toggle()
        p.general.snoozeMinutes = 9
        #expect(p.scheduleKey == key)
    }

    @Test func scheduleKeyTracksScheduleFields() {
        var p = Prefs()
        let key = p.scheduleKey
        p.water.intervalMinutes = 60
        #expect(p.scheduleKey != key)
    }

    @Test func defaultPrefs() {
        let p = Prefs()
        #expect(p.water.intervalMinutes == 120)
        #expect(p.water.startMinutes == 570)
        #expect(p.water.endMinutes == 1110)
        #expect(p.reading.timeMinutes == 1320)
        #expect(p.water.strictness == .strict)
        #expect(p.reading.strictness == .persistent)
    }

    @Test func defaultGeneralPrefs() {
        let g = GeneralPrefs()
        #expect(g.name == "Mridul")
        #expect(g.snoozeMinutes == 5)
        #expect(g.ignoreMinutes == 5)
        #expect(g.soundOn)
    }

    @Test func defaultWaterAndReadingPrefs() {
        let w = WaterPrefs()
        #expect(w.enabled)
        #expect(w.container == .glass)
        #expect(w.bottleSizeGlasses == 3)
        #expect(w.dailyGoalGlasses == 8)
        let r = ReadingPrefs()
        #expect(r.enabled)
        #expect(r.sessionMinutes == 15)
    }

    @Test func defaultLiveState() {
        let live = LiveState()
        #expect(live.bottleLevel == 1)
        #expect(live.lastWaterDone == nil)
        #expect(live.streakReset.isEmpty)
    }

    @Test func perHabitAccessors() {
        var p = Prefs()
        p.reading.enabled = false
        #expect(p.isEnabled(.water))
        #expect(!p.isEnabled(.reading))
        #expect(p.strictness(.water) == .strict)
        #expect(p.strictness(.reading) == .persistent)
    }

    @Test func eventFactoriesSetKindAndAmount() {
        let at = day(2026, 3, 4, 10)
        let done = HistoryEvent.done(.water, 1.5, at: at)
        #expect(done.date == at && done.habit == .water && done.kind == .done && done.amount == 1.5)
        let snooze = HistoryEvent.snooze(.reading, at: at)
        #expect(snooze.date == at && snooze.habit == .reading && snooze.kind == .snooze && snooze.amount == 0)
        let skip = HistoryEvent.skip(.water, at: at)
        #expect(skip.date == at && skip.habit == .water && skip.kind == .skip && skip.amount == 0)
    }

    @Test func eventKindRawValuesAreStable() {
        #expect(EventKind.done.rawValue == "done")
        #expect(EventKind.snooze.rawValue == "snooze")
        #expect(EventKind.skip.rawValue == "skip")
    }

    @Test func lastDoneReadsLiveState() {
        var data = Persisted()
        data.live.lastWaterDone = day(2026, 3, 4, 9)
        #expect(data.lastDone(.water) == day(2026, 3, 4, 9))
        #expect(data.lastDone(.reading) == nil)
    }

    @Test(arguments: HabitID.allCases)
    func rulesMatchTheirHabit(_ id: HabitID) {
        #expect(id.rules(Prefs()).id == id)
    }
}
