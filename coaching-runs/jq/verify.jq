# verify.jq — workspace invariant checks over plan.json.
# Prints one FAIL line per finding, and nothing when the workspace is
# consistent. Arguments: $journal (array of journal front-matter
# objects, each with a file key).

def epoch: strptime("%Y-%m-%d") | mktime;
def completed_run: any(.workouts[]?; .sport == "run" and .completed == true);
def run_of: [.workouts[]? | select(.sport == "run")] | first;
def numkm: (.distanceKm // "x") | tonumber?;

. as $plan
| ($plan.guardrails.spikeRatioMax // 1.10) as $spikemax
| [
    ($journal[]
     | select(.date == null)
     | "FAIL: \(.file): front matter does not parse (no date)"),

    ($journal[]
     | select(.date != null)
     | . as $e
     | ( (if $e.day == null then "day" else empty end),
         (if ($e | numkm) == null then "distanceKm" else empty end),
         (if $e.activity == null and $e.backfilled != "true" then "activity" else empty end) )
     | "FAIL: \($e.file): front matter lacks \(.)"),

    ($journal[]
     | select(.date != null)
     | select((.file | split("/") | last | .[:10]) != .date)
     | "FAIL: \(.file): the date \(.date) disagrees with the filename"),

    ($journal | map(select(.date != null)) | group_by(.date)[]
     | select(length > 1)
     | "FAIL: two journal files for \(.[0].date): \(map(.file) | join(", "))"),

    ($plan.weeks[] | .days[]? | select(completed_run)
     | select(.date as $d | ($journal | any(.date == $d)) | not)
     | "FAIL: \(.date) is marked complete but has no journal file"),

    ($journal[] | select(.date != null)
     | select(.date as $d
              | ((first($plan.weeks[] | .days[]? | select(.date == $d))
                  | completed_run) // false) | not)
     | "FAIL: \(.file): the day is not marked complete in plan.json"),

    ($plan.weeks[]
     | . as $w
     | ([ $w.days[]? | select(completed_run) | .date ]) as $dates
     | ([ $journal[] | select(.date as $d | $dates | index($d)) | numkm // 0 ]
        | add // 0) as $sum
     | ( (if ((($w.summary.actualKm // 0) - $sum) | fabs) > 0.05 then
            "FAIL: week \($w.weekNumber): actualKm \($w.summary.actualKm // 0) disagrees with the journal sum \((($sum * 100 | round) / 100))"
          else empty end),
         (if ($w.summary.actualSessions // 0) != ($dates | length) then
            "FAIL: week \($w.weekNumber): actualSessions \($w.summary.actualSessions // 0) disagrees with \($dates | length) completed days"
          else empty end) )),

    ( ([ $plan.weeks[] | .days[]?
         | select(completed_run | not)
         | . as $d | (run_of // empty) | select(.type == "long")
         | {date: $d.date, km: .distanceKm} ]
       | sort_by(.date) | first) as $lr
      | if $lr then
          ([ $journal[]
             | select(.date != null and .date < $lr.date)
             | select((($lr.date | epoch) - (.date | epoch)) <= 30 * 86400)
             | numkm // 0 ]
           | max // 0) as $longest
          | if $longest > 0 and ($lr.km / $longest) > $spikemax then
              "FAIL: the long run on \($lr.date) (\($lr.km)km) breaks the spike rule: \(((($lr.km / $longest) * 100 | round) / 100)) > \($spikemax)"
            else empty end
        else empty end )
  ]
| .[]
