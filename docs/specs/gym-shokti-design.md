# Gym (Shokti): design

Status: draft for review. Date: 2026-10-26.
Demo: `.superpowers/brainstorm/33898-1793029157/content/gym-demo-v2.html` (approved look).

Marks used in this file:
- **(user)**: the user said it.
- **(call)**: my call. The user can change it.

## Why

The user works 9 to 5 at a desk and sits for many hours without a break **(user)**. They want a buddy that suggests a short movement while they work, for a healthy body **(user)**. It is a soft suggestion. It must not force them, and it is not a "go to the gym" alarm **(user)**.

## Goals

1. During work hours, every 1 hour, suggest 1 short workout: a stretch, a short walk, or a simple gym exercise **(user)**.
2. The user keeps their own list of 4 workouts and can change them **(user)**.
3. A calm corner popup, the same look as Boi (reading) **(user approved demo)**.
4. A short timer while the user moves. "Done" saves the workout to stats **(user approved demo)**.

## Non-goals

- No gym plan, sets, reps, or weights.
- No sync with Apple Health or other apps.
- No check if the user is away from the Mac (idle, camera, meetings). The roadmap has "Stay quiet in meetings" for later.
- No more or fewer than 4 workouts. The list is fixed at 4 rows **(user: "4 workout reminders")**.

## Anti-goals (a failure even if it works)

- The reminder takes focus from the active app or locks the screen.
- The copy makes the user feel guilty.
- The buddy breaks the performance budget in `CLAUDE.md` (idle CPU, wakeups, memory).

## The habit

| Item | Value |
|---|---|
| `HabitID` case and raw value | `.gym`, `"gym"` **(call)** |
| `name` | "Gym" **(user)** |
| `buddy` | "Shokti" (শক্তি, strength) **(user)** |
| Popup label | `SHOKTI · GYM` (the user wrote "Shokti x Gym"; I read it as this label) **(call, confirm)** |
| Accent color | `#CDEF5A` lime **(user)**. Hero fill `#222A16`, hero border `#46561F` **(call)** |
| Buddy drawing | A new `BuddyKind`. A small round kettlebell with a face, in the Night buddy style **(call)** |
| Default | Off. An update never starts a reminder the user did not ask for (Decision 2026-10-24) |
| Settings sidebar | Shows a "New" label, like Meditation did |

This is kind C in the `/add-habit` skill: an interval inside active hours, with a timed session. Model: Meditation.

## Schedule

| Setting | Default | Choices |
|---|---|---|
| Remind me every | 60 min **(user)** | 45, 60, 90 min **(call)** |
| Work hours | 9:00 AM to 5:00 PM **(user)** | 15-minute steps, like other habits |
| Work days | Mon to Fri **(call)** | Any of the 7 days. The last day cannot be turned off (same as Reading rule 8) |

1. The first reminder of a work day comes 1 interval after the start of work hours: 10:00 with the defaults **(user: "after 1 hour")**.
2. After "Done", the next reminder comes 1 interval after the done time (Schedules rule 1).
3. No reminder outside work hours or on a day that is off. The next due time is the next work-day start plus 1 interval.
4. "Not now" **(user)**: a close (✕), or no answer for the General ignore time, skips this reminder. The next reminder comes 1 interval after that moment. It writes a `.snooze` event, so the report counts it, and it does not raise the strictness level **(call)**. It never resets the streak (this is not the `.skip` of Escalation rule 3). This is a new rule in `business-logic.md`.
4a. The **In {n} min** button is a normal snooze. It uses the General snooze length and counts toward Nudgy, like every other reminder.
5. A settings change that moves the due time follows Schedules rules 5 and 11.

## The 4 workouts

Each row has a name and minutes **(user approved demo)**.

| # | Default name | Default minutes |
|---|---|---|
| 1 | Neck and shoulder stretch | 5 |
| 2 | Short walk | 5 |
| 3 | 10 squats | 3 |
| 4 | Wall push-ups | 3 |

