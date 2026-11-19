import Combine
import SathiCore

@MainActor
final class MainRoute: ObservableObject {
    @Published var page: MainPage

    init(_ page: MainPage) {
        self.page = page
    }

    func settle(calendarOn: Bool, todosOn: Bool) {
        if !calendarOn, case .calendar = page { page = .dashboard(.day) }
        if !todosOn, page == .todos { page = .dashboard(.day) }
    }
}
