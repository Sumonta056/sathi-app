# Sathi

Sathi is a macOS menu bar companion. Buddies remind the user about habits, and the user can track where their time goes.

## App

**Main window**:
The one window of Sathi, with a sidebar. It holds Today, Activities, Reports, and Settings. Sathi shows in the Dock while it is open.
_Avoid_: Dashboard, app view, Settings window, Reports window

**Quick panel**:
The small panel that opens from the menu bar icon. It shows the status of the buddies and the running activity, and it opens the main window.
_Avoid_: Menu, popover, dropdown

**Range**:
The span of days that Reports and Activities show: Day, Week, or Month. Each range compares with the range before it.
_Avoid_: Period, window, timeframe

## Time tracking

**Time block**:
A period of work that the user starts and ends by hand, with a title. When it ends, it becomes one event in the user's calendar.
_Avoid_: Session (meditation uses it), task, focus, timer

**Planned length**:
A length that the user picks at Start, for example 30 minutes. When the planned length passes, the time block ends by itself.
_Avoid_: Duration preset, timer, countdown

**Open time block**:
A time block with no planned length. It runs until the user taps End.
_Avoid_: Unlimited block, free block

**Block widget**:
The small pill in the screen corner that shows a running time block, when the user picks it over the menu bar alone.
_Avoid_: Timer window, overlay, HUD

**Target calendar**:
The calendar in the macOS Calendar app that receives the event for a finished time block.
_Avoid_: Account, destination

**Daily activity tracker**:
The feature that asks the user at set times what they are doing now, keeps the answers for the day, and shows them in a report. It is separate from time blocks.
_Avoid_: Time tracker, timesheet, journal, check-in (the time block uses it)

**Activity**:
One thing that the user did, with a short text, an optional category, a start, and an end. Only one activity runs at a time. A new activity ends the one before it.
_Avoid_: Task, entry, event, time block

**Expected length**:
The time that the user thinks an activity will take. When it passes, Sathi asks if the user is still on it. The activity does not end by itself.
_Avoid_: Planned length (a time block ends at it), duration, estimate

**Away**:
Time when the Mac is locked, asleep, closed, or idle for the idle limit. Away ends the running activity. When the user comes back, Sathi asks where they were. The user can name it or ignore the question.
_Avoid_: Break (Take a break pauses reminders), idle, gap

**Not logged**:
Time that has no activity and is not Away, for example when the user says they stopped earlier than the prompt.
_Avoid_: Unknown, empty, gap

**Switch time**:
The moment the user moved from one activity to the next. The user picks it after Done, when Sathi learned about the change late. It ends the old activity and starts the new one.
_Avoid_: Start override, backdate, correction

**Activity prompt**:
The one popup at the screen center that asks "What are you doing now?". Its top line tells the reason: time to ask, shortcut, activity ends, back from Away, or a calendar event starts. It stays on screen until the user answers, taps Keep going, or taps Skip.
_Avoid_: Check-in, nudge, reminder, bubble, corner prompt, center prompt, Still on it popup

**Reason**:
Why the activity prompt shows: time to ask, shortcut, activity ends, back from Away, or a calendar event. It sets the prompt's color, tag, and buttons.
_Avoid_: kind, type, mode

## Breathing

**Breathing session**:
A timed meditation session in which Shanti guides the user's breath. It counts toward the meditation goal only when it runs to its end.
_Avoid_: Meditation timer, exercise, round

**Breathing pattern**:
A named rhythm of phases with fixed seconds, for example Box 4·4·4·4.
_Avoid_: Style, mode, technique

**Phase**:
One part of a breathing pattern: breathe in, hold, breathe out, or rest.
_Avoid_: Step, stage

**Time left**:
The minutes and seconds that remain until the breathing session ends. It replaces the round count on the session card.
_Avoid_: Countdown, round, timer

**Pause**:
A break inside a breathing session. Time left and the phase stop until the user taps Resume, and the session then continues from the same point.
_Avoid_: Stop, snooze, break, Take a break (that pauses reminders, not a session)

**Voice guide**:
A calm spoken voice that says the name of each phase as it starts, so that the user can breathe with eyes closed.
_Avoid_: Narrator, coach, TTS

**Background music**:
A quiet music loop that plays during a breathing session.
_Avoid_: Soundtrack, ambient, chime

**Minute tick**:
A very soft sound at each full minute of a breathing session.
_Avoid_: chime, bell

## Gym

**Gym goal**:
The minutes of movement that the user wants on each gym day, for example 20 minutes. When today's minutes meet it, Shokti is quiet until the next gym day.
_Avoid_: Workout count, target, daily workouts

**Session length**:
The minutes of one gym session, for example 5 minutes. Every workout idea uses the same session length.
_Avoid_: Workout minutes, duration

**Session count**:
The number of gym popups in one day: the gym goal divided by the session length. Shokti spreads them evenly over work hours.
_Avoid_: Reminder count, slots

**Workout idea**:
A name on the user's gym list, for example "10 squats". Shokti suggests one workout idea in each popup. It has no length of its own.
_Avoid_: Workout, exercise, task
