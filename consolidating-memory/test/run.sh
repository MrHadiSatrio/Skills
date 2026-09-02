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

pass() { passes=$((passes + 1)); }
fail() { failures=$((failures + 1)); echo "FAIL: $1"; }

# Reset the temporary configuration directory and the working directory.
fresh() {
  rm -rf "$TEMPORARY/configuration" "$TEMPORARY/workspace"
  mkdir -p "$TEMPORARY/configuration" "$TEMPORARY/workspace"
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

# --- summary --------------------------------------------------------------

echo "passed: $passes, failed: $failures"
[ "$failures" -eq 0 ]
