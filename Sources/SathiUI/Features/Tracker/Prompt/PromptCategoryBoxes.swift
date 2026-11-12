import SathiCore
import SwiftUI

struct PromptCategoryBoxes: View {
    @ObservedObject var model: ActivityPromptModel
    let categories: [ActivityCategory]

    var body: some View {
        PromptBoxes {
            ForEach(categories) { category in
                PromptBox(
                    label: category.name, on: model.draft.category == category.name, id: "tracker.category." + category.name,
                    dot: Night.category(category.colorHex)
                ) { model.pick(category: category.name) }
            }
        }
    }
}
