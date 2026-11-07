# Phase 15: Breathing card D, Calm 4·6, pause, voice, music, date picker

Terms: `GLOSSARY.md` (Breathing session, Breathing pattern, Phase, Time left, Pause, Voice guide, Background music).
Design reference: card "D" in `breath-prototypes.html` (published prototype). The values in Task 9 come from that file.

## Global Constraints

- Every task follows `/feature`: failing tests first (red for the right reason, not a compile error), then code, then `./scripts/test.sh` and `./scripts/lint.sh`. Both must pass at the end of each task. Report the real test count.
- `SathiCore` imports only Foundation/Combine. AVFoundation, CoreText, AppKit and SwiftUI live only in `SathiUI`.
- No `Date()` in Core. Use `clock.now`. Tests use `EngineHarness` and `FakeClock`, with no real waits.
- Max 200 lines per file and 150 per type. No comments. No magic numbers: behavior goes in `Sources/SathiCore/Constants/Timing.swift` or `Limits.swift`, layout and animation in `Sources/SathiUI/Constants/UIMetrics+Breath.swift` (new), file names in `Sources/SathiUI/Platform/AudioFiles.swift` (new).
- Use `package` access for anything another target needs. `@MainActor` on everything that touches Engine, AppKit or SwiftUI.
- Every `switch` on `HabitID` is exhaustive. No `default:`.
- Storage: add fields only (recipe A of `/data-migration`). No schema bump. Tolerant decoding with defaults. Stored dates go through `.wholeSecond`.
- Performance:
  - No new repeating timer.
  - Audio players are created lazily when a session starts and released after it ends.
  - The breathing `TimelineView` runs at most at `UIMetrics.animationFrameInterval`. It is paused when hidden, when the session is paused, and (for motion) when Reduce Motion is on.
  - Idle CPU < 1%, < 40 MB fresh, < 50 MB after a window, < 10 idle wakeups/min.
- No drop shadows on cards. A glow inside the orb is fine.
- Never weaken a test. When a requirement changes an old test, change it in its own step and name the reason.

## Decisions

1. **Session pause model.**
   - `Session` gets `pausedAt: Date?`.
   - Resume shifts both `start` and `end` by `now − pausedAt`. Elapsed time (and so the phase) continues from the same point, and the end moves later by the paused length. `finishSession` still counts `end − start` = the full session minutes.
   - The pause is generic on `Session`, but only the breathing card shows the button.
2. **Persistence.** `LiveState.meditationSession: Session?` (lenient: a value that cannot be read loads `nil`). It is kept in sync from an `activities` `didSet` in `Engine.swift`. On `start()`, `restoreMeditationSession()` runs:
   - Paused, and `pausedAt` is today: restore it paused.
   - Running, its `end` is in the future, and it started today: restore it running.
   - Anything else: drop it with no event and no snooze.
   - Reading and Gym sessions are still not saved. Out of scope.
3. **Midnight.** A paused session whose `pausedAt` is before today's start ends at the next tick, with no event and no snooze, and the next due time stays. The next midnight is a deadline while paused. A running session that crosses midnight is unchanged.
4. **Default pattern.** `BreathingStyle` gains `.calm` as the first case, so it is the first settings card. `MeditationPrefs().style = .calm`. A saved `"style"` is kept. An unknown or missing style decodes to the default (`.calm`), following Schedules rule 9. Every `prefs.json` written so far contains `style`, so existing users keep theirs.
5. **One audio port.** `SessionAudio` (Core port) carries voice, music, bells and the minute tick. The Engine decides when and what plays. The Platform `BreathAudioPlayer` decides how: bundled clip if present, else `AVSpeechSynthesizer` with the best installed English voice. Bell: bundled clip if present, else system sound `SoundName.tink`. Tick: bundled clip if present, else system sound `SoundName.pop`. Both system sounds play as private copies.
6. **Chime moves to the port.** `celebrationSound(.meditation)` returns `nil`. The end bell goes through `SessionAudio.play(.bell, …)`. The `chime` pref keeps its key and now means "bell at start and natural end".
7. **Master sound.** `GeneralPrefs.soundOn == false` silences all session audio (voice, music, bells, tick) and disables Preview. One rule: "Sound off = Sathi is silent".
8. **Cue timing.**
   - Each phase boundary (and each full minute when the tick is on) is a deadline in `upcomingDeadlines()`.
   - `TickPlanner.delay` now lets a nearer deadline cut the 1 s session tick, so a cue fires on time.
   - A cue more than `Timing.cueLateLimit` (1 s) late is skipped. This stops a burst after sleep.
   - A paused session is not "in session": no 1 s tick while paused.
9. **Session start order.** Bell, music fade-in, "Let's begin", then the first phase cue ("Breathe in") in the same tick. The Platform queues speech, so they never overlap.
10. **Natural end:** silence the voice, "Well done", bell, then `endSession()` (music fades out, players are released after the fade and after the last phrase). Early Stop, midnight end, or habit turned off: `endSession()` only.
11. **Mid-session settings changes.** A change to voice on/off or voice volume applies at the next cue. A change to music on/off or music volume applies at the next session or Preview.
12. **Resources.**
    - `SathiUI` owns SPM resources: `.copy("Resources/Fonts")` and `.copy("Resources/Audio")`.
    - `Bundle.module` is NOT used, because it calls `fatalError` when the bundle is missing. `SathiResources.url(_:in:)` searches, in order: `Bundle.main.resourceURL/<sub>` (the .app), `Bundle.main.bundleURL/Sathi_SathiUI.bundle/<sub>` (`swift run`), and the folder next to the test bundle (`swift test`). It returns `nil` when the file is not found.
    - `build.sh` copies the bundle's `Fonts/` and `Audio/` folders (not the `.bundle`) into `Sathi.app/Contents/Resources/`. This avoids codesign trouble with a nested bundle that has no Info.plist.
