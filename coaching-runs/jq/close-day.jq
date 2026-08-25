# close-day.jq — mark one day complete and recompute its week.
# Arguments: $date (YYYY-MM-DD), $path (the journal file for that day),
# $now (ISO timestamp), $journal (array of journal front-matter objects,
# the new file included).

def completed_run: any(.workouts[]?; .sport == "run" and .completed == true);

.weeks |= map(
  if any(.days[]?; .date == $date) then
    (.days |= map(
       if .date == $date then
         .journal = $path
         | (.workouts |= map(if .sport == "run" then .completed = true else . end))
       else . end))
    | . as $w
    | ([ $w.days[]? | select(completed_run) | .date ]) as $dates
    | .summary = {
        actualKm: ((([ $dates[] as $d
                       | (first($journal[] | select(.date == $d)) // null)
                       | if . == null then 0
                         else ((.distanceKm // "0") | tonumber) end ]
                     | add // 0) * 100 | round) / 100),
        actualSessions: ($dates | length)
      }
  else . end)
| .meta.updatedAt = $now
