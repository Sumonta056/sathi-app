import SathiCore
import SwiftUI

extension CalendarEventPopover {
    static func closes(after result: CalendarPageWriteResult) -> Bool {
        if case .saved = result { return true }
        return false
    }

    func save() {
        guard form.canSave else { return }
        if Self.closes(after: e.saveCalendarPageEvent(form)) {
            onClose()
        } else {
            failure = Copywriter.calendarEventSaveFailed
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
