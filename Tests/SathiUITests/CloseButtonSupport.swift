import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import ViewInspector

enum ReminderSurface: String, CaseIterable, Sendable {
    case waterBubble, meditationInvite, readingFocus, readingInvite, gymInvite

    var id: HabitID {
        switch self {
        case .waterBubble: return .water
        case .meditationInvite: return .meditation
        case .readingFocus, .readingInvite: return .reading
        case .gymInvite: return .gym
        }
    }

    @MainActor
    func harness(_ configure: @escaping (inout Persisted) -> Void = { _ in }) -> EngineHarness {
        let h = EngineHarness(at: day(2026, 3, 4, 15)) {
            $0.prefs.meditation.enabled = true
            $0.prefs.gym.enabled = true
            $0.prefs.general.snoozeMinutes = 5
            $0.live.lastWaterDone = day(2026, 3, 4, 14, 59)
            $0.prefs.reading.reminderStyle = self == .readingFocus ? .focus : .corner
            configure(&$0)
        }
        h.showReminder(id)
        return h
    }

    @MainActor
    func persisting() -> EngineHarness {
        let h = harness {
            $0.prefs.water.strictness = .persistent
            $0.prefs.reading.strictness = .persistent
            $0.prefs.meditation.strictness = .persistent
            $0.prefs.gym.strictness = .persistent
        }
        h.engine.snooze(id)
        h.advance(minutes: 5)
        return h
    }

    @MainActor
    func inspect(_ h: EngineHarness, _ level: Level) throws -> InspectableView<ViewType.ClassifiedView> {
        try view(level).environmentObject(h.engine).inspect()
    }

    @MainActor
    @ViewBuilder
    private func view(_ level: Level) -> some View {
        switch self {
        case .waterBubble: WaterBubble(level: level)
        case .meditationInvite: MeditationInvite(level: level)
        case .readingFocus: LegacyBubble(id: .reading, level: level)
        case .readingInvite: ReadingInvite(level: level)
        case .gymInvite: GymInvite(level: level)
        }
    }
}

@MainActor
func hasDismiss(_ sut: InspectableView<some BaseViewType>) -> Bool {
    (try? sut.find(viewWithAccessibilityLabel: "Dismiss")) != nil
}

@MainActor
func closeSwitch(_ sut: InspectableView<some BaseViewType>) throws -> InspectableView<ViewType.Button> {
    var node = try sut.find(text: "Show a close button").parent()
    for _ in 0 ..< 16 {
        let hits = node.findAll(BuddySwitch.self)
        if hits.count == 1 { return try hits[0].find(ViewType.Button.self) }
        if hits.count > 1 { break }
        node = try node.parent()
    }
    throw LabelNotFound(label: "Show a close button")
}

@MainActor
func allOnHarness(_ configure: @escaping (inout Persisted) -> Void = { _ in }) -> EngineHarness {
    EngineHarness {
        $0.prefs.meditation.enabled = true
        $0.prefs.gym.enabled = true
        configure(&$0)
    }
}
