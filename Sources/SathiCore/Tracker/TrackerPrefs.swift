import Foundation

package struct TrackerPrefs: Codable, Equatable, Sendable {
    package var isOn = false
    package var startMinutes = Limits.trackerStartMinutes
    package var endMinutes = Limits.trackerEndMinutes
    package var weekdays: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday]
    package var daysOff: Set<DayKey> = []
    package var askEveryMinutes = Limits.trackerAskEveryDefault
    package var usualLength: ActivityLength = .minutes(Limits.trackerUsualLengthDefault)
    package var idleMinutes = Limits.idleDefault
    package var categories = ActivityCategory.defaults
    package var calendarOnByDefault = false
    package var defaultCalendarID: String?
    package var shortcut = KeyShortcut.trackerDefault
    package var endOfDayOn = true
    package var playsSound = true
    package var readsEvents = false
    package var quietByDefault = false
    package var readCalendarIDs: [String] = []
    package var eventMode: EventMode = .logAndTell
    package var categoryByCalendar: [String: String] = [:]
    package var eventCategoryByTitle: [String: String] = [:]

    package init() {}

    enum CodingKeys: String, CodingKey {
        case isOn, startMinutes, endMinutes, weekdays, daysOff, askEveryMinutes, usualLength, idleMinutes, categories
        case calendarOnByDefault, defaultCalendarID, shortcut, endOfDayOn, playsSound, readsEvents, quietByDefault
        case readCalendarIDs, eventMode, categoryByCalendar, eventCategoryByTitle
    }

    package var days: HabitDays { HabitDays(weekdays: weekdays, daysOff: daysOff) }
    package var sortedWeekdays: [Weekday] { Weekday.allCases.filter(weekdays.contains) }
    package var defaultCategory: String? { categories.first?.name }
}

extension TrackerPrefs {
    package init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = TrackerPrefs()
        isOn = c.lenient(.isOn, or: d.isOn)
        let start = Self.validTime(c.lenient(.startMinutes, or: d.startMinutes), or: d.startMinutes)
        let end = Self.validTime(c.lenient(.endMinutes, or: d.endMinutes), or: d.endMinutes)
        (startMinutes, endMinutes) = Self.ordered(start: start, end: end)
        weekdays = (try? c.knownSet(.weekdays, or: d.weekdays, keepsEmpty: false)) ?? d.weekdays
        daysOff = c.lenientSet(.daysOff, or: d.daysOff)
        askEveryMinutes = Self.chip(c.lenient(.askEveryMinutes, or: d.askEveryMinutes), in: Limits.trackerAskChips, or: d.askEveryMinutes)
        let length = c.lenient(.usualLength, or: d.usualLength)
        usualLength = ActivityLength.choices.contains(length) ? length : d.usualLength
        idleMinutes = Self.chip(c.lenient(.idleMinutes, or: d.idleMinutes), in: Limits.idleChips, or: d.idleMinutes)
        categories = c.contains(.categories) ? Array((c.lenientArray(.categories) as [ActivityCategory]).prefix(Limits.categoryMax)) : d.categories
        calendarOnByDefault = c.lenient(.calendarOnByDefault, or: d.calendarOnByDefault)
        defaultCalendarID = c.lenient(.defaultCalendarID, or: d.defaultCalendarID)
        shortcut = Self.validShortcut(c.lenient(.shortcut, or: d.shortcut), or: d.shortcut)
        endOfDayOn = c.lenient(.endOfDayOn, or: d.endOfDayOn)
        playsSound = c.lenient(.playsSound, or: d.playsSound)
        readsEvents = c.lenient(.readsEvents, or: d.readsEvents)
        quietByDefault = c.lenient(.quietByDefault, or: d.quietByDefault)
        readCalendarIDs = c.lenientArray(.readCalendarIDs)
        eventMode = (try? c.known(.eventMode, or: d.eventMode)) ?? d.eventMode
        categoryByCalendar = c.lenient(.categoryByCalendar, or: d.categoryByCalendar)
        eventCategoryByTitle = c.lenient(.eventCategoryByTitle, or: d.eventCategoryByTitle)
    }

    package func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(isOn, forKey: .isOn)
        try c.encode(startMinutes, forKey: .startMinutes)
        try c.encode(endMinutes, forKey: .endMinutes)
        try c.encode(sortedWeekdays, forKey: .weekdays)
        try c.encode(daysOff.sorted(), forKey: .daysOff)
        try c.encode(askEveryMinutes, forKey: .askEveryMinutes)
        try c.encode(usualLength, forKey: .usualLength)
        try c.encode(idleMinutes, forKey: .idleMinutes)
        try c.encode(categories, forKey: .categories)
        try c.encode(calendarOnByDefault, forKey: .calendarOnByDefault)
        try c.encodeIfPresent(defaultCalendarID, forKey: .defaultCalendarID)
        try c.encode(shortcut, forKey: .shortcut)
        try c.encode(endOfDayOn, forKey: .endOfDayOn)
        try c.encode(playsSound, forKey: .playsSound)
        try c.encode(readsEvents, forKey: .readsEvents)
        try c.encode(quietByDefault, forKey: .quietByDefault)
        try c.encode(readCalendarIDs, forKey: .readCalendarIDs)
        try c.encode(eventMode, forKey: .eventMode)
        try c.encode(categoryByCalendar, forKey: .categoryByCalendar)
        try c.encode(eventCategoryByTitle, forKey: .eventCategoryByTitle)
    }

    private static func validTime(_ minutes: Int, or fallback: Int) -> Int {
        (0 ... Limits.minutesPerDay).contains(minutes) && minutes % Limits.scheduleSlotMinutes == 0 ? minutes : fallback
    }

    private static func chip(_ value: Int, in chips: [Int], or fallback: Int) -> Int {
        chips.contains(value) ? value : fallback
    }

    private static func validShortcut(_ s: KeyShortcut, or fallback: KeyShortcut) -> KeyShortcut {
        s.modifiers.isEmpty || s.sameKeys(as: .finderSearch) ? fallback : s
    }
}
