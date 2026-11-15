import Combine
import SathiCore

@MainActor
final class MainRoute: ObservableObject {
    @Published var page: MainPage

    init(_ page: MainPage) {
        self.page = page
    }

    func settle(calendarOn: Bool, todosOn: Bool = true) {
        if !calendarOn, case .calendar = page { page = .today }
        if !todosOn, page == .todos { page = .today }
    }
}
