import AppKit
import SathiCore
import SwiftUI

struct ReadingListCard: View {
    @EnvironmentObject var e: Engine
    @State private var link = ""
    @State private var title = ""
    @State private var problem: ReadingAddResult?
    let paste: () -> String?

    init(paste: @escaping () -> String? = { NSPasteboard.general.string(forType: .string) }) {
        self.paste = paste
    }

    var body: some View {
        let list = e.data.prefs.reading.list
        let unread = list.filter { $0.doneOn == nil }
        let read = list.filter { $0.doneOn != nil }
        VStack(alignment: .leading, spacing: UIMetrics.sectionSpacing) {
            SettingsCard {
                ReadingAddRow(link: $link, title: $title, problem: $problem, paste: paste)
                if unread.isEmpty {
                    emptyLine
                } else {
                    ForEach(Array(unread.enumerated()), id: \.element.id) { index, item in
                        ReadingItemRow(item: item, position: .unread(index: index, count: unread.count))
                    }
                }
            }
            if !read.isEmpty {
                SectionLabel(Copywriter.readingReadHeader(count: read.count))
                SettingsCard {
                    ForEach(read) { item in
                        ReadingItemRow(item: item, position: .read)
                    }
                }
            }
        }
    }

    private var emptyLine: some View {
        Text(verbatim: Copywriter.readingListEmpty)
            .font(Typography.hint)
            .foregroundStyle(Night.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(UIMetrics.rowPadding)
            .overlay(alignment: .top) {
                Rectangle().fill(Night.divider).frame(height: UIMetrics.dividerHeight)
            }
    }
}
