import Foundation

extension Copywriter {
    package static let trackerPlacesLabel = "Away places"
    package static let trackerPlacesHint = "Your own answers for \"Where were you?\""
    package static let trackerPlacesEmpty = "Add a place in the Welcome back popup."

    package static func trackerRemovePlace(_ name: String) -> String { "Remove " + name }
    package static let daysOffTitle = "Days off"
    package static let daysOffAdd = "Add a day off"
    package static let daysOffPick = "Pick a date"
    package static let trackerDaysOffHint = "Sathi stays quiet on these days."
    package static let trackerNoCalendars = "No calendars found on this Mac."
    package static let trackerNewCategory = "New category"
    package static let trackerSidebarGroup = "MY DAY"
    package static let trackerNewBadge = "NEW"
    package static let trackerSettingsTitle = "Activity tracker"
    package static let trackerSettingsSubtitle =
        "Sathi asks what you are doing and keeps your day. It is quiet on days off and when you take a break."
    package static let trackerOnLabel = "Tracker on"
    package static let trackerWhenToAsk = "When to ask"
    package static let trackerHours = "Hours"
    package static let trackerHoursHint = "Sathi asks only inside these hours."
    package static let trackerFrom = "From"
    package static let trackerTo = "To"
    package static let trackerDays = "Days"
    package static let trackerDaysHint = "Days off keep the tracker quiet."
    package static let trackerAskEvery = "Ask every"
    package static let trackerAskEveryHint = "How often Sathi asks \"Still on it?\" and \"What now?\"."
    package static let trackerUsualLength = "Usual length"
    package static let trackerUsualLengthHint = "The For chip starts here."
    package static let trackerAwayAfter = "Away after"
    package static let trackerAwayAfterHint = "No mouse or keys for this long."
    package static let trackerCategories = "Categories"
    package static let trackerAddCategory = "+ Add category"
    package static let trackerCategoriesFull = "You can have up to \(Limits.categoryMax) categories."
    package static let trackerCalendar = "Calendar"
    package static let trackerCalendarAllowed = "✓ Allowed"
    package static let trackerCalendarByDefault = "Tick \"Add to calendar\" by default"
    package static let trackerCalendarByDefaultHint = "You can change it on each activity."
    package static let trackerDefaultCalendar = "Default calendar"
    package static let trackerDefaultCalendarHint = "The prompt starts with this one. You can pick another one each time."
    package static let trackerCalendarEvents = "Calendar events"
    package static let trackerUseEvents = "Use my calendar events"
    package static let trackerReadCalendars = "Read these calendars"
    package static let trackerReadCalendarsHint = "Sathi reads events only from the calendars you tick, only on this Mac."
    package static let trackerWhenEventStarts = "When an event starts"
    package static let trackerWhenEventStartsHint = "When the Mac is away, Sathi always logs it and shows it when you come back."
    package static let trackerCategoryPerCalendar = "Category for each calendar"
    package static let trackerCategoryPerCalendarHint =
        "By default the calendar name is the category. A pick in the note for one event name wins."
    package static let trackerCalendarNameSuffix = " (calendar name)"
    package static let trackerMore = "More"
    package static let trackerShortcutLabel = "Keyboard shortcut"
    package static let trackerShortcutHint = "Opens the center panel from any app."
    package static let trackerChange = "Change"
    package static let trackerPressKeys = "Press the new keys"
    package static let trackerEndOfDayLabel = "Show my day when tracker hours end"
    package static let trackerSoundLabel = "Sound with each prompt"
    package static let trackerSoundHint = "A soft tap when Sathi asks."

    package static func trackerRemoveCategory(_ name: String) -> String { "Remove " + name }

    package static func trackerEndOfDayHint(_ minutes: Int) -> String {
        "The timeline opens at " + Fmt.timeOfDay(minutes) + "."
    }

    package static func trackerEventMode(_ mode: EventMode) -> String {
        switch mode {
        case .logAndTell: return "Log it and tell me"
        case .askFirst: return "Ask me first"
        }
    }

    package static func trackerModifier(_ m: KeyModifier) -> String {
        switch m {
        case .control: return "⌃"
        case .option: return "⌥"
        case .shift: return "⇧"
        case .command: return "⌘"
        }
    }

    package static func trackerShortcut(_ s: KeyShortcut) -> String {
        s.orderedModifiers.map(trackerModifier).joined() + s.keyName
    }
}
