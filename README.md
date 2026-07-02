# AgentSkills

Hadi's personal collection of agent skills for Claude — engineering conventions, workflows, and reference knowledge. Every skill is written for the weakest reader: an agent with less reasoning capacity than the author must be able to execute it literally, without inference leaps, dead-end references, or overapplied absolutes.

## Using

- **Claude Code:** clone into `~/.claude/skills` for global use, or add as a submodule inside a project (see `onboarding-onto-software-projects` for the trade-offs).
- **Anthropic Skills API:** every push to `master` deploys all skills via `.github/workflows/cd.yaml`.

## Catalog

### Conventions and workflows (auto-trigger on matching work)

| Skill | What it governs |
| ----- | --------------- |
| `writing-organism-oriented-code` | Objects as autonomous organisms; composition over inheritance. Canonical owner of the test-design rules and the codebase-precedence rule. |
| `writing-prose-like-code` | Code that reads as English prose — naming, narrative method bodies, domain vocabulary. |
| `writing-code-documentation` | Caller-facing documentation for public APIs. |
| `practicing-test-driven-development` | Red-green-refactor, inside-out from value types, tests as design pressure. |
| `working-with-git-repositories` | Granular commits, branch naming, merging, pull requests, tags. |
| `working-with-adr-tracking-projects` | Nygard-format Architecture Decision Records. |
| `working-with-opentelemetry-specifications` | Distilled OTel spec knowledge plus audit/build/review workflows. |
| `fixing-defects` | Reproduce → regression-test at the lowest layer → fix → commit together. |
| `planning-code-changes` | The implementation-plan template: commit plan, blackbox test plan, ADRs, adversarial pass. |

### Explicit-only (load on request, or when directed by another skill)

| Skill | What it does |
| ----- | ------------ |
| `coding-like-hadi` | Composite — loads the five core convention skills in one invocation. |
| `exploring-well-documented-code` | Token-efficient exploration through contracts and doc comments. |
| `exploring-well-tested-code` | Token-efficient exploration through test names, setup, and fakes. |
| `onboarding-onto-software-projects` | Guided onboarding: explore, write CLAUDE.md, define project skills. |
| `refactoring-legacy-code` | Strangler-style migration of a codebase toward the conventions. |
| `authoring-agent-skills` | How to write skills for this repository — start here for any new skill. |

### Other

| Skill | What it does |
| ----- | ------------ |
| `endurance-coaching` | Triathlon/marathon/ultra training plans — not an engineering skill. |

## How the skills relate

- `coding-like-hadi` loads `writing-organism-oriented-code`, `writing-prose-like-code`, `writing-code-documentation`, `practicing-test-driven-development`, and `working-with-git-repositories`.
- `onboarding-onto-software-projects` directs `working-with-git-repositories`, both `exploring-*` skills, and `authoring-agent-skills`.
- `planning-code-changes` aggregates the "Planning" sections of the Git, ADR, and TDD skills into one plan template.
- `fixing-defects` and `refactoring-legacy-code` build on `practicing-test-driven-development` and `working-with-git-repositories`.
- Deliberately duplicated content (the test-design rules, the precedence rule) is restated where needed; the copy in `writing-organism-oriented-code` is canonical.

## Maintaining

- **New or changed skills** follow `authoring-agent-skills` — naming, trigger descriptions, structure, examples, fallbacks.
- **CI** (`.github/workflows/ci.yaml`) validates every skill: frontmatter parses, `name` matches the directory, and every relative `.md` path referenced in a SKILL.md exists. Run it locally with `scripts/validate-skills.sh` before pushing.
- **CD** (`.github/workflows/cd.yaml`) uploads every directory containing a `SKILL.md` on push to `master`, matching deployed skills by `display_title` == directory name. **Renaming a directory creates a new deployed skill and orphans the old one** — after a rename, delete the orphan through the Skills API.
- The OTel skill's reference files are distilled from a pinned upstream commit; `working-with-opentelemetry-specifications/reference/maintenance.md` documents the re-distillation procedure.