13. **Figtree.**
    - One variable font `Sources/SathiUI/Resources/Fonts/Figtree-Variable.ttf` from Google Fonts, plus `OFL.txt`. The weights Light 300, Regular 400, Medium 500 and SemiBold 600 come from its weight axis.
    - Registered with `CTFontManagerRegisterFontsForURL(…, .process, …)` once, lazily, on the first breathing card.
    - Referenced by family name "Figtree" with `.weight(_:)`. If registration fails or the file is missing, the card uses `.system(…, design: .rounded)` at the same weight.
    - Used on the breathing card only.
14. **Days-off picker.**
    - A "Pick a date" chip opens a popover with a Monday-first month grid (`Limits.weekStartWeekday`).
    - One tap adds the day. The popover stays open, so several days can be added. A tap on a day already off does nothing.
    - Arrows are disabled before the current month and after the month of today + 365.
    - The grid comes from the pure Core `HabitDays.month(offset:now:calendar:)`.
15. **Time left** replaces "Round x of y". `BreathingPattern.totalRounds`/`round`, `Copywriter.breathRound`/`breathHeader`, `BreathCircle` and the old `breath*` UIMetrics that become unused are deleted with their tests (subtract before add), in the task that replaces them.

---

## Task 1: Business rules and words first

Files:
- `.claude/rules/business-logic.md`. Add a section `## Breathing session` after `## Time blocks` (after line 343) with these rules:
  1. A breathing session runs the selected pattern (`MeditationPrefs.style`). The card shows the time left (m:ss), never a round count.
  2. Pause (in a session) freezes the time left and the phase. Resume continues from the same point. The session end moves later by the paused length. There is no time limit. "Take a break" (Habits rule 9) is a different thing and does not pause a session.
  3. A pause survives a restart (`LiveState.meditationSession`). At launch:
     - A session paused today comes back paused.
     - A running session whose end is still ahead and that started today comes back running.
     - Anything else is dropped with no event and no snooze.
  4. At midnight a paused session ends. It does not count: no event, no snooze, and the next due time stays.
  5. An early Stop (running or paused) follows Schedules rule 6.
  6. During a pause, the voice is silent and the music fades out. Both come back on Resume. Other buddies keep reminding (Habits rule 5).
  7. Voice guide (`voiceOn`, `voiceVolume`): it speaks once at the start of each phase ("Breathe in", "Hold", "Breathe out", "Rest"), "Let's begin" at the start, and "Well done" at the natural end. It never counts aloud. A cue more than `Timing.cueLateLimit` late is skipped.
  8. Background music (`musicOn`, `musicVolume`): one loop that fades in at the start and fades out at the end, at Stop, and at Pause. A missing music file means no music.
  9. Bell (`chime`): at the start and at the natural end. Minute tick (`minuteTick`, default off): a very soft tick at each full minute of the session, not at the end.
  10. General Sound off silences all session audio, and Preview is off.
  11. Default pattern for new installs: Calm 4·6. A saved pattern is kept.
  12. No new timer. `upcomingDeadlines()` adds the next phase boundary, the next minute tick, and, while paused, the next midnight.
- Words table (line 184, "Session"): append "A meditation session can be paused (`Session.pausedAt`)."
- Escalation rule 5 (line 244): append "Stop works the same while paused."
- `GLOSSARY.md`, entry "Pause": add `_Avoid_: Take a break (that pauses reminders, not a session)`. Add the entry "**Minute tick**: a very soft sound at each full minute of a breathing session. _Avoid_: chime, bell".

Check: lint and tests pass (docs only).

## Task 2: Session model, persistence field (data-migration recipe A)

Tests first:
- `Tests/SathiCoreTests/SessionPauseTests.swift`, suite "Session pause":
  - `elapsed(at:)` while paused stays at `pausedAt − start` however far `now` moves.
  - `left(at:)` while paused is frozen.
  - `resumed(at:)` shifts `start` and `end` by the paused length, clears `pausedAt`, and keeps `end − start`.
  - `paused(at:)` stores `now.wholeSecond`.
  - `paused(at:)` on a session that is already paused returns it unchanged.
- `Tests/SathiCoreTests/LiveStateSessionDecodingTests.swift`, suite "LiveState session decoding":
  - Old `state.json` without `meditationSession` → `nil`, and the other fields stay (copy the pattern of `partialPrefsFileKeepsTheOtherDefaults`).
  - A malformed `meditationSession` (for example a string) → `nil`, and `quickReminders` and `timeBlock` stay.
  - Round trip with `pausedAt`.
  - Fractional dates decode as whole seconds (add a case to `WholeSecondTests.swift`).

Code:
- Move `Session` out of `Sources/SathiCore/Models/ReminderState.swift:15-29` into a new `Sources/SathiCore/Models/Session.swift`.
  - Add `package var pausedAt: Date?` (init parameter, default `nil`).
  - Make it `Codable` with `CodingKeys` `start, end, pausedAt, fromReminder, workout, readingItem`.
  - Custom `init(from:)`: `start` and `end` are required and pass through `.wholeSecond`. `pausedAt` passes through `.wholeSecond`. `fromReminder` uses `value(_:or: false)`.
  - Add `isPaused`, `elapsed(at:)`, `left(at:)`, `paused(at:)`, `resumed(at:)`.
- `Sources/SathiCore/Models/LiveState.swift:9`: add `package var meditationSession: Session?`. Decode with `c.lenient(.meditationSession, or: d.meditationSession)` (same pattern as line 21).

## Task 3: Engine pause, resume, midnight, restore, tick

