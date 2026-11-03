import Foundation

extension Engine {
    static let calendarPrivacyURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars")!

    package func openCalendarSettings() {
        links.open(Self.calendarPrivacyURL)
    }

    package func cancelBlockStart() {
        presenter.closeBlockStart()
    }
}
