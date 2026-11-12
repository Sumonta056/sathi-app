# The daily activity tracker replaces time blocks

Status: accepted, 2026-11-09

Time blocks (v3.0) and the daily activity tracker both record "what I worked on, from when to when" and can write it to a calendar. Two trackers that do not know about each other give two half-complete pictures of one day. We will keep the tracker as the only work log in the long term.

We build the tracker as a separate feature first and keep time blocks unchanged, so the user has a working tool while the tracker is new. While a time block runs, the tracker does not ask, and its log shows the block as a read-only activity. A later phase removes time blocks after the user has used the tracker for about two weeks. We did not merge the two in one phase, because that change is large, and a time block's planned length ends the block, but an activity's expected length only asks.

## Consequences

- Until removal, the tracker reads running and finished time blocks to fill its log.
- Saved time block data must move into the activity log, or stay readable, when time blocks go away (see `.claude/rules/storage.md`).
