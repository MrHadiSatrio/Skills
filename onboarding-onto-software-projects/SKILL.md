---
name: onboarding-onto-software-projects
description: Onboard Claude onto a new software project by exploring its architecture, writing a CLAUDE.md, and defining project-specific skills. Use only when explicitly triggered by the user.
---

# Onboarding onto Software Projects

Onboarding is an investment in every future session. The goal is to capture enough context — architecture, conventions, tooling, workflows — that any future Claude instance can produce correct code without rediscovering the project from scratch. Be thorough now so every session after this one is faster.

Wherever this skill says **AskUserQuestion** and that tool is unavailable in the runtime, ask the same question in plain text and wait for the reply — never skip the question.

## 0. Pre-flight Check

Before doing anything else, check whether the project is already partially onboarded:

```bash
ls CLAUDE.md 2>/dev/null
ls .claude/skills/ 2>/dev/null
ls .claude/commands/ 2>/dev/null
```

If an existing `CLAUDE.md` or project-local skills are found, use **AskUserQuestion** to confirm intent:

```
questions:
  - question: "An existing CLAUDE.md (or project-local skills) was found. How should we proceed?"
    header: "Existing Config"
    options:
      - label: "Extend / merge"
        description: "Keep what's there and add to it — good if the existing content is still valid"
      - label: "Replace entirely"
        description: "Discard the existing content and build fresh from this exploration"
      - label: "Abort"
        description: "The project is already onboarded. Stop here"
```

Record the user's choice — it governs how steps 4 and 5 handle existing artifacts.

---

## 1. Git Branch Setup

Load the `working-with-git-repositories` skill via the Skill tool before performing any Git operations.

Check whether the working directory is a Git repository:

```bash
git rev-parse --is-inside-work-tree 2>/dev/null
```

**If it is a Git repo:**

Inspect the project's existing branch naming convention:

```bash
git branch -a | head -20
git log --oneline -20
```

Look for patterns: does the project use `feat/`, `feature/`, `fix/`, `task/`, `chore/`, or no prefix at all? Create the onboarding branch following whatever convention is in use. Default to `task/onboard_claude` when no clear pattern exists, since onboarding is infrastructure work, not a user-facing feature.

Examples based on detected conventions:

| Detected pattern | Branch to create |
| ---------------- | ---------------- |
| `feat/` or `feature/` | `feat/onboard_claude` |
| `task/` or `chore/` | `task/onboard_claude` |
| No prefix | `onboard_claude` |

```bash
git checkout -b <branch-name>
```

**If it is not a Git repo:** skip this step silently and proceed to step 2.

---

## 2. Global AgentSkills Submodule

Skip this step if the project is not a Git repository.

Use **AskUserQuestion** to ask:

```
questions:
  - question: "Would you like to include the global AgentSkills repository as a Git submodule?"
    header: "Global Skills"
    options:
      - label: "Yes, add as submodule"
        description: "Adds https://github.com/MrHadiSatrio/Skills.git — brings shared coding, Git, and documentation conventions to this project"
      - label: "No, skip for now"
        description: "You can always add it manually later"
```

**If yes:**

Ask the user for the preferred submodule path (default: `.claude/skills`). Then add it:

```bash
git submodule add https://github.com/MrHadiSatrio/Skills.git <path>
```

Verify the submodule was added correctly:

```bash
git submodule status
```

**If no:** acknowledge and proceed.

---

## 3. Explore the Project

Use **AskUserQuestion** to decide the exploration approach — ask both questions before loading anything:

```
questions:
  - question: "Is this project well-documented (doc comments, interface definitions, etc.)?"
    header: "Docs Quality"
    options:
      - label: "Yes — well-documented"
        description: "I'll use contract-only exploration for maximum token efficiency"
      - label: "No / unsure"
        description: "I'll use standard exploration and read files more fully"
  - question: "Does this project have well-tested code (descriptive test names, fakes, clear setup)?"
    header: "Test Quality"
    options:
      - label: "Yes — well-tested"
        description: "I'll use test-driven exploration to catalog behaviors and construction patterns"
      - label: "No / unsure"
        description: "I'll skip test-driven exploration and rely on other signals"
```

