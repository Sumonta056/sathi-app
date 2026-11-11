import SathiCore
import SwiftUI

@MainActor
final class PromptWhereForm: ObservableObject {
    @Published var place: AwayPlace?
    @Published var placeName: String?
    @Published var places: [String]
    @Published var adding = false
    @Published var newName = ""

    init(_ state: TrackerPromptState) {
        place = state.away?.place
        placeName = state.away?.placeName
        places = state.places
    }

    var label: String? {
        placeName ?? place.map(Copywriter.trackerAwayPlace)
    }

    func pick(_ picked: AwayPlace) {
        place = picked
        placeName = nil
    }

    func pick(named name: String) {
        place = .other
        placeName = name
    }

    func save() -> String? {
        guard let next = AwayPlaceList.adding(newName, to: places), let added = next.last else { return nil }
        places = next
        pick(named: added)
        adding = false
        newName = ""
        return added
    }
}
