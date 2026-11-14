import Combine
import SathiCore

@MainActor
final class MainRoute: ObservableObject {
    @Published var page: MainPage

    init(_ page: MainPage) {
        self.page = page
    }

    func settle(calendarOn: Bool) {
        if !calendarOn, case .calendar = page { page = .today }
    }
}
