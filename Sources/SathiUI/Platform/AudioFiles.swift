import SathiCore

enum AudioFiles {
    static let music = "breath-music"
    static let bell = "breath-bell"
    static let tick = "breath-tick"
    static let ext = "mp3"
    static let preferredVoices = ["Ava", "Zoe"]

    static func voice(_ cue: BreathCue) -> String { "voice-\(cue.rawValue)" }
}