Tests first:
- `Tests/SathiCoreTests/EngineSessionPauseTests.swift`, suite "Engine session pause". All use `EngineHarness` with meditation on and a 5-minute session.
  - Pause, `advance(minutes: 3)`: the session is still active and `left(at: now)` is unchanged.
  - Resume, then `advance(minutes: 5)` from resume: `history.appended == [.done(.meditation, 5, …)]`. It is not finished at the old end.
  - Stop while paused, started when nothing is due: no event, no snooze, `nextDue` unchanged.
  - Stop while paused, started from a reminder: one snooze (existing rule).
  - Paused at 23:50, advance to 00:01: the session is closed, no event, no snooze, and `presenter.calls` contains `.closeSession(.meditation)`.
  - While paused, a due water reminder still shows (`.showBubble(.water, …)`).
  - `statusText` is frozen while paused.
  - `nextTickDelay()` is not `Timing.activeTick` while paused.
- `Tests/SathiCoreTests/EngineSessionRestoreTests.swift`, suite "Engine session restore" (use `EngineHarness.restarted(from:at:)` plus `engine.start()`, as in `EngineTimeBlockStateTests.swift:84`):
  - Pause → `store.live.meditationSession?.pausedAt` is set.
  - Restart the same day → restored paused, and `.showSession(.meditation)`.
  - Restart the next day → `meditationSession == nil`, no event.
  - Running with its end in the future → restored running.
  - Running with its end in the past → dropped, no event.
  - Finish → `meditationSession == nil`.
- `Tests/SathiCoreTests/TickPlannerTests.swift`: add `sessionTickStopsAtANearerDeadline` (in session, deadline 0.4 s away → 0.4) and keep `sessionTicksEverySecond`.

Code:
- `Sources/SathiCore/Scheduling/TickPlanner.swift:10`: replace `if inSession { return Timing.activeTick }` with `var delay = inSession ? Timing.activeTick : Timing.idleTickMax`. Keep the loop and the `max(Timing.minTick, …)`.
- `Sources/SathiCore/Engine/Engine.swift`:
  - Line 22 `activities`: add `didSet { syncMeditationSession() }`.
  - Add stored vars `var breathCueMark: Date?` and `var minuteTickMark: Date?` (used in Task 5).
- New `Sources/SathiCore/Engine/Engine+SessionPause.swift`:
  - `package func pauseSession(_ id: HabitID)` and `package func resumeSession(_ id: HabitID)`. Both replace `activities[id]` with the new session, call the audio hooks from Task 5 (no-ops until then), and call `requestTick()`.
  - `func syncMeditationSession()`: writes `data.live.meditationSession = session(.meditation)` only when it differs.
  - `func endPausedSessionIfNewDay()`: when paused and `now >= calendar.nextDay(after: pausedAt)` → `close(.meditation)`, `requestTick()`.
- New `Sources/SathiCore/Engine/Engine+SessionRestore.swift`: `func restoreMeditationSession()` with the rules of Decision 2. A restore sets `activities[.meditation]` and calls `presenter.showSession(.meditation)`.
- `Sources/SathiCore/Engine/Engine+Loop.swift`:
  - `start()` line 7: call `restoreMeditationSession()` after `restoreBlock()`.
  - `tick()` line 21: call `endPausedSessionIfNewDay()` before the `endIfExpired` loop.
  - Line 37: `inSession: HabitID.allCases.contains { session($0).map { !$0.isPaused } ?? false }`.
  - Line 52: add `where now >= s.end && !s.isPaused`.
  - Line 74: running session → `s.end`; paused → `calendar.nextDay(after: pausedAt)`.
- `Sources/SathiCore/Engine/Engine+Session.swift:24-27`: use `n.wholeSecond` for `start` and for `end`'s base.
- `Sources/SathiCore/Engine/Engine+Display.swift:105`: replace `session($0)?.end` / `end.timeIntervalSince(now)` with the minimum of `session($0)?.left(at: now)`, passed to `Fmt.clock`.
- `Calendar.nextDay(after:)` (`Models/Calendar+Days.swift:10`) is internal. That is fine, same target.

## Task 4: Calm 4·6 pattern, default, copy, pattern cards

Tests first:
- `BreathingPatternTests.swift`:
  - `.calm` steps are `[(.inhale, 4), (.exhale, 6)]` and the cycle is 10.
  - `step(.calm, at: 5)` is `.exhale` with 5 s remaining.
- `MeditationPrefsTests.swift` (changed requirement, its own step):
  - `defaults()` (line 27) expects `.calm`.
  - `rawValuesAreStable` expects `["calm", "box", "relax", "even"]`.
  - New: a saved `"style":"box"` decodes `.box`.
- `LenientPrefsDecodingTests.swift:38`: rename to `…UnknownStyleBecomesCalm` and expect `.calm` (changed requirement: unknown → the new default).
- `BreathCopyTests.swift`:
  - `breathEyebrow` → `"CALM · 4 6"`, `"BOX · 4 4 4 4"`, `"WIND DOWN · 4 7 8"`, `"EVEN · 5 5"`.
  - `breathCount(4, .inhale)` → `"4 · IN"`; also `HOLD`, `OUT`, `REST`.
  - `breathLeft(192)` → `"3:12 left"`.
  - `breathVoice` for each cue: "Let's begin", "Breathe in", "Hold", "Breathe out", "Rest", "Well done".
  - `meditationInviteHint(minutes: 2, style: .calm)` contains "calm breathing".
- `Tests/SathiUITests/MeditationSettingsTabTests.swift`: 4 pattern cards, "Calm" is selected by default, a tap on "Box" sets `.box`. Check `OptionCardRedrawTests` still passes.

Code:
- `Sources/SathiCore/Habits/Meditation/MeditationPrefs.swift:4`: `case calm, box, relax, even`. Line 14: `= .calm`.
- `Sources/SathiCore/Habits/Meditation/BreathingPattern.swift:20-29`: add `case .calm: return [(.inhale, Timing.breathCalmIn), (.exhale, Timing.breathCalmOut)]`. `Timing.breathCalmIn = 4` and `breathCalmOut = 6` go after line 39 of `Timing.swift`.
- `Sources/SathiCore/Formatting/Copywriter+Meditation.swift`:
  - Add `breathEyebrow(_:)`, `breathCount(_:_:)`, `breathLeft(_:)` (uses `Fmt.clock`) and `breathVoice(_ cue: BreathCue)`. `breathVoice` needs `BreathCue`, so add the enum here or in Task 5 first.
  - Add `.calm` to `breathName` ("calm breathing").
  - Replace `breathTitle` with `breathShortName` ("Calm", "Box", "Wind down", "Even").
  - Keep `breathBeats` ("4·6") for the settings cards.
  - `breathHeader` and `breathRound` are deleted in Task 9.
  - If the file passes 200 lines, split into `Copywriter+Breath.swift`.
