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

# write_journal <path> <date> <day> <workout> <km>
write_journal() {
  cat > "$1" <<EOF
---
date: $2
day: $3
workout: $4
activity: 10000009
distanceKm: $5
durationMin: 45.0
backfilled: false
---

# $3

Synthetic entry written by a test.
EOF
}

# --- verify ---------------------------------------------------------------

fresh
check 'verify accepts a consistent workspace' 0 'OK' verify

fresh
check 'verify accepts week 0 with its partial days' 0 'OK' verify

fresh
check 'verify tolerates a colon inside a front matter value' 0 'OK' verify

fresh
check 'verify tolerates a backfilled entry without an activity id' 0 'OK' verify

fresh
rm "$TMP/ws/journal/2030-01-07-w1d1.md"
check 'verify reports a completed day without a journal file' \
  1 'marked complete but has no journal file' verify

fresh
write_journal "$TMP/ws/journal/2030-01-16-w2d2.md" 2030-01-16 W2D2 w2-thu 7.3
check 'verify reports a journal file without a completed day' \
  1 'not marked complete in plan.json' verify

fresh
cp "$TMP/ws/journal/2030-01-14-w2d1.md" "$TMP/ws/journal/2030-01-14-w2d1b.md"
check 'verify reports two journal files for one date' \
  1 'two journal files for 2030-01-14' verify

fresh
sed 's/^date: 2030-01-14$/date: 2030-01-15/' \
  "$TMP/ws/journal/2030-01-14-w2d1.md" > "$TMP/ws/journal/2030-01-14-w2d1.md.new"
mv "$TMP/ws/journal/2030-01-14-w2d1.md.new" "$TMP/ws/journal/2030-01-14-w2d1.md"
check 'verify reports a journal date that disagrees with its filename' \
  1 'disagrees with the filename' verify

fresh
printf '%s\n' '# W2D2' 'No front matter here.' \
  > "$TMP/ws/journal/2030-01-14-w2d1.md"
check 'verify reports front matter that awk cannot parse' \
  1 'front matter does not parse' verify

fresh
jq '(.weeks[2].summary.actualKm) = 99' \
  "$TMP/ws/plan.json" > "$TMP/ws/plan.json.new" && mv "$TMP/ws/plan.json.new" "$TMP/ws/plan.json"
check 'verify reports a week total that disagrees with its journal records' \
  1 'disagrees with the journal sum' verify

fresh
jq '(.weeks[2].days[2].workouts[0].distanceKm) = 20' \
  "$TMP/ws/plan.json" > "$TMP/ws/plan.json.new" && mv "$TMP/ws/plan.json.new" "$TMP/ws/plan.json"
check 'verify reports a next long run that breaks the spike rule' \
  1 'breaks the spike rule' verify

# --- summary --------------------------------------------------------------

echo "passed: $passes, failed: $failures"
[ "$failures" -eq 0 ]
