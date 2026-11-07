# Sathi

Sathi is a macOS menu bar companion. Buddies remind the user about habits, and the user can track where their time goes.

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