- `Sources/SathiUI/Features/Meditation/BreathingPatternCards.swift:28-42`: `.calm` gets title "Calm" and detail "Long, slow out-breath."
- Visual risk: 4 cards in `OptionCardRow` (an HStack). If "Wind down" wraps badly at the settings width, use a 2×2 `LazyVGrid` inside `BreathingPatternCards` only.

## Task 5: Sound prefs, SessionAudio port, cue planner, Engine cues

Tests first:
- `Tests/SathiCoreTests/MeditationSoundPrefsTests.swift`, suite "Meditation sound prefs":
  - Defaults: `voiceOn` true, `voiceVolume` 0.8, `musicOn` true, `musicVolume` 0.5, `minuteTick` false.
  - Old JSON without the keys → defaults, and `dailyGoalMinutes` stays.
  - Volumes 1.7 → 1 and −0.2 → 0 (clamped to `Limits.sessionVolume`).
  - Round trip.
- `Tests/SathiCoreTests/BreathCuesTests.swift`, suite "Breath cues" (pure):
  - At `start`: due `.inhale` at boundary `start`.
  - Calm at +3.5 s → next boundary is `start + 4`.
  - At +4 s with mark `start` → due `.exhale`.
  - Same mark again → nil.
  - 1.5 s after a boundary with no mark → nil (late).
  - Paused → nil and no boundary.
  - No boundary at or after `end`.
  - `dueMinute` at +60 s → `start + 60`; none at +30 s; none at `end` for a 1-minute session.
- `Tests/SathiCoreTests/EngineBreathAudioTests.swift`, suite "Engine breath audio" (`h.audio.calls`):
  - Start with defaults → `[.play(.bell, Limits.bellVolume), .startMusic(0.5), .speak(.begin, 0.8), .speak(.inhale, 0.8)]`.
  - Voice off → no `.speak`. Music off → no `.startMusic`. Chime off → no `.play(.bell, …)`.
  - `general.soundOn = false` → no calls at all.
  - Calm: advance 4 s → `.speak(.exhale, 0.8)` appended once; ticking again at 4.5 s adds nothing.
  - `minuteTick` on, advance 60 s → `.play(.minuteTick, Limits.minuteTickVolume)`.
  - Pause → `[.silenceVoice, .pauseMusic]`. Resume → `.startMusic(0.5)`, and the next cue fires only at the next boundary (no repeat of the current phase).
  - Natural end → ends with `[.silenceVoice, .speak(.wellDone, 0.8), .play(.bell, …), .endSession]`, and `sound.played` has no `.tink`.
  - Early stop → `.endSession` with no `.wellDone` and no bell.
  - Habit turned off mid-session → `.endSession`.
  - At start + 3.5 s (calm), `nextTickDelay()` ≈ 0.5.
  - `previewSessionSound()` → `.preview(voiceVolume: 0.8, musicVolume: 0.5, seconds: 5)`. Ignored during a session and when sound is off.
- Changed requirement (Decision 6), its own step:
  - `EngineSessionFixTests.swift:77`: `sound.played == []`, and `audio.calls` contains `.play(.bell, …)`.
  - `EngineMeditationTests.swift:29`: the same change.
  - `meditationFinishWithoutChimeIsSilent` stays and also asserts no bell.

Code:
- `MeditationPrefs.swift`: add `voiceOn = true`, `voiceVolume = Limits.voiceVolumeDefault`, `musicOn = true`, `musicVolume = Limits.musicVolumeDefault`, `minuteTick = false`. Add them to `CodingKeys` (lines 23-26), decode (clamp volumes with `min(max(v, lower), upper)` over `Limits.sessionVolume`), and encode.
- `Limits.swift`: `sessionVolume: ClosedRange<Double> = 0 ... 1`, `voiceVolumeDefault = 0.8`, `musicVolumeDefault = 0.5`, `bellVolume = 0.6`, `minuteTickVolume = 0.25`, `speechRateRatio = 0.85`.
- `Timing.swift`: `cueLateLimit: TimeInterval = 1`, `musicFadeIn: TimeInterval = 3`, `musicFadeOut: TimeInterval = 2`, `soundPreview: TimeInterval = 5`.
- New `Sources/SathiCore/Ports/SessionAudio.swift`:
  ```swift
  package enum BreathCue: String, CaseIterable, Sendable { case begin, inhale, hold, exhale, rest, wellDone; package init(_ phase: BreathPhase) }
  package enum SessionSound: String, Sendable { case bell, minuteTick }
  @MainActor package protocol SessionAudio: AnyObject {
      func speak(_ cue: BreathCue, volume: Double)
      func play(_ sound: SessionSound, volume: Double)
      func startMusic(volume: Double)
      func pauseMusic()
      func silenceVoice()
      func endSession()
      func preview(voiceVolume: Double?, musicVolume: Double?, seconds: TimeInterval)
  }
  @MainActor package final class SilentSessionAudio: SessionAudio { package init() {} … no-ops }
  ```
- New `Sources/SathiCore/Habits/Meditation/BreathCues.swift`, an enum of pure functions. Each takes `(style, session, now)`:
  - `dueCue(…, mark: Date?) -> (cue: BreathCue, boundary: Date)?`
  - `nextBoundary(…) -> Date?`
  - `dueMinute(session:now:mark:) -> Date?`
  - `nextMinute(session:now:) -> Date?`
  - The current phase start = `now − (phaseLength − step.remaining)`, from `BreathingPattern.step(style, at: s.elapsed(at: now))`.
