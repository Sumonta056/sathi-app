import Combine
import Foundation

@MainActor
package final class StatusModel: ObservableObject {
    @Published package private(set) var text = "Sathi"
    @Published package private(set) var isBook = false
    @Published package private(set) var iconLevel: Double = 1

    package init() {}

    package func update(text: String, isBook: Bool, iconLevel: Double) {
        if self.text != text { self.text = text }
        if self.isBook != isBook { self.isBook = isBook }
        if self.iconLevel != iconLevel { self.iconLevel = iconLevel }
    }
}
