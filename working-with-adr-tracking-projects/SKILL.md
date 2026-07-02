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
3. If neither exists, the project does not use ADRs yet. Do not bootstrap uninvited — ask the user first (via AskUserQuestion where available, in plain text otherwise). With their approval: create `doc/adr/`, create a `.adr-dir` file at the project root containing `doc/adr`, and write ADR 0001 ("Record architecture decisions") as the first entry — copy and adapt this skill's bundled `reference/0001-record-architecture-decisions.md`. If the bundled reference files are unavailable in your runtime, the template in the "ADR Format" section alone suffices.

List existing ADRs by reading the directory — there is no index file. The filenames are the table of contents. Read them in numeric order to follow the decision timeline.

## 2. ADRs as Constraints

Most sessions in an ADR-tracking project read records rather than write them. Accepted ADRs are binding constraints, not background reading:

- **Consult before designing.** Before changing anything plausibly governed by a recorded decision — storage, protocols, module boundaries, cross-cutting concerns — scan the ADR filenames for relevant records and read those in full.
- **The conflict procedure.** If the intended change contradicts an accepted ADR: stop. Either conform the design to the record, or propose supersedure to the user with the changed circumstances. Never silently contradict a live record; never privately judge a record stale.
- **Cite what governed you.** When an accepted ADR shaped the work, cite it by number in the plan, PR description, or commit body ("per ADR 0007").

## 3. ADR Format

New practice bootstraps with Michael Nygard's original format, and projects already on it stay on it. In a project whose existing records follow another convention — MADR, adr-tools ordering, a bespoke template — match the existing records: consistency within the trail beats conformance to this template, and never reformat existing records.

Format-matching covers the whole lifecycle, not just headings: section names, status vocabulary, and supersedure markers all follow the trail's convention. The exact strings in this skill (the status set, `Superseded by …` / `Supersedes …`) apply to Nygard-format trails; in a foreign-format trail, map the intent — records immutable once accepted, supersedure linked in both directions, acceptance is the team's call — onto the trail's own vocabulary, and ask the user where the mapping is unclear.

The template:

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
[An accepted ADR that replaces another adds a second line: Supersedes [ADR NNNN](NNNN-name.md)]

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

ADR 0001 is always "Record architecture decisions" — the decision to use ADRs. It bootstraps the practice and serves as a template for all subsequent entries. A filled copy ships with this skill at `reference/0001-record-architecture-decisions.md` — match its length and tone in every record you write.

## 4. Creating New ADRs

### Is this decision ADR-worthy?

Apply this litmus before writing anything:

- **Record it if any of these hold:** reversing it later would be expensive (a migration, a rewrite, a broken contract); it constrains code not yet written — others must conform to it; or it was chosen among viable alternatives a future reader would plausibly re-propose ("why didn't you just use X?").
- **Skip it if all of these hold:** it is reversible by an ordinary refactor; its effect is visible entirely within the code it touches; and no future reader would ask why.
- **Boundary examples.** ADR-worthy: "PostgreSQL over DynamoDB for the event store", "all service-to-service calls go through the message bus". Not ADR-worthy: "extract a shared helper", "rename a module", "bump a patch version".
- **The library tiebreaker.** A dependency choice is architectural when swapping it would ripple beyond the module that imports it — the dependency-injection framework: yes; a date-formatting helper used in one file: no.
- **When the litmus is inconclusive, ask the user** (via AskUserQuestion where available, in plain text otherwise) — never silently decide an inconclusive case needs no record. Cases the skip-litmus cleanly resolves need no prompt.
- **One decision per record.** If the Decision section needs an "and" between unrelated choices, split them into separate ADRs.

Determine the next number by reading the ADR directory and incrementing the highest existing number. Then:

1. Create the file with the correct name and number.
2. Set the date to today.
3. Set the status to `Proposed` if the decision is under discussion, or `Accepted` if it is already agreed upon.

Flipping `Proposed` to `Accepted` is the user's or team's call — never do it unilaterally. Exception: an ADR specified in a plan the user approved may be created as `Accepted`; the approval already happened. If you encounter a stale `Proposed` record during other work, flag it to the user — do not treat it as binding, and do not adopt or delete it.

### Length and tone

- **The whole record fits on one page.** A future reader should get the decision and its why in minutes: Context in one to three paragraphs, Decision in a sentence to a paragraph (`###` subsections only for genuinely multi-part decisions), Consequences as a handful of concrete effects.
- **An ADR records the decision, not the design.** API specifications, diagrams, and step-by-step migration plans belong in the project's design documents or issues — link them from the ADR as supplementary pointers. The record must still stand alone if every link dies: links carry design detail, never the decision or its why. If the project has no home for design material, ask the user where it should live; keep the record itself scannable regardless.
- **Write self-contained statements.** A future reader cannot resolve "as discussed in Slack" or "per yesterday's meeting" — restate the substance in the record itself, with absolute dates.
- **Do not pad.** No boilerplate openers ("This document describes…"), no restating the template's bracketed prompts, no repeating Context inside Consequences.

