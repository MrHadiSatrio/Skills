---
name: planning-code-changes
description: Conventions on writing implementation plans for coding tasks — commit sequence, blackbox test plan, ADRs, and an adversarial review pass. Use when writing an implementation plan (e.g., in plan mode) rather than executing changes directly.
---

# Planning Code Changes

A plan is instructions to an executing agent that may not share your context, your skills, or your reasoning capacity — and a proposal to a reviewer who must approve behavior, not just intent. Write the plan so the executor can follow it literally and the reviewer can see what the system will do once it lands.

Several convention skills mandate that their details appear in plans (`working-with-git-repositories`, `working-with-adr-tracking-projects`, `practicing-test-driven-development` — each in its "Planning" section). This skill is the single template that aggregates them.

## 1. What Every Plan Contains

In order:

1. **Context** — why the change is being made: the problem or need, what prompted it, the intended outcome.
2. **Branch** — the branch name, following the Git conventions' category prefixes (or the project's own detected convention).
3. **Commit sequence** — see section 2.
4. **Blackbox test plan** — see section 3.
5. **ADRs** — see section 4, when the work involves architectural decisions.
6. **Quality gate** — the exact command (e.g., `./gradlew check`, `npm test`) as an explicit verification step the executor runs before each commit.

Omit a section only when it genuinely does not apply — never because it was inconvenient to think through.

## 2. The Commit Plan

List which steps get their own commit and provide the exact message for each — subject *and* body, following the Git conventions' format (imperative subject; body carrying the *why* when the subject alone isn't enough). A reviewer reading only the planned commit messages should see the narrative arc of the change.

## 3. The Blackbox Test Plan

List the behaviors to be tested as natural-language test names — `reports its coordinates`, `refuses a timestamp from the future` — one line per behavior, ordered inside-out (value types first, then the objects built on them). Add a one-line description only where the name alone is ambiguous.

This is the highest-leverage section of the plan: the test names *are* the behavioral specification, so reviewing the plan doubles as reviewing the behavior. A reviewer who disagrees with a test name is catching a requirements defect before any code exists.

## 4. ADRs

When the work involves decisions that constrain future work — technology selections, protocol choices, data models, integration patterns — specify each ADR per the ADR conventions: proposed title, filename, and a brief sketch of Context and Decision. Sequence the ADR before the implementation steps it governs.

## 5. The Adversarial Pass

Before presenting the plan, attack it:

- **Does each commit leave the tree green?** A commit sequence that breaks the quality gate mid-way is broken history waiting to happen.
- **Which failure modes have no test name?** Walk the error paths, the empty cases, the boundary values — every one you'd want pinned should appear in section 3.
- **Are there hidden dependencies between steps?** If step 4 silently requires step 7's artifact, the executor will discover it the hard way — reorder or state it.
- **What would a reviewer push back on?** Name the weakest decision in the plan and either strengthen it or flag it openly as a judgment call.

Where subagents are available, a fresh-context agent prompted to refute the plan catches what the author's context blinds them to. Where they are not, do the pass yourself against the checklist above.

## 6. What NOT to Do

- Don't write "add tests" as a plan step — name the tests; unnamed tests are unplanned behavior.
- Don't describe commits ("commit the changes") — provide the exact messages, subject and body.
- Don't assume the executor has any skill loaded — everything they need must be in the plan itself.
- Don't leave the quality-gate command implicit ("run the tests") — name it exactly, or state where to discover it.
- Don't present a plan that hasn't survived the adversarial pass — an unchallenged plan is a draft.
- Don't plan refactoring and behavior change into the same commit — keep them separable, per the Git conventions.
