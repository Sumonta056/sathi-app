import Foundation

package enum SessionSound: String, Sendable {
    case bell, minuteTick
}

@MainActor
package protocol SessionAudio: AnyObject {
    func speak(_ cue: BreathCue, volume: Double)
    func play(_ sound: SessionSound, volume: Double)
    func startMusic(volume: Double)
    func pauseMusic()
    func silenceVoice()
    func endSession()
    func preview(voiceVolume: Double?, musicVolume: Double?, seconds: TimeInterval)
}

@MainActor
package final class SilentSessionAudio: SessionAudio {
    package nonisolated init() {}

    package func speak(_ cue: BreathCue, volume: Double) {}
    package func play(_ sound: SessionSound, volume: Double) {}
    package func startMusic(volume: Double) {}
    package func pauseMusic() {}
    package func silenceVoice() {}
    package func endSession() {}
    package func preview(voiceVolume: Double?, musicVolume: Double?, seconds: TimeInterval) {}
}
