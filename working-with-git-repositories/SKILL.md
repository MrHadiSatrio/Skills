---
name: working-with-git-repositories
description: Conventions on working with Git repositories. Always use when creating commits, branches, tags, or pull requests.
---

# Working with Git Repositories

A repository's history is its autobiography. Every commit, branch, and tag tells a story — what changed, why, and where. Favor many small, well-narrated steps over few large leaps.

## 1. Commits

Granular commits. Each commit represents one small, coherent change — a single idea describable in one sentence. A commit touching more than a handful of files is the exception, not the norm. When a task involves multiple steps, commit after each step rather than bundling everything into one commit.

### Message format

- **Subject** — imperative mood, sentence-case, no trailing period. Describes what the commit does when applied: "Add", "Fix", "Replace", "Define" — not "Added", "Fixes", "Replacing".
- **Scope** (only in projects that already use scoped messages) — a slash-separated path identifying the area of change, prefixed to the subject: `<scope>: <imperative summary>`. Check the project's recent `git log` to determine whether scope is used and what the scope tokens look like. Common scope patterns: module paths (`android/journal3`, `kotlin/geography`), package names (`lib/auth`, `api/users`), or `root` for project-wide changes.
- **Body** (optional, separated by blank line) — explains the *why* when the subject alone isn't enough. Not a changelog; not a diff summary.

Examples:

- `Add golden flow E2E test`
- `android/journal3: Rely on current place to capture moments`
- `root: Update dependency org.xerial:sqlite-jdbc to v3.47.2.0`

### Quality gate

Always run the project's quality gate before committing — tests, linting, formatting, coverage, whatever the project defines. A commit that breaks the quality gate is not acceptable. When the repository defines a single command for this (e.g., `./gradlew check`, `npm test`, `make check`), prefer that over running individual tools.

## 2. Branches

Name branches with a category prefix and a snake_case descriptor:

- **`feature/`** — new user-facing functionality: `feature/writing_suggestions`, `feature/autocapture`
- **`fix/`** — bug fixes: `fix/location_selector`, `fix/missing_keys`
- **`task/`** — chores, refactors, dependency updates, infrastructure: `task/housekeeping`, `task/di_via_hilt`
- **`spike/`** — exploratory, throwaway investigations: `spike/compose`, `spike/otel`

Keep descriptors short and specific. The branch name should tell a reviewer what to expect before they look at any code.

## 3. Merging

Standard merge commits. Do not rebase feature branches onto the main branch — preserve the branch topology in the history. Merge commit messages follow Git's default: `Merge branch '<branch-name>' into <target>`.

## 4. Tags

Semantic versioning: `v<major>.<minor>.<patch>`. No prerelease suffixes unless the project explicitly uses them. Tag releases on the main integration branch, not on feature branches.

## 5. What NOT to Do

- Don't bundle unrelated changes in one commit — split them.
- Don't write commit subjects in past tense ("Added", "Fixed") — use imperative mood ("Add", "Fix").
- Don't omit scope when the project uses scoped messages — check `git log` and match the convention.
- Don't leave the quality gate broken — fix it before committing, not after.
- Don't force-push to shared branches.
- Don't rebase published history.
- Don't use vague branch names like `dev`, `wip`, `test`, or `my-branch`.
