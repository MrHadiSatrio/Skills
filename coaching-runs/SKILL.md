---
name: coaching-runs
description: Coaching workflows for a planned run day — pre-run consults, post-run analysis, plan updates, and Garmin workout management for Hadi's training. Use when a session plans, analyzes, or adjusts a run training day.
---

# Coaching Runs

The workspace is the coach's memory, and Garmin is the system of
record for measurements. The `coach` CLI owns everything
deterministic — day names, rollups, ratios, and the plan-file writes —
so the session spends its judgment on the run, the body, and the
athlete's questions, never on arithmetic a script does better.

## 1. Locate and run the CLI

The skill root is the directory that contains this SKILL.md. In
Claude Code that is `~/.config/claude/skills/coaching-runs`. Invoke
the CLI as:

```sh
sh <skill-root>/bin/coach <command>
```

Run it from the workspace directory — the directory that holds
`plan.json` (for Hadi: `~/Projects/RunCoaching`). The commands:
`status [date]`, `verify`, `close-day [--amend] <date>`,
`stops <file> [threshold]`, `artifact-check <file>`. If no workspace
is present (for example on a deployed runtime with no filesystem
state), say so and give advice only — never guess state. If the CLI
itself fails, obey the manual fallback recipe in
`reference/plan-contract.md`.

## 2. Precedence

For a run-coaching workspace, this skill wins over
`endurance-coaching`. Do not probe `~/.claude-coach` or any Strava
tooling — that stack is not in use here.

## 3. Session start

1. Run `coach status` from the workspace. It gives the day name, the
   prescription, the week state, the next long run's spike ratio, the
   carries, and the open rulings.
2. Set the session name to `W#D# Planning & Analysis`, with the W#D#
   that `status` printed. A session that does meta work instead of day
   work stays outside this scheme.
3. Read `profile.md` — equipment, time windows, sport history, fuel
   products, decision style. Advice that contradicts the profile is
   wrong before it leaves the session.

## 4. The two entry modes

**Pre-run consult** — the athlete asks what to do with the day:

1. Pull the pre-run battery (`reference/garmin-battery.md`).
2. Do a freshness check of the wellness data. Name every gap.
3. Answer in the pre-run options shape
   (`reference/report-formats.md`), with the three votes named.
4. If the plan changes, update `plan.json` and the Garmin calendar in
   the same turn (`reference/garmin-workouts.md`).

**Post-run analysis** — the athlete finished the day's run:

1. Pull the post-run battery in one ToolSearch round
   (`reference/garmin-battery.md`). Expect unplanned activities next
   to the planned run.
2. Run `coach stops` on the typed splits. When a reading looks wrong,
   pull the FIT records and run `coach artifact-check`.
3. Interrogate the athlete: one batched AskUserQuestion after all
   data is in (`reference/report-formats.md`). Open rulings the day
   touched become questions.
4. Write the journal entry from `reference/journal-template.md`.
   State the live carries again.
5. Run `coach close-day <date>`, then `coach verify`. Fix every FAIL
   line before the session ends.
6. Report in the debrief shape (`reference/report-formats.md`),
   verdict first.

## 5. Write-back discipline

The journal holds the narratives. `rules.md` holds the rules with
lifecycle stamps (MODEL, PROVISIONAL, ADOPTED, VALIDATED, RULED —
each with a date). `rulings.md` holds the open questions and the
settled ones. `plan.json` holds prescriptions, guardrail numbers, and
the execution index that only the CLI writes. The full contract, the
carry rule, and the moved-day rule live in
`reference/plan-contract.md`.

## 6. Epistemics

- Check every claim about training history or load against a Garmin
  pull in the same turn, and cite the pull.
- When the athlete says "Recheck", expect to be wrong — past rechecks
  had a hit rate of one for one.
- Ask, do not assume. A guessed fact in the journal costs a
  correction later.
- New rules are PROVISIONAL until the athlete signs off. Questions
  the session cannot settle go into `rulings.md` under Open, and the
  report names them.

## 7. What NOT to Do

- Do not probe `~/.claude-coach` or start a Strava flow. That stack
  is not in use. If the athlete asks for Strava, treat it as a new
  requirement and say the skill does not cover it yet.
- DO NOT ENCODE FROZEN BPM RANGES IN GARMIN WORKOUT TARGETS. Use
  named zones. Exception: strides get a static pace target, because
  no live pace zone exists — give it a revisit trigger
  (`reference/garmin-workouts.md`).
- Do not edit the CLI-owned fields of `plan.json` by hand. Exceptions:
  the CLI fails, or a repair is beyond `--amend`. In each case obey
  the manual fallback recipe in `reference/plan-contract.md`.
- Do not leave a replaced run on the Garmin calendar as a missed run.
  Obey the schedule-mutation runbook in
  `reference/garmin-workouts.md`.
- Do not render HTML, unless the athlete asks for it. The workspace
  keeps JSON and markdown only.
- Do not put analysis prose, real activity ids, or physiology into
  this skill's files. The bundle is public; the workspace is private.
