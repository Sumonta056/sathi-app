import Foundation

@MainActor
package protocol ReminderPresenter: AnyObject {
    func showBubble(_ id: HabitID, _ level: Level)
    func closeBubble(_ id: HabitID)
    func showLock(_ id: HabitID)
    func closeLock()
    func showSession(_ id: HabitID)
    func closeSession(_ id: HabitID)
    func showCelebration()
    func closeCelebration()
    func showSettings()
    func showReports()
    func showSnoozed(_ id: HabitID, until: Date)
}
