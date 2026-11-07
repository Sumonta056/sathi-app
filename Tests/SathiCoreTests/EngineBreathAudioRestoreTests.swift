import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine breath audio preview and restore")
struct EngineBreathAudioRestoreTests {
    private let start = day(2026, 3, 4, 7)

    private func harness(configure: (inout Persisted) -> Void = { _ in }) -> EngineHarness {
        EngineHarness(at: start) {
            $0.prefs.meditation.enabled = true
            $0.live.lastWaterDone = day(2026, 3, 4, 7).addingTimeInterval(-Timing.minute)
            configure(&$0)
        }
    }

    @Test func previewUsesTheVolumes() {
        let h = harness()
        h.engine.previewSessionSound()
        #expect(h.audio.calls == [.preview(voiceVolume: 0.8, musicVolume: 0.5, seconds: 5)])
    }

    @Test func previewIsIgnoredDuringASession() {
        let h = harness()
        h.engine.startMeditation()
        let before = h.audio.calls.count
        h.engine.previewSessionSound()
        #expect(h.audio.calls.count == before)
    }

    @Test func previewIsIgnoredWhenSoundIsOff() {
        let h = harness { $0.prefs.general.soundOn = false }
        h.engine.previewSessionSound()
        #expect(h.audio.calls == [])
    }

    @Test func previewWithVoiceAndMusicOffCallsNothing() {
        let h = harness {
            $0.prefs.meditation.voiceOn = false
            $0.prefs.meditation.musicOn = false
        }
        h.engine.previewSessionSound()
        #expect(h.audio.calls == [])
    }

    @Test func restoreOfARunningSessionStartsMusic() {
        let saved = Session(start: start.addingTimeInterval(-30), end: start.addingTimeInterval(90))
        let h = harness { $0.live.meditationSession = saved }
        h.engine.start()
        h.engine.stop()
        #expect(h.audio.calls == [.startMusic(0.5)])
    }

    @Test func restoreOfAPausedSessionPlaysNothing() {
        let saved = Session(start: start.addingTimeInterval(-30), end: start.addingTimeInterval(90), pausedAt: start.addingTimeInterval(-10))
        let h = harness { $0.live.meditationSession = saved }
        h.engine.start()
        h.engine.stop()
        #expect(h.audio.calls == [])
    }
}
