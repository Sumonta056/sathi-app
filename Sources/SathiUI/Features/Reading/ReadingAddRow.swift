import SathiCore
import SwiftUI

struct ReadingAddRow: View {
    @EnvironmentObject var e: Engine
    @Binding var link: String
    @Binding var title: String
    @Binding var problem: ReadingAddResult?
    let paste: () -> String?

    init(
        link: Binding<String>,
        title: Binding<String>,
        problem: Binding<ReadingAddResult?>,
        paste: @escaping () -> String?
    ) {
        _link = link
        _title = title
        _problem = problem
        self.paste = paste
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: UIMetrics.readingFieldSpacing) {
                field(Copywriter.readingLinkPlaceholder, text: linkBinding)
                field(Copywriter.readingTitlePlaceholder, text: $title)
                    .frame(width: UIMetrics.readingTitleFieldWidth)
                Button { if let text = paste() { linkBinding.wrappedValue = text } } label: {
                    Text(verbatim: Copywriter.readingPaste)
                }
                .buttonStyle(GhostButton(accent: Night.reading, height: UIMetrics.chipHeight))
                Button(action: add) {
                    Text(verbatim: Copywriter.readingAdd)
                }
                .buttonStyle(AccentButton(accent: Night.reading, height: UIMetrics.chipHeight))
            }
            .padding(UIMetrics.rowPadding)
            if let line = problem.flatMap(Copywriter.readingProblem) {
                Text(verbatim: line)
                    .font(Typography.hint)
                    .foregroundStyle(Night.muted)
                    .padding(UIMetrics.readingProblemPadding)
            }
        }
    }

    private var linkBinding: Binding<String> {
        Binding(get: { link }, set: { link = $0; problem = nil })
    }

    private func field(_ placeholder: String, text: Binding<String>) -> some View {
        LazyTextField(placeholder: placeholder, text: text, onSubmit: add)
    }

    private func add() {
        let result = e.addReading(url: link, title: title)
        if result == .added {
            link = ""
            title = ""
            problem = nil
        } else {
            problem = result
        }
    }
}
