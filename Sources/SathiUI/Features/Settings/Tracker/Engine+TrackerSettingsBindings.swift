import SathiCore
import SwiftUI

extension Engine {
    private func trackerBinding<V>(_ path: WritableKeyPath<TrackerPrefs, V>) -> Binding<V> {
        Binding(get: { self.data.prefs.tracker[keyPath: path] }, set: { self.data.prefs.tracker[keyPath: path] = $0 })
    }

    var trackerOn: Binding<Bool> { trackerBinding(\.isOn) }
    var trackerStartMinutes: Binding<Int> {
        Binding(get: { self.data.prefs.tracker.startMinutes }, set: { self.data.prefs.tracker.setStart($0) })
    }

    var trackerEndMinutes: Binding<Int> {
        Binding(get: { self.data.prefs.tracker.endMinutes }, set: { self.data.prefs.tracker.setEnd($0) })
    }
    var trackerWeekdays: Binding<Set<Weekday>> { trackerBinding(\.weekdays) }
    var trackerAskEvery: Binding<Int> { trackerBinding(\.askEveryMinutes) }
    var trackerIdle: Binding<Int> { trackerBinding(\.idleMinutes) }
    var trackerUsualLength: Binding<ActivityLength> { trackerBinding(\.usualLength) }
    var trackerCalendarOnByDefault: Binding<Bool> { trackerBinding(\.calendarOnByDefault) }
    var trackerEndOfDay: Binding<Bool> { trackerBinding(\.endOfDayOn) }
    var trackerSound: Binding<Bool> { trackerBinding(\.playsSound) }
    var trackerReadsEvents: Binding<Bool> { trackerBinding(\.readsEvents) }
    var trackerEventMode: Binding<EventMode> { trackerBinding(\.eventMode) }
    var trackerShortcut: Binding<KeyShortcut> { trackerBinding(\.shortcut) }

    func toggleTrackerWeekday(_ day: Weekday) {
        data.prefs.tracker.weekdays = data.prefs.tracker.weekdays.togglingKeepingOne(day)
    }

    func toggleReadCalendar(_ id: String) {
        var ids = data.prefs.tracker.readCalendarIDs
        if let i = ids.firstIndex(of: id) { ids.remove(at: i) } else { ids.append(id) }
        data.prefs.tracker.readCalendarIDs = ids
    }

    func setCategory(forCalendar id: String, to category: String?) {
        data.prefs.tracker.categoryByCalendar[id] = category
    }

    func setTrackerDefaultCalendar(_ id: String?) {
        data.prefs.tracker.defaultCalendarID = id
    }

    @discardableResult
    func renameTrackerCategory(_ old: String, to name: String) -> Bool {
        renameActivityCategory(old, to: name)
    }

    func removeTrackerCategory(_ name: String) {
        deleteActivityCategory(name)
    }

    func nextCategoryColor() -> UInt32 {
        let used = Set(activityCategories.map(\.colorHex))
        return ActivityCategory.palette.first { !used.contains($0) } ?? ActivityCategory
            .palette[activityCategories.count % ActivityCategory.palette.count]
    }
}

extension Engine {
    private var settingsCalendar: Calendar { Calendar.gregorian(in: timeZone) }

    func upcomingTrackerDaysOff() -> [DayKey] {
        data.prefs.tracker.days.upcoming(from: now, calendar: settingsCalendar)
    }

    func trackerDayOffMonth(offset: Int) -> DayOffMonth {
        data.prefs.tracker.days.month(offset: offset, now: now, calendar: settingsCalendar)
    }

    func addTrackerDayOff(_ key: DayKey) {
        let d = data.prefs.tracker.days
        let next = d.addingDayOff(key.start(in: settingsCalendar), now: now, calendar: settingsCalendar)
        if next != d { data.prefs.tracker.daysOff = next.daysOff }
    }

    func removeTrackerDayOff(_ key: DayKey) {
        data.prefs.tracker.daysOff.remove(key)
    }
}
