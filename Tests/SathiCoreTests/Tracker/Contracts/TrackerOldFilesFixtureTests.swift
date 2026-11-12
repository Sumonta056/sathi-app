import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Tracker old files fixture")
struct TrackerOldFilesFixtureTests {
    private let base = makeTempFolder()

    private static let oldPrefs = """
    {"schemaVersion":1,"value":{"general":{"name":"Asha","soundOn":true},
    "water":{"enabled":true,"intervalMinutes":45},
    "timeBlock":{"display":"widget","playsSound":false}}}
    """

    private static let oldState = """
    {"schemaVersion":1,"value":{"bottleLevel":0.5,"lastWaterDone":"2026-11-08T10:00:00Z",
    "streakReset":{},"quickReminders":[],"gymMinutesSince":"2026-11-01T00:00:00Z"}}
    """

    @Test func oldPrefsFileLoadsTrackerDefaultsAndKeepsTheRest() throws {
        try writeText(Self.oldPrefs, to: base.appendingPathComponent(StorageKeys.prefsFile))
        let p = FileStateStore(base: base).loadPrefs()
        #expect(p.tracker == TrackerPrefs())
        #expect(p.general.name == "Asha")
        #expect(p.water.intervalMinutes == 45)
        #expect(p.timeBlock.display == .widget)
    }

    @Test func oldStateFileLoadsAnEmptyTrackerAndKeepsTheRest() throws {
        try writeText(Self.oldState, to: base.appendingPathComponent(StorageKeys.stateFile))
        let l = FileStateStore(base: base).loadLive()
        #expect(l.tracker == TrackerLiveState())
        #expect(l.bottleLevel == 0.5)
        #expect(l.gymMinutesSince != nil)
    }

    @Test func oldFilesAreNotMovedAside() throws {
        try writeText(Self.oldPrefs, to: base.appendingPathComponent(StorageKeys.prefsFile))
        try writeText(Self.oldState, to: base.appendingPathComponent(StorageKeys.stateFile))
        let store = FileStateStore(base: base)
        _ = store.loadPrefs()
        _ = store.loadLive()
        #expect(!fileExists(base.appendingPathComponent(StorageKeys.prefsFile + StorageKeys.corruptSuffix)))
        #expect(!fileExists(base.appendingPathComponent(StorageKeys.stateFile + StorageKeys.corruptSuffix)))
    }
}
