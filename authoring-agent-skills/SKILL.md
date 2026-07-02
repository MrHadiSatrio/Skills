---
name: authoring-agent-skills
description: Conventions on authoring agent skills for this repository — naming, trigger descriptions, structure, examples, and deployment. Use when creating or modifying a skill, or when directed by another skill.
---

# Authoring Agent Skills

A skill is a set of instructions executed by an agent that may reason less capably than its author. Write for the weakest reader: every rule must be executable without inference leaps, every reference must resolve, and every absolute must carry its boundary. A skill that only works when read charitably does not work.

## 1. The Weakest-Reader Principle

Assume the executing agent takes instructions literally and cannot fill gaps from judgment.

- **Examples beat abstractions.** A rule a capable reader operationalizes from prose, a weaker reader can only imitate from an example. Any rule that changes what code looks like gets one.
- **Every absolute gets an escape hatch.** An unqualified "never X" will be obeyed even where X is the only option (a language without the preferred construct, a framework that mandates a name). State the boundary in the same breath as the rule.
- **Decision points get decision procedures.** Where two loaded rules can collide, write the tiebreaker ("acceptable at system boundaries; inside the domain, prefer..."). Do not leave arbitration to the reader.
- **Dead ends stall weak readers.** Before publishing, follow every path, command, and skill reference in the text as literally as an agent would — each must resolve or carry a fallback.

## 2. Naming and Frontmatter

- **`name` matches the directory name exactly** — the CD pipeline matches deployed skills by directory name (see section 7).
- **Names are gerund phrases** describing the activity: `writing-…`, `working-with-…`, `exploring-…`, `practicing-…`, `authoring-…`.
- **`description` states what the skill is, then when to use it**, in third person. The "when" clause is the trigger — the only part the agent sees before deciding to load the skill.
- **Trigger on task traits, not project traits.** "Use when auditing OTel compliance" fires on the right work; "use on any project that integrates OTel" loads spec workflows onto unrelated tasks.
- **Two trigger modes, stated explicitly:**
  - *Auto:* "Use when <task trait>." — for conventions that should apply whenever the matching work happens.
  - *Explicit-only:* "Use only when explicitly triggered by the user, or when directed by another skill." — for skills that change how the agent works (exploration strategies, onboarding, composites). The "directed by another skill" clause matters: without it, a literal reader refuses programmatic loading mid-workflow.

## 3. Structure

Every SKILL.md follows the house shape:

1. **Opening philosophy paragraph** — two or three sentences on why the convention exists. This is the lens through which a reader interprets everything below it.
2. **Numbered sections** — one concern per section, rules as bold-led bullets.
3. **"What NOT to Do" as the final section** — the prohibitions, each with its escape hatch inline.
4. **A "Planning" section where applicable** — any skill whose conventions must survive into an implementation plan (Git workflow, ADRs, TDD) ends its relevant guidance with: the details must appear in the plan itself; do not assume the executing agent has access to this skill.

Composite skills — an index whose whole body is a load list (`coding-like-hadi`) — are exempt from the numbered-section shape; theirs is the load list plus failure handling.

## 4. Examples

- **Pseudocode shape first, Kotlin realization second.** The pseudocode carries the transferable pattern — a reader in another language copies the shape rather than transliterating Kotlin idioms. The Kotlin grounds it in one real implementation.
- **Good/bad pairs** for anything with a failure mode worth naming — show the violation next to the fix, labeled `Good:` and `Bad:`.
- **Examples must obey every rule in their own skill.** A skill whose flagship example violates its own prohibition forces the reader to arbitrate between rule and example, and weak readers arbitrate unpredictably.

## 5. References and Paths

- **Bundled-file paths are relative to the skill's root directory** (the directory containing SKILL.md). Never prefix with the skill name or any mount point — those differ between runtimes.
- **Restate, don't reference, cross-skill content.** A skill must stand alone; content another skill also needs gets restated, with one line naming the canonical owner: "if these diverge, <skill>'s <section title> wins." Never maintain two canonical copies.
- **Reference sibling skills by name and section title, never section number.** Numbers break silently on reorder.
- **External resources need a retrieval recipe** — a skill that points at unbundled files (an upstream spec, a repository) must say exactly how to fetch them, pinned to a version, with an offline fallback.

## 6. Runtime Robustness

These skills run in Claude Code *and* deploy to the Anthropic Skills API, where the toolset differs.

- **Every tool dependency gets a one-line fallback:** Skill tool unavailable → read the sibling skill's SKILL.md directly; AskUserQuestion unavailable → ask in plain text; Explore subagents unavailable → search directly with bounded reads.
- **Composite skills state what to do when a child fails to load** — the first instruction of a composite must not be its only path.

## 7. Deployment

`.github/workflows/cd.yaml` uploads every directory containing a SKILL.md to the Anthropic Skills API on push to `master`.

- **Skills are matched by `display_title` == directory name.** Renaming a directory does not rename the deployed skill — it creates a new one and orphans the old. A rename therefore requires manually deleting the orphaned skill via the API.
- **Dot-files are excluded from upload** — anything a deployed skill needs must not be hidden.
- **CI must pass before merging to master** — the lint verifies frontmatter parses, `name` matches the directory, and every relative path referenced in a SKILL.md exists.

## 8. What NOT to Do

- Don't state a rule without either an example or an escape hatch — prose-only absolutes are the two failure modes of this repo's own audit. Exception: rules whose scope is genuinely universal and self-executing ("no trailing period in commit subjects").
- Don't reference another skill's section by number — use the section title.
- Don't write a description that triggers on project traits — scope it to the task.
- Don't let an example violate its own skill's rules — fix the example or scope the rule.
- Don't duplicate content without naming which copy is canonical.
- Don't rename a skill directory casually — it orphans the deployed skill (see section 7).
- Don't put load-bearing content in dot-files — the CD pipeline won't ship them.
- Don't assume Claude Code's toolset — every tool dependency needs a deployed-runtime fallback.
