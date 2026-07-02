---
name: working-with-adr-tracking-projects
description: Conventions on working with Architecture Decision Records (ADRs). Use when working on projects that already track architecture decisions through ADRs, or when the user asks to record an architectural decision.
---

# Working with ADR-Tracking Projects

Architecture decisions are the load-bearing walls of a system. They are invisible in code yet they shape everything — why this database, why that protocol, why not the obvious alternative. ADRs make these walls visible. Each record captures one decision at the moment it was made, preserving the context that future readers will need to understand — or safely change — what was built.

## 1. Discovering ADRs

Before creating or referencing ADRs, locate where they live:

1. Check for a `.adr-dir` file at the project root — it contains the ADR directory path (e.g., `doc/adr`).
2. If no `.adr-dir` exists, check for `doc/adr/` directly.
3. If neither exists, the project does not use ADRs yet. Do not bootstrap uninvited — ask the user first (via AskUserQuestion where available, in plain text otherwise). With their approval: create `doc/adr/`, create a `.adr-dir` file at the project root containing `doc/adr`, and write ADR 0001 ("Record architecture decisions") as the first entry.

List existing ADRs by reading the directory — there is no index file. The filenames are the table of contents. Read them in numeric order to follow the decision timeline.

## 2. ADR Format

Every ADR follows Michael Nygard's original format. The template:

```
# [Number]. [Title]

Date: [YYYY-MM-DD]

## Context

[The issue or problem that motivated this decision. Describe the forces at play —
technical constraints, business requirements, team capabilities, trade-offs considered.
A reader who was not in the room should understand why this decision was on the table.]

## Decision

[What was decided. State it directly: "We will use X" or "We will not do Y."
For complex decisions, use ### subsections to break down different aspects.]

## Status

[One of: Proposed | Accepted | Deprecated | Superseded by [ADR NNNN](NNNN-name.md)]

## Consequences

[The resulting context — both positive and negative. What becomes easier? What becomes
harder? What new constraints does this decision introduce? What follow-up decisions
does it force?]
```

### Naming convention

- File format: `NNNN-kebab-case-title.md`
- 4-digit zero-padded sequential numbering starting from `0001`
- Title in the filename matches the title in the heading
- Example: `0014-adopt-event-sourcing-for-audit-trail.md`

### The meta-ADR

ADR 0001 is always "Record architecture decisions" — the decision to use ADRs. It bootstraps the practice and serves as a template for all subsequent entries.

## 3. Creating New ADRs

Determine the next number by reading the ADR directory and incrementing the highest existing number. Then:

1. Create the file with the correct name and number.
2. Set the date to today.
3. Set the status to `Proposed` if the decision is under discussion, or `Accepted` if it is already agreed upon.

### Writing a strong Context section

Describe the problem, not the solution. Explain the forces — what is pulling the team toward a decision? Technical constraints, business deadlines, team expertise, existing infrastructure, scale requirements. A good Context section lets a reader who joins the project two years later understand why the decision was necessary. Avoid vague statements like "we needed a better approach" — name the specific pain or requirement.

### Writing a strong Decision section

State the decision in active voice: "We will adopt PostgreSQL for the event store." Not "PostgreSQL was chosen." For complex decisions, use `###` subsections to address distinct aspects — e.g., one subsection for the technology choice, another for the migration strategy, another for the rollback plan.

### Writing strong Consequences

Be honest. Every decision has trade-offs. List what becomes easier and what becomes harder. Name the new constraints. Identify follow-up decisions that this one forces. A Consequences section that lists only benefits is incomplete — it makes future readers distrust the record.

## 4. Superseding and Deprecating

ADRs are immutable records once accepted. A `Proposed` ADR is still a draft — edit it freely until it is accepted. Do not edit an accepted ADR to change its decision. Instead:

**Superseding** — when a new decision replaces an old one:

1. Create the new ADR. In its Context section, reference the old ADR and explain why circumstances changed.
2. In the old ADR, change only the Status field to: `Superseded by [ADR NNNN](NNNN-name.md)`.

**Deprecating** — when a decision is no longer relevant without a replacement:

1. Change only the Status field of the old ADR to: `Deprecated`.
2. Optionally add a one-line note in the Status section explaining why (e.g., "the subsystem this governed was decommissioned").

These are the only permitted edits to an accepted ADR. The Context, Decision, and Consequences sections remain untouched — they are the historical record.

## 5. Planning Integration

When writing an implementation plan that involves architectural choices, include ADR creation as explicit steps:

- **Identify which decisions qualify** — technology selections, protocol choices, data model designs, integration patterns, and any decision that constrains future work. Not every implementation detail is an architectural decision.
- **Specify the ADR** — include the proposed title, a brief sketch of the Context and Decision content, and the filename. The executing agent should not have to determine whether an ADR is needed or what to write in it.
- **Sequence the ADR before the implementation** — the ADR captures the decision; the code implements it. Write the record first, then build.

These details must appear in the plan itself — do not assume the executing agent has access to this skill's conventions.

## 6. What NOT to Do

- Don't edit an accepted ADR's Context, Decision, or Consequences — supersede or deprecate instead.
- Don't create ADRs for trivial implementation details — reserve them for decisions that constrain future work.
- Don't write vague Context sections ("we needed something better") — name specific forces, constraints, and trade-offs.
- Don't omit negative consequences — every decision has trade-offs; a one-sided Consequences section is dishonest.
- Don't skip numbering or reuse numbers — the sequence is the timeline.
- Don't create subdirectories within the ADR directory — all ADRs are peers in a flat directory.
- Don't create an index file or TOC — the filesystem is the index; filenames are self-describing.
- Don't write the code first and backfill the ADR afterward — the record captures the decision at the moment it is made, not as post-hoc documentation.
