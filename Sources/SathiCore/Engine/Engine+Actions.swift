import Foundation

extension Engine {
    package func snooze(_ id: HabitID) {
        guard case .bubble = activities[id] else { return }
        snoozeHabit(id)
        presenter.closeBubble(id)
        if usesCorner(id), let until = state(id).snoozedUntil { presenter.showSnoozed(id, until: until) }
        activities[id] = nil
        requestTick()
    }

    package func logWater(_ amount: Double) {
        let glasses = max(Limits.minimumLog, Fmt.roundToGlassStep(amount))
        let n = clock.now
        record(.done(.water, glasses, at: n))
        data.live.lastWaterDone = n.wholeSecond
        habits[.water] = HabitState(nextDue: freshDue(.water, lastDone: n))
        close(.water)
        if activities.isEmpty { celebrate(.water, glasses) } else { play(.glass) }
        requestTick()
    }

    package func logBottle(newLevel: Double) {
        let level = max(0, min(1, newLevel))
        let amount = (data.live.bottleLevel - level) * data.prefs.water.bottleSizeGlasses
        data.live.bottleLevel = level
        logWater(amount)
    }

    package func refillBottle() { data.live.bottleLevel = 1 }

    package func lockConfirmed(_ id: HabitID) {
        switch id {
        case .water: logWater(1)
        case .reading: startReading()
        case .meditation: startMeditation()
        }
    }

    package func emergencySkip(_ id: HabitID) {
        let n = clock.now
        record(.skip(id, at: n))
        data.live.streakReset[id.rawValue] = n.wholeSecond
        habits[id] = HabitState(nextDue: freshDue(id, lastDone: n, skipToday: true))
        close(id)
        requestTick()
    }

    package func endCelebrate() {
        guard isCelebrating else { return }
        presenter.closeCelebration()
        isCelebrating = false
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
    package func openReports() { presenter.showReports() }

    package func play(_ name: SoundName) {
        guard data.prefs.general.soundOn else { return }
        sound.play(name)
    }

    func reschedule() {
        let n = clock.now
        for id in HabitID.allCases where !enabled(id) {
            close(id)
        }
        for id in HabitID.allCases where !isActive(id) {
            let fresh = freshDue(id, lastDone: data.lastDone(id))
            var due = fresh
            if due < n, let slot = rules(id).nextSlot(after: n) { due = slot }
            let staleSnooze = state(id).snoozedUntil.map { $0 <= n } ?? false
            if due == .distantFuture || !enabled(id) || staleSnooze || fresh > n {
                update(id) { $0 = HabitState(nextDue: due) }
            } else if state(id).snoozedUntil == nil {
                update(id) { $0.nextDue = due }
            }
        }
        requestTick()
    }

    func close(_ id: HabitID) {
        switch activities[id] {
        case .bubble: presenter.closeBubble(id)
        case .lock: presenter.closeLock()
        case .session: presenter.closeSession(id)
        case nil: return
        }
        activities[id] = nil
    }

    func snoozeHabit(_ id: HabitID) {
        let n = clock.now
        record(.snooze(id, at: n))
        let until = n.addingTimeInterval(TimeInterval(data.prefs.general.snoozeMinutes) * Timing.minute)
        update(id) { st in
            st.snoozes += 1
            st.snoozedUntil = until
        }
    }

    func celebrate(_ id: HabitID, _ amount: Double) {
        celebration = Celebration(id: id, amount: amount, title: Copywriter.celebrationTitle(id, amount: amount))
        isCelebrating = true
        presenter.showCelebration()
        if let sound = celebrationSound(id) { play(sound) }
        let token = UUID()
        celebrateToken = token
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(Timing.celebrationDuration * 1_000_000_000))
            guard let self, celebrateToken == token else { return }
            endCelebrate()
        }
    }
}
