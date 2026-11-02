import Foundation

extension Engine {
    package var timeBlock: TimeBlock? { data.live.timeBlock }

    package func openBlockStart() {
        refreshCalendarAccess()
        guard calendarWriter.access == .notAsked else { return presenter.showBlockStart() }
        Task {
            await requestCalendarAccess()
            presenter.showBlockStart()
        }
    }

    @discardableResult
    package func startBlock(title: String, length: TimeBlockLength, calendarID: String) -> BlockStartResult {
        refreshCalendarAccess()
        guard calendarAccess == .allowed else { return .noAccess }
        if timeBlock?.waitingForCalendar == true {
            presenter.showBlockCalendarGone()
            return refuseStart()
        }
        guard calendarChoices().contains(where: { $0.id == calendarID }) else { return .noCalendar }
        endRunningBlockForStart()
        guard timeBlock == nil else { return refuseStart() }
        if finishedBlock != nil { dismissBlockDone() }
        let block = TimeBlock(
            title: TimeBlockText.clean(title),
            startedAt: clock.now.wholeSecond,
            length: length,
            calendarID: calendarID
        )
        data.live.timeBlock = block
        data.prefs.timeBlock.lastLength = length
        presenter.closeBlockStart()
        if usesBlockWidget {
            let calendarTitle = calendarTitle(calendarID) ?? calendarID
            presenter.showBlockNote(.started(
                title: block.title, length: length, end: block.plannedEnd, calendarTitle: calendarTitle
            ))
            presenter.showBlockWidget()
        }
        requestTick()
        return .started(block.id)
    }

    package func undoBlockStart(_ id: UUID) {
        guard let b = timeBlock, b.id == id, b.isRunning else { return }
        closeRunningBlock()
        data.live.timeBlock = nil
        requestTick()
    }

    package func endBlock() {
        guard let b = timeBlock, b.isRunning else { return }
        endNow(b)
        requestTick()
    }

    package func renameBlock(_ title: String) {
        guard timeBlock != nil else { return }
        data.live.timeBlock?.title = TimeBlockText.clean(title)
    }

    package func setBlockCalendar(_ id: String) {
        guard timeBlock != nil, calendarChoices().contains(where: { $0.id == id }) else { return }
        data.live.timeBlock?.calendarID = id
    }

    package func extendBlock() {
        guard let f = finishedBlock, timeBlock == nil else { return }
        var b = f.block
        b.plannedEnd = max(f.end, clock.now.wholeSecond).addingTimeInterval(Timing.blockExtend)
        data.live.timeBlock = b
        finishedBlock = nil
        presenter.closeBlockDone()
        if usesBlockWidget { presenter.showBlockWidget() }
        requestTick()
    }

    package func dismissBlockDone() {
        finishedBlock = nil
        presenter.closeBlockDone()
    }

    package func keepGoingBlock() {
        guard let b = timeBlock, b.isRunning, b.length == .open else { return }
        data.live.timeBlock?.nextCheckIn = clock.now.wholeSecond.addingTimeInterval(Timing.blockCheckIn)
        closeBlockCheckIn()
        requestTick()
    }

    var usesBlockWidget: Bool { data.prefs.timeBlock.display == .widget }

    func closeRunningBlock() {
        if usesBlockWidget { presenter.closeBlockWidget() }
        closeBlockCheckIn()
    }

    func closeBlockCheckIn() {
        guard blockCheckInShowing else { return }
        blockCheckInShowing = false
        presenter.closeBlockCheckIn()
    }

    private func refuseStart() -> BlockStartResult {
        presenter.closeBlockStart()
        return .blockWaiting
    }

    private func endRunningBlockForStart() {
        guard let b = timeBlock, b.isRunning, endNow(b) else { return }
        let minutes = Int(clock.now.wholeSecond.timeIntervalSince(b.startedAt) / Timing.minute)
        let calendarTitle = calendarTitle(b.calendarID) ?? b.calendarID
        presenter.showBlockNote(.savedPrevious(minutes: minutes, title: b.title, calendarTitle: calendarTitle))
    }

    @discardableResult
    private func endNow(_ b: TimeBlock) -> Bool {
        let end = clock.now.wholeSecond
        guard b.savedEventID != nil || end.timeIntervalSince(b.startedAt) >= Timing.blockMinimum else {
            closeRunningBlock()
            data.live.timeBlock = nil
            presenter.showBlockNote(.tooShort)
            return false
        }
        return finish(b, end: end)
    }
}
