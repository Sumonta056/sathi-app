import Foundation

extension Engine {
    package var waitingSaveCalendarID: String? {
        let ids = calendarChoices().map(\.id)
        let candidates = [waitingCalendarPick, timeBlock?.calendarID]
        return candidates.compactMap { $0 }.first(where: ids.contains) ?? startCalendarID
    }

    package func pickWaitingCalendar(_ id: String) {
        guard timeBlock?.waitingForCalendar == true, calendarChoices().contains(where: { $0.id == id }) else { return }
        waitingCalendarPick = id
    }

    func blockDisplayChanged() {
        guard let b = timeBlock, b.isRunning else { return }
        if usesBlockWidget {
            presenter.showBlockWidget()
        } else {
            presenter.closeBlockWidget()
        }
    }
}

package enum WaitingSaveState: Equatable {
    case noAccess, noCalendar, choose
}

extension Engine {
    package var waitingSaveState: WaitingSaveState {
        guard calendarAccess == .allowed else { return .noAccess }
        return calendarChoices().isEmpty ? .noCalendar : .choose
    }
}
