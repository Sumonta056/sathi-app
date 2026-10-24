# Phase 2: File storage

Goal: move all data from one UserDefaults blob to small JSON files in Application Support. Split `Prefs` by habit. Record every done, snooze, and skip as a `HistoryEvent`. Migrate old data once without loss.

Rules: `.claude/rules/business-logic.md` (History and storage). Roadmap: `docs/ROADMAP.md`.

## Files on disk

```
<base>/prefs.json            {"schemaVersion":1,"value":<Prefs>}
<base>/state.json            {"schemaVersion":1,"value":<LiveState>}
<base>/history/2026-10.json  {"schemaVersion":1,"value":[<HistoryEvent>, ...]}
```

- `<base>` is injected. Production: `FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]/Sathi`.
- Dates encode as ISO 8601 (`JSONEncoder.dateEncodingStrategy = .iso8601`). Keys sort (`outputFormatting = [.sortedKeys]`).
- Month file name: `yyyy-MM` in the store's calendar, from the event date.
- Writes are atomic (`Data.write(to:options: .atomic)`). The folder is created on first write.
- A file that does not decode: rename it to `<name>.corrupt` (replace an older `.corrupt`), then use defaults. Never delete it.

## Models (SathiCore/Models)

```swift
package struct Prefs: Codable, Equatable, Sendable {
    package var general = GeneralPrefs()
    package var water = WaterPrefs()
    package var reading = ReadingPrefs()
    package var scheduleKey: String
    package func isEnabled(_ id: HabitID) -> Bool
    package func strictness(_ id: HabitID) -> Strictness
}
package struct GeneralPrefs  { name = "Mridul", snoozeMinutes = 5, ignoreMinutes = 5, soundOn = true }
package struct WaterPrefs    { enabled = true, intervalMinutes = 120, startMinutes = 570, endMinutes = 1110,
                               strictness = .strict, container = .glass, bottleSizeGlasses = 3, dailyGoalGlasses = 8 }
package struct ReadingPrefs  { enabled = true, timeMinutes = 1320, sessionMinutes = 15, strictness = .persistent }
```

Every prefs struct, `LiveState`, and `HistoryEvent` decodes JSON with missing keys by using the default for each missing key (custom `init(from:)` with `decodeIfPresent`). Unknown keys are ignored.

```swift
package struct LiveState: Codable, Equatable, Sendable {
    package var bottleLevel: Double = 1
    package var lastWaterDone: Date?
    package var streakReset: [String: Date] = [:]
}

package enum EventKind: String, Codable, Sendable { case done, snooze, skip }

package struct HistoryEvent: Codable, Equatable, Sendable {
    package var date: Date
    package var habit: HabitID
    package var kind: EventKind
    package var amount: Double
    package static func done(_ habit: HabitID, _ amount: Double, at date: Date) -> HistoryEvent
    package static func snooze(_ habit: HabitID, at date: Date) -> HistoryEvent
    package static func skip(_ habit: HabitID, at date: Date) -> HistoryEvent
}

package struct Persisted: Equatable, Sendable {
    package var prefs = Prefs()
    package var live = LiveState()
    package var events: [HistoryEvent] = []
    package func lastDone(_ id: HabitID) -> Date?
}
```

`amount`: water = glasses, reading = minutes, snooze and skip = 0.
`Persisted` is the in-memory aggregate. It is not encoded as one file. `drinks`, `reads`, `DrinkEntry`, `ReadEntry` are removed.

## Ports (SathiCore/Ports)

```swift
package protocol StateStore: AnyObject {
    func loadPrefs() -> Prefs
    func savePrefs(_ prefs: Prefs)
    func loadLive() -> LiveState
    func saveLive(_ live: LiveState)
    func flush()
}

package protocol HistoryStore: AnyObject {
    func append(_ event: HistoryEvent)
    func events(from start: Date, to end: Date) -> [HistoryEvent]
    func flush()
}
```

- `events(from:to:)` returns events with `start <= date < end`, sorted by date, reading only the month files that overlap the range.
- `flush()` writes every pending save now, on the calling thread.

## Implementations (SathiCore/Storage)

| Type | Job |
|---|---|
| `JSONFiles` | Encoder/decoder setup, `Versioned<T>` wrapper, atomic write, corrupt-file rename. |
| `FileStateStore(base:)` | `prefs.json` and `state.json`. A save marks the file dirty and schedules a write after `Timing.saveCoalesce` (0.5 s) on a private serial queue. `flush()` writes now. |
| `FileHistoryStore(base:calendar:)` | Keeps the current month's events in memory. `append` adds and schedules a coalesced write of that month file. Other months load on demand and are not cached. |
| `LegacyMigrator` | `static func migrateIfNeeded(defaults: UserDefaults, state: StateStore, history: HistoryStore, prefsFileExists: Bool) -> Bool`. Runs only when `prefsFileExists == false` and `defaults` has `StorageKeys.legacyV1` (`"sathi.state.v1"`). Decodes the old flat JSON (copy the old `Persisted`/`Prefs` shapes into `Storage/Legacy/LegacyV1.swift`), saves the mapped prefs and live state, appends every drink as `.done(.water, glasses)` and every read as `.done(.reading, minutes)`, then flushes. It never removes the old key. Returns true when it migrated. |

