import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import ViewInspector

extension Prefs {
    mutating func setWeekdays(_ id: HabitID, _ days: Set<Weekday>) {
        switch id {
        case .water: water.weekdays = days
        case .reading: reading.weekdays = days
        case .meditation: meditation.weekdays = days
        case .gym: gym.weekdays = days
        }
    }

    mutating func enableAll() {
        water.enabled = true
        reading.enabled = true
        meditation.enabled = true
        gym.enabled = true
    }

    mutating func setDaysOff(_ id: HabitID, _ keys: Set<DayKey>) {
        switch id {
        case .water: water.daysOff = keys
        case .reading: reading.daysOff = keys
        case .meditation: meditation.daysOff = keys
        case .gym: gym.daysOff = keys
        }
    }
}

func key(_ y: Int, _ m: Int, _ d: Int) -> DayKey {
    DayKey(day(y, m, d, 12), calendar: .current)
}

@MainActor
func settingsTab(_ id: HabitID, _ h: EngineHarness) throws -> InspectableView<ViewType.ClassifiedView> {
    switch id {
    case .water: return try hosted(WaterSettingsTab(), h).inspect()
    case .reading: return try hosted(ReadingSettingsTab(), h).inspect()
    case .meditation: return try hosted(MeditationSettingsTab(), h).inspect()
    case .gym: return try hosted(GymSettingsTab(), h).inspect()
    }
}
