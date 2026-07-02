---
name: working-with-opentelemetry-specifications
description: OpenTelemetry specification expertise for auditing, building, and reviewing OTel-adjacent projects. Use when the task concerns OpenTelemetry compliance, instrumentation design, or implementing/reviewing SDKs, collectors, or exporters — not merely because the project uses OpenTelemetry.
---

# Working with OpenTelemetry Specifications

The OpenTelemetry specification is the contract. Every SDK, instrumentation library, collector, and exporter either satisfies it or violates it. This skill equips you with a distilled knowledge base and structured workflows to apply that contract — whether auditing an existing implementation, building a new one, or reviewing changes.

The knowledge base is split into 8 focused reference files. Read only what the current task requires. All `reference/` paths below are relative to this skill's root directory — the directory containing this SKILL.md.

## 1. Reference Files

| File | When to Read | Contents |
| ---- | ------------ | -------- |
| `reference/overview.md` | Always — first step for any task | Architecture & API/SDK split, error handling, performance, versioning, cross-signal patterns |
| `reference/cross-cutting.md` | When working with any signal | Context API, Propagators, Resource SDK, Common attributes, Instrumentation Scope |
| `reference/traces.md` | When working with traces | TracerProvider, Tracer, Span, SpanContext, Sampling, SpanProcessor, SpanExporter |
| `reference/metrics.md` | When working with metrics | MeterProvider, Meter, 7 instrument types, Views, Aggregation, Cardinality, Exemplars |
| `reference/logs.md` | When working with logs | LogRecord data model, LoggerProvider, Logger, LogRecordProcessor, bridge pattern |
| `reference/baggage-and-configuration.md` | When working with baggage or config | Baggage API, all OTEL_* env vars, declarative configuration |
| `reference/compliance-checklist.md` | When auditing for compliance | MUST/MUST NOT checkboxes organized by component (A.1–A.12) |
| `reference/file-index.md` | When navigating to original spec files | Compatibility areas, lower-priority signals, all 86 spec files with paths and line counts |

**Tier system** (used throughout the reference files):
- **Tier 1 (Inline):** Full MUST requirements, API contracts, defaults, env vars — act on this directly
- **Tier 2 (Summary + Pointer):** 2-5 sentence summary + `[Source: path]` — read source for full detail
- **Tier 3 (Pointer Only):** File path + one-line description — relevant when the task specifically touches these areas

**Source pointers:** Every reference subsection has `[Source: path]` — a path into the upstream spec's `specification/` directory, which is NOT bundled with this skill. To resolve a pointer:

1. Read the pinned source commit hash from the header of `reference/overview.md`.
2. Fetch the file at `https://raw.githubusercontent.com/open-telemetry/opentelemetry-specification/<pinned-commit>/specification/<path>` (WebFetch or `curl`). Use the pinned commit, not HEAD — it keeps the source consistent with what the reference files were distilled from.
3. When a task needs many source files, clone once instead: `git clone https://github.com/open-telemetry/opentelemetry-specification && git -C opentelemetry-specification checkout <pinned-commit>`, then read from its `specification/` directory.
4. If the source cannot be fetched (offline, no network access), report which pointer needs verification rather than citing the spec from memory.

## 2. Freshness Validation

The reference files are distilled from a specific commit of the upstream specification. They can become stale as the spec evolves.

Before relying on the reference content:

1. Read the source commit hash from `reference/overview.md` (recorded in its header)
2. Check the upstream repository for changes since that commit — with a bounded query only. The compare API returns full commit lists and file diffs by default, which will flood your context:
   - `gh api "repos/open-telemetry/opentelemetry-specification/compare/{source_commit}...HEAD" --jq '{ahead_by: .ahead_by, total_commits: .total_commits}'`
   - Never fetch the compare result without that `--jq` filter (or an equivalent field selection via WebFetch)
   - If the check cannot run at all (offline, `gh` unavailable, permission denied): state the pinned commit, proceed with the current reference files, and note the unverified-freshness caveat in any findings