- Engine:
  - `Engine.swift`: add `let audio: SessionAudio` and init parameter `audio: SessionAudio = SilentSessionAudio()` after `calendarWriter`. If the compiler rejects the default, pass it explicitly at the call sites: `EngineHarness.swift:28`, `AppEnvironment.swift:20`, `EnginePauseRestOfDayTests`, `EngineExportTimingTests`, `StreakReloadTests`, `GregorianTests`, `QuickAddFormTests`, `QuickPopupTests`.
  - New `Sources/SathiCore/Engine/Engine+Breath.swift`:
    - `func sessionStarted(_ id:)`, `sessionPaused`, `sessionResumed`, `sessionFinishing`, `sessionClosed`. Each switches on `HabitID`; only `.meditation` acts.
    - `func tickBreath()`: speaks the due cue (voice on, sound on) and sets `breathCueMark`; plays the due minute tick and sets `minuteTickMark`.
    - `var breathDeadlines: [Date]`.
    - `package func previewSessionSound()`.
    - Volumes and switches are read from `data.prefs.meditation`, gated by `data.prefs.general.soundOn`.
  - Hook calls:
    - `Engine+Session.swift` `startSession` (after `presenter.showSession`, line 29): `sessionStarted(id)`. It resets the marks and calls `tickBreath()`.
    - `finishSession` before `close(id)` (line 39): `sessionFinishing(id)`.
    - Line 61: `.meditation` → `nil`.
    - `Engine+Actions.swift:117`, `close`: `case .session: presenter.closeSession(id); sessionClosed(id)`.
    - `Engine+SessionPause`: pause and resume hooks.
    - `Engine+Loop.swift`: `tick()` calls `tickBreath()` after `endIfExpired`; `upcomingDeadlines()` appends `breathDeadlines`.
    - Restore of a running session calls `audio.startMusic` (music on, sound on).
- New `Tests/SathiTestSupport/SpySessionAudio.swift`: `@MainActor` final class with `enum Call: Equatable` mirroring the port and `private(set) var calls`. `EngineHarness` adds `package let audio: SpySessionAudio` and passes it.

## Task 6: SPM resources and locator

Tests first:
- `Tests/SathiUITests/SathiResourcesTests.swift`, suite "Sathi resources":
  - `SathiResources.url("OFL", ext: "txt", in: .fonts)` is not nil (proves the SPM wiring under `swift test`).
  - `SathiResources.url("does-not-exist", ext: "mp3", in: .audio)` is nil and does not crash.

Code:
- `Package.swift:12`: `.target(name: "SathiUI", dependencies: ["SathiCore"], path: "Sources/SathiUI", resources: [.copy("Resources/Fonts"), .copy("Resources/Audio")])`.
- Add `Sources/SathiUI/Resources/Fonts/OFL.txt` (SIL OFL 1.1 text with the Figtree copyright line).
- Add `Sources/SathiUI/Resources/Audio/AUDIO.txt`. It lists the expected optional files, so the folder exists in git: `breath-music.mp3`, `voice-begin.mp3`, `voice-inhale.mp3`, `voice-hold.mp3`, `voice-exhale.mp3`, `voice-rest.mp3`, `voice-wellDone.mp3`, `breath-bell.mp3`, `breath-tick.mp3`.
- New `Sources/SathiUI/Platform/SathiResources.swift`: `enum ResourceFolder: String { case fonts = "Fonts", audio = "Audio" }` and `static func url(_ name: String, ext: String, in folder: ResourceFolder) -> URL?` (search order in Decision 12; the bundle name comes from a constant in this file).
- `build.sh`, after line 22: `RES="$(swift build -c release --show-bin-path)/Sathi_SathiUI.bundle"; cp -R "$RES/Fonts" "$RES/Audio" "$APP/Contents/Resources/"`. `scripts/make-dmg.sh` calls `build.sh`, so no change there.
- Manual check: `./build.sh`, then `ls build/Sathi.app/Contents/Resources/Fonts`, then `codesign --verify --deep build/Sathi.app`.

## Task 7: Platform audio

Tests first (`Tests/SathiUITests/VoicePickerTests.swift`, suite "Voice picker"; pure, uses a `VoiceInfo` value struct):
- A Premium en-US female "Ava" beats an Enhanced "Zoe", which beats the default "Samantha".
- A non-English voice is never picked.
- An empty list → nil (the synthesizer then uses the system default).
- Preferred names `["Ava", "Zoe"]` come from `AudioFiles.preferredVoices`.

`Tests/SathiUITests/AudioFilesTests.swift`:
- `AudioFiles.voice(.wellDone) == "voice-wellDone"`.
- The music name is `"breath-music"`.

Code:
- `Sources/SathiUI/Platform/AudioFiles.swift`: file names and `preferredVoices`.
- `Sources/SathiUI/Platform/VoicePicker.swift`: `struct VoiceInfo { id, name, language, quality: Int, isFemale }` and `static func best(_:) -> VoiceInfo?`. Plus a mapper from `AVSpeechSynthesisVoice`.
  - Voice preference (user ruling after a 4-voice demo): English only, then the identifier `com.apple.ttsbundle.gryphon-neural_Simone_en-US_premium` (`AudioFiles.preferredVoiceIDs`), then a voice named or identified "Simone", then "Martha" (`AudioFiles.preferredVoiceMarks`, matched on the name or as a substring of the identifier, because installed voices may show as "Voice 1"/"Voice 2"), then quality, then the preferred names Ava and Zoe, then female.
