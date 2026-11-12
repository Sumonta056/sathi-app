import SathiCore
import SwiftUI

struct PromptPlaceField: View {
    @Binding var text: String
    let saveID: String
    let onSave: () -> Void

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.promptBoxRadius, style: .continuous)
        HStack(spacing: UIMetrics.promptWhereGap) {
            LazyTextField(placeholder: Copywriter.trackerNewPlace, text: $text, startsEditing: true, onSubmit: onSave)
                .modifier(QuickTextLimit(text: $text, limit: Limits.awayPlaceNameMax))
                .frame(width: UIMetrics.promptPlaceFieldWidth, height: UIMetrics.promptBoxHeight)
                .background(shape.fill(Night.promptBox))
                .overlay(shape.strokeBorder(Night.promptBack, lineWidth: UIMetrics.promptBorder))
            PromptBox(label: Copywriter.trackerAddPlace, on: true, id: saveID, look: .place, action: onSave)
        }
    }
}
