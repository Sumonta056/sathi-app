import Foundation

package enum CalendarBlockStyle: Equatable, Sendable {
    case event(colorHex: UInt32)
    case activity(category: String?)
    case away
    case joined(category: String?)
    case todo(colorHex: UInt32)
}

package enum CalendarBlockSource: Equatable, Sendable {
    case event(CalendarEventInfo)
    case activity(Activity, running: Bool)
    case todo(String)
}

package struct CalendarBlock: Equatable, Identifiable, Sendable {
    package var id: String
    package var title: String
    package var interval: DateInterval
    package var style: CalendarBlockStyle
    package var source: CalendarBlockSource
    package var isAllDay: Bool
    package var activityIDs: [ActivityID]
    package var copies: Int
    package var group: CalendarBlockGroup?

    package init(
        id: String,
        title: String,
        interval: DateInterval,
        style: CalendarBlockStyle,
        source: CalendarBlockSource,
        isAllDay: Bool,
        activityIDs: [ActivityID],
        copies: Int = 1,
        group: CalendarBlockGroup? = nil
    ) {
        self.copies = copies
        self.group = group
        self.id = id
        self.title = title
        self.interval = interval
        self.style = style
        self.source = source
        self.isAllDay = isAllDay
        self.activityIDs = activityIDs
    }
}
