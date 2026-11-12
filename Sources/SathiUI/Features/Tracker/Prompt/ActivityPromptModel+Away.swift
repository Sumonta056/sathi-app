import SathiCore
import SwiftUI

struct PromptAwayPick: Equatable {
    let place: AwayPlace
    let name: String?

    var label: String { name ?? Copywriter.trackerAwayPlace(place) }
}

extension ActivityPromptModel {
    var awaySwitch: Binding<Bool> {
        Binding(get: { self.awayOn }, set: { self.turnAway($0) })
    }

    func turnAway(_ on: Bool) {
        awayOn = on
        guard !on else { return }
        awayPick = nil
        awayAdding = false
        awayNewName = ""
    }

    func pickAway(_ place: AwayPlace) {
        awayPick = PromptAwayPick(place: place, name: nil)
    }

    func pickAway(named name: String) {
        awayPick = PromptAwayPick(place: .other, name: name)
    }

    func saveAwayPlace() -> String? {
        guard let next = AwayPlaceList.adding(awayNewName, to: places.places), let added = next.last else { return nil }
        places.places = next
        pickAway(named: added)
        awayAdding = false
        awayNewName = ""
        return added
    }
}
