import Foundation

extension Engine {
    package var blockStatusText: String? {
        guard let b = timeBlock, b.isRunning else { return nil }
        if let end = b.plannedEnd {
            let left = max(0, end.timeIntervalSince(now))
            return Copywriter.blockMinutes(Int((left / Timing.minute).rounded(.up)))
        }
        return Copywriter.blockMinutes(Int(max(0, now.timeIntervalSince(b.startedAt)) / Timing.minute))
    }

    var blockDeadlines: [Date] {
        guard let b = timeBlock, b.isRunning else { return [] }
        let elapsed = max(0, now.timeIntervalSince(b.startedAt))
        let nextMinute = b.startedAt.addingTimeInterval(((elapsed / Timing.minute).rounded(.down) + 1) * Timing.minute)
        var deadlines = [nextMinute]
        if let end = b.plannedEnd { deadlines.append(end) }
        if b.length == .open {
            deadlines.append(b.startedAt.addingTimeInterval(Timing.blockCap))
            if !blockCheckInShowing, let c = b.nextCheckIn { deadlines.append(c) }
        }
        return deadlines
    }

    func tickBlock() {
        guard let b = timeBlock, b.isRunning else { return }
        if let end = b.plannedEnd {
            if now >= end { completePlanned(b, end: end) }
            return
        }
        let cap = b.startedAt.addingTimeInterval(Timing.blockCap)
        if now >= cap {
            finish(b, end: cap)
        } else if let c = b.nextCheckIn, now >= c, !blockCheckInShowing {
            blockCheckInShowing = true
            presenter.showBlockCheckIn()
            playBlockSound()
        }
    }

    func restoreBlock() {
        guard let b = timeBlock else { return }
        if b.waitingForCalendar {
            presenter.showBlockCalendarGone()
        } else if usesBlockWidget {
            presenter.showBlockWidget()
        }
    }

    private func completePlanned(_ b: TimeBlock, end: Date) {
        closeRunningBlock()
        guard let eventID = write(b, end: end) else { return wait(b, end: end) }
        var saved = b
        saved.savedEventID = eventID.isEmpty ? nil : eventID
        saved.plannedEnd = end
        data.live.timeBlock = nil
        finishedBlock = FinishedBlock(block: saved, end: end, calendarTitle: calendarTitle(b.calendarID) ?? b.calendarID)
        presenter.showBlockDone()
        playBlockSound()
    }

    private func playBlockSound() {
        if data.prefs.timeBlock.playsSound { play(.ping) }
    }
}
