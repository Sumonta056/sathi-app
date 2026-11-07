import SathiCore

enum AudioFiles {
    static let music = "breath-music"
    static let bell = "breath-bell"
    static let tick = "breath-tick"
    static let ext = "mp3"
    static let preferredVoiceIDs = ["com.apple.ttsbundle.gryphon-neural_Simone_en-US_premium"]
    static let preferredVoiceMarks = ["Simone", "Martha"]
    static let preferredVoices = ["Ava", "Zoe"]

    static func voice(_ cue: BreathCue) -> String { "voice-\(cue.rawValue)" }
}
