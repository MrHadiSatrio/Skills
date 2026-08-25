#!/bin/sh
# Blackbox tests for the coach CLI. Each test runs against a fresh copy
# of the fixture workspace inside a temporary directory.

set -u

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
COACH=$ROOT/../bin/coach
TMP=$(mktemp -d) || exit 1
trap 'rm -rf "$TMP"' EXIT INT TERM

passes=0
failures=0
out=''

ok() { passes=$((passes + 1)); }
ko() { failures=$((failures + 1)); echo "FAIL: $1"; }

fresh() {
  rm -rf "$TMP/ws"
  cp -R "$ROOT/fixtures/workspace" "$TMP/ws"
}

# run_coach <expected-exit> [args...]; the output lands in $out.
run_coach() {
  rc_want=$1; shift
  out=$(cd "$TMP/ws" && sh "$COACH" "$@" 2>&1)
  rc_got=$?
  [ "$rc_got" -eq "$rc_want" ]
}

# check <name> <expected-exit> <grep-pattern> [args...]
check() {
  c_name=$1; c_want=$2; c_pat=$3; shift 3
  if run_coach "$c_want" "$@" && echo "$out" | grep -q -- "$c_pat"; then
    ok
  else
    ko "$c_name"
  fi
}

# --- status ---------------------------------------------------------------

fresh
check 'status names the day by week number and day position' \
  0 'Day: W2D2' status 2030-01-16

fresh
check 'status shows the day.s prescription' \
  0 'Prescription: Easy 7km Z2' status 2030-01-16

fresh
check 'status lists the open rulings' \
  0 'Open rulings: 2' status 2030-01-16

fresh
check 'status prints the carry items of the newest journal entry' \
  0 'gate Thursday on feel' status 2030-01-16

fresh
check 'status reports the spike ratio of the next long run' \
  0 'spike ratio 1.04' status 2030-01-16

fresh
jq '(.weeks[2].days[2].workouts[0].distanceKm) = 20' \
  "$TMP/ws/plan.json" > "$TMP/ws/plan.json.new" && mv "$TMP/ws/plan.json.new" "$TMP/ws/plan.json"
check 'status flags a next long run that breaks the spike rule' \
  0 'BREAKS THE SPIKE RULE' status 2030-01-16

fresh
jq 'del(.weeks[2].days[2])' \
  "$TMP/ws/plan.json" > "$TMP/ws/plan.json.new" && mv "$TMP/ws/plan.json.new" "$TMP/ws/plan.json"
check 'status says so when no long run remains on the plan' \
  0 'No long run remains on the plan' status 2030-01-16

fresh
jq '(.weeks[2].days[1].date) = "2030-01-15" | (.weeks[2].days[1].dayOfWeek) = "Wednesday"' \
  "$TMP/ws/plan.json" > "$TMP/ws/plan.json.new" && mv "$TMP/ws/plan.json.new" "$TMP/ws/plan.json"
check 'status names a moved day by its date, not its workout id' \
  0 'Day: W2D2' status 2030-01-15

fresh
check 'status reports the next planned day on a rest day' \
  0 'Next: W2D2 on 2030-01-16' status 2030-01-15

fresh
mkdir -p "$TMP/bin"
# shellcheck disable=SC2016 # the stub must expand at run time, not here
printf '%s\n' '#!/bin/sh' \
  'if [ "${1:-}" = "+%Y-%m-%d" ]; then echo 2030-01-16; else exec /bin/date "$@"; fi' \
  > "$TMP/bin/date"
chmod +x "$TMP/bin/date"
out=$(cd "$TMP/ws" && PATH="$TMP/bin:$PATH" sh "$COACH" status 2>&1)
rc_got=$?
if [ "$rc_got" -eq 0 ] && echo "$out" | grep -q 'Day: W2D2'; then
  ok
else
  ko 'status names the day from the caller.s local date'
fi

fresh
rm "$TMP/ws/plan.json"
check 'status refuses to run outside a coaching workspace' \
  2 'not a coaching workspace' status 2030-01-16

# --- summary --------------------------------------------------------------

echo "passed: $passes, failed: $failures"
[ "$failures" -eq 0 ]
