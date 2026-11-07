import AppKit
import AVFoundation
import SathiCore

@MainActor
package final class BreathAudioPlayer: SessionAudio {
    private let voice = BreathVoice()
    private var music: AVAudioPlayer?
    private var pauseWork: DispatchWorkItem?
    private var releaseWork: DispatchWorkItem?
    private var previewWork: DispatchWorkItem?
    private var effects: [NSSound] = []

    package nonisolated init() {}

    package func speak(_ cue: BreathCue, volume: Double) {
        voice.speak(cue, volume: volume)
    }

    package func play(_ sound: SessionSound, volume: Double) {
        let file = sound == .bell ? AudioFiles.bell : AudioFiles.tick
        let fallback = sound == .bell ? SoundName.tink.rawValue : "Pop"
        let url = SathiResources.url(file, ext: AudioFiles.ext, in: .audio)
        let player = url.flatMap { NSSound(contentsOf: $0, byReference: true) } ?? NSSound(named: NSSound.Name(fallback))
        guard let player else { return }
        player.volume = Float(volume)
        effects.removeAll { !$0.isPlaying }
        effects.append(player)
        player.play()
    }

    package func startMusic(volume: Double) {
        pauseWork?.cancel()
        releaseWork?.cancel()
        if music == nil { music = makeMusic() }
        guard let music else { return }
        music.volume = 0
        music.play()
        music.setVolume(Float(volume), fadeDuration: Timing.musicFadeIn)
    }

    package func pauseMusic() {
        guard let music else { return }
        music.setVolume(0, fadeDuration: Timing.musicFadeOut)
        let work = DispatchWorkItem { [weak music] in music?.pause() }
        pauseWork?.cancel()
        pauseWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Timing.musicFadeOut, execute: work)
    }

    package func silenceVoice() {
        voice.silence()
    }

    package func endSession() {
        previewWork?.cancel()
        pauseMusic()
        releaseWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.music?.stop()
            self?.music = nil
            self?.voice.release()
        }
        releaseWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Timing.musicFadeOut, execute: work)
    }

    package func preview(voiceVolume: Double?, musicVolume: Double?, seconds: TimeInterval) {
        if let voiceVolume { voice.speak(.inhale, volume: voiceVolume) }
        if let musicVolume { startMusic(volume: musicVolume) }
        previewWork?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.endSession() }
        previewWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: work)
    }

    private func makeMusic() -> AVAudioPlayer? {
        guard let url = SathiResources.url(AudioFiles.music, ext: AudioFiles.ext, in: .audio),
              let player = try? AVAudioPlayer(contentsOf: url) else { return nil }
        player.numberOfLoops = -1
        return player
    }
}