### Writing a strong Context section

Describe the problem, not the solution. Explain the forces — what is pulling the team toward a decision? Technical constraints, business deadlines, team expertise, existing infrastructure, scale requirements. A good Context section lets a reader who joins the project two years later understand why the decision was necessary. Avoid vague statements like "we needed a better approach" — name the specific pain or requirement.

### Writing a strong Decision section

State the decision in active voice: "We will adopt PostgreSQL for the event store." Not "PostgreSQL was chosen." For complex decisions, use `###` subsections to address distinct aspects of the decision — e.g., one subsection for the technology choice, another for the compatibility commitment it makes. Do not use subsections to inline design material such as migration steps or rollback runbooks — that belongs in a linked design document (see "Length and tone").

### Writing strong Consequences

Be honest. Every decision has trade-offs. List what becomes easier and what becomes harder. Name the new constraints. Identify follow-up decisions that this one forces. A Consequences section that lists only benefits is incomplete — it makes future readers distrust the record.

## 5. Superseding and Deprecating

ADRs are immutable records once accepted. A `Proposed` ADR is still a draft — edit it freely until it is accepted. Do not edit an accepted ADR to change its decision. Instead:

**When does a new decision supersede an old one?** Supersede only when following the old record would now be wrong. If the old and the new decision can both be obeyed simultaneously, the new ADR stands alone — reference the old one in its Context if they are related, but leave its status untouched.

**Superseding** — when a new decision replaces an old one:

1. Create the new ADR. In its Context section, reference the old ADR and explain why circumstances changed.
2. In the new ADR's Status section, below its status, add the back-link: `Supersedes [ADR NNNN](NNNN-name.md)`.
3. In the old ADR, change only the Status field to: `Superseded by [ADR MMMM](MMMM-name.md)`.

Links go in both directions, and every link target is a bare same-directory filename — ADRs live in a flat directory, so a sibling filename always resolves.

**Supersede whole records only.** When a new decision invalidates part of an old ADR, supersede the whole record and restate what still holds in the new ADR's Decision section ("Carried forward from ADR NNNN: …"). Never leave a record half-live.

**Number collisions** — when two branches each claim the same next number, resolve at merge time: the later-merged ADR renumbers — filename, heading, and any links pointing to it.

**Deprecating** — when a decision is no longer relevant without a replacement:

1. Change only the Status field of the old ADR to: `Deprecated`.
2. Optionally add a one-line note in the Status section explaining why (e.g., "the subsystem this governed was decommissioned").

These are the only permitted edits to an accepted ADR. The Context, Decision, and Consequences sections remain untouched — they are the historical record.

A worked pair ships with this skill: `reference/0002-store-events-in-postgresql.md` and `reference/0003-move-the-event-store-to-eventstoredb.md` demonstrate the exact status edits, the bidirectional links, and a carried-forward decision.

## 6. Planning

When writing an implementation plan that involves architectural choices, include ADR creation as explicit steps:

- **Identify which decisions qualify** — technology selections, protocol choices, data model designs, integration patterns, and any decision that constrains future work. Not every implementation detail is an architectural decision.
- **Specify the ADR** — include the proposed title, a brief sketch of the Context and Decision content, and the filename. The executing agent should not have to determine whether an ADR is needed or what to write in it.
- **Sequence the ADR before the implementation** — the ADR captures the decision; the code implements it. Write the record first, then build.

These details must appear in the plan itself — do not assume the executing agent has access to this skill's conventions.

## 7. What NOT to Do

- Don't edit an accepted ADR's Context, Decision, or Consequences — supersede or deprecate instead.
- Don't write code that contradicts an accepted ADR — conform, or propose supersedure first.
- Don't create ADRs for trivial implementation details — reserve them for decisions that constrain future work.
- Don't bundle unrelated decisions into one ADR — split them.
- Don't inline the design into the record — an ADR that needs diagrams and API tables is a design doc wearing an ADR's filename; link the design material instead.
- Don't write vague Context sections ("we needed something better") — name specific forces, constraints, and trade-offs.
- Don't omit negative consequences — every decision has trade-offs; a one-sided Consequences section is dishonest.
- Don't skip numbering or reuse numbers — the sequence is the timeline.
- Don't create subdirectories within the ADR directory — all ADRs are peers in a flat directory.
- Don't create an index file or TOC — the filesystem is the index; filenames are self-describing.
- Don't write the code first and backfill the ADR afterward — for new decisions, the record captures the decision at the moment it is made, not as post-hoc documentation. Recording a pre-existing, undocumented decision is legitimate: date it the day it is written and open its Context with a retrospective marker — e.g., "Recorded retrospectively: this decision was made circa 2023, when…".
