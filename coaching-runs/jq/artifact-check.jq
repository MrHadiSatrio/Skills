# artifact-check.jq — find cadence-locked HR spans in FIT records.
# The optical HR sensor can lock onto the step cadence: HR then tracks
# the cadence in steps per minute while power stays easy. The input is
# a get_activity_fit_data result with include_records=true — the raw
# object, or the {result: "<json>"} wrapper from a tool-results file.
# Records arrive at roughly one per second, so record counts read as
# seconds.

def payload:
  if type == "object" and has("records") then .
  elif type == "object" and has("result") then
    (.result | if type == "string" then fromjson else . end)
  else . end;

payload
| [ .records[]? | select(.heart_rate_bpm != null and .cadence_rpm != null) ] as $r
| ([ $r[].power_w | select(. != null) ] | sort) as $p
| (if ($p | length) > 0 then $p[(($p | length) / 2) | floor] else 0 end) as $median
| (reduce $r[] as $rec ({spans: [], cur: null};
     (($rec.heart_rate_bpm >= 120)
      and ((($rec.heart_rate_bpm - $rec.cadence_rpm * 2) | fabs) <= 4)) as $locked
     | if $locked then
         .cur = (if .cur != null then
                   {start: .cur.start, end: $rec.timestamp, n: (.cur.n + 1),
                    hr: (.cur.hr + $rec.heart_rate_bpm),
                    spm: (.cur.spm + $rec.cadence_rpm * 2),
                    pw: (.cur.pw + ($rec.power_w // 0))}
                 else
                   {start: $rec.timestamp, end: $rec.timestamp, n: 1,
                    hr: $rec.heart_rate_bpm,
                    spm: ($rec.cadence_rpm * 2),
                    pw: ($rec.power_w // 0)}
                 end)
       else
         (if .cur != null and .cur.n >= 10 then .spans += [.cur] else . end)
         | .cur = null
       end)
   | (if .cur != null and .cur.n >= 10 then .spans += [.cur] else . end)
   | .spans) as $spans
| if ($spans | length) == 0 then
    "no cadence-locked spans of 10 records or more; the device Z4/Z5 seconds look genuine"
  else
    ( $spans[]
      | "LOCKED \(.start) .. \(.end) (\(.n) records): avg HR \((.hr / .n) | round), avg cadence \((.spm / .n) | round)spm, avg power \((.pw / .n) | round)W (activity median \($median)W)" ),
    "verdict: HR tracks cadence in the spans above; discount device Z4/Z5 seconds inside them when their power sits at or below the activity median"
  end