- `Sources/SathiUI/Platform/BreathAudioPlayer.swift`: `@MainActor final class BreathAudioPlayer: SessionAudio`, AVFoundation, < 200 lines. If it grows, split out `BreathVoice.swift` (clips plus speech queue).
  - Music: created lazily in `startMusic`. `numberOfLoops = -1`, volume 0, `play()`, then `setVolume(v, fadeDuration: Timing.musicFadeIn)`. Reused after `pauseMusic`.
  - `pauseMusic`: `setVolume(0, fadeDuration: Timing.musicFadeOut)`, then `pause()` after the fade (one-shot `DispatchWorkItem`, cancelled by `startMusic`).
  - Voice:
    - A clip is played if `SathiResources.url` finds it; otherwise an `AVSpeechUtterance` with the `VoicePicker` voice and rate `AVSpeechUtteranceDefaultSpeechRate * Limits.speechRateRatio`.
    - Clips are queued, so a phrase never overlaps another.
    - `silenceVoice` stops the clip and calls `stopSpeaking(at: .immediate)`.
  - Bell and tick: a bundled clip if present, else a private copy of `NSSound(named:)` for `SoundName.tink` or `SoundName.pop`, with `volume` set. A copy, so the volume never leaks into the shared sound that reminders play.
  - Preview hand-off: the first `speak`, `play` or `startMusic` of a session cancels the pending Preview end and any pending release, silences the Preview voice, and fades out the Preview music unless `startMusic` takes it over (`PreviewHandoff`). `endSession` drops queued voice lines; only the current line finishes.
  - `endSession`: fades the music out, then releases the music player and voice resources after the fade and after the last utterance.
  - `preview`: plays "Breathe in" and the music for `seconds`, then calls `endSession`.
  - A missing file → nothing plays, no crash.
- `Sources/Sathi/AppEnvironment.swift:20-28`: pass `audio: BreathAudioPlayer()`.

Manual check: `./build.sh --install`, start a session with no clips present: speech plays, no music, no crash.

## Task 8: Settings "Sound" card

Tests first (`Tests/SathiUITests/MeditationSoundCardTests.swift`, suite "Meditation sound card"):
- The card shows "Voice guide", "Music", "Soft bell at start and end", "Soft tick every minute" and "Preview".
- Each switch flips its pref.
- Setting a slider value (`find(ViewType.Slider.self)`) changes `voiceVolume` or `musicVolume`.
- A slider is hidden when its switch is off.
- Preview tap → `h.audio.calls.last == .preview(…)`.
- Preview is disabled when `general.soundOn == false`.
- Changed requirement: `MeditationSettingsFixTests.swift:16` and `MeditationSettingsTabTests.swift:86` look for the chime switch under its new label, in the Sound card.

Code:
- New `Sources/SathiUI/Components/VolumeSlider.swift`: `Slider(value:in: Limits.sessionVolume)`, `.tint(accent)`, width `UIMetrics.volumeSliderWidth` (140, in `UIMetrics+Components.swift`), accessibility label.
- New `Sources/SathiUI/Features/Meditation/MeditationSoundCard.swift`:
  - A `SettingsCard` with `SettingRow`s and `BuddySwitch(accent: Night.calm)`.
  - Hints: "Shanti says each phase once. She never counts." and "Plays softly under the voice."
  - The Preview button uses `GhostButton`.
- `MeditationSettingsTab.swift:20`: add `SettingsSection("Sound") { MeditationSoundCard() }` after "Breathing pattern".
- Remove the chime row at `MeditationGoalCard.swift:29-30`.

## Task 9: Figtree and card D

Tests first:
- `Tests/SathiUITests/BreathFontTests.swift`: `BreathFont.font(.light, size: 34)` returns a font in both states; `BreathFont.isRegistered == (fonts found)`. Never crashes without the files.
- `Tests/SathiUITests/BreathMotionTests.swift` replaces the `BreathCircle` cases in `LoopAnimationTests.swift:60-75`:
  - `openness` is 0 at the start of an inhale, 0.5 mid-inhale, and 1 during hold.
  - `scale(open: 0, .orb) == 0.72`.
  - Reduce motion → open is 0.85.
  - Ripples: 3 during an inhale at +2.5 s, none during an exhale.
  - The mood blend reaches the new phase colour after `UIMetrics.breathMoodBlend`.
- `Tests/SathiUITests/BreatheViewTests.swift`, rewritten (changed requirement: time left replaces rounds):
  - Start calm 5 min → "CALM · 4 6", "4 · IN", "Breathe in", "5:00 left", "Pause", "Stop"; no "Round".
  - +5 s → "Breathe out", "5 · OUT", "4:55 left".
  - Paused, then +60 s → still "4:55 left" and the button reads "Resume". Tap → `engine.session(.meditation)?.isPaused == false`.
  - Stop → no event.
  - `find(BreathOrb.self)` is present.

Code:
- Fonts:
  - Add `Sources/SathiUI/Resources/Fonts/Figtree-Variable.ttf` (Google Fonts) and `OFL.txt` (Decision 13). If the file is missing, the fallback path covers it.
  - `Sources/SathiUI/Theme/BreathFont.swift`: `enum BreathFace { case light, regular, medium, semibold }` with a `Font.Weight` for each, a `static let isRegistered` (lazy `CTFontManagerRegisterFontsForURL` of `Figtree-Variable.ttf`), and `static func font(_:size:) -> Font` (`.custom("Figtree", size:).weight(face.weight)`, falls back to `.system(size:weight:design: .rounded)`).
