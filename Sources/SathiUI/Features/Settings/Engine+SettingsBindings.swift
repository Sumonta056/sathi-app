import SathiCore
import SwiftUI

extension Engine {
    func enabledBinding(_ id: HabitID) -> Binding<Bool> {
        Binding(get: { self.data.prefs.isEnabled(id) }, set: { self.setEnabled(id, $0) })
    }

    func closeButtonBinding(_ id: HabitID) -> Binding<Bool> {
        Binding(get: { self.data.prefs.showsCloseButton(id) }, set: { self.data.prefs.setShowsCloseButton(id, $0) })
    }

    var quickStrictness: Binding<Strictness> {
        Binding(get: { self.data.prefs.quick.strictness }, set: { self.data.prefs.quick.strictness = $0 })
    }

    var quickShowsClose: Binding<Bool> {
        Binding(get: { self.data.prefs.quick.showsCloseButton }, set: { self.data.prefs.quick.showsCloseButton = $0 })
    }

    static let noSnoozeLimitStep = Limits.snoozeLimits.upperBound + 1

    var snoozeLimitStep: Binding<Int> {
        Binding(get: { self.data.prefs.general.snoozeLimit ?? Self.noSnoozeLimitStep }, set: { n in
            self.data.prefs.general.snoozeLimit = n == Self.noSnoozeLimitStep ? nil : n
        })
    }

    private func setEnabled(_ id: HabitID, _ on: Bool) {
        switch id {
        case .water: data.prefs.water.enabled = on
        case .reading: data.prefs.reading.enabled = on
        case .meditation: data.prefs.meditation.enabled = on
        case .gym: data.prefs.gym.enabled = on
        }
    }
}

extension Engine {
    func gymIdeaName(at index: Int) -> Binding<String> {
        Binding(get: {
            let ideas = self.data.prefs.gym.ideas
            return ideas.indices.contains(index) ? ideas[index] : ""
        }, set: { name in
            guard self.data.prefs.gym.ideas.indices.contains(index) else { return }
            self.data.prefs.gym.ideas[index] = String(name.prefix(Limits.gymNameMaxLength))
        })
    }

    func addGymIdea() {
        guard data.prefs.gym.ideas.count < Limits.gymIdeasMax else { return }
        data.prefs.gym.ideas.append("")
    }

    func removeGymIdea(at index: Int) {
        guard data.prefs.gym.ideas.count > 1, data.prefs.gym.ideas.indices.contains(index) else { return }
        data.prefs.gym.ideas.remove(at: index)
    }

    func commitGymIdeas() {
        let cleaned = GymIdeas.cleaned(data.prefs.gym.ideas)
        if cleaned != data.prefs.gym.ideas { data.prefs.gym.ideas = cleaned }
    }
}

extension Engine {
    func weekdays(_ id: HabitID) -> Binding<Set<Weekday>> {
        Binding(get: { self.data.prefs.days(id).weekdays }, set: { days in
            var d = self.data.prefs.days(id)
            d.weekdays = days
            self.data.prefs.setDays(id, d)
        })
    }
}

extension Engine {
    var blockDisplay: Binding<TimeBlockDisplay> {
        Binding(get: { self.data.prefs.timeBlock.display }, set: { self.data.prefs.timeBlock.display = $0 })
    }

    var blockPlaysSound: Binding<Bool> {
        Binding(get: { self.data.prefs.timeBlock.playsSound }, set: { self.data.prefs.timeBlock.playsSound = $0 })
    }

    func pickDefaultCalendar(_ id: String) {
        data.prefs.timeBlock.defaultCalendarID = id
    }
}
