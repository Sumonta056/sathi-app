import AVFoundation
import SathiCore

@MainActor
final class BreathVoice: NSObject {
    private struct Line {
        let cue: BreathCue
        let volume: Double
    }

    private var queue: [Line] = []
    private var busy = false
    private var clip: AVAudioPlayer?
    private var synth: AVSpeechSynthesizer?
    private var voice: AVSpeechSynthesisVoice?
    private var voiceResolved = false
    private var releasePending = false

    func speak(_ cue: BreathCue, volume: Double) {
        releasePending = false
        queue.append(Line(cue: cue, volume: volume))
        playNext()
    }

    func silence() {
        queue.removeAll()
        clip?.stop()
        clip = nil
        synth?.stopSpeaking(at: .immediate)
        busy = false
    }

    func release() {
        guard !busy, queue.isEmpty else {
            releasePending = true
            return
        }
        releasePending = false
        synth?.delegate = nil
        synth = nil
        voice = nil
        voiceResolved = false
    }

    func dropQueued() {
        queue.removeAll()
    }

    private func playNext() {
        guard !busy, !queue.isEmpty else { return }
        let line = queue.removeFirst()
        busy = true
        if !playClip(line) { say(line) }
    }

    private func playClip(_ line: Line) -> Bool {
        guard let url = SathiResources.url(AudioFiles.voice(line.cue), ext: AudioFiles.ext, in: .audio),
              let player = try? AVAudioPlayer(contentsOf: url) else { return false }
        player.delegate = self
        player.volume = Float(line.volume)
        guard player.play() else { return false }
        clip = player
        return true
    }

    private func say(_ line: Line) {
        let utterance = AVSpeechUtterance(string: Copywriter.breathVoice(line.cue))
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * Float(Limits.speechRateRatio)
        utterance.volume = Float(line.volume)
        if !voiceResolved {
            voice = VoicePicker.systemBest()
            voiceResolved = true
        }
        utterance.voice = voice
        let speaker = synth ?? AVSpeechSynthesizer()
        speaker.delegate = self
        synth = speaker
        speaker.speak(utterance)
    }

    private func finished() {
        busy = false
        clip = nil
        playNext()
        if releasePending { release() }
    }
}

extension BreathVoice: AVAudioPlayerDelegate, AVSpeechSynthesizerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in self.finished() }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in self.finished() }
    }
}
