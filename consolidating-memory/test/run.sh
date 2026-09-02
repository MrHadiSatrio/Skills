#!/bin/sh
# Blackbox tests for the archivist CLI. Each test runs against fresh
# copies of the fixtures inside a temporary directory, with the Claude
# Code configuration directory pointed at that temporary directory, so
# no test reads or writes the real memory or the real transcripts.

set -u

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
ARCHIVIST=$ROOT/../bin/archivist
TEMPORARY=$(mktemp -d) || exit 1
trap 'rm -rf "$TEMPORARY"' EXIT INT TERM

passes=0
failures=0
output=''
tab=$(printf '\t')
SECONDS_PER_DAY=86400

pass() { passes=$((passes + 1)); }
fail() { failures=$((failures + 1)); echo "FAIL: $1"; }

# Reset the temporary configuration directory, the working directory,
# the memory directory, and the transcripts directory from the fixtures.
fresh() {
  rm -rf "$TEMPORARY/configuration" "$TEMPORARY/workspace" "$TEMPORARY/memory" "$TEMPORARY/transcripts"
  mkdir -p "$TEMPORARY/configuration" "$TEMPORARY/workspace"
  cp -R "$ROOT/fixtures/memory" "$TEMPORARY/memory"
  cp -R "$ROOT/fixtures/transcripts" "$TEMPORARY/transcripts"
}

# run_archivist <expected-exit> [args...]; the output lands in $output.
# The two override variables come from $MEMORY and $TRANSCRIPTS, which
# a test may clear to exercise the lookup through settings.json.
MEMORY=''
TRANSCRIPTS=''
run_archivist() {
  expected_exit=$1; shift
  output=$(cd "$TEMPORARY/workspace" && \
        CLAUDE_CONFIG_DIR="$TEMPORARY/configuration" \
        ARCHIVIST_MEMORY_DIRECTORY="$MEMORY" \
        ARCHIVIST_TRANSCRIPTS_DIRECTORY="$TRANSCRIPTS" \
        sh "$ARCHIVIST" "$@" 2>&1)
  actual_exit=$?
  [ "$actual_exit" -eq "$expected_exit" ]
}

# expect <behavior> <expected-exit> <pattern> [args...]
expect() {
  behavior=$1; exit_wanted=$2; pattern=$3; shift 3
  if run_archivist "$exit_wanted" "$@" && echo "$output" | grep -q -- "$pattern"; then
    pass
  else
    fail "$behavior"
  fi
}

# expect_absent <behavior> <expected-exit> <pattern> [args...]
expect_absent() {
  behavior=$1; exit_wanted=$2; pattern=$3; shift 3
  if run_archivist "$exit_wanted" "$@" && ! echo "$output" | grep -q -- "$pattern"; then
    pass
  else
    fail "$behavior"
  fi
}

# --- dispatch -------------------------------------------------------------

fresh
expect 'archivist prints its usage when no command is given' \
  2 'usage: archivist'

fresh
expect 'archivist refuses an unknown command' \
  2 "There is no command named 'dream'." dream

# --- locate ---------------------------------------------------------------

fresh
MEMORY=$TEMPORARY/memory; TRANSCRIPTS=$TEMPORARY/transcripts
expect 'locate honors the memory override' \
  0 "^memory: $TEMPORARY/memory\$" locate

fresh
MEMORY=$TEMPORARY/memory; TRANSCRIPTS=$TEMPORARY/transcripts
expect 'locate honors the transcripts override' \
  0 "^transcripts: $TEMPORARY/transcripts\$" locate

fresh
# shellcheck disable=SC2088 # the unexpanded tilde is the point of the test
MEMORY='~/somewhere/memory'; TRANSCRIPTS=''
expect 'locate expands a leading tilde in the override' \
  0 "^memory: $HOME/somewhere/memory\$" locate

fresh
MEMORY=''; TRANSCRIPTS=''
printf '{"autoMemoryDirectory": "~/elsewhere/memory"}\n' > "$TEMPORARY/configuration/settings.json"
expect 'locate reads autoMemoryDirectory from settings.json' \
  0 "^memory: $HOME/elsewhere/memory\$" locate