`UserDefaultsStateStore` is removed.

## Engine

1. `init(store:history:clock:sound:presenter:calendar:)`. It loads prefs and live state, and loads events from the start of the month `Limits.monthsInMemory - 1` months back (`monthsInMemory = 3`) up to `now`.
2. `data.didSet`: if `prefs` changed, `store.savePrefs`; if `live` changed, `store.saveLive`. Events are never saved through `didSet`.
3. `record(_ event:)` (internal): appends to `data.events` and calls `history.append`. It drops in-memory events older than the window start.
4. `logWater` records `.done(.water, glasses)`. `finishSession` records `.done(.reading, minutes)`. Every snooze (button, ignore timeout, stopped session) records `.snooze(id)`. `emergencySkip` records `.skip(id)`.
5. The old `prune()` and `Limits.historyRetentionDays` are removed.
6. `Stats` and `HabitRules.total` read `done` events of that habit. `Stats.streak` skips events at or before `live.streakReset[habit]`.

## App wiring (Sathi target)

- `AppEnvironment` builds the base URL, both file stores, runs `LegacyMigrator.migrateIfNeeded` before building the Engine.
- `AppDelegate.applicationWillTerminate` calls `flush()` on both stores.

## Constants

- `Timing.saveCoalesce = 0.5`
- `Limits.monthsInMemory = 3`, `Limits.schemaVersion = 1`
- `StorageKeys`: `legacyV1 = "sathi.state.v1"`, `appFolder = "Sathi"`, `prefsFile = "prefs.json"`, `stateFile = "state.json"`, `historyFolder = "history"`, `corruptSuffix = ".corrupt"`

## Test support

- `InMemoryStateStore(prefs:live:)` with `prefs`, `live`, `prefsSaves`, `liveSaves`, `flushes`.
- `InMemoryHistoryStore(events:)` with `events`, `appended`, `flushes`.
- `EngineHarness` keeps `configure: (inout Persisted) -> Void`. It seeds the state store with `prefs`/`live` and the history store with `events`. It exposes `history`.
- File tests use a fresh temp folder: `FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)`. Call `flush()` instead of waiting.

## Tests that define done

1. Prefs, LiveState, HistoryEvent: round-trip; `{}` decodes to defaults; a JSON with one known key keeps the other defaults.
2. `FileStateStore`: empty folder loads defaults; save + flush + new store loads the same; corrupt `prefs.json` loads defaults and leaves `prefs.json.corrupt`; no file is written before `flush()` when the coalesce delay has not passed.
3. `FileHistoryStore`: events on Oct 31 23:59 and Nov 1 00:01 land in `2026-10.json` and `2026-11.json`; `events(from:to:)` across both months returns both, sorted; the range end is exclusive; a corrupt month file is renamed and returns no events for that month.
4. `LegacyMigrator`: a v1 JSON fixture (flat prefs with non-default values, 3 drinks, 2 reads, bottleLevel 0.5, lastWaterDone, streakReset) maps to the exact new prefs, live state, and 5 events; runs only once (second call returns false, adds nothing); does nothing when the prefs file exists; the old key is still there after.
5. Engine: a logged glass appends one `.done(.water, 1)` to `h.history.appended`; ignoring a bubble records one `.snooze(.water)`; emergency skip records `.skip`; changing a pref saves prefs and not live; logging water saves live (`lastWaterDone`); init loads only events inside the 3-month window from the history store.
6. Every existing test still passes after the field renames (`prefs.water.intervalMinutes`, `live.lastWaterDone`, `events`).

## Decisions made while writing the tests

1. `Stats.total(_ id: HabitID, on: Date, in: [HistoryEvent]) -> Double` replaces `glasses(on:in:)` and `readMinutes(on:in:)`. It sums only `.done` events of that habit.
2. The v1 blob was written by a plain `JSONEncoder`, so its dates are numbers (seconds since 2001-01-01). `LegacyMigrator` decodes it with a plain `JSONDecoder`.
3. A corrupt file also means valid JSON of the wrong shape (for example `"value": 42`).

## Hardening (from the Phase 2 review)

Goal: no path may lose or double the user's data, including a crash, a full disk, or an unreadable file.

### H1. Migration marker and order (blockers)

- New file `<base>/migrated-v1` (`StorageKeys.migrationMarker`). Its content is not important (write `"1"`).
- New signature: `LegacyMigrator.migrateIfNeeded(defaults: UserDefaults, state: StateStore, history: HistoryStore, base: URL) -> Bool`. The `prefsFileExists` parameter is removed.
- Runs only when the marker file does not exist and the legacy key exists and decodes.
- Order:
  1. Append the legacy events that the history store does not already hold (H2), then `history.flush()`.
  2. Save prefs and live state, then `state.flush()`.
  3. Write the marker only when both flushes returned `true`.
