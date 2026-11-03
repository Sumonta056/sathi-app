import Foundation

extension Engine {
    static let calendarPrivacyURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars")!

    package func openCalendarSettings() {
        links.open(Self.calendarPrivacyURL)
    }

    package func cancelBlockStart() {
        presenter.closeBlockStart()
    }

    package func undoStartedNote(_ note: BlockNote) {
        presenter.closeBlockNote()
        guard case let .started(title, length, end, _) = note,
              let b = timeBlock, b.title == title, b.length == length, b.plannedEnd == end else { return }
        undoBlockStart(b.id)
    }
}
