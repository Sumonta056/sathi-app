import Foundation

@MainActor
package protocol CalendarChangeSource: AnyObject {
    func start(_ onChange: @escaping @MainActor () -> Void)
    func stop()
}

@MainActor
package final class NoCalendarChangeSource: CalendarChangeSource {
    package nonisolated init() {}

    package func start(_ onChange: @escaping @MainActor () -> Void) {}
    package func stop() {}
}