- Returns `true` only when the marker was written.
- A deleted or quarantined `prefs.json` never starts the migration again. Only the marker controls it.

### H2. Idempotent history migration

- Before it appends, the migrator reads `history.events(from: first legacy date, to: last legacy date + 1 s)` and skips each legacy event that is equal (`==`) to an event already there.
- A second run after a partial first run gives exactly one copy of each legacy event.

### H3. Reads never cause an overwrite

- `JSONFiles.load` returns one of: `.missing` (no file), `.value(T)`, `.unreadable` (the file exists but cannot be read, or it did not decode and the quarantine move failed).
- A file that does not decode is moved to `<name>.corrupt` with `FileManager.replaceItemAt` (or an equivalent move-then-replace), so a failed move never deletes the older `.corrupt` copy. After a successful move the result is `.missing`.
- When a file is `.unreadable`, the store refuses to write that file for the rest of the session. Saves stay in memory. Loads return the in-memory value or defaults.

### H4. Failed writes are kept and retried

- `JSONFiles.write` returns `Bool`.
- `StateStore.flush()` and `HistoryStore.flush()` return `Bool` (`@discardableResult`): `true` only when every pending write succeeded.
- A failed write keeps its data pending (and the month cached). The next coalesced write or `flush()` tries again.

### H5. Deterministic coalescing

- `FileStateStore(base:delay:)` and `FileHistoryStore(base:calendar:delay:)`, where `delay` defaults to `Timing.saveCoalesce`. Tests that check "no file before flush" pass a long delay (for example 3600 s).

### Out of scope here

- Streaks longer than the 3-month window: Phase 4 (`StreakCalculator` reads older months from the `HistoryStore`). Until then a streak is capped at the window.

### Tests that define done (hardening)

1. Migration where the history flush fails (history folder made read-only with `chmod 0o500`): returns false, no marker. After the folder is writable again, a second call migrates, writes the marker, and each legacy event exists once.
2. Migration, then `prefs.json` deleted: a second call does nothing (marker exists), and the history is unchanged.
3. Migration run twice with the marker deleted in between: each legacy event exists once.
4. A month file with permission `000`: `events(from:to:)` returns no events for that month, an `append` + `flush` to that month returns false, and the file bytes are unchanged after `chmod` back.
5. A corrupt file when `<name>.corrupt` already exists: the new corrupt bytes end up in `<name>.corrupt`, and nothing is lost if the move fails (folder read-only: the original file is unchanged and the store does not write it).
6. A state save into a read-only folder: `flush()` returns false; after the folder is writable, `flush()` returns true and the file holds the last saved value.
7. `noFileIsWrittenBeforeFlush` tests use the injected long delay.

### Hardening decisions made while writing the tests

1. The migrator creates `<base>` when it writes the marker.
2. `flush()` returns `false` for both stores when a write is refused because the file is unreadable or its quarantine failed.
3. When `history.flush()` fails, the migrator stops: it does not save state and returns `false`.
4. A file that cannot be read (for example permission `000`) is not quarantined. Only a file that fails to decode is moved.

## Hardening round 2 (from the re-review)

### H6. Times are stored to the whole second (blocker)

- Rule: every stored time has a precision of 1 second. Fractional seconds are dropped (rounded down) when the value is created, so memory and disk always hold the same value.
- Add `Date.wholeSecond` in Core: `Date(timeIntervalSinceReferenceDate: floor(timeIntervalSinceReferenceDate))`.
- `HistoryEvent` stores `date.wholeSecond` in every init and factory (`done`, `snooze`, `skip`) and when it decodes.
- `LiveState.lastWaterDone` and every `LiveState.streakReset` value are stored as `.wholeSecond` (in the Engine where they are set, and when `LiveState` decodes).
- `LegacyV1` events use the same factories, so legacy dates are cut too.
- Result: a legacy event read back from disk is `==` to the same legacy event built from the v1 blob, so H2 dedup works on real data.

### H7. A re-run never overwrites newer state

- On a migration run, the migrator saves prefs only when `<base>/prefs.json` does not exist, and live state only when `<base>/state.json` does not exist.
- Events still go through the H2 dedup.

### Later (not in this phase)

- A second quarantine of the same file replaces the first `.corrupt` copy. A timestamped name can fix it later.

### Tests that define done (round 2)

1. `HistoryEvent.done(.water, 1, at: t)` with `t = 792403200.734512` has `date == 792403200`. Same for `snooze`, `skip`, and decoding.
2. `LiveState` decoded or set through the Engine (`logWater`, `emergencySkip`) holds whole-second dates.
3. A v1 fixture drink at `792403200.734512`: migrate, delete the marker, migrate again with fresh file stores: exactly one copy of each event.
4. A first run whose state flush fails after history was written (history on disk, no marker): the user's custom `prefs.json` and `state.json` written before the second run are unchanged after the second run, and no event is doubled.
5. Streak: a done event and a streak reset in the same second, stored and reloaded, give the same streak before and after the reload.
