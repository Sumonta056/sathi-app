import Foundation

extension Engine {
    package var activityCategories: [ActivityCategory] { data.prefs.tracker.categories }

    @discardableResult
    package func addActivityCategory(_ name: String, colorHex: UInt32) -> Bool {
        guard let next = ActivityCategoryList.adding(name, colorHex: colorHex, to: activityCategories) else { return false }
        data.prefs.tracker.categories = next
        return true
    }

    @discardableResult
    package func renameActivityCategory(_ old: String, to name: String) -> Bool {
        guard let next = ActivityCategoryList.renaming(old, to: name, in: activityCategories) else { return false }
        data.prefs.tracker.categories = next
        let new = next.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }?.name ?? name
        data.prefs.tracker.categoryByCalendar = data.prefs.tracker.categoryByCalendar.mapValues { $0 == old ? new : $0 }
        data.prefs.tracker.eventCategoryByTitle = data.prefs.tracker.eventCategoryByTitle.mapValues { $0 == old ? new : $0 }
        return true
    }

    package func deleteActivityCategory(_ name: String) {
        data.prefs.tracker.categories = ActivityCategoryList.removing(name, from: activityCategories)
        data.prefs.tracker.categoryByCalendar = data.prefs.tracker.categoryByCalendar.filter { $0.value != name }
        data.prefs.tracker.eventCategoryByTitle = data.prefs.tracker.eventCategoryByTitle.filter { $0.value != name }
    }

    package func setActivityCategoryColor(_ name: String, colorHex: UInt32) {
        data.prefs.tracker.categories = ActivityCategoryList.recoloring(name, to: colorHex, in: activityCategories)
    }
}