- `Sources/SathiUI/Theme/NightPalette.swift`: add `enum NightHex` with `calm 0xA99CF5`, `water 0x4CC3F5`, `cheek 0xFF9FB8`, `spark 0xFFC94A`, `calmGround 0x16142A`, `text 0xEEF2FA`, `muted 0x9AA6BF`, `sprout 0x5FD39A`, `border 0x263049`. The matching `Night` tokens use them. New `Sources/SathiUI/Theme/RGB.swift`: `struct RGB { init(hex:), mix(_:_:), color(opacity:) }`.
- New `Sources/SathiUI/Constants/UIMetrics+Breath.swift`, with the values from the prototype:
  - Stage and ring: stage 236; ring radius 114, width 1, track opacity 0.8; tick marks 5, from 110 to 117; dot radius 2.5; stage margins 14 and 10.
  - Core: 104.
  - Blobs: 150, blur 12, drift 8, radius swing 0.12, spin 8°/s, frequency 0.18 + 0.07·j, phase step 2.1, scale step 0.06.
  - Scales: orb 0.72…1, core 0.82…1, face 0.84…1.05; face size 76.
  - Ripples: 3, gap 1.1 s, span 3.8 s, from 70·scale to 108, width 5, blur 1.5, peak opacity 0.32.
  - Colour: mood blend 1.4 s; reduce-motion openness 0.85 and frame interval 0.25.
  - Fonts and tracking: eyebrow 11 / 2.2, count 12 / 2.4, phase 34 / 0.68, left 13 / 0.78, button 13.
  - Buttons: height 30, padding 14, gap 18; separator 1×14.
  - Card padding: top 26, bottom 22.
  - Mix amounts:
    - Inhale: calm→water 0.45, accent water.
    - Hold: calm→cheek 0.30, accent cheek→spark 0.35.
    - Exhale: calm→ground 0.22, accent calm.
    - Rest: calm→ground 0.50, accent muted→ground 0.3.
    - Core light 0.4, ripple light 0.2, phase text tint 0.25, ring light 0.4.
  - Drop `fontBreathPhase` (24) and the old `breath*` values in `UIMetrics+Meditation.swift:15-27` once unused.
- New `Sources/SathiUI/Features/Meditation/BreathMotion.swift` (pure): `openness`, `scale(open:range:)`, `blob(index:t:open:) -> BlobState` (dx, dy, rotation, scale, 4 radii), `ripples(sinceInhale:) -> [Double]`, `progress(session:at:)`.
- New `Sources/SathiUI/Features/Meditation/BreathMood.swift` (pure): `main` and `accent` per `BreathPhase`, and `blended(phase:previous:since:)`.
- New `Sources/SathiUI/Features/Meditation/BlobShape.swift`: a `Shape` with 4 radii, cubic arcs (k = 0.5523).
- New `Sources/SathiUI/Features/Meditation/BreathOrb.swift`: 3 blobs (`RadialGradient` from 0.85 opacity to 0 at 72%, `.blendMode(.screen)`, `.blur`), the core, ripples, and `StaticBuddy(habit: .meditation, size: UIMetrics.breathFaceSize)` scaled. Wrap it in `.drawingGroup()`.
- New `Sources/SathiUI/Features/Meditation/BreathRing.swift`: track, progress arc from −90°, 5 ticks, and the dot.
- `Sources/SathiUI/Features/Meditation/BreatheView.swift`, rewritten:
  - One `TimelineView(.animation(minimumInterval: reduceMotion ? UIMetrics.breathReducedInterval : UIMetrics.animationFrameInterval, paused: !isVisible || s.isPaused))`.
  - Order: eyebrow (muted, semibold), stage (ring + orb), count line, phase word (light, tinted), "m:ss left", then "Pause | Stop" as plain text buttons with a hairline separator.
  - All text uses `BreathFont`. Wrap in `.modifier(CalmCard())`.
  - `onAppear`/`onDisappear` toggle `isVisible`.
  - All values come from `s.elapsed(at: tl.date)` and `s.left(at: tl.date)`; nothing reads `e.now`.
- Delete `BreathCircle.swift`, `Copywriter.breathHeader` and `breathRound`, and `BreathingPattern.totalRounds` and `round`, with `BreathingRoundsTests.swift` and the `BreathCopyTests` cases for them (Decision 15).

Check: `/perf-check`. Open a session: CPU must stay modest (target < 8% with the card open; measure and report). Close the card: CPU must return to about 0%. Turn on Reduce Motion: the orb is still and the text still updates.

## Task 10: Days-off picker

Tests first:
- `Tests/SathiCoreTests/DayOffMonthTests.swift`, suite "Day off month". Use `FixedZone` and now = 2026-11-07 10:00.
  - Offset 0: November 2026 has 30 cells, 6 leading `nil` (Monday-first; Nov 1 is a Sunday), and `canGoBack == false`.
  - Nov 1–6 are `.unavailable`; Nov 7 is `.pickable`.
  - A day in `daysOff` is `.off`.
  - Offset 12 (Nov 2027): days after 2027-11-07 are `.unavailable`, and `canGoForward == false`.
  - 100 upcoming days off → no `.pickable` cell.
  - A DST month (March 2027 in a DST zone) has 31 unique keys.
- `Tests/SathiCoreTests/EngineDaysOffTests.swift`:
  - `addDayOff(.water, key:)` adds the day once; a second call does not change the prefs.
  - `dayOffMonth(.gym, offset: 0)` matches the HabitDays result.
- `Tests/SathiUITests/DaysOffCardTests.swift` and `DaysOffCardTapTests.swift` (changed requirement: no DatePicker, no Add):
  - Replace the expectations at `DaysOffCardTests.swift:38-39` and `DaysOffCardTapTests.swift:26,38,52` with: a "Pick a date" button, no `DatePicker`, no "Add".
- New `Tests/SathiUITests/DayOffCalendarTests.swift`, parameterized over `HabitID.allCases`:
  - Tapping the cell with accessibility label "Sat 7 Nov" adds `2026-11-07`.
  - A past cell is disabled.
  - An off cell has accessibility value "Day off" and is disabled.
  - The back arrow is disabled at offset 0.
  - The title is "November 2026".

Code:
- New `Sources/SathiCore/Habits/DayOffMonth.swift`:
  - `package enum DayOffCellState { case pickable, off, unavailable }`
  - `package struct DayOffCell: Hashable { key, day, state }`
  - `package struct DayOffMonth: Equatable { firstDay: DayKey, weeks: [[DayOffCell?]], canGoBack, canGoForward }`
  - `extension HabitDays { package func month(offset: Int, now: Date, calendar: Calendar) -> DayOffMonth }`. Use `Calendar.gregorian(in:)`, `HabitDays.dayOffRange`, `Limits.daysOffMax` and `Limits.weekStartWeekday`.
