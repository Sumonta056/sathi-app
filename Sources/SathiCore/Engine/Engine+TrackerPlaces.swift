import Foundation

extension Engine {
    package var awayPlaces: [String] { data.prefs.tracker.awayPlaces }

    @discardableResult
    package func addAwayPlace(_ name: String) -> Bool {
        guard let next = AwayPlaceList.adding(name, to: awayPlaces), let added = next.last else { return false }
        data.prefs.tracker.awayPlaces = next
        if data.live.tracker.prompt?.kind == .welcomeBack { setAwayPlace(named: added) }
        return true
    }

    package func removeAwayPlace(_ name: String) {
        data.prefs.tracker.awayPlaces = awayPlaces.filter { $0 != name }
    }

    package func setAwayPlace(_ place: AwayPlace) {
        pickAwayPlace(place, name: nil)
    }

    package func setAwayPlace(named name: String) {
        pickAwayPlace(.other, name: name)
    }

    func pickAwayPlace(_ place: AwayPlace, name: String?) {
        for id in trackerRuntime.awayItems {
            guard var item = removeStoredActivity(id) else { continue }
            item.awayPlace = place
            item.awayPlaceName = name
            item.text = item.awayText
            storeActivity(item)
        }
        trackerRuntime.lastAway?.place = place
        trackerRuntime.lastAway?.placeName = name
        objectWillChange.send()
    }
}
