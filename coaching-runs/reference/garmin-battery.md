# The Garmin Battery

Garmin is the system of record for measurements. Pull from it; never
assert a number about training history without a pull in the same
turn. The Garmin MCP tools are deferred, thus their schemas load
through ToolSearch. Load each mode's full set in ONE ToolSearch round
— past sessions lost turns to piecemeal loads.

## 1. Pre-run consult

Load and pull:

- `get_scheduled_workouts` — the Garmin calendar around the target day.
- `get_training_readiness` — the composite and its component factors.
- `get_sleep_summary` — the night before.
- `get_hrv_data` — the overnight HRV against its baseline band.

Read the component factors, not only the composite. A night with no
sleep record zeroes the sleep factor and drags the composite down with
no real fatigue behind it.

## 2. Post-run analysis

Load the full set in one round, then pull in parallel:

The run itself:

- `get_activities_fordate` — find the day's activities. Expect
  unplanned extras next to the planned run.
- `get_activity`, `get_activity_splits`, `get_activity_typed_splits`,
  `get_activity_hr_in_timezones`, `get_activity_weather`,
  `get_training_effect`.
- `get_activity_gear` and `get_gear` (with stats) — the shoe odometer
  lives here, not in the workspace.

The morning context, for today and the day before:

- `get_sleep_summary` (two days), `get_hrv_data`, `get_rhr_day`,
  `get_training_readiness`, `get_training_status`,
  `get_training_load_balance`, `get_body_battery`,
  `get_stress_summary` (two days), `get_race_predictions`.

The deep dive, when perception and output disagree or a reading looks
wrong:

- `get_activity_fit_data` with `include_records=true` — per-second HR,
  cadence, and power. Feed the saved result to
  `coach artifact-check`.
- `get_rhr_day` over three dates for a baseline,
  `get_respiration_summary`, `get_lactate_threshold`.

## 3. Freshness

Before advice, make sure that the wellness data for the target dates
exists. If sleep or readiness is absent, say so, ask for a watch sync,
and give advice with that gap named. Do not fill the gap with a guess.

## 4. Large results and the two analyses

The harness saves a large MCP result to a tool-results file and gives
its path. Such a file wraps the payload as `{"result": "<json>"}` —
the CLI's analyses unwrap that form by themselves.

- Stop map: pass the `get_activity_typed_splits` result file to
  `coach stops <file> [threshold-seconds]`.
- HR artifact: pass the `get_activity_fit_data` result file to
  `coach artifact-check <file>`.

If a result was small and stayed inline, save it to the scratchpad
with Write first, then pass that file. To orient inside a saved file,
query its keys first: `jq -r '.result | fromjson | keys' <file>`.

## 5. Known traps

- `get_endurance_score` can fail server-side. Report the error in the
  "records and gaps" section and move on. Do not retry more than once.
- A 404 from `unschedule_workout` means a stale calendar-entry id, not
  a connection failure. The runbook in `reference/garmin-workouts.md`
  covers it.
- `request_reload` covers wellness data only. It does not refresh the
  workout calendar.
