import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine tracker away name edits")
struct EngineTrackerAwayNameEditTests {
    private let plain = Activity(kind: .away, text: "Away", start: wed(12), end: wed(13))
    private let named = Activity(
        kind: .away, text: "Away · Doctor", start: wed(14), end: wed(15), awayPlace: .other, awayPlaceName: "Doctor"
    )

    private func harness() -> EngineHarness {
        EngineHarness.tracker(at: wed(17), activities: [plain, named])
    }

    private func edit(_ a: Activity, _ place: AwayPlace?, name: String?) -> ActivityEdit {
        ActivityEdit(text: "", category: nil, start: a.start, end: a.end, awayPlace: place, awayPlaceName: name)
    }

    private func saved(_ h: EngineHarness, _ a: Activity) -> Activity? { h.saved.first { $0.id == a.id } }

    @Test func otherWithANameSavesTheNameAndTheTextFollows() {
        let h = harness()
        #expect(h.engine.editActivity(plain.id, edit(plain, .other, name: "Doctor")) == .saved(plain.id))
        #expect(saved(h, plain)?.awayPlace == .other)
        #expect(saved(h, plain)?.awayPlaceName == "Doctor")
        #expect(saved(h, plain)?.text == "Away · Doctor")
        #expect(saved(h, plain)?.kind == .away)
    }

    @Test func anEditThatKeepsOtherKeepsTheName() {
        let h = harness()
        var e = edit(named, .other, name: "Doctor")
        e.start = wed(14, 10)
        #expect(h.engine.editActivity(named.id, e) == .saved(named.id))
        #expect(saved(h, named)?.awayPlaceName == "Doctor")
        #expect(saved(h, named)?.text == "Away · Doctor")
        #expect(saved(h, named)?.start == wed(14, 10))
    }

    @Test(arguments: [AwayPlace.lunch, .meeting, .walk, .commute, .breakTime])
    func aBuiltInPlaceNeverKeepsAName(_ place: AwayPlace) {
        let h = harness()
        #expect(h.engine.editActivity(named.id, edit(named, place, name: "Doctor")) == .saved(named.id))
        #expect(saved(h, named)?.awayPlace == place)
        #expect(saved(h, named)?.awayPlaceName == nil)
        #expect(saved(h, named)?.text == Copywriter.trackerAwayText(place))
    }

    @Test func noPlaceNeverKeepsAName() {
        let h = harness()
        h.engine.editActivity(named.id, edit(named, nil, name: "Doctor"))
        #expect(saved(h, named)?.awayPlace == nil)
        #expect(saved(h, named)?.awayPlaceName == nil)
        #expect(saved(h, named)?.text == "Away")
    }

    @Test func otherWithNoNameClearsTheSavedName() {
        let h = harness()
        h.engine.editActivity(named.id, edit(named, .other, name: nil))
        #expect(saved(h, named)?.awayPlace == .other)
        #expect(saved(h, named)?.awayPlaceName == nil)
        #expect(saved(h, named)?.text == "Away · Other")
    }

    @Test func aRefusedEditKeepsTheSavedName() {
        let h = harness()
        var e = edit(named, .lunch, name: nil)
        e.start = wed(12, 30)
        #expect(h.engine.editActivity(named.id, e) == .overlap)
        #expect(saved(h, named) == named)
    }
}
