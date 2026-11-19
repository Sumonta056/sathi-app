import SathiCore
import SwiftUI

struct SidebarPlanGroup: View {
    @EnvironmentObject var e: Engine
    @ObservedObject var route: MainRoute

    var body: some View {
        let todosOn = e.data.prefs.todos.isOn
        let calendarOn = e.data.prefs.calendarPage.isOn
        if todosOn || calendarOn {
            SidebarHeading(title: Copywriter.sidebarPlanHeading)
            if todosOn {
                MainSidebarItem(
                    title: Copywriter.mainPageTodos,
                    icon: "checkmark.circle",
                    isSelected: route.page == .todos,
                    badge: badge
                ) { route.page = .todos }
            }
            if calendarOn {
                MainSidebarItem(title: Copywriter.calendarPageTitle, icon: "calendar", isSelected: isCalendar) {
                    route.page = .calendar(nil)
                }
            }
        }
    }

    private var badge: SidebarBadge? {
        let n = e.todosBadgeCount
        return n > 0 ? SidebarBadge(count: n, label: Copywriter.todosBadge(n), id: "sidebar.todosBadge") : nil
    }

    private var isCalendar: Bool {
        if case .calendar = route.page { return true }
        return false
    }
}
