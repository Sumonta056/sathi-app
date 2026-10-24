import SathiCore

enum TimeSlots {
    struct Slot: Hashable {
        let minutes: Int
        let label: String
    }

    static let all: [Slot] = stride(from: 0, to: Limits.minutesPerDay, by: Limits.scheduleSlotMinutes).map {
        Slot(minutes: $0, label: Fmt.timeOfDay($0))
    }
}