fresh
MEMORY=''; TRANSCRIPTS=''
printf '{"model": "x"}\n' > "$TEMPORARY/configuration/settings.json"
project_name=$(printf '%s' "$TEMPORARY/workspace" | sed 's/[^A-Za-z0-9]/-/g')
expect 'locate falls back to the per-project default of Claude Code' \
  0 "^memory: $TEMPORARY/configuration/projects/$project_name/memory\$" locate

fresh
MEMORY=''; TRANSCRIPTS=''
expect 'locate places the transcripts under the configuration directory' \
  0 "^transcripts: $TEMPORARY/configuration/projects\$" locate

# --- signals --------------------------------------------------------------

# write_transcript <path> <age-in-seconds> <text>: one utterance, dated
# relative to now, so that a test of the default window cannot age out.
write_transcript() {
  jq -n -c --arg age "$2" --arg text "$3" \
    '{type: "user", timestamp: ((now - ($age | tonumber)) | todate),
      cwd: "/Users/jordan/now", sessionId: "dddddddd-0000-4000-8000-000000000004",
      message: {role: "user", content: $text}}' > "$1"
}

fresh
MEMORY=''; TRANSCRIPTS=$TEMPORARY/transcripts
expect 'signals prints an utterance with its time, project, and session' \
  0 "^2030-01-05T09:00:00Z${tab}app${tab}aaaaaaaa${tab}No, actually use spaces" \
  signals --since 2030-01-01

fresh
expect 'signals prints the text blocks of an array-shaped utterance' \
  0 'Also, from now on run prettier' signals --since 2030-01-01

fresh
expect_absent 'signals drops tool results' \
  0 'always use yarn' signals --since 2030-01-01

fresh
expect_absent 'signals drops meta lines' \
  0 'local-command-caveat' signals --since 2030-01-01

fresh
expect_absent 'signals drops task notifications' \
  0 'I prefer tabs' signals --since 2030-01-01

fresh
expect_absent 'signals drops slash-command echoes' \
  0 '/clear' signals --since 2030-01-01

fresh
expect_absent 'signals drops interruption markers' \
  0 'Request interrupted' signals --since 2030-01-01

fresh
expect_absent 'signals drops compaction summaries' \
  0 'I prefer yarn' signals --since 2030-01-01

fresh
expect_absent 'signals drops sidechain lines' \
  0 'yarn lockfile' signals --since 2030-01-01

fresh
expect_absent 'signals drops the words of the assistant' \
  0 'two spaces from now on' signals --since 2030-01-01

fresh
expect 'signals folds a newline inside an utterance into a pilcrow' \
  0 'My name is Jordan, not Alex. ¶ Not sure where Alex came from.' \
  signals --since 2030-01-01

fresh
expect_absent 'signals drops a blank utterance' \
  0 "aaaaaaaa${tab}\$" signals --since 2030-01-01

fresh
expect_absent 'signals drops an utterance older than --since' \
  0 'Old news' signals --since 2030-01-01

fresh
expect 'signals keeps an utterance inside a wider --since' \
  0 'Old news' signals --since 2029-12-01

fresh
expect 'signals accepts a full timestamp for --since' \
  0 'run prettier' signals --since 2030-01-05T09:06:30Z

fresh
expect_absent 'signals applies a full timestamp for --since to the minute' \
  0 'actually use spaces' signals --since 2030-01-05T09:06:30Z

fresh
if run_archivist 0 signals --since 2030-01-01 \
   && echo "$output" | sed -n 1p | grep -q "^2030-01-04T18:00:00Z${tab}site${tab}bbbbbbbb"; then
  pass
else
  fail 'signals sorts the utterances of every session by time'
fi

fresh
mkdir -p "$TEMPORARY/transcripts/-Users-jordan-old"
printf '%s\n' '{"type":"user","timestamp":"2030-01-05T12:00:00.000Z","cwd":"/Users/jordan/old","sessionId":"cccccccc-0000-4000-8000-000000000003","message":{"role":"user","content":"Ancient words."}}' \
  > "$TEMPORARY/transcripts/-Users-jordan-old/cccccccc-0000-4000-8000-000000000003.jsonl"
touch -t 202001010000 "$TEMPORARY/transcripts/-Users-jordan-old/cccccccc-0000-4000-8000-000000000003.jsonl"
expect_absent 'signals skips a transcript file older than the window' \
  0 'Ancient words' signals --since 2030-01-01

