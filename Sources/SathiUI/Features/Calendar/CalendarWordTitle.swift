import SwiftUI

struct CalendarWordTitle: View {
    let text: String
    let font: Font
    let color: Color
    let lines: Int

    static func longestWord(_ text: String) -> String {
        text.split(whereSeparator: \.isWhitespace).map(String.init).max { $0.count < $1.count } ?? text
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            ZStack(alignment: .topLeading) {
                styled(Text(verbatim: Self.longestWord(text))).fixedSize().hidden()
                styled(Text(verbatim: text))
                    .lineLimit(lines)
                    .frame(minWidth: 0, idealWidth: 0, maxWidth: .infinity, alignment: .leading)
            }
            styled(Text(verbatim: text))
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }

    private func styled(_ t: Text) -> some View {
        t.font(font).foregroundStyle(color)
    }
}
