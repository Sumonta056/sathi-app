import Foundation

extension Engine {
    private var breath: MeditationPrefs { data.prefs.meditation }
    private var soundOn: Bool { data.prefs.general.soundOn }

    func sessionStarted(_ id: HabitID) {
        switch id {
        case .water, .reading, .gym: return
        case .meditation:
            breathCueMark = nil
            minuteTickMark = nil
            if soundOn {
                if breath.chime { audio.play(.bell, volume: Limits.bellVolume) }
                if breath.musicOn { audio.startMusic(volume: breath.musicVolume) }
                if breath.voiceOn { audio.speak(.begin, volume: breath.voiceVolume) }
            }
            tickBreath()
        }
    }

    func sessionPaused(_ id: HabitID) {
        switch id {
        case .water, .reading, .gym: return
        case .meditation:
            guard soundOn else { return }
            audio.silenceVoice()
            audio.pauseMusic()
        }
    }

    func sessionResumed(_ id: HabitID) {
        switch id {
        case .water, .reading, .gym: return
        case .meditation:
            markCurrentBreath()
            if soundOn && breath.musicOn { audio.startMusic(volume: breath.musicVolume) }
        }
    }

    func sessionFinishing(_ id: HabitID) {
        switch id {
        case .water, .reading, .gym: return
        case .meditation:
            guard soundOn else { return }
            audio.silenceVoice()
            if breath.voiceOn { audio.speak(.wellDone, volume: breath.voiceVolume) }
            if breath.chime { audio.play(.bell, volume: Limits.bellVolume) }
        }
    }

    func sessionClosed(_ id: HabitID) {
        switch id {
        case .water, .reading, .gym: return
        case .meditation: audio.endSession()
        }
    }

    func sessionRestored() {
        guard let s = session(.meditation), !s.isPaused else { return }
        markCurrentBreath()
        if soundOn && breath.musicOn { audio.startMusic(volume: breath.musicVolume) }
    }

    func tickBreath() {
        guard let s = session(.meditation) else { return }
        let n = clock.now
        if let due = BreathCues.dueCue(breath.style, session: s, now: n, mark: breathCueMark) {
            breathCueMark = due.boundary
            if soundOn && breath.voiceOn { audio.speak(due.cue, volume: breath.voiceVolume) }
        }
        if let minute = BreathCues.dueMinute(session: s, now: n, mark: minuteTickMark) {
            minuteTickMark = minute
            if soundOn && breath.minuteTick { audio.play(.minuteTick, volume: Limits.minuteTickVolume) }
        }
    }

    var breathDeadlines: [Date] {
        guard let s = session(.meditation), !s.isPaused else { return [] }
        var deadlines: [Date] = []
        if let b = BreathCues.nextBoundary(breath.style, session: s, now: now) { deadlines.append(b) }
        if breath.minuteTick, let m = BreathCues.nextMinute(session: s, now: now) { deadlines.append(m) }
        return deadlines
    }

    package func previewSessionSound() {
        guard soundOn, session(.meditation) == nil else { return }
        audio.preview(
            voiceVolume: breath.voiceOn ? breath.voiceVolume : nil,
            musicVolume: breath.musicOn ? breath.musicVolume : nil,
            seconds: Timing.soundPreview
        )
    }

    private func markCurrentBreath() {
        guard let s = session(.meditation) else { return }
        let n = clock.now
        breathCueMark = BreathCues.phaseStart(breath.style, session: s, now: n)
        minuteTickMark = BreathCues.minuteStart(session: s, now: n)
    }
}
