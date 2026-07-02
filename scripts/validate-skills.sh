#!/usr/bin/env bash
# Validates every skill against the authoring conventions
# (see authoring-agent-skills/SKILL.md): frontmatter parses,
# `name` matches the directory, and every relative .md path
# referenced in a SKILL.md resolves on disk.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
failures=0

fail() {
  echo "FAIL: $1"
  failures=$((failures + 1))
}

for skill_md in "$root"/*/SKILL.md; do
  dir="$(dirname "$skill_md")"
  skill="$(basename "$dir")"

  if [ "$(head -1 "$skill_md")" != "---" ]; then
    fail "$skill: SKILL.md does not open with a frontmatter block"
    continue
  fi

  frontmatter="$(awk '/^---$/{n++; next} n==1' "$skill_md")"
  name="$(echo "$frontmatter" | sed -n 's/^name:[[:space:]]*//p')"
  description="$(echo "$frontmatter" | sed -n 's/^description:[[:space:]]*//p')"

  [ -n "$name" ] || fail "$skill: frontmatter declares no name"
  [ -n "$description" ] || fail "$skill: frontmatter declares no description"
  if [ -n "$name" ] && [ "$name" != "$skill" ]; then
    fail "$skill: frontmatter name '$name' does not match the directory name"
  fi

  # Backtick-quoted relative .md paths with a directory component must
  # resolve from the skill root. Tokens with placeholders (<, {) never
  # match the character class and are ignored.
  while IFS= read -r ref; do
    [ -f "$dir/$ref" ] || fail "$skill: referenced path '$ref' does not exist"
  done < <(grep -oE '`[a-zA-Z0-9_-]+(/[a-zA-Z0-9_.-]+)+\.md`' "$skill_md" | tr -d '\140' | sort -u)
done

if [ "$failures" -gt 0 ]; then
  echo ""
  echo "$failures check(s) failed."
  exit 1
fi

echo "All skills valid."
