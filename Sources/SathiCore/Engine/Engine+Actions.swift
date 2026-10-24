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
        data.drinks.append(DrinkEntry(date: n, glasses: glasses))
        data.lastWaterDone = n
        prune()
        water = HabitState(nextDue: scheduler.nextWaterDue(after: n))
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
        let amount = (data.bottleLevel - level) * data.prefs.bottleSizeGlasses
        data.bottleLevel = level
        logWater(amount)
    }

    package func refillBottle() { data.bottleLevel = 1 }

    package func startReading() {
        guard phase == .idle || isActive(.reading) else { sound.beep(); return }
        presenter.closeBubble()
        presenter.closeLock()
        queue.removeAll { $0 == .reading }
        sessionStart = clock.now
        sessionEnd = sessionStart.addingTimeInterval(TimeInterval(data.prefs.readingSessionMinutes) * Timing.minute)
        phase = .session
        presenter.showSession()
        play(.purr)
        requestTick()
    }

    package func finishSession() {
        let minutes = data.prefs.readingSessionMinutes
        let n = clock.now
        data.reads.append(ReadEntry(date: n, minutes: minutes))
        prune()
        reading = HabitState(nextDue: scheduler.nextReadingDue(now: n, readToday: readToday, skipToday: false))
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
        if id == .water { logWater(1) } else { startReading() }
    }

    package func emergencySkip(_ id: HabitID) {
        let n = clock.now
        data.streakReset[id.rawValue] = n
        if id == .water {
            water = HabitState(nextDue: scheduler.nextWaterDue(after: n))
        } else {
            reading = HabitState(nextDue: scheduler.nextReadingDue(now: n, readToday: readToday, skipToday: true))
        }
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
        guard data.prefs.soundOn else { return }
        sound.play(name)
    }

    func reschedule() {
        let n = clock.now
        if !isActive(.water) && water.snoozedUntil == nil {
            water.nextDue = scheduler.nextWaterDue(after: data.lastWaterDone ?? n)
        }
        if !isActive(.reading) && reading.snoozedUntil == nil {
            reading.nextDue = scheduler.nextReadingDue(now: n, readToday: readToday, skipToday: false)
        }
        queue.removeAll { !enabled($0) }
        requestTick()
    }

    private func snoozeHabit(_ id: HabitID) {
        let until = clock.now.addingTimeInterval(TimeInterval(data.prefs.snoozeMinutes) * Timing.minute)
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

    private func prune() {
        let cutoff = clock.now.addingTimeInterval(-Double(Limits.historyRetentionDays) * Timing.day)
        if data.drinks.contains(where: { $0.date < cutoff }) { data.drinks.removeAll { $0.date < cutoff } }
        if data.reads.contains(where: { $0.date < cutoff }) { data.reads.removeAll { $0.date < cutoff } }
    }
}
