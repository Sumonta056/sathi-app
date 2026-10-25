# Phase 6b: tolerant decoding

Goal: a file written by a newer Sathi version never resets the other settings or drops a month of history. Business rules: Schedules 9, History and storage 8.

## Prefs

`WaterPrefs.init(from:)`, `ReadingPrefs.init(from:)`, `MeditationPrefs.init(from:)`: decode `strictness` with `c.known(.strictness, or: d.strictness)`. `WaterPrefs`: decode `container` with `c.known(.container, or: d.container)`.

Result: an unknown raw value (for example `"strictness": "fierce"`, `"container": "mug"`) gives that field's default. Every other field keeps its stored value. The file is not moved to `.corrupt`.

## History

### New types (SathiCore, `Storage/`)

```swift
enum RawJSON: Codable, Equatable {
    case null, bool(Bool), number(Double), string(String), array([RawJSON]), object([String: RawJSON])
}

struct MonthEvents: Codable {
    var events: [HistoryEvent]
    var unknown: [RawJSON]
}
```

- `RawJSON` decodes any JSON value and encodes it back to the same JSON value. Integers stay integers when they fit in a `Double` exactly (JSON numbers have no type; `Double` is enough for every number a newer version writes in an event).
- `MonthEvents` is encoded as one flat JSON array, the same shape as `[HistoryEvent]` today: first `events`, then `unknown`. Old files and new files have the same format. `schemaVersion` does not change.
- `MonthEvents.init(from:)` reads the array as `[RawJSON]`, and reads it a second time with a wrapper whose `init(from:)` never throws (`try? HistoryEvent(from: decoder)`). Each element that decodes as a `HistoryEvent` goes to `events`; each one that does not goes to `unknown` with its raw value.
- If the top level is not an array, decoding throws as today (the file moves to `.corrupt`).

### `FileHistoryStore`

- Load month files as `MonthEvents`. Keep `unknown` per month next to `cache` (for example `private var unknown: [String: [RawJSON]]`).
- Every write of a month writes `MonthEvents(events: cache[month] ?? [], unknown: unknown[month] ?? [])`.
- Cache release (`writeDirty`) releases the month's `unknown` together with its events. A later read loads both again from the file.
- `events(from:to:)` and `allEvents()` return only known events.
- No change to `HistoryStore`, `Engine`, the migrator, or export. A JSON backup (`allEvents`) does not include unknown events.

### Limits

- No new constants.
- Each file ≤ 200 lines; `RawJSON` and `MonthEvents` each in their own file.

## Tests that define done

Core (`Tests/SathiCoreTests/`), with `TestFiles.makeTempFolder()` and `flush()`:

1. Prefs: a `prefs.json` with an unknown water `strictness` loads `strictness` = default and keeps a non-default `intervalMinutes`, `container`, and the reading and meditation sections. Same for reading and meditation `strictness`, and water `container`. No `.corrupt` file exists afterwards.
2. History load: a month file with 2 valid events and 1 event with `"habit": "stretch"` returns the 2 valid events from `events(from:to:)` and `allEvents()`. No `.corrupt` file exists.
3. History load: an event with an unknown `kind` and an event with a missing `date` are kept as unknown (both cases).
4. Write-back: after loading that file, `append` a new event, `flush()`, then read the file as raw JSON: it holds the 2 old events, the new event, and the unknown event with every key and value unchanged (compare as parsed JSON, not as text).
5. Write-back after cache release: append to another month so the first month leaves the cache, then append to the first month again and flush. The unknown event is still in the file.
6. A month file whose top level is not an array still moves to `.corrupt` (existing behavior; keep the existing test green).
7. `RawJSON` round trip: a nested value with null, bool, int, float, string, array, object encodes to the same parsed JSON.
8. All existing tests pass.

## Review round 1 (2026-10-25)

### R1. Keep extra fields of known events (user: keep them)

A newer version can add a field to an event that this version still reads (for example `"note":"gym"`). The next write must keep it.

- `MonthEvents` gets `var extras: [[String: RawJSON]]`, one entry per event in `events`, in the same order. An entry holds the keys of the raw event object that `HistoryEvent` does not use (`date`, `habit`, `kind`, `amount`). It is empty when there are none.
- `FileHistoryStore` only appends events, so the first `extras.count` events of a month are the events read from the file. Appended events have no extras.
- Encoding: encode each event to a JSON object, then add its extra keys. A key that `HistoryEvent` writes always wins over an extra key with the same name.
- `FileHistoryStore` keeps `extras` per month next to `unknown`, and releases and reloads them together.

### R2. No stale unknown events

`readMonth` sets `unknown[month]` and `extras[month]` on every result: the file's values on `.value`, and empty on `.missing` and `.unreadable`.

### R3. Tests compare `RawJSON`, not `NSObject`

Parsed `NSNumber` values cannot tell `true` from `1`. Tests that check unknown or extra values compare decoded `RawJSON` values with `==`.

### Tests that define done (round 1)

1. A month file with a known event that has extra keys (`"note":"gym"`, a nested object, `true`, an int): after `append` and `flush()`, the written event has every extra key with the same value (compare as `RawJSON`).
2. An extra key named like a known key cannot exist in JSON (one object has unique keys), so no test for it. A test checks that the known fields of that event are written from the `HistoryEvent` values.
3. Stale unknown: `events(from:to:)` loads month X with an unknown event; the month file is then replaced with invalid JSON; `append` to X and `flush()`. The new file of X does not contain the old unknown event.
4. The existing unknown-event tests compare unknown values as `RawJSON`.

### Later (accepted limits)

- `RawJSON` stores numbers as `Double`: integers above 2^53 and `-0.0` are not written back exactly.
- A written month file lists known events first, then unknown events. It is not sorted by date. This version sorts on read.
- Each month file is decoded twice (about 4 times the cost of plain decoding; 3–4 ms for a few hundred events).
