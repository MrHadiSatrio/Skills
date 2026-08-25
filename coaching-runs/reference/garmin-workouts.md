# Garmin Workouts

The Garmin workout library and calendar mirror the plan. Two things
went wrong in past sessions: a frozen bpm range shipped as a target,
and stale calendar-entry ids burned seven failed calls. This file
prevents the two. All examples are synthetic.

## 1. Encoding a workout

- Name: the `[EG]` prefix, the session, and the expected distance —
  for example "[EG] Easy 60min Z2 + Strides (~8.5km)".
- Description: restate the constraints that govern the session, for
  example "End by 06:00 on school days."
- HR targets: ALWAYS a named Garmin zone (`heart.rate.zone` with
  `zoneNumber`). NEVER a frozen bpm range. Garmin re-detects LTHR and
  moves its zones with fitness; a hard-coded range goes stale the day
  that happens.
- Pace targets: only where no live zone exists — strides are the one
  case. A pace target is m/s: divide 1000 by the pace in seconds per
  km. Example: 5:00/km is 1000/300 = 3.3333 m/s. Give each static
  pace target a revisit trigger in the workout description, tied to
  the 5K race prediction.
- Pace windows for normal steps travel as description text, never as
  enforced targets. A window belongs to one start-time class, and an
  enforced pace from the wrong class misfires.

## 2. The schedule-mutation runbook

Ids go stale after any mutation. Obey the order:

1. Upload or update the workout (`upload_workout`).
2. Fetch the calendar fresh (`get_scheduled_workouts`). Never reuse
   ids from an earlier fetch.
3. Schedule the new dates (`schedule_workout`).
4. Unschedule replaced entries with the ids from step 2
   (`unschedule_workout`).
5. Delete the old parent workout (`delete_workout`) — this sweeps
   orphan calendar entries.
6. Fetch the calendar once more and make sure that the result matches
   the plan.

A 404 in step 4 means the id went stale, not that Garmin is
unreachable — the MCP error text says otherwise and is wrong. Go back
to step 2. Deleted entries can linger as ghosts in listings until
Garmin re-indexes; note them and move on.

## 3. Replaced runs

When the athlete and the coach agree on a substitute session, update
the calendar in the same turn: schedule the replacement and
unschedule the old entry. The record must show a replaced run, not a
missed run. The workout template stays in the library.
