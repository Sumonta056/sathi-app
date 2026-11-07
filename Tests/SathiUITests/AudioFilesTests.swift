import Foundation
@testable import SathiUI
import Testing

@Suite("Audio files")
struct AudioFilesTests {
    @Test func voiceNameUsesTheCueName() {
        #expect(AudioFiles.voice(.wellDone) == "voice-wellDone")
    }

    @Test func musicName() {
        #expect(AudioFiles.music == "babylon-meditation")
    }

    @Test func bellAndTickNames() {
        #expect(AudioFiles.bell == "breath-bell")
        #expect(AudioFiles.tick == "breath-tick")
    }
}