3. If changes exist:
   - Inform the user: the reference files were distilled against commit X, the upstream spec has moved forward (briefly: how many commits, rough summary of what changed)
   - Do NOT attempt to diff individual files or map changes to reference sections — this risks context bloat on large changesets
   - Ask whether to proceed with the current reference files or halt for re-distillation
   - If the user chooses to proceed, continue normally but note the caveat in any findings
   - If the user chooses re-distillation, follow the procedure in `reference/maintenance.md`

## 3. Workflows

### 3.1 Compliance Auditing

1. Run freshness validation (Section 2)
2. Read `reference/overview.md` for architecture principles
3. Identify which components the target project implements (API? SDK? Both? Which signals?)
4. Read `reference/cross-cutting.md` + the relevant signal file(s) (`traces.md` / `metrics.md` / `logs.md`)
5. Read `reference/compliance-checklist.md` and work through the relevant component sections
6. For each requirement, verify the target project's implementation against the checklist
7. When Tier 1 content is insufficient, follow `[Source: ...]` pointers to the original spec files
8. Report findings with spec file references; distinguish MUST violations from SHOULD recommendations

### 3.2 Building / Implementing

1. Run freshness validation (Section 2)
2. Read `reference/overview.md` — internalize API/SDK split, error handling rules, performance constraints, cross-signal patterns
3. Read `reference/cross-cutting.md` — Context, Resource, and Common types apply to all signals
4. Read the relevant signal file (`traces.md` / `metrics.md` / `logs.md`) for the component being built
5. Read `reference/baggage-and-configuration.md` if the component handles baggage, env vars, or config files
6. Follow `[Source: ...]` pointers for implementation-level detail beyond Tier 1 summaries

### 3.3 Code Review / PR Review

1. Run freshness validation (Section 2)
2. Read `reference/overview.md` for foundational principles
3. Identify which spec areas the changes touch
4. Read only the relevant signal/topic reference file(s)
5. Verify changes against MUST/MUST NOT requirements in those sections
6. Flag violations as blocking; flag SHOULD deviations as recommendations

## 4. Key Specification Principles

These are top-of-mind reminders — not replacements for the reference files:

- **API/SDK separation:** Instrumentation MUST only depend on API, never SDK
- **No-op safety:** API MUST work without SDK installed; all API calls return valid, non-null objects
- **Error handling:** MUST NOT throw unhandled exceptions at runtime
- **Immutability:** Context, Resource, and Baggage are immutable; mutations return new instances
- **Provider pipeline:** `Provider → Get(name, version, schema_url, attrs) → Signal instance → Processor → Exporter`
- **RFC 2119:** MUST = mandatory, MUST NOT = prohibited, SHOULD = recommended, MAY = optional
- **Semantic Conventions:** Attribute naming and values live in a SEPARATE repository (`opentelemetry/semantic-conventions`) — not covered in these reference files

## 5. Common Pitfalls

- Confusing semantic conventions (separate repo) with the core specification
- Missing the attribute limits cascade: signal-specific MUST override general env var
- Forgetting `ForceFlush`/`Shutdown` lifecycle on Processors and Exporters
- Ignoring cardinality limits in metrics (default 2000; overflow attribute set `{otel.metric.overflow=true}`)
- Not distinguishing synchronous vs asynchronous instruments — they have different callback semantics
- Treating `SpanKind` as optional — each value has specific semantics (CLIENT, SERVER, PRODUCER, CONSUMER, INTERNAL)
- Missing the bridge/appender pattern for logs — Logs API is for bridges to existing logging frameworks, not direct use by applications
- Treating `SHOULD` requirements as `MUST` — they carry different compliance weight

## 6. What NOT to Do

- Don't cite spec requirements from memory — always verify against the reference files or original spec
- Don't read all 8 reference files upfront — read only what the current task requires
- Don't confuse the specification with semantic conventions (separate repo, not covered here)
- Don't assume all signals have identical APIs — each has signal-specific contracts alongside the shared patterns
- Don't skip `[Source: ...]` pointers when the reference summary is ambiguous
- Don't treat `SHOULD` requirements as `MUST` — they carry different compliance weight
- Don't skip freshness validation — the reference files can become stale as the spec evolves