**If well-documented:** load the `exploring-well-documented-code` skill via the Skill tool. Apply its contract-only technique throughout this step.

**If well-tested:** load the `exploring-well-tested-code` skill via the Skill tool. Apply its test-driven technique throughout this step.

**If both:** use both skills together — `exploring-well-documented-code` first for the architectural skeleton, then `exploring-well-tested-code` for behavioral depth and edge cases.

**If neither:** use standard exploration — read files with Glob, Grep, and Read tools, and delegate broader surveys to Explore subagents without contract-only constraints.

### Exploration checklist

Work through each area in order. Take notes as you go — they feed directly into `CLAUDE.md`.

1. **Build system and dependencies** — `package.json`, `build.gradle`, `Cargo.toml`, `pyproject.toml`, `Makefile`, `Dockerfile`, etc. Identify language(s), runtime(s), framework(s), and key third-party libraries.

2. **Project structure** — Glob for source directories. Map the top-level layout. Is it a monorepo, multi-module project, or single module? What lives where?

3. **Entry points** — How does the application start? Look for `main()`, `index.ts`, `app.py`, route definitions, or equivalent. Understand what the system does at a high level.

4. **Testing setup** — Test runner, directory structure, naming conventions, and how to run the test suite. Note any separation between unit, integration, and e2e tests.

5. **CI/CD** — `.github/workflows/`, `.gitlab-ci.yml`, `Jenkinsfile`, etc. What is the quality gate? How does code get deployed?

6. **Code style and conventions** — Linter configs (`.eslintrc`, `ktlint`, `rustfmt.toml`), formatter configs, editor configs. Are style rules enforced automatically?

7. **Git conventions** — Recent commit messages (`git log --oneline -30`). Scoped commits? Conventional commits? Imperative mood? PR templates? Note overlaps or conflicts with any global skills already loaded.

8. **Documentation** — README, CONTRIBUTING, architecture decision records (ADRs), API docs. What does the project say about itself?

### Clarification

After exploration, use **AskUserQuestion** to surface and resolve anything ambiguous. Do not assume. Examples of things to clarify:

- "I see both JUnit 4 and JUnit 5 in the test dependencies — which should new tests use?"
- "The commit history uses both `feat:` and imperative-only subjects — which is preferred going forward?"
- "I found conventions in the existing `CLAUDE.md` that overlap with the global AgentSkills — should the project-level rules override or defer to global ones?"
- "There appear to be two separate module structures here — is this intentional or legacy fragmentation?"

Repeat until you have a clear, complete picture of the project.

---

## 4. Write CLAUDE.md

Write a `CLAUDE.md` at the project root. If an existing one was found in step 0, follow the user's pre-flight decision (merge/extend vs. replace).

### Structure

Include every section that applies to the project:

```markdown
# <Project Name>

<One-paragraph overview: what the project is, what it does, who it serves.>

## Tech Stack

<Language(s), runtime, framework(s), key libraries, build tool.>

## Project Structure

<Description of the directory layout and what lives where. Be explicit.>

## Development Workflow

<Exact commands to build, test, lint, and run the project. No vague descriptions.>

## Coding Conventions

<Style rules, naming conventions, architectural patterns the project enforces.>

## Git Conventions

<Commit message format, branch naming, merge strategy, PR process. Note scope usage if present.>

## Testing Conventions

<Test framework, naming conventions, where tests live, how to run them, what kinds of tests exist.>

## Key Architectural Decisions

<Non-obvious design choices a newcomer would stumble on. Include the "why" where known.>

## Known Gotchas

<Things that are easy to get wrong. Anything that has burned people before.>
```

### Principles

