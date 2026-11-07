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

    @Test func neuralSimoneBeatsPremiumAva() {
        let ava = voice("Ava", quality: 3)
        let simone = VoiceInfo(
            id: "com.apple.ttsbundle.gryphon-neural_Simone_en-US_premium",
            name: "Voice 2", language: "en-US", quality: 2, isFemale: false
        )
        #expect(VoicePicker.best([ava, simone])?.id == simone.id)
    }

    @Test func exactSimoneIdentifierBeatsAnotherSimone() {
        let named = voice("Simone", quality: 3)
        let exact = VoiceInfo(id: AudioFiles.preferredVoiceIDs[0], name: "Voice 2", language: "en-US", quality: 1, isFemale: false)
        #expect(VoicePicker.best([named, exact])?.id == exact.id)
    }

    @Test func simoneBeatsMartha() {
        let martha = voice("Martha", quality: 3)
        let simone = voice("Simone", quality: 1)
        #expect(VoicePicker.best([martha, simone])?.name == "Simone")
    }

    @Test func marthaSiriVoiceBeatsDefaultSamantha() {
        let samantha = voice("Samantha", quality: 3)
        let martha = VoiceInfo(
            id: "com.apple.speech.synthesis.voice.custom.siri.Martha.premium",
            name: "Voice 1", language: "en-GB", quality: 1, isFemale: false
        )
        #expect(VoicePicker.best([samantha, martha])?.id == martha.id)
    }

    @Test func nonEnglishSimoneIsNeverPicked() {
        let french = VoiceInfo(id: "x.gryphon-neural_Simone_fr-FR", name: "Simone", language: "fr-FR", quality: 3, isFemale: true)
        let samantha = voice("Samantha", quality: 1)
        #expect(VoicePicker.best([french, samantha])?.name == "Samantha")
    }
}
