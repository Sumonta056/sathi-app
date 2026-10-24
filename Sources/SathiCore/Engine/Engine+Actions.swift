import Foundation

extension Engine {
    package func snooze() {
        guard case let .bubble(id, _) = phase else { return }
        snoozeHabit(id)
        presenter.closeBubble()
        phase = .idle
        requestTick()
    }

    package func logWater(_ amount: Double) {
        let glasses = max(Limits.minimumLog, Fmt.roundToGlassStep(amount))
        let n = clock.now
        record(.done(.water, glasses, at: n))
        data.live.lastWaterDone = n.wholeSecond
        habits[.water] = HabitState(nextDue: freshDue(.water, lastDone: n))
        queue.removeAll { $0 == .water }
        if isActive(.water) {
            presenter.closeBubble()
            presenter.closeLock()
            phase = .idle
        }
        if phase == .idle { celebrate(.water, glasses) } else { play(.glass) }
        requestTick()
    }

    package func logBottle(newLevel: Double) {
        let level = max(0, min(1, newLevel))
        let amount = (data.live.bottleLevel - level) * data.prefs.water.bottleSizeGlasses
        data.live.bottleLevel = level
        logWater(amount)
    }

    package func refillBottle() { data.live.bottleLevel = 1 }

    package func startReading() {
        guard phase == .idle || isActive(.reading) else { sound.beep(); return }
        presenter.closeBubble()
        presenter.closeLock()
        queue.removeAll { $0 == .reading }
        sessionStart = clock.now
        sessionEnd = sessionStart.addingTimeInterval(TimeInterval(data.prefs.reading.sessionMinutes) * Timing.minute)
        phase = .session
        presenter.showSession()
        play(.purr)
        requestTick()
    }

    package func finishSession() {
        let minutes = data.prefs.reading.sessionMinutes
        let n = clock.now
        record(.done(.reading, Double(minutes), at: n))
        habits[.reading] = HabitState(nextDue: freshDue(.reading, lastDone: n))
        presenter.closeSession()
        phase = .idle
        celebrate(.reading, Double(minutes))
    }

    package func stopSession() {
        presenter.closeSession()
        snoozeHabit(.reading)
        phase = .idle
        requestTick()
    }

    package func lockConfirmed(_ id: HabitID) {
        switch id {
        case .water: logWater(1)
        case .reading: startReading()
        }
    }

    package func emergencySkip(_ id: HabitID) {
        let n = clock.now
        record(.skip(id, at: n))
        data.live.streakReset[id.rawValue] = n.wholeSecond
        habits[id] = HabitState(nextDue: freshDue(id, lastDone: n, skipToday: true))
        presenter.closeLock()
        phase = .idle
        requestTick()
    }

    package func endCelebrate() {
        guard phase == .celebrate else { return }
        presenter.closeCelebration()
        phase = .idle
        requestTick()
    }

    package func trigger(_ id: HabitID) {
        pausedUntil = nil
        guard enabled(id), !isActive(id) else { return }
        forced.insert(id)
        let n = clock.now
        update(id) { st in
            st.snoozedUntil = nil
            st.nextDue = n
        }
        if phase == .celebrate { endCelebrate() }
        tick()
    }

    package func pause(hours: Double = Timing.defaultPauseHours) {
        pausedUntil = clock.now.addingTimeInterval(hours * Timing.hour)
        requestTick()
    }

    package func resume() {
        pausedUntil = nil
        requestTick()
    }

    package func openSettings() { presenter.showSettings() }

    package func play(_ name: SoundName) {
        guard data.prefs.general.soundOn else { return }
        sound.play(name)
    }

    func reschedule() {
        for id in HabitID.allCases where !isActive(id) && state(id).snoozedUntil == nil {
            let due = freshDue(id, lastDone: data.lastDone(id))
            update(id) { $0.nextDue = due }
        }
        queue.removeAll { !enabled($0) }
        requestTick()
    }

    private func snoozeHabit(_ id: HabitID) {
        let n = clock.now
        record(.snooze(id, at: n))
        let until = n.addingTimeInterval(TimeInterval(data.prefs.general.snoozeMinutes) * Timing.minute)
        update(id) { st in
            st.snoozes += 1
            st.snoozedUntil = until
        }
    }

    private func celebrate(_ id: HabitID, _ amount: Double) {
        celebration = Celebration(id: id, amount: amount, title: Copywriter.celebrationTitle(id))
        phase = .celebrate
        presenter.showCelebration()
        play(.hero)
        let token = UUID()
        celebrateToken = token
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(Timing.celebrationDuration * 1_000_000_000))
            guard let self, celebrateToken == token else { return }
            endCelebrate()
        }
    }
}
