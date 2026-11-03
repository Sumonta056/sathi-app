import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import ViewInspector

enum Block {
    static let now = day(2026, 3, 4, 10)

    static func clock(_ date: Date) -> String {
        date.formatted(Date.FormatStyle(date: .omitted, time: .shortened))
    }

    @MainActor
    static func harness(_ configure: (inout Persisted) -> Void = { _ in }) -> EngineHarness {
        EngineHarness.quiet(at: now, configure: configure)
    }

    @MainActor
    static func running(_ length: TimeBlockLength = .minutes(30), after minutes: Double = 0) -> EngineHarness {
        let h = harness()
        h.startBlock("Plan", length)
        h.advance(minutes: minutes)
        return h
    }

    @MainActor
    static func waiting() -> EngineHarness {
        let h = running(.minutes(30), after: 5)
        h.calendarWriter.nextSaveResult = .calendarMissing
        h.engine.endBlock()
        return h
    }

    @MainActor
    static func denied() -> EngineHarness {
        let h = harness()
        h.calendarWriter.access = .denied
        h.engine.refreshCalendarAccess()
        return h
    }

    @MainActor
    static func card(_ h: EngineHarness) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(TimeBlockCard(), h).inspect()
    }

    @MainActor
    static func popup(_ h: EngineHarness) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(BlockStartPopup(), h).inspect()
    }
}

@MainActor
final class Picked<Value> {
    var value: Value

    init(_ value: Value) {
        self.value = value
    }

    var binding: Binding<Value> {
        Binding(get: { self.value }, set: { self.value = $0 })
    }
}
