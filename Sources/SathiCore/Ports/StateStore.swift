import Foundation

package protocol StateStore: AnyObject {
    func loadPrefs() -> Prefs
    func savePrefs(_ prefs: Prefs)
    func loadLive() -> LiveState
    func saveLive(_ live: LiveState)
    @discardableResult
    func flush() -> Bool
}
