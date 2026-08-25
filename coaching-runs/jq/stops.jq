# stops.jq — the stop map from a get_activity_typed_splits result.
# Argument: $threshold (seconds, number). The input can be the raw
# result object, or the {result: "<json>"} wrapper that the harness
# saves to a tool-results file.

def payload:
  if type == "object" and has("splits") then .
  elif type == "object" and has("result") then
    (.result | if type == "string" then fromjson else . end)
  else . end;

payload
| [ .splits[]?
    | select(.type == "RWD_STAND" or .type == "RWD_WALK")
    | select((.elapsedDuration // 0) >= $threshold) ] as $stops
| ( $stops[]
    | "\(.startTimeLocal // "?")  \(.type | sub("RWD_"; "") | ascii_downcase)  \(.elapsedDuration | round)s\(if .distance then "  \(.distance | round)m" else "" end)" ),
  "total: \($stops | length) segments of \($threshold)s or more, \(($stops | map(.elapsedDuration) | add // 0) | round)s not in motion"
