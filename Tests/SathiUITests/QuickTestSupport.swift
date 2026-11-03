import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import ViewInspector

enum Quick {
    static let now = day(2026, 3, 4, 10)

    static func item(_ text: String, minutes: Double) -> QuickReminder {
        QuickReminder(text: text, due: now.addingTimeInterval(minutes * 60), createdAt: now)
    }

    static func clock(_ date: Date) -> String {
        date.formatted(Date.FormatStyle(date: .omitted, time: .shortened))
    }

    @MainActor
    static func harness(_ items: [QuickReminder] = []) -> EngineHarness {
        EngineHarness(at: now) { $0.live.quickReminders = items }
    }

    @MainActor
    static func many(_ count: Int) -> [QuickReminder] {
        (0 ..< count).map { item("Item \($0)", minutes: Double($0 + 1)) }
    }
}