- `Sources/SathiCore/Engine/Engine+DaysOff.swift`: add `package func dayOffMonth(_ id: HabitID, offset: Int) -> DayOffMonth` and `package func addDayOff(_ id: HabitID, key: DayKey)`. The latter forwards to the existing `addDayOff` (line 18) with `key.start(in: calendar)`.
- New `Sources/SathiUI/Components/DayOffPicker.swift`: the chip "Pick a date", styled like `TimeMenu` (`TimeMenu.swift:11-27`: `Night.bg` fill, `TimeMenu.border`). It holds `@State isOpen` and `@State offset`, and shows a `.popover` with `DayOffCalendar`.
- New `Sources/SathiUI/Components/DayOffCalendar.swift`:
  - Header: `chevron.left`, the month title (static cached `DateFormatter`, template "MMMMyyyy", Gregorian in the engine time zone), `chevron.right`.
  - A weekday-initials row, then 7-column rows of day chips (size `UIMetrics.dayChipSize` 30 in `UIMetrics+Components.swift`).
  - Pickable: `Night.bg` with `fieldBorder`. Off: accent fill at `chipFillOpacity` with an accent border. Unavailable: `Night.faint`, disabled.
  - Accessibility label from `DaysOffRow.label(key)`.
  - `.background(Night.card)`, `.environment(\.colorScheme, .dark)`.
- `Sources/SathiUI/Components/DaysOffCard.swift`:
  - Replace lines 23-33 with `DayOffPicker(habit: habit, accent: accent)`.
  - Delete `picked`, `add`, `date(in:)` and the `Date.clamped` extension (lines 7, 46-53, 69-73).
  - Keep `Engine.dayOffRange` only if tests still use it.

## Task 11: Docs and final checks

- `CLAUDE.md` module map:
  - Ports: add `SessionAudio`.
  - Models: add `Session`.
  - Habits: add `DayOffMonth`, `BreathCues`.
  - SathiUI Platform: add `BreathAudioPlayer`, `VoicePicker`, `AudioFiles`, `SathiResources`.
  - Theme: add `BreathFont`, `RGB`.
  - Components: add `DayOffPicker`, `DayOffCalendar`, `VolumeSlider`.
  - Meditation: add `BreathOrb`, `BreathRing`, `BreathMotion`, `BreathMood`, `BlobShape`, `MeditationSoundCard`.
  - Add a line `Sources/SathiUI/Resources/ (Fonts: Figtree + OFL.txt; Audio: optional MP3 clips)`.
  - Intro paragraph: pause, voice, music.
- `.claude/rules/architecture.md` ports table: `SessionAudio | BreathAudioPlayer (SathiUI) | SpySessionAudio`.
- `.claude/rules/performance.md`, Timers section: "1 s only during a running session (not paused); a nearer deadline cuts it". Add "Audio players exist only during a session or a Preview".
- `.claude/rules/storage.md`, section 4: `LiveState.init(from:)` rounds `meditationSession` dates.
- `README.md`:
  - Calm 4·6 is the default, voice guide, music, pause.
  - The Sound card, the date picker.
  - Add a "Fonts" credit: Figtree, SIL Open Font License 1.1.
- `docs/ROADMAP.md`: add Phase 15 (only if the file is restored; the working tree shows it deleted).
- Run `swift build -c release` (no new warnings), `./build.sh --install`, `./scripts/perf.sh` idle, then after one session closes, then `./scripts/perf.sh --windows` (the user runs it in Terminal).

## Task 12: Website and screenshots (out of this plan)

The website text, the `WebsiteShots` screenshots (`Tests/SathiUITests/WebsiteShots.swift:95` renders `BreatheView`) and SEO are handled later by `/sathi-website`. Do not edit `site/` in this phase.

---

## Performance impact

- Engine: no new timer. Phase boundaries and minute ticks are one-shot deadlines in `upcomingDeadlines()`, so a session adds about 1 wakeup per phase on top of the existing 1 s session tick. While paused there is no 1 s tick: only the next midnight and other deadlines.
- Audio: `AVAudioPlayer`, the clip players and `AVSpeechSynthesizer` are created on the first use in a session and released after `endSession`. Nothing lives at idle. Linking AVFoundation and CoreText adds a few MB at launch; check fresh idle stays < 40 MB.
- UI: one `TimelineView` per card at ≤ 30 fps, paused on disappear and on pause; 4 fps with Reduce Motion. Blobs render in `.drawingGroup()`. Fonts are registered once. The days-off popover is static.

## Risks

1. Sessions are not saved today (`Engine.activities`, `Engine.swift:22`). Decision 2 adds `LiveState.meditationSession` and also restores a running meditation session (new behavior).
2. `performance.md` says the 1 s tick runs only during a reading session; the code uses it for any session. Task 11 corrects the rule.
3. Without the TickPlanner change, cues would arrive up to about 1.1 s late. Task 3 fixes this.
4. The word "Pause" is already used for "Take a break" (Habits rule 9). Code uses `pauseSession`, `resumeSession`, `Session.pausedAt`.
5. Changing the default pattern changes the decode fallback to `.calm`. Saved styles are kept.
6. The chime moves off `SoundPlayer` (Decision 6); two old assertions change.
7. Sound off mutes voice and music too (Decision 7).
8. A Premium voice may load tens of MB during a session. If memory after a session goes over 50 MB, prefer bundled clips.
9. A nested SPM `.bundle` without Info.plist can break `codesign --deep`. Decision 12 copies the folders instead.
10. Figtree TTFs need a download. The fallback keeps the card working.
11. `BlobShape` approximates the CSS border-radius morph. Check visually against the prototype.
12. Four pattern cards may not fit one row. Fallback: a 2×2 grid.
