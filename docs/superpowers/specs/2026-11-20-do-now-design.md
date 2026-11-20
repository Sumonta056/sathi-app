# Do now: start a buddy session at once

Date: 2026-11-20. Size: small change.

## Intent

The user wants to start a buddy session the moment they choose ("I want to meditate now", "I go to the gym now"). One tap starts it. The finished session must show on the Activities page like any other activity.

The menu bar used to have "Read now", "Breathe" and "Move" buttons. Commit `65c09ba` (short quick panel) removed them. Today only the Dashboard Meditation card keeps "Breathe now".

## Goals

1. A "Do now" button for Boi, Shanti and Shokti in 2 places:
   - the menu bar quick panel buddy rows (`QuickBuddyRow`),
   - the Dashboard Day buddy cards (`TodayBuddyCard`).
2. Every finished buddy session shows as 1 activity on the Activities page, in the Calendar page Actual column, and in activity reports. This is true when the activity tracker is off and outside tracker hours too.

## Non-goals

- No macOS calendar event for buddy sessions (same as today).
- No change to how reminders schedule the next popup after a manual start.
- No change to Fota: it keeps "+1 glass".

## Anti-goals

- 2 activities for 1 session (one from the live tracker, one from the new rule).
- The tracker turns on, or tracker prompts appear, because of a "Do now" tap.

## Approaches

- A. Buttons only. Smallest, but a session does not become an activity when the tracker is off (the default). Rejected: fails goal 2.
- **B. Buttons, plus a finished session always logs an activity. Picked by the user.**
- C. "Do now" turns the tracker on for that session. Rejected: mixes 2 features and surprises the user.

## Design (B)

### Buttons

- Labels: Boi "Read now", Shanti "Breathe", Shokti "Move". The labels live in `Copywriter`.
- The button calls the existing `Engine.startReading()`, `startMeditation()` or `startSession(.gym)`. The menu bar panel closes first.
- The button shows when the buddy is on and has no running session. It also shows after the goal is met and on a day off (the user can always do extra).
- On the Dashboard, the Shanti "Breathe now" link becomes the same button as the other buddies.

### Activity log rule

- Tracker on and inside tracker hours: no change. `trackerSessionStarted` starts a live buddy activity and `trackerSessionEnded` ends it.
- Otherwise: `finishSession` writes 1 finished activity of kind `.buddy`. Its start is the session start. Its end is the finish time. Its text and category are the same as the live buddy activity (`Copywriter.trackerBuddyText`, `ActivityCategory.buddy`). The buddy category gets added if it is missing.
- A stopped (cancelled) session writes nothing on this path.
- Guard against duplicates: write the finished activity only when no live buddy activity for this buddy was running.

### Rules file

Add the log rule to `.claude/rules/business-logic.md` before the code changes.

## Calls left to the builder

- Exact file split under the 200-line limit.
- Where the "write a finished activity" helper lives (`Engine+TrackerSessions` or a new `Engine+SessionLog`).
- Button size and style follow `GhostButton` and the current row and card metrics.

## Tests

- Engine: tracker off, start and finish a gym session → 1 `.buddy` activity with real start and end.
- Engine: tracker on inside hours → still exactly 1 activity.
- Engine: tracker off, stop a session → no activity.
- UI: quick panel row and Dashboard card show the button, hide it while a session runs, and tapping it starts the session.
