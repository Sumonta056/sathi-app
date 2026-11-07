import Foundation
@testable import SathiUI
import Testing

@Suite("Preview handoff")
struct PreviewHandoffTests {
    @Test func noPreviewMeansNothingToStop() {
        for call in SessionAudioCall.allCases {
            #expect(PreviewHandoff.plan(previewing: false, call: call) == PreviewHandoff(silencesVoice: false, fadesMusic: false))
        }
    }

    @Test func aSessionSoundEndsThePreviewVoiceAndMusic() {
        let plan = PreviewHandoff(silencesVoice: true, fadesMusic: true)
        #expect(PreviewHandoff.plan(previewing: true, call: .play) == plan)
        #expect(PreviewHandoff.plan(previewing: true, call: .speak) == plan)
    }

    @Test func sessionMusicTakesOverThePreviewMusic() {
        #expect(PreviewHandoff.plan(previewing: true, call: .startMusic) == PreviewHandoff(silencesVoice: true, fadesMusic: false))
    }
}
