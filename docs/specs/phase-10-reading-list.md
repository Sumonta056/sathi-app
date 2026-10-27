# Phase 10: Reading list (Boi)

Branch: `feat/reading-list`.

## Goal

The user keeps a queue of links to read. Each day Boi suggests the oldest unread link. "Start reading" opens that link in the default browser and starts the reading timer. When the user finishes the article, it moves to a "Read" section with its date. An unfinished link comes back the next day.

## Slices

| Slice | Scope |
|---|---|
| 10a | Core: `ReadingItem`, `ReadingPrefs.list`, decoding, rules, Engine actions, `LinkOpener` port. Tests first. |
| 10b | UI: Settings > Reading "Reading list" card (add, paste, remove, reorder, undo). |
| 10c | UI: corner popup title, timer pill "Finished it", thank-you "Did you finish?", menu bar "Up next". |
| 10d | Website, README, screenshots. |

## Data shape (10a)

```swift
package struct ReadingItem: Codable, Equatable, Identifiable, Sendable {
    package let id: UUID
    package var title: String
    package var url: URL
    package let addedOn: DayKey
    package var doneOn: DayKey?
}
```

- `ReadingPrefs.list: [ReadingItem]`, JSON key `list`. Missing key decodes as `[]`. An item that cannot be read is dropped; the other items and settings stay (rule 9 of Schedules). No schema bump.
- Links read from disk pass the same check as Add (allowed scheme, http/https need a host, `file` needs an absolute path, at most `readingURLMax`). An item with a bad link is dropped, so a hand-edited file or a restored backup never reaches the browser.
- Two items with the same id: the first stays, later ones are dropped. Decode tidies the list: titles cut to `readingTitleMax`, unread items in saved order, then read items newest `doneOn` first. Decode never drops unread items for being over `readingListMax`; only Add refuses new ones.
- Order in the array is the queue order. Unread items keep the user's order. Read items are kept after unread items, newest `doneOn` first.
- `Limits.readingListMax = 50` unread items. `Limits.readingReadKeep = 50` read items. `Limits.readingTitleMax = 120` characters. `Limits.readingURLMax = 2048` characters.

## Rules (10a)

1. Add: the text is trimmed. A text without a scheme gets `https://`. Only `http`, `https`, and `file` schemes are accepted. A URL with no host (http/https) or longer than `readingURLMax` is refused. A URL already unread in the list is refused. A `file` URL needs an absolute path (`file:` and `file:foo` are refused). Add is refused when there are `readingListMax` unread items. A refused add changes nothing and returns a reason.
2. Title: trimmed and cut to `readingTitleMax`. An empty title shows the host (`www.` dropped), or the file name for `file` URLs. The stored title stays empty; only the display falls back.
3. Today's pick: the first unread item in the list. No unread item: no pick.
4. Mark done: sets `doneOn` to today's day key and moves the item to the top of the read section. When the read section has more than `readingReadKeep` items, the oldest read items are removed. Unread items are never removed by this rule.
5. Undo: clears `doneOn` and moves the item to the end of the unread items. Refused when unread items are already at `readingListMax`.
6. Remove: deletes one item by id. Move: changes the position of one unread item inside the unread items.
7. `Engine.startReading()` opens today's pick through the `LinkOpener` port (only when its link passes the same check), then starts the session as today. No pick: it only starts the session. The lock press-and-hold and every other session start never open a link.
8. `Engine.finishReading(markDone: Bool)`: during a reading session, finishes the session as done (full session minutes, same as `finishSession(.reading)`) and, when `markDone` is true and there is a pick, marks the pick done. Outside a session with `markDone` true, it only marks the pick done (the thank-you "Yes, done" button after the timer ended).
9. All list changes save prefs at once, like every other settings change. They never change the due time, snooze, or streak.

## Port

`Ports/LinkOpener.swift`: `package protocol LinkOpener: Sendable { func open(_ url: URL) }`. `SathiUI` implements it with `NSWorkspace.shared.open`. Tests use `SpyLinkOpener` in `SathiTestSupport`, wired into `EngineHarness`.

## Out of scope

Fetching page titles from the network. Reports listing read articles. A separate window.

## Settings card (10b)

Settings > Reading gets a section "What to read", placed right after "When". It holds a `ReadingListCard`:

1. Add row: a link field (placeholder "Paste a link"), an optional title field (placeholder "Title (optional)"), and an "Add" button in `Night.reading`. A "Paste" button fills the link field from the clipboard (plain text only). Return in either field also adds. After a good add both fields clear.
2. A refused add keeps the text and shows one short line under the row, by `ReadingAddResult`: unsupportedScheme "Only web links and files.", missingHost "That does not look like a link.", tooLong "That link is too long.", duplicate "That link is already on your list.", full "Your list is full. Read one first." The line clears when the link text changes.
3. Unread rows, in queue order. The first row has the tag "Up next". Each row shows `displayTitle` and the host (or file name) in muted text, and has up and down buttons (`moveReading`), and a remove button (`removeReading`). The first row has no up button; the last unread row has no down button.
4. Empty state when there is no unread item: "Add a link and Boi will suggest it at reading time."
5. A "Read" section label with the count, below the unread rows, only when there are read items. Each read row shows the title, the done date ("Read Oct 27"), an "Undo" button (`undoReadingDone`), and a remove button. Read rows are muted.
6. Every button has an accessibility label that names the item ("Remove <title>", "Move <title> up").
7. Strings go in `Copywriter+Reading`. Sizes go in `UIMetrics+Settings`. Each view stays under 200 lines: split into `ReadingListCard`, `ReadingAddRow`, `ReadingItemRow`.
