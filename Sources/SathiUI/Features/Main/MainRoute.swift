import Combine
import SathiCore

@MainActor
final class MainRoute: ObservableObject {
    @Published var page: MainPage

    init(_ page: MainPage) {
        self.page = page
    }
}
