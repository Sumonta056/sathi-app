import SathiCore
import SwiftUI

extension CalendarEventPopover {
    static func closes(after result: CalendarPageWriteResult) -> Bool {
        if case .saved = result { return true }
        return false
    }

    static func failureLine(after result: CalendarPageWriteResult) -> String? {
        switch result {
        case .saved: nil
        case .refused: Copywriter.calendarEventChanged
        case .failed, .invalid: Copywriter.calendarEventSaveFailed
        }
    }

    func save() {
        guard form.canSave else { return }
        let result = e.saveCalendarPageEvent(form)
        if Self.closes(after: result) {
            onClose()
        } else {
            failure = Self.failureLine(after: result)
        }
    }

    func delete() {
        guard let id = form.eventID else { return }
        if e.deleteCalendarPageEvent(id) {
            onClose()
        } else {
            failure = Copywriter.calendarEventDeleteFailed
        }
    }
}
