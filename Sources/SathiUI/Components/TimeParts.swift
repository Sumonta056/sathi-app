import SathiCore

struct TimeParts: Equatable {
    static let hours = [12] + Array(1 ... 11)
    static let minuteOptions = Array(stride(from: 0, to: 60, by: Limits.scheduleSlotMinutes))

    private static let hoursPerHalfDay = 12
    private static let minutesPerHour = 60

    let hour: Int
    let minute: Int
    let isPM: Bool

    init(minutes: Int) {
        let h24 = minutes / Self.minutesPerHour
        let h12 = h24 % Self.hoursPerHalfDay
        hour = h12 == 0 ? Self.hoursPerHalfDay : h12
        minute = minutes % Self.minutesPerHour
        isPM = h24 >= Self.hoursPerHalfDay
    }

    private init(hour: Int, minute: Int, isPM: Bool) {
        self.hour = hour
        self.minute = minute
        self.isPM = isPM
    }

    var minutes: Int {
        let h24 = hour % Self.hoursPerHalfDay + (isPM ? Self.hoursPerHalfDay : 0)
        return h24 * Self.minutesPerHour + minute
    }

    func with(hour: Int) -> TimeParts { TimeParts(hour: hour, minute: minute, isPM: isPM) }
    func with(minute: Int) -> TimeParts { TimeParts(hour: hour, minute: minute, isPM: isPM) }
    func with(isPM: Bool) -> TimeParts { TimeParts(hour: hour, minute: minute, isPM: isPM) }
}
