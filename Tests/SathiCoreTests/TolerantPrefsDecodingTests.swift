import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Tolerant prefs decoding")
struct TolerantPrefsDecodingTests {
    private let base = makeTempFolder()
    private var prefsURL: URL { base.appendingPathComponent("prefs.json") }
    private var corruptURL: URL { base.appendingPathComponent("prefs.json.corrupt") }

    private func writePrefs(
        waterStrictness: String = "friendly",
        container: String = "bottle",
        readingStrictness: String = "strict",
        meditationStrictness: String = "persistent"
    ) throws {
        let json = """
        {"schemaVersion":1,"value":{\
        "general":{"name":"Asha"},\
        "water":{"intervalMinutes":45,"strictness":"\(waterStrictness)","container":"\(container)","dailyGoalGlasses":6},\
        "reading":{"timeMinutes":1260,"sessionMinutes":20,"strictness":"\(readingStrictness)"},\
        "meditation":{"enabled":true,"sessionMinutes":10,"strictness":"\(meditationStrictness)"}\
        }}
        """
        try writeText(json, to: prefsURL)
    }

    private func load() -> Prefs {
        FileStateStore(base: base, delay: 3600).loadPrefs()
    }

    private func expectOtherSectionsKept(_ p: Prefs) {
        #expect(p.general.name == "Asha")
        #expect(p.water.intervalMinutes == 45)
        #expect(p.water.dailyGoalGlasses == 6)
        #expect(p.reading.timeMinutes == 1260)
        #expect(p.reading.sessionMinutes == 20)
        #expect(p.meditation.enabled)
        #expect(p.meditation.sessionMinutes == 10)
    }

    @Test func unknownWaterStrictnessBecomesTheDefaultAndKeepsTheRest() throws {
        try writePrefs(waterStrictness: "fierce")
        let p = load()
        #expect(p.water.strictness == WaterPrefs().strictness)
        #expect(p.water.container == .bottle)
        #expect(p.reading.strictness == .strict)
        #expect(p.meditation.strictness == .persistent)
        expectOtherSectionsKept(p)
        #expect(!fileExists(corruptURL))
    }

    @Test func unknownWaterContainerBecomesTheDefaultAndKeepsTheRest() throws {
        try writePrefs(container: "mug")
        let p = load()
        #expect(p.water.container == WaterPrefs().container)
        #expect(p.water.strictness == .friendly)
        #expect(p.reading.strictness == .strict)
        #expect(p.meditation.strictness == .persistent)
        expectOtherSectionsKept(p)
        #expect(!fileExists(corruptURL))
    }

    @Test func unknownReadingStrictnessBecomesTheDefaultAndKeepsTheRest() throws {
        try writePrefs(readingStrictness: "fierce")
        let p = load()
        #expect(p.reading.strictness == ReadingPrefs().strictness)
        #expect(p.water.strictness == .friendly)
        #expect(p.water.container == .bottle)
        #expect(p.meditation.strictness == .persistent)
        expectOtherSectionsKept(p)
        #expect(!fileExists(corruptURL))
    }

    @Test func unknownMeditationStrictnessBecomesTheDefaultAndKeepsTheRest() throws {
        try writePrefs(meditationStrictness: "fierce")
        let p = load()
        #expect(p.meditation.strictness == MeditationPrefs().strictness)
        #expect(p.water.strictness == .friendly)
        #expect(p.water.container == .bottle)
        #expect(p.reading.strictness == .strict)
        expectOtherSectionsKept(p)
        #expect(!fileExists(corruptURL))
    }

    @Test func theUnknownFileStaysInPlace() throws {
        try writePrefs(waterStrictness: "fierce", container: "mug")
        _ = load()
        #expect(fileExists(prefsURL))
        #expect(!fileExists(corruptURL))
    }
}
