#!/usr/bin/env bash
# Validates every skill against the authoring conventions
# (see authoring-agent-skills/SKILL.md): frontmatter parses,
# `name` matches the directory, and every relative .md path
# referenced in a bundled markdown file resolves on disk.
#
# Path checking covers backtick-quoted .md paths that contain a
# directory component, resolved against the skill root and the
# referencing file's own directory. A file whose backticked paths
# deliberately point outside the skill (an index of upstream files)
# opts out by containing the marker: <!-- lint:external-paths -->
#
# Known blind spots, by design: bare same-directory filenames
# (`overview.md`), non-.md files (`cd.yaml`), and dot-leading or
# parent-relative paths (`.github/...`, `../...`) are not checked —
# the character class cannot distinguish them from prose examples.
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

  while IFS= read -r -d '' doc; do
    if grep -q '<!-- lint:external-paths -->' "$doc"; then
      continue
    fi
    docdir="$(dirname "$doc")"
    while IFS= read -r ref; do
      if [ ! -f "$dir/$ref" ] && [ ! -f "$docdir/$ref" ]; then
        fail "$skill: ${doc#"$root"/} references '$ref', which does not exist"
      fi
    done < <(grep -oE '`[a-zA-Z0-9_-]+(/[a-zA-Z0-9_.-]+)+\.md`' "$doc" | tr -d '\140' | sort -u)
  done < <(find "$dir" -name '*.md' -print0)
done

if [ "$failures" -gt 0 ]; then
  echo ""
  echo "$failures check(s) failed."
  exit 1
fi

echo "All skills valid."
