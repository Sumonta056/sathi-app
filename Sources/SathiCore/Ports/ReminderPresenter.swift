import Foundation

@MainActor
package protocol ReminderPresenter: AnyObject {
    func showBubble(_ id: HabitID, _ level: Level)
    func closeBubble()
    func showLock(_ id: HabitID)
    func closeLock()
    func showSession()
    func closeSession()
    func showCelebration()
    func closeCelebration()
    func showSettings()
}