fresh
mkdir -p "$TEMPORARY/transcripts/-Users-jordan-now"
write_transcript "$TEMPORARY/transcripts/-Users-jordan-now/dddddddd-0000-4000-8000-000000000004.jsonl" \
  0 'Fresh words.'
expect 'signals defaults to the last seven days' 0 'Fresh words' signals

fresh
mkdir -p "$TEMPORARY/transcripts/-Users-jordan-now"
write_transcript "$TEMPORARY/transcripts/-Users-jordan-now/dddddddd-0000-4000-8000-000000000004.jsonl" \
  $((30 * SECONDS_PER_DAY)) 'Stale words.'
expect_absent 'signals leaves out an utterance older than seven days by default' \
  0 'Stale words' signals

fresh
mkdir -p "$TEMPORARY/transcripts/-Users-jordan-now"
write_transcript "$TEMPORARY/transcripts/-Users-jordan-now/dddddddd-0000-4000-8000-000000000004.jsonl" \
  $((30 * SECONDS_PER_DAY)) 'Stale words.'
expect 'signals widens the window with --days' 0 'Stale words' signals --days 45

fresh
expect 'signals refuses a --days that is not a number' \
  2 'The window must be a whole number of days' signals --days soon

fresh
expect 'signals refuses a --days of zero' \
  2 'The window must be at least one day' signals --days 0

fresh
expect 'signals refuses a --since that is not a date' \
  2 'The start of the window must be a date or a timestamp' signals --since yesterday

fresh
expect 'signals refuses an unknown option' \
  2 'usage: archivist signals' signals --window 7

fresh
TRANSCRIPTS=$TEMPORARY/nowhere
expect 'signals refuses to run without a transcripts directory' \
  2 'No transcripts directory exists' signals

fresh
mkdir -p "$TEMPORARY/empty"
TRANSCRIPTS=$TEMPORARY/empty
expect 'signals says so when the directory holds no transcript' \
  2 'No transcript sits under' signals

# --- check ----------------------------------------------------------------

# write_memory <path> <name> <type>
write_memory() {
  cat > "$1" <<EOF
---
name: $2
description: A synthetic memory written by a test
metadata:
  type: $3
---

Synthetic content.
EOF
}

# The fixture index holds four pointer lines. Headings are permitted
# lines, so they pad the index past a limit without another defect.
FIXTURE_INDEX_LINES=4
INDEX_LINE_LIMIT=200
INDEX_BYTE_LIMIT=25600

fresh
MEMORY=$TEMPORARY/memory; TRANSCRIPTS=''
expect 'check accepts a consistent memory directory' 0 '^OK$' check

fresh
rm "$TEMPORARY/memory/widget-api-migration.md"
expect 'check reports an index line that points at a missing file' \
  1 'MEMORY.md line 3 points at widget-api-migration.md, which does not exist.' check

fresh
write_memory "$TEMPORARY/memory/stray-fact.md" stray-fact project
expect 'check reports a memory file without an index line' \
  1 'stray-fact.md has no line in MEMORY.md.' check

fresh
echo 'Jordan likes dark themes.' >> "$TEMPORARY/memory/MEMORY.md"
expect 'check reports memory content written into the index' \
  1 'MEMORY.md line 5 is not a pointer line: "Jordan likes dark themes."' check

fresh
{ echo '# Memory'; echo; cat "$TEMPORARY/memory/MEMORY.md"; } > "$TEMPORARY/memory/MEMORY.md.new"
mv "$TEMPORARY/memory/MEMORY.md.new" "$TEMPORARY/memory/MEMORY.md"
expect 'check permits headings and blank lines in the index' 0 '^OK$' check

fresh
first_line=$(sed -n 1p "$TEMPORARY/memory/MEMORY.md")
echo "$first_line" >> "$TEMPORARY/memory/MEMORY.md"
expect 'check reports a file that the index points at twice' \
  1 'MEMORY.md line 5 points at jordan-editor-preferences.md twice.' check

fresh
echo 'Jordan said this last week.' >> "$TEMPORARY/memory/jordan-editor-preferences.md"
expect 'check reports a relative date in a memory file' \
  1 'jordan-editor-preferences.md line 11 has a relative date: "Jordan said this last week."' check

fresh
echo 'On 2030-01-05 Jordan said: do it tomorrow.' >> "$TEMPORARY/memory/jordan-editor-preferences.md"
expect 'check permits a relative word next to an absolute date' 0 '^OK$' check

