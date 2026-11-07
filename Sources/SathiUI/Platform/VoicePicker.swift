import AVFoundation

struct VoiceInfo: Equatable {
    let id: String
    let name: String
    let language: String
    let quality: Int
    let isFemale: Bool
}

enum VoicePicker {
    static func best(_ voices: [VoiceInfo]) -> VoiceInfo? {
        voices.filter { $0.language.hasPrefix("en") }.max { rank($0).lexicographicallyPrecedes(rank($1)) }
    }

    private static func rank(_ v: VoiceInfo) -> [Int] {
        [
            score(AudioFiles.preferredVoiceIDs) { $0 == v.id },
            score(AudioFiles.preferredVoiceMarks) { v.name == $0 || v.id.contains($0) },
            v.quality,
            AudioFiles.preferredVoices.contains(v.name) ? 1 : 0,
            v.isFemale ? 1 : 0
        ]
    }

    private static func score(_ list: [String], _ matches: (String) -> Bool) -> Int {
        guard let i = list.firstIndex(where: matches) else { return 0 }
        return list.count - i
    }

    static func info(_ voice: AVSpeechSynthesisVoice) -> VoiceInfo {
        VoiceInfo(
            id: voice.identifier,
            name: voice.name,
            language: voice.language,
            quality: voice.quality.rawValue,
            isFemale: isFemale(voice)
        )
    }

    private static func isFemale(_ voice: AVSpeechSynthesisVoice) -> Bool {
        if #available(macOS 14.0, *) { return voice.gender == .female }
        return false
    }

    static func systemBest() -> AVSpeechSynthesisVoice? {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        guard let id = best(voices.map(info))?.id else { return nil }
        return voices.first { $0.identifier == id }
    }
}
