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
    func showDaySummary()
    func closeDaySummary()
    func showQuick(_ id: UUID, _ level: Level)
    func closeQuick(_ id: UUID)
    func showQuickLock(_ id: UUID)
    func showQuickSnoozed(text: String, until: Date)
}
