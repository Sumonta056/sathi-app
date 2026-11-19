import Combine
import SathiCore

@MainActor
final class MainRoute: ObservableObject {
    @Published var page: MainPage
    @Published private(set) var opens = 0

    init(_ page: MainPage) {
        self.page = page
    }

    func open(_ page: MainPage) {
        self.page = page
        opens += 1
    }

    func settle(calendarOn: Bool, todosOn: Bool) {
        if !calendarOn, case .calendar = page { page = .dashboard(.day) }
        if !todosOn, page == .todos { page = .dashboard(.day) }
    }
}
