enum SessionAudioCall: CaseIterable {
    case speak, play, startMusic
}

struct PreviewHandoff: Equatable {
    let silencesVoice: Bool
    let fadesMusic: Bool

    static func plan(previewing: Bool, call: SessionAudioCall) -> PreviewHandoff {
        PreviewHandoff(silencesVoice: previewing, fadesMusic: previewing && call != .startMusic)
    }
}