- Optimize for a future agent that has never seen the project. Be explicit. Assume nothing.
- Include exact commands, not descriptions (`./gradlew check`, not "run the quality gate").
- Do not restate conventions already captured in referenced skills — reference them instead.
- Every section should earn its place. Omit sections where there is nothing meaningful to say.

Notify the user after writing and offer to review any section together.

---

## 5. Project-Specific Skills

Some project knowledge cannot live in a static document. Recurring multi-step workflows — raising merge requests, deploying to staging, debugging production issues, running migrations, cutting releases — are better expressed as skills that can be invoked on demand.

Use **AskUserQuestion** to prompt the user:

```
questions:
  - question: "Are there project-specific workflows you'd like to turn into Claude skills?"
    header: "Project Skills"
    options:
      - label: "Yes, let's define some"
        description: "E.g., raising MRs, deploying, debugging, running migrations, cutting releases"
      - label: "No, CLAUDE.md is enough for now"
        description: "Skills can always be added later"
```

**If yes — the creation loop:**

For each skill the user wants to add:

1. Ask the user to describe the workflow: what triggers it, what steps it involves, what it produces.
2. Load the `authoring-agent-skills` skill via the Skill tool and follow its conventions to write the skill. If it is unavailable, fall back to this inline procedure:
   - Create `.claude/skills/<kebab-case-name>/SKILL.md`.
   - Frontmatter: `name` matching the directory name exactly, and a `description` stating what the skill does, then when to use it.
   - Body: a one-paragraph purpose statement, numbered step-by-step sections with exact commands (not descriptions), and a final "What NOT to Do" section.
   - Follow every path and command in the draft literally to confirm it resolves before moving on.
3. After the skill is created, use **AskUserQuestion** to ask if there are more:

```
questions:
  - question: "Any more project-specific skills to add?"
    header: "More Skills"
    options:
      - label: "Yes, one more"
        description: "Continue the loop"
      - label: "No, that's all"
        description: "Move on to wrap-up"
```

Repeat until the user says they are done.

If project-local skills already existed (detected in step 0), follow the user's pre-flight decision before adding or merging anything.

---

## 6. Wrap Up

Summarize what was accomplished:

- Branch created (name it) — or note that the project is not a Git repo
- Submodule added (path) — or skipped
- `CLAUDE.md` written or updated
- Skills defined (list each by name) — or none

Use **AskUserQuestion** to ask what to do next:

```
questions:
  - question: "Onboarding is complete. What would you like to do next?"
    header: "Next Steps"
    options:
      - label: "Commit and raise an MR"
        description: "Commit all onboarding artifacts and open a merge/pull request"
      - label: "Commit only"
        description: "Commit changes locally without raising an MR"
      - label: "Nothing for now"
        description: "Leave changes uncommitted — you can commit later"
```

**If committing:** follow the `working-with-git-repositories` skill's conventions (already loaded from step 1). Use granular commits — one per artifact type. Example order:

1. `Add CLAUDE.md`
2. `Add .claude/skills/<name>` (one commit per skill)
3. `Add AgentSkills submodule` (if applicable)

**If raising an MR:** use `gh pr create` (or the project's equivalent) with a brief description of what was onboarded.

---

## 7. What NOT to Do

- Don't write a shallow CLAUDE.md based on assumptions — explore first, ask when unclear.
- Don't load `exploring-well-documented-code` without asking whether the project actually has documentation worth using.
- Don't load `exploring-well-tested-code` without asking whether the project actually has well-named tests worth using.
- Don't overwrite an existing `CLAUDE.md` or project-local skills without following the user's pre-flight decision.
- Don't add the global AgentSkills submodule without asking.
- Don't assume branch naming conventions — inspect the project's history first.
- Don't bundle all onboarding changes into a single commit — commit each artifact separately.
- Don't create skills for things that belong in `CLAUDE.md` — skills are for interactive, multi-step workflows, not static reference material.
- Don't proceed past ambiguity — if something is unclear from exploration, ask before writing it down as fact.
