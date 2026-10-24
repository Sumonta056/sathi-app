import Foundation
import SathiCore
import SathiTestSupport

enum LegacyV1Fixture {
    static let json = """
    {
      "prefs": {
        "name": "Asha",
        "waterEnabled": false,
        "waterIntervalMinutes": 90,
        "waterStartMinutes": 480,
        "waterEndMinutes": 1200,
        "waterStrictness": "persistent",
        "defaultContainer": "bottle",
        "bottleSizeGlasses": 4.5,
        "dailyGoalGlasses": 10,
        "readingEnabled": false,
        "readingTimeMinutes": 1260,
        "readingSessionMinutes": 30,
        "readingStrictness": "friendly",
        "snoozeMinutes": 10,
        "ignoreMinutes": 3,
        "soundOn": false
      },
      "drinks": [
        {"date": 792403200.734512, "glasses": 1},
        {"date": 792496800, "glasses": 0.5},
        {"date": 792590400, "glasses": 2.25}
      ],
      "reads": [
        {"date": 792705600, "minutes": 15},
        {"date": 792795600, "minutes": 30}
      ],
      "bottleLevel": 0.5,
      "lastWaterDone": 792590400,
      "streakReset": {"water": 792320400}
    }
    """

    static func at(_ seconds: TimeInterval) -> Date { Date(timeIntervalSinceReferenceDate: seconds) }

    static var prefs: Prefs {
        var p = Prefs()
        p.general.name = "Asha"
        p.general.snoozeMinutes = 10
        p.general.ignoreMinutes = 3
        p.general.soundOn = false
        p.water.enabled = false
        p.water.intervalMinutes = 90
        p.water.startMinutes = 480
        p.water.endMinutes = 1200
        p.water.strictness = .persistent
        p.water.container = .bottle
        p.water.bottleSizeGlasses = 4.5
        p.water.dailyGoalGlasses = 10
        p.reading.enabled = false
        p.reading.timeMinutes = 1260
        p.reading.sessionMinutes = 30
        p.reading.strictness = .friendly
        return p
    }

    static var live: LiveState {
        var live = LiveState()
        live.bottleLevel = 0.5
        live.lastWaterDone = at(792_590_400)
        live.streakReset = ["water": at(792_320_400)]
        return live
    }

    static var events: [HistoryEvent] {
        [
            .done(.water, 1, at: at(792_403_200)),
            .done(.water, 0.5, at: at(792_496_800)),
            .done(.water, 2.25, at: at(792_590_400)),
            .done(.reading, 15, at: at(792_705_600)),
            .done(.reading, 30, at: at(792_795_600))
        ]
    }

    static func defaults(_ blob: String = json) -> UserDefaults {
        let name = "sathi.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        defaults.set(Data(blob.utf8), forKey: "sathi.state.v1")
        return defaults
    }

    static func marker(_ base: URL) -> URL { base.appendingPathComponent("migrated-v1") }

    static func storedEvents(_ base: URL) -> [HistoryEvent] {
        FileHistoryStore(base: base, calendar: .current, delay: 3600).events(from: day(2026, 1, 1), to: day(2026, 4, 1))
    }
}