1. The user edits the name in a text field in the Settings tab. Max length: 40 characters **(call)**. An empty name saves as the default name of that row **(call)**.
2. Minutes: a choice of 1, 2, 3, 5, 10 **(call)**.
3. Order: Shokti uses the workouts in order 1 → 2 → 3 → 4 → 1 **(user approved demo)**.
4. How the order works **(call)**: the workout of a reminder = (count of `.gym` done events today) mod 4. Each work day starts at workout 1. No new saved field is needed for the order.
5. "Next idea" in the popup shows the next workout in the list. Each tap moves 1 more (3, 4, 1, ...). It is only for this popup. It saves nothing, writes no event, and does not restart the ignore timer **(call)**.
6. **Start** runs the workout that the popup shows. The Engine carries that workout (index, name, minutes) in the in-memory `Session` only **(call)**.
7. After a done workout that came from "Next idea", the next reminder follows rule 4 (the done count). It can show that same workout again. This is accepted, because it needs no saved field **(call)**.

## Reminder (corner popup)

Same frame as `ReadingInvite` (corner, never takes focus).

- Label `SHOKTI · GYM`, title (for example "Time to stretch, Mridul?"), hint "{workout name} · {n} min".
- Buttons: **Start** (accent), **Next idea**, **{snooze label}** (for example "In 15 min").
- A close button at Gentle means "Not now" (Schedule rule 4): the next reminder comes 1 interval later.
- Strictness: Gentle (default) and Nudgy only. Gym never locks the screen. A stored Strict acts as Nudgy (`withoutLock`). Nudgy follows Escalation rule 2: one ping, then a silent wiggle.
- After a snooze, the note "Shokti comes back at {time}" shows, like Boi.

## Session (timer)

- **Start** opens a corner timer card, like `ReadingTimerPill`: label `SHOKTI · {workout name}`, 1 general kind line from the Copywriter (no tip for each workout, so no new saved field) **(call)**, a countdown of the workout minutes, a progress bar, **Done** and **Stop** **(user approved demo)**.
- When the countdown ends, it counts as done.
- **Done** before the end also counts as done, with the full workout minutes **(call: the user walks away from the Mac and may not come back at the exact second)**.
- **Stop** does not count (Schedules rule 6).
- Done writes `HistoryEvent.done(.gym, 1, at: now)` and shows a small thank-you card in the corner.

## Goal, stats, and streak

- Daily goal: 4 workouts a day **(user)**. Reminders continue every interval after the goal is met. Gym does not join Schedules rule 3 **(user)**.
- Event `amount` = 1 for each done workout, so the daily total counts workouts **(call: follows the goal unit)**.
- The goal is fixed at 4. No goal row in the Settings tab **(call: matches the approved layout)**.
- Reports tile unit: "workouts". The streak and calendar shades use the goal of 4.
- Reports: one tile for Gym, a chart of workouts, the streak calendar, like the other habits.
- Menu bar: a `HabitCard` for Gym with the next reminder time.

## Settings tab

Copy the layout of the approved demo:

1. Hero card: buddy, `SHOKTI · GYM`, "Get up, little and often", on/off switch.
2. RHYTHM card: Remind me every, Work hours, Work days.
3. MY 4 WORKOUTS card: 4 rows with a number, a name field, and a minutes choice.
4. IF I IGNORE SHOKTI: Gentle and Nudgy cards only.

## Add a buddy tab

The "Stretch" and "Walk" Soon cards are now inside Gym. Remove them. Keep "Eye break" and "Posture" in 1 row **(call)**.

## Storage

- New `Prefs.gym` (`GymPrefs`). An old `prefs.json` without `gym` decodes to the defaults. Follow the `/data-migration` skill, recipe "Add a field".
- New raw value `"gym"` in history files. An older Sathi version keeps these events and does not show them (History rule 8).
- No new `LiveState` field.

## Rules file

Before code, add Gym to `.claude/rules/business-logic.md`: Words (Shokti), Schedules table, Escalation rule 1 (Gym never locks), and a calm rule like Escalation rule 5.

## Left to the builder

- File split and names, inside the `/add-habit` steps and the 200-line limit.
- Copy lines for titles, nudges, and thank-you cards, in a kind tone with no guilt.
- The menu bar icon when Gym is the focus.
- The exact kettlebell drawing, checked later with the `ui-verifier` agent.

## Done when

The "Definition of done" in `CLAUDE.md`, plus the website and README name Shokti (`/sathi-website`).