fresh
sed 's/on 2030-01-12;/yesterday;/' "$TEMPORARY/memory/MEMORY.md" > "$TEMPORARY/memory/MEMORY.md.new"
mv "$TEMPORARY/memory/MEMORY.md.new" "$TEMPORARY/memory/MEMORY.md"
expect 'check reports a relative date in an index hook' \
  1 'MEMORY.md line 3 has a relative date' check

fresh
sed 's/^name: jordan-editor-preferences$/name: editor-preferences/' \
  "$TEMPORARY/memory/jordan-editor-preferences.md" > "$TEMPORARY/memory/jordan-editor-preferences.md.new"
mv "$TEMPORARY/memory/jordan-editor-preferences.md.new" "$TEMPORARY/memory/jordan-editor-preferences.md"
expect 'check reports a name that disagrees with the filename' \
  1 'jordan-editor-preferences.md declares name "editor-preferences", not its own filename.' check

fresh
sed '/^description:/d' "$TEMPORARY/memory/neverthrow-documentation.md" > "$TEMPORARY/memory/neverthrow-documentation.md.new"
mv "$TEMPORARY/memory/neverthrow-documentation.md.new" "$TEMPORARY/memory/neverthrow-documentation.md"
expect 'check reports a missing description' \
  1 'neverthrow-documentation.md declares no description.' check

fresh
sed 's/^  type: user$/  type: note/' \
  "$TEMPORARY/memory/jordan-editor-preferences.md" > "$TEMPORARY/memory/jordan-editor-preferences.md.new"
mv "$TEMPORARY/memory/jordan-editor-preferences.md.new" "$TEMPORARY/memory/jordan-editor-preferences.md"
expect 'check reports a type outside user, feedback, project, and reference' \
  1 'jordan-editor-preferences.md declares type "note", not one of user, feedback, project, reference.' check

fresh
printf '%s\n' 'Jordan likes dark themes.' > "$TEMPORARY/memory/jordan-editor-preferences.md"
expect 'check reports a file without a frontmatter block' \
  1 'jordan-editor-preferences.md does not open with a frontmatter block.' check

fresh
printf '%s\n' '---' 'name: jordan-editor-preferences' 'Jordan likes dark themes.' \
  > "$TEMPORARY/memory/jordan-editor-preferences.md"
expect 'check reports an unclosed frontmatter block' \
  1 'jordan-editor-preferences.md has no complete frontmatter block.' check

fresh
echo 'See [[jordan-testing-habits]].' >> "$TEMPORARY/memory/jordan-editor-preferences.md"
if run_archivist 0 check \
   && echo "$output" | grep -q 'WARN: jordan-editor-preferences.md links to \[\[jordan-testing-habits\]\], which has no file yet.' \
   && echo "$output" | grep -q '^OK$'; then
  pass
else
  fail 'check warns about a link without a file, and still accepts the directory'
fi

fresh
headings_written=0
while [ "$headings_written" -lt $((INDEX_LINE_LIMIT + 1 - FIXTURE_INDEX_LINES)) ]; do
  echo '#'
  headings_written=$((headings_written + 1))
done >> "$TEMPORARY/memory/MEMORY.md"
expect 'check reports an index over 200 lines' \
  1 "MEMORY.md has $((INDEX_LINE_LIMIT + 1)) lines; Claude loads the first $INDEX_LINE_LIMIT only." check

fresh
{
  printf '# '
  bytes_written=0
  while [ "$bytes_written" -le "$INDEX_BYTE_LIMIT" ]; do
    printf 'xxxxxxxxxx'
    bytes_written=$((bytes_written + 10))
  done
  echo
} >> "$TEMPORARY/memory/MEMORY.md"
expect 'check reports an index over 25600 bytes' \
  1 "bytes; Claude loads the first $INDEX_BYTE_LIMIT only." check

fresh
rm "$TEMPORARY/memory/MEMORY.md"
expect 'check reports a missing index' 1 'MEMORY.md is missing.' check

fresh
expect 'check refuses extra arguments' 2 'usage: archivist check' check --memory somewhere

fresh
MEMORY=$TEMPORARY/nowhere
expect 'check refuses to run without a memory directory' \
  2 'No memory directory exists' check

# --- summary --------------------------------------------------------------

echo "passed: $passes, failed: $failures"
[ "$failures" -eq 0 ]
