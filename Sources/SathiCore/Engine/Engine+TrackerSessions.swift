import Foundation

extension Engine {
    func trackerSessionStarted(_ id: HabitID) {
        let n = clock.now
        guard trackerPrefs.isOn, id != .water, trackerHours.isInside(n) else { return }
        let r = data.live.tracker.running
        if r?.kind != .buddy { data.live.tracker.beforeSession = pendingDoneAt == nil ? r.map(draft(of:)) : nil }
        endRunningOnInterrupt(at: n)
        clearTrackerPrompt()
        beginBuddyActivity(id, at: n)
    }

    func trackerSessionResumed() {
        guard trackerPrefs.isOn, data.live.tracker.awayCause == .idle else { return }
        returnFromAway(at: clock.now)
    }

    func trackerSessionEnded(_ id: HabitID) {
        guard trackerPrefs.isOn else { return }
        trackerSessionResumed()
        let n = clock.now
        data.live.tracker.lastInput = n.wholeSecond
        let other = HabitID.allCases.first { $0 != id && session($0) != nil }
        let r = data.live.tracker.running
        let ownsRunning = r?.kind == .buddy && r?.category == ActivityCategory.buddy(id).name
        if ownsRunning { endRunningActivity(at: n) }
        if let other {
            if ownsRunning, data.live.tracker.running == nil { beginBuddyActivity(other, at: n) }
            return requestTick()
        }
        guard ownsRunning else {
            data.live.tracker.beforeSession = nil
            return
        }
        if let before = data.live.tracker.beforeSession {
            data.live.tracker.beforeSession = nil
            setTrackerPrompt(
                PromptState(kind: .whatNow, shownAt: n, askTime: n, switchFrom: n, resume: before),
                byUser: !trackerRuntime.sessionTimedOut
            )
        }
        requestTick()
    }

    func logFinishedSession(_ id: HabitID, _ s: Session, at end: Date) {
        guard id != .water, !(trackerPrefs.isOn && trackerHours.isInside(s.start)) else { return }
        let category = addedBuddyCategory(id)
        storeActivity(Activity(
            kind: .buddy,
            text: buddyText(id),
            category: category,
            start: s.start,
            end: min(end, calendar.nextDay(after: s.start))
        ))
    }

    private func beginBuddyActivity(_ id: HabitID, at n: Date) {
        let left = session(id).map { $0.end.timeIntervalSince(max($0.start, n)) } ?? 0
        let minutes = Int((left / Timing.minute).rounded(.up))
        let d = ActivityDraft(
            text: buddyText(id),
            category: addedBuddyCategory(id),
            length: minutes > 0 ? .minutes(minutes) : .open
        )
        beginActivity(d, kind: .buddy, at: n)
    }

    private func addedBuddyCategory(_ id: HabitID) -> String {
        let category = ActivityCategory.buddy(id)
        if !activityCategories.contains(where: { $0.name == category.name }) {
            addActivityCategory(category.name, colorHex: category.colorHex)
        }
        return category.name
    }

    private func buddyText(_ id: HabitID) -> String {
        Copywriter.trackerBuddyText(id, detail: buddyDetail(id))
    }

    private func buddyDetail(_ id: HabitID) -> String? {
        switch id {
        case .water, .reading: return nil
        case .meditation:
            let style = data.prefs.meditation.style
            return Copywriter.breathShortName(style) + " " + Copywriter.breathBeats(style)
        case .gym: return gymIdeaText
        }
    }
}
