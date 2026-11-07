import Foundation
@testable import SathiUI
import Testing

@Suite("Voice picker")
struct VoicePickerTests {
    private func voice(_ name: String, quality: Int, language: String = "en-US", female: Bool = true) -> VoiceInfo {
        VoiceInfo(id: name, name: name, language: language, quality: quality, isFemale: female)
    }

    @Test func premiumAvaBeatsEnhancedZoeBeatsDefaultSamantha() {
        let samantha = voice("Samantha", quality: 1)
        let zoe = voice("Zoe", quality: 2)
        let ava = voice("Ava", quality: 3)
        #expect(VoicePicker.best([samantha, zoe, ava])?.name == "Ava")
        #expect(VoicePicker.best([samantha, zoe])?.name == "Zoe")
    }

    @Test func nonEnglishIsNeverPicked() {
        let french = voice("Amelie", quality: 3, language: "fr-FR")
        #expect(VoicePicker.best([french]) == nil)
        let samantha = voice("Samantha", quality: 1)
        #expect(VoicePicker.best([french, samantha])?.name == "Samantha")
    }

    @Test func emptyListGivesNil() {
        #expect(VoicePicker.best([]) == nil)
    }

    @Test func preferredNameBreaksQualityTies() {
        let other = voice("Karen", quality: 2)
        let zoe = voice("Zoe", quality: 2)
        #expect(VoicePicker.best([other, zoe])?.name == "Zoe")
    }

    @Test func femaleBreaksRemainingTies() {
        let male = voice("Alex", quality: 2, female: false)
        let female = voice("Karen", quality: 2)
        #expect(VoicePicker.best([male, female])?.name == "Karen")
    }

    @Test func preferredNamesComeFromAudioFiles() {
        #expect(AudioFiles.preferredVoices == ["Ava", "Zoe"])
    }
}
