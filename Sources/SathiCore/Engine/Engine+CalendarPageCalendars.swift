import Foundation

package struct ShownCalendar: Equatable, Sendable {
    package var choice: CalendarChoice
    package var isShown: Bool
}

package struct ShownCalendarGroup: Equatable, Sendable {
    package var account: String
    package var calendars: [ShownCalendar]
}

extension Engine {
    package func shownCalendarGroups() -> [ShownCalendarGroup] {
        let hidden = data.prefs.calendarPage.hiddenCalendarIDs
        var groups: [ShownCalendarGroup] = []
        for choice in calendarWriter.readableCalendars() {
            let item = ShownCalendar(choice: choice, isShown: !hidden.contains(choice.id))
            if let i = groups.firstIndex(where: { $0.account == choice.account }) {
                groups[i].calendars.append(item)
            } else {
                groups.append(ShownCalendarGroup(account: choice.account, calendars: [item]))
            }
        }
        return groups
    }

    var shownCalendarIDs: [String] {
        shownCalendars(calendarWriter.readableCalendars()).map(\.id)
    }

    func shownCalendars(_ readable: [CalendarChoice]) -> [CalendarChoice] {
        let hidden = data.prefs.calendarPage.hiddenCalendarIDs
        return readable.filter { !hidden.contains($0.id) }
    }

    package func setCalendarShown(_ id: String, _ shown: Bool) {
        if shown {
            data.prefs.calendarPage.hiddenCalendarIDs.remove(id)
        } else {
            data.prefs.calendarPage.hiddenCalendarIDs.insert(id)
        }
    }

    package func setCalendarPageOn(_ on: Bool) {
        data.prefs.calendarPage.isOn = on
    }
}
