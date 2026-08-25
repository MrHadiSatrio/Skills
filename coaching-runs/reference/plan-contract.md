# The Plan Contract

The workspace is the coach's memory. Every fact that must survive a
session lives in one of the files below, in the form this contract
gives. All examples in this file are synthetic.

## 1. Layout

```
<workspace>/
  plan.json      # prescriptions and the execution index
  journal/       # one markdown file per run day
  rules.md       # the rule register, prose
  rulings.md     # open questions for the athlete, plus dated rulings
  profile.md     # equipment, time windows, sport history, fuel, decision style
```

## 2. plan.json

The top-level keys: `version`, `meta`, `preferences`, `zones`,
`guardrails`, `phases`, `evergreenCycle`, `raceBridge`, `weeks`.
A plan without races can omit `phases` and `raceBridge`.

`weeks[]` entries carry `weekNumber`, `cycleWeek`, `startDate`,
`endDate`, `targetKm`, `days[]`, and `summary`. Each day carries
`date`, `dayOfWeek`, an optional `journal` path, and `workouts[]`.
Each workout carries `id`, `sport`, `type`, `name`, `description`,
`distanceKm`, `primaryZone`, and `completed`. The `description` holds
the prescription only. Analysis prose belongs in the journal, never in
`plan.json`.

The CLI owns these fields, and no session edits them by hand: each
day's `completed` flags and `journal` path, each week's
`summary.actualKm` and `summary.actualSessions`, and `meta.updatedAt`.
Exception: the manual fallback recipe in section 8.

`guardrails` holds the numbers that `coach verify` reads, for example
`spikeRatioMax` and `longRunTimeCapHours`. `rules.md` carries the same
rules as prose. If the two diverge, `plan.json` wins.

## 3. The journal

One file per run day: `journal/` plus the date, a dash, and the day
name in lowercase — for example journal/2030-01-16-w2d2.md. The file
opens with a front matter block:

```
---
date: 2030-01-16
day: W2D2
workout: w2-thu
activity: 10000009
distanceKm: 7.31
durationMin: 47.5
backfilled: false
carry:
  - "Note: legs heavy; gate Saturday on feel"
---
```

The parser is `awk`, thus the format stays flat:

- One `key: value` per line. A value can contain a colon. A value must
  not contain a tab.
- One level of dash lists. Quote each list item.
- `date`, `day`, and `distanceKm` are required. `activity` is required,
  unless `backfilled: true` marks an entry rebuilt from a week-level
  note.

The body carries the narrative under fixed headings: Verdict,
Structure, Zones, Drift and weather, Body and perception, Other
activities, Rulings raised. The front matter describes the planned run
only. An unplanned activity on the same day (a swim, a walk) goes
under "Other activities" and never into `plan.json` weeks.

## 4. Carries

A carry is a concern that must reach the next session. `coach status`
prints the carry items of the newest journal entry only. Thus each new
entry must state again every carry that stays live. A carry that is
not stated again dies. This keeps the list self-cleaning.

## 5. Day names and moved days

D# is the position of the day inside its week's `days` array, plus
one. It is not a weekday code. Workout ids are weekday-coded (for
example `w2-thu`), so an id keeps its old weekday when a day moves.
The CLI therefore matches days by `date`, never by workout id. When a
day moves, change its `date` and `dayOfWeek`, and keep the id.

## 6. Rules and rulings

`rules.md` holds one entry per rule, with a lifecycle stamp and a
date. The lifecycle: MODEL (a hypothesis under test), PROVISIONAL
(proposed, awaits the athlete's sign-off), ADOPTED (signed off),
VALIDATED (held up against a later run), RULED (settled by the
athlete). A stamp never disappears — append the new stamp with its
date.

`rulings.md` has two sections. `## Open` lists questions that wait for
the athlete, one `### ` heading per question. `## Ruled` lists settled
questions, each heading prefixed `RULED <date>:`. `coach status`
counts and prints the open headings. When the athlete rules, move the
entry from Open to Ruled, add the date, and apply the ruling to
`rules.md` or `plan.json` in the same session.

## 7. Day close

After the post-run analysis:

1. Write the journal entry from the template
   (`reference/journal-template.md`). State the live carries again.
2. Run `coach close-day <date>`. The command flags the day complete,
   links the journal file, recomputes the week totals, bumps
   `meta.updatedAt`, validates, and only then replaces `plan.json`.
3. Run `coach verify`. Fix every FAIL line before the session ends.
4. If a closed day later proves wrong, correct the journal entry and
   run `coach close-day --amend <date>`.

## 8. Manual fallback recipe

Use this recipe only when the CLI fails, or when a repair is beyond
`--amend`. Do the whole list, in order:

1. Set the day's run workout `completed` to `true` and its day
   `journal` path, with one `jq` filter that writes to a new file —
   never edit `plan.json` in place.
2. Recompute the week's `summary.actualKm` and
   `summary.actualSessions` from the journal front matter of that
   week's completed days.
3. Set `meta.updatedAt` to the current UTC time.
4. Validate with `jq -e '.weeks and .meta.updatedAt' <new-file>`, then
   move the new file over `plan.json`.
5. Run `coach verify` if the CLI works at all, and fix every finding.
