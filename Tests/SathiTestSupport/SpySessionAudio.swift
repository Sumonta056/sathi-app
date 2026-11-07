import Foundation
import SathiCore

@MainActor
package final class SpySessionAudio: SessionAudio {
    package enum Call: Equatable {
        case speak(BreathCue, Double)
        case play(SessionSound, Double)
        case startMusic(Double)
        case pauseMusic
        case silenceVoice
        case endSession
        case preview(voiceVolume: Double?, musicVolume: Double?, seconds: TimeInterval)
    }

    package private(set) var calls: [Call] = []

    package init() {}

    package func speak(_ cue: BreathCue, volume: Double) { calls.append(.speak(cue, volume)) }
    package func play(_ sound: SessionSound, volume: Double) { calls.append(.play(sound, volume)) }
    package func startMusic(volume: Double) { calls.append(.startMusic(volume)) }
    package func pauseMusic() { calls.append(.pauseMusic) }
    package func silenceVoice() { calls.append(.silenceVoice) }
    package func endSession() { calls.append(.endSession) }
    package func preview(voiceVolume: Double?, musicVolume: Double?, seconds: TimeInterval) {
        calls.append(.preview(voiceVolume: voiceVolume, musicVolume: musicVolume, seconds: seconds))
    }
}
