import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine breath audio sound off and late end")
struct EngineBreathAudioSoundOffTests {
    private let start = day(2026, 3, 4, 7)

    private func harness() -> EngineHarness {
        EngineHarness(at: start) {
            $0.prefs.meditation.enabled = true
            $0.live.lastWaterDone = day(2026, 3, 4, 7).addingTimeInterval(-Timing.minute)
        }
    }

    private func at(_ h: EngineHarness, _ seconds: TimeInterval) {
        h.clock.now = start.addingTimeInterval(seconds)
        h.engine.tick()
    }

    private func speaks(_ calls: some Sequence<SpySessionAudio.Call>) -> Bool {
        calls.contains { if case .speak = $0 { true } else { false } }
    }

    @Test func pauseAfterSoundTurnedOffStillPausesMusic() {
        let h = harness()
        h.engine.startMeditation()
        at(h, 2)
        h.engine.data.prefs.general.soundOn = false
        let before = h.audio.calls.count
        h.engine.pauseSession(.meditation)
        #expect(h.audio.calls.dropFirst(before).contains(.pauseMusic))
        #expect(h.audio.calls.dropFirst(before).contains(.silenceVoice))
    }

    @Test func turningSoundOffMidSessionSilencesVoiceAndMusic() {
        let h = harness()
        h.engine.startMeditation()
        at(h, 2)
        let before = h.audio.calls.count
        h.engine.data.prefs.general.soundOn = false
        #expect(Array(h.audio.calls.dropFirst(before)) == [.silenceVoice, .pauseMusic])
        at(h, 4)
        at(h, 10)
        #expect(!speaks(h.audio.calls.dropFirst(before)))
    }

    @Test func turningSoundOffWithoutASessionEndsAnyPreview() {
        let h = harness()
        h.engine.previewSessionSound()
        h.engine.data.prefs.general.soundOn = false
        #expect(h.audio.calls.last == .endSession)
    }

    @Test func aLateNaturalEndSkipsWellDoneAndTheBell() {
        let h = harness()
        h.engine.startMeditation()
        let before = h.audio.calls.count
        h.advance(minutes: 10)
        let after = Array(h.audio.calls.dropFirst(before))
        #expect(!after.contains(.speak(.wellDone, 0.8)))
        #expect(!after.contains(.play(.bell, Limits.bellVolume)))
        #expect(after.contains(.endSession))
        #expect(h.history.appended.contains(.done(.meditation, 2, at: start.addingTimeInterval(10 * Timing.minute))))
    }
}
