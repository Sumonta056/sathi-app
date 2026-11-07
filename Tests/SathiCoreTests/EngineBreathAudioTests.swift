import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine breath audio")
struct EngineBreathAudioTests {
    private let start = day(2026, 3, 4, 7)

    private func harness(configure: (inout Persisted) -> Void = { _ in }) -> EngineHarness {
        EngineHarness(at: start) {
            $0.prefs.meditation.enabled = true
            $0.live.lastWaterDone = day(2026, 3, 4, 7).addingTimeInterval(-Timing.minute)
            configure(&$0)
        }
    }

    private func at(_ h: EngineHarness, _ seconds: TimeInterval) {
        h.clock.now = start.addingTimeInterval(seconds)
        h.engine.tick()
    }

    private let bell = SpySessionAudio.Call.play(.bell, Limits.bellVolume)

    @Test func startWithDefaultsPlaysBellMusicBeginAndInhale() {
        let h = harness()
        h.engine.startMeditation()
        #expect(h.audio.calls == [bell, .startMusic(0.5), .speak(.begin, 0.8), .speak(.inhale, 0.8)])
    }

    @Test func voiceOffSpeaksNothing() {
        let h = harness { $0.prefs.meditation.voiceOn = false }
        h.engine.startMeditation()
        at(h, 4)
        #expect(!h.audio.calls.contains { if case .speak = $0 { true } else { false } })
    }

    @Test func musicOffStartsNoMusic() {
        let h = harness { $0.prefs.meditation.musicOn = false }
        h.engine.startMeditation()
        #expect(!h.audio.calls.contains { if case .startMusic = $0 { true } else { false } })
    }

    @Test func chimeOffPlaysNoBell() {
        let h = harness { $0.prefs.meditation.chime = false }
        h.engine.startMeditation()
        h.advance(minutes: 2)
        #expect(!h.audio.calls.contains(bell))
    }

    @Test func soundOffPlaysNothing() {
        let h = harness {
            $0.prefs.general.soundOn = false
            $0.prefs.meditation.minuteTick = true
        }
        h.engine.startMeditation()
        at(h, 4)
        at(h, 60)
        #expect(h.audio.calls == [])
    }

    @Test func calmExhaleIsSpokenOnceAtFourSeconds() {
        let h = harness()
        h.engine.startMeditation()
        let before = h.audio.calls.count
        at(h, 4)
        #expect(Array(h.audio.calls.dropFirst(before)) == [.speak(.exhale, 0.8)])
        at(h, 4.5)
        #expect(h.audio.calls.count == before + 1)
    }

    @Test func minuteTickPlaysAtSixtySeconds() {
        let h = harness { $0.prefs.meditation.minuteTick = true }
        h.engine.startMeditation()
        at(h, 60)
        #expect(h.audio.calls.contains(.play(.minuteTick, Limits.minuteTickVolume)))
    }

    @Test func noMinuteTickWhenItIsOff() {
        let h = harness()
        h.engine.startMeditation()
        at(h, 60)
        #expect(!h.audio.calls.contains(.play(.minuteTick, Limits.minuteTickVolume)))
    }

    @Test func pauseSilencesVoiceAndPausesMusic() {
        let h = harness()
        h.engine.startMeditation()
        at(h, 2)
        let before = h.audio.calls.count
        h.engine.pauseSession(.meditation)
        #expect(Array(h.audio.calls.dropFirst(before)) == [.silenceVoice, .pauseMusic])
    }

    @Test func resumeStartsMusicAndDoesNotRepeatTheCurrentCue() {
        let h = harness()
        h.engine.startMeditation()
        at(h, 3.5)
        h.engine.pauseSession(.meditation)
        at(h, 63.5)
        let before = h.audio.calls.count
        h.engine.resumeSession(.meditation)
        #expect(Array(h.audio.calls.dropFirst(before)) == [.startMusic(0.5)])
        at(h, 63.9)
        #expect(h.audio.calls.count == before + 1)
        at(h, 64)
        #expect(h.audio.calls.last == .speak(.exhale, 0.8))
    }

    @Test func resumeRightAfterABoundaryDoesNotRepeatIt() {
        let h = harness()
        h.engine.startMeditation()
        h.engine.pauseSession(.meditation)
        at(h, 30)
        let before = h.audio.calls.count
        h.engine.resumeSession(.meditation)
        at(h, 30.5)
        #expect(Array(h.audio.calls.dropFirst(before)) == [.startMusic(0.5)])
    }

    @Test func naturalEndSaysWellDoneThenBellThenEnds() {
        let h = harness()
        h.engine.startMeditation()
        h.advance(minutes: 2)
        #expect(Array(h.audio.calls.suffix(4)) == [.silenceVoice, .speak(.wellDone, 0.8), bell, .endSession])
        #expect(!h.sound.played.contains(.tink))
    }

    @Test func earlyStopOnlyEndsTheSession() {
        let h = harness()
        h.engine.startMeditation()
        at(h, 10)
        let before = h.audio.calls.count
        h.engine.stopSession(.meditation)
        #expect(Array(h.audio.calls.dropFirst(before)) == [.endSession])
    }

    @Test func turningTheHabitOffEndsTheSession() {
        let h = harness()
        h.engine.startMeditation()
        let before = h.audio.calls.count
        h.engine.data.prefs.meditation.enabled = false
        #expect(Array(h.audio.calls.dropFirst(before)) == [.endSession])
    }

    @Test func nextTickWaitsForTheNextPhaseBoundary() {
        let h = harness()
        h.engine.startMeditation()
        at(h, 3.5)
        #expect(abs(h.engine.nextTickDelay() - 0.5) < 0.01)
    }
}
