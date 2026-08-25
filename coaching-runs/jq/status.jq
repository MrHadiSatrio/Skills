# status.jq — the session-start briefing over plan.json.
# Arguments: $today (YYYY-MM-DD, from the caller's local clock),
# $journal (array of journal front-matter objects, each with a file key),
# $rulings (array of open-ruling titles).
# All date math here works on dates parsed from files, never on the clock.

def round2: (. * 100 | round) / 100;

def epoch: strptime("%Y-%m-%d") | mktime;

def day_hits:
  [ .weeks[] as $w
    | ($w.days | to_entries[]) as $e
    | {week: $w, index: $e.key, day: $e.value} ];

def day_name: "W\(.week.weekNumber)D\(.index + 1)";

def run_of: [.workouts[]? | select(.sport == "run")] | first;

def completed_run: any(.workouts[]?; .sport == "run" and .completed == true);

. as $plan
| ($plan.guardrails.spikeRatioMax // 1.10) as $spikemax
| (day_hits) as $hits
| ([$hits[] | select(.day.date == $today)] | first) as $hit
| ([$hits[] | select(.day.date > $today)] | sort_by(.day.date) | first) as $next
| ([ $hits[]
    | select(.day.date >= $today and (.day | completed_run | not))
    | select((.day | run_of) != null and (.day | run_of | .type == "long"))
    | {date: .day.date, km: (.day | run_of | .distanceKm)} ]
   | sort_by(.date) | first) as $longrun
| ($journal | sort_by(.date // "") | last) as $newest
| [
    (if $hit then
       "Day: \($hit | day_name) (\($hit.day.dayOfWeek // "?") \($today))",
       (($hit.day | run_of) as $r
        | if $r then "Prescription: \($r.name) — \($r.description // "")"
          else "Prescription: no run workout on this day" end),
       "Week \($hit.week.weekNumber)\(if $hit.week.cycleWeek then " (cycle \($hit.week.cycleWeek))" else "" end): target \($hit.week.targetKm // "?")km, actual \($hit.week.summary.actualKm // 0)km over \($hit.week.summary.actualSessions // 0) sessions"
     elif $next then
       "No planned day on \($today). Next: \($next | day_name) on \($next.day.date) — \(($next.day | run_of).name // "?")"
     else
       "No planned day on \($today), and none remain on the plan."
     end),
    (if $longrun then
       ([ $journal[]
          | select(.date != null and .date < $longrun.date)
          | select((($longrun.date | epoch) - (.date | epoch)) <= (30 * 86400))
          | (.distanceKm // "0") | tonumber ]
        | (max // 0)) as $longest
       | if $longest > 0 then
           (($longrun.km / $longest) | round2) as $ratio
           | "Next long run: \($longrun.km)km on \($longrun.date); spike ratio \($ratio) (max \($spikemax))\(if $ratio > $spikemax then " — BREAKS THE SPIKE RULE" else "" end)"
         else
           "Next long run: \($longrun.km)km on \($longrun.date); no journal record in the prior 30 days, so the spike ratio has no base"
         end
     else
       "No long run remains on the plan."
     end),
    (if $newest and (($newest.carry // []) | length) > 0 then
       "Carries (from \($newest.date // $newest.file)):",
       (($newest.carry)[] | "  - \(.)")
     else
       "Carries: none"
     end),
    "Open rulings: \($rulings | length)",
    ($rulings[] | "  - \(.)")
  ]
| .[]
