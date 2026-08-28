# OpenTelemetry Specification: Overview & Architecture

> **Source commit:** `8057bf6d5cf0ab10891b9e6f7b928cded76ab2f7`
> **Repository:** https://github.com/open-telemetry/opentelemetry-specification
> **Spec root:** `specification/` (relative paths used throughout). NOT bundled with this skill — fetch files at
> `https://raw.githubusercontent.com/open-telemetry/opentelemetry-specification/<source-commit>/specification/<path>`
> **Semantic Conventions:** In a SEPARATE repository — `opentelemetry/semantic-conventions`. Not covered here.

---

## How to Use These Reference Files

**Tier system:**
- **Tier 1 (Inline):** Full distilled content — API contracts, MUST requirements, defaults, env vars
- **Tier 2 (Summary + Pointer):** 2-5 sentence summary + file path
- **Tier 3 (Pointer Only):** File path + one-line description

**RFC 2119 notation:** MUST = mandatory, MUST NOT = prohibited, SHOULD = recommended, MAY = optional.

**Source pointers:** Every subsection has `[Source: path]` — fetch those files for full normative text using the retrieval recipe in this skill's SKILL.md (raw.githubusercontent.com at the pinned source commit above).

**For compliance auditing:** Read `reference/compliance-checklist.md` for checkbox-formatted MUST/MUST NOT requirements per component.

---

## 1. Architecture & Principles

### 1.1 Core Architecture
[Source: overview.md, library-guidelines.md]

OpenTelemetry clients are organized into package types per signal:

- **API Packages** — Cross-cutting public interfaces consumed by instrumentation libraries and applications. Must be well-defined and clearly decoupled from SDK.
- **SDK Packages** — OpenTelemetry's implementation of the API, installed by application owners.
- **Semantic Conventions** — Attribute keys and values for common concepts (separate repo).
- **Contrib Packages** — Optional OSS integrations, separate from the SDK. **API Contrib** depends solely on the API; **SDK Contrib** also depends on the SDK.
- **Core Packages** — Not an additional package type. The term names client packages that implement specification-defined components across the categories above (API, SDK, and plugins such as OTLP Exporters and TraceContext Propagators). Core packages are maintained by an OpenTelemetry SIG; the term does not prescribe a repository, module, or artifact layout.

**Component pipeline:** API → SDK (batching, enrichment) → Exporters (protocol-dependent)

**Key rules:**
- "the OpenTelemetry API and SDK libraries MUST be provided as independent artifacts" (the only capitalised MUST in the Requirements list; the rest use lowercase "must"/"should")
- The API must be well-defined and clearly decoupled from the implementation; third-party libraries depend only on the API and cannot know which implementation the final application uses
- When the SDK is not installed, "the API calls should be no-ops which generate minimal overhead"
- The API package is self-sufficient: an application that depends only on it builds and runs without an SDK (no telemetry delivered). Values returned from the minimal implementation are valid and non-null (e.g., `createSpan()` "should not fail and should return a valid non-null Span object")
- Resource detectors from cloud vendors "MUST be implemented outside of the SDK"
- "API and SDK packages MUST be labeled with their own version number"; every release "MUST clearly mention the Specification version number that they implement"

### 1.2 Error Handling
[Source: error-handling.md]

- "OpenTelemetry implementations MUST NOT throw unhandled exceptions at runtime."
- "API methods MUST NOT throw unhandled exceptions when used incorrectly by end users." The API and SDK SHOULD provide safe defaults for missing or invalid arguments.
- "The SDK MUST NOT throw unhandled exceptions for errors in their own operations." (e.g., exporter failures)
- "API methods that accept external callbacks MUST handle all errors."
- Whenever an API call returns a value expected to be non-null, on error the "SDK MUST return a "no-op" or any other "default" object"
- Whenever the library suppresses an error, "the library SHOULD log the error using language-specific conventions." SDKs MAY expose callbacks for self-diagnostics.
- "SDK implementations MUST allow end users to change the library's default error handling behavior for relevant errors."
- The API or SDK MAY fail fast on initialization (bad config or environment) "but MUST NOT cause the application to fail later at runtime, e.g. due to dynamic config settings received from the Collector."
- Self-diagnostics telemetry (metrics or logs about the SDK's own behaviour) is specified in `self-observability.md` — see 1.7.

### 1.3 Performance
[Source: performance.md]

- Library should not block end user application by default
- Library should not consume unbounded memory resources
- Shutdown and explicit flushing could block; the client should support a user-configurable timeout
- Client should provide a way to filter logs to prevent excessive memory consumption
- When there is a trade-off between blocking and memory, provide options to end users: prevent information loss, prevent blocking, or sampling
- (This file uses lowercase "should"; it carries no RFC 2119 MUST requirements.)

### 1.4 Versioning & Stability
[Source: versioning-and-stability.md]

**Signal lifecycle:** follows the maturity levels in `maturity-levels.md` (see 1.6) plus the signal-specific **Removed** level: Development → Stable → Deprecated → Removed. Any use of "Experimental" is treated the same as "Development".

**Language-specific document:** Each language implementation "MUST take these versioning and stability requirements, and produce a language-specific document"; it "MUST be placed in the root of each repository and named `VERSIONING` or `VERSIONING.md`."

**For signals in Development:**
- "Long-term dependencies SHOULD NOT be taken against signals in Development."
- "OpenTelemetry clients MUST NOT be designed in a manner that breaks existing users when a signal transitions from Development to Stable."
- "Terms which denote stability, such as "development", MUST NOT be used as part of a directory or import name."

**For Stable signals:**
- "The API MUST become stable before the other components."
- "Backward-incompatible changes to API packages MUST NOT be made unless the major version number is incremented."
- "All existing API calls MUST continue to compile and function against all future minor versions of the same major version."
- "Public portions of SDK packages MUST remain backward compatible." (plugin interfaces and constructors)
- End user code implementing plugin interfaces "MUST continue to be possible to use with newer versions of the SDK without making changes to the end user's code."
- Contrib packages: public portions "SHOULD remain backward compatible."
- "Signals MUST NOT be marked as deprecated unless the replacement is stable."
- "Deprecated code MUST abide by the same support guarantees as stable code."
- When a deprecated signal is removed, "The release MUST make a major version bump."
- Embedded `service.*` resource attributes "MUST NOT be ever changed."

**Versioning:**
- "OpenTelemetry clients MUST follow Semantic Versioning 2.0.0"
- "All stable API packages MUST version together, across all signals." "Stable signals MUST NOT have separate version numbers."
- "SDK packages for all signals MUST version together, across all signals."
- "Major version bumps MUST occur when there is a breaking change to a stable interface or a deprecated signal is removed."
- "Major versions of the API MUST be supported for a minimum of **three years** after the release of the next major API version." During that window API stability "MUST be maintained" and "Bug and security fixes MUST be backported."
- SDK major versions: supported for a minimum of one year after the next major SDK version release

### 1.5 Library Guidelines
[Source: library-guidelines.md, library-layout.md]

- "The SDK must be clearly separated into wire protocol-independent parts ... and protocol-dependent telemetry exporters." (lowercase "must" in source)
- "Telemetry exporters must contain minimal functionality, thus enabling vendors to easily add support for their specific protocol."
- The SDK implementation should include: OTLP, standard output/logging, and in-memory (mock) exporters for logs, metrics, and traces; Prometheus for metrics; Zipkin for traces
- Vendor-specific exporters "should not be included in OpenTelemetry clients"
- Separately shipped exporters are named `opentelemetry-exporter-{vendor_name}` (Python, Java) or `@opentelemetry/exporter-{vendor_name}` (JavaScript)
- `library-layout.md` gives the reference tree: `api/{context,baggage,trace,metrics,logs}` and `sdk/{context,baggage,trace,metrics,logs}`; lowercase, camelCase, or snake_case depends on the language

### 1.6 Maturity Levels (Tier 2)
[Source: maturity-levels.md, document-status.md]

Status: Stable. Defines the project-wide maturity scale that `versioning-and-stability.md` and per-document "Status" headers refer to: Development, Alpha (the default when no level is declared), Beta, Release Candidate, Stable, Deprecated, Unmaintained. "Deliverables of a SIG MUST have a declared maturity level"; a main deliverable and its components may differ (a Stable Collector may ship a non-Stable receiver, clearly marked). "Components SHOULD NOT be marked as Stable if their user-visible interfaces are not Stable." Development components "SHOULD NOT be used in production" and "MAY be removed without prior notice". Deprecated components in distributions are expected to exist for at least two minor releases or six months, whichever is later, and "MUST communicate in which version they will be removed". Unmaintained components (no code owner responding within 6 weeks) "MAY be Deprecated" after 6 months. `document-status.md` now only says a document's support guarantees follow its maturity level; a "Mixed" status means the document itself labels each section.

### 1.7 Self-Observability (Tier 2)
[Source: self-observability.md, error-handling.md]

Status: Development. "OpenTelemetry SDKs SHOULD emit self-observability ("internal") telemetry about their own behavior (for example, metrics, logs, and other signals describing the state of processors, exporters, and metric readers)". Metric names, attributes, and values come from the semantic conventions (SDK Metrics, `otel/sdk-metrics/`); "SDKs that implement self-observability metrics SHOULD follow these conventions." Telemetry emitted during SDK startup and shutdown is best-effort, because the recording SDK may not be initialized yet or may already be shut down. Cross-referenced from the self-diagnostics section of `error-handling.md`.

### 1.8 Self-Observability Supplementary Guidelines (Tier 3)
[Source: self-observability-supplementary-guidelines.md]

Non-normative; adds no requirements. Covers lifecycle ordering between providers (whichever provider comes up second loses the window before it exists), obtaining the Meter/Logger from the global provider versus a user-supplied provider (or both, with global fallback), avoiding telemetry-induced-telemetry loops via an isolated provider or a Context suppression flag (spec issue #530; per-SDK examples), and treating self-observability under the SDK's normal stability rules — experimental metrics or attributes must be opt-in (e.g., `OTEL_GO_X_OBSERVABILITY`).

---

## Appendix C: Cross-Signal Patterns

> Patterns appearing identically (or near-identically) across Traces, Metrics, and Logs. Use as templates when auditing any signal.

### C.1 Provider.GetInstance Pattern

All three signals use the same provider acquisition pattern:

```
Provider.Get{Tracer|Meter|Logger}(
  name: string,           // instrumentation scope name (REQUIRED)
  version?: string,       // instrumentation scope version (OPTIONAL)
  schema_url?: string,    // schema URL (OPTIONAL)
  attributes?: Attributes // scope attributes (OPTIONAL)
) -> {Tracer|Meter|Logger}
```

- Same `(name, version, schema_url, attributes)` combination MUST return same instance (or equivalent)
- Null/empty name MUST be accepted (SHOULD log warning, returns working instance)
- No-op instance returned when SDK not installed

### C.2 Processor Pattern (OnEvent + Lifecycle)

| Interface | Traces | Logs |
|---|---|---|
| OnEvent | `OnStart(span, ctx)` + `OnEnd(span)` | `OnEmit(logRecord, ctx)` |
| Shutdown | `Shutdown() -> result` | `Shutdown() -> result` |
| ForceFlush | `ForceFlush() -> result` | `ForceFlush() -> result` |

Metrics uses MetricReader instead of Processor (pull-based collection via `Collect(exporter)`).

- Shutdown MUST be called only once; subsequent calls SHOULD be gracefully ignored
- ForceFlush MUST complete pending processing; if exporter attached, MUST call exporter's Export then ForceFlush

### C.3 Exporter Pattern

| Method | Description |
|---|---|
| `Export(batch) -> ExportResult` | Send batch; MUST NOT block indefinitely; Success or Failure |
| `Shutdown() -> result` | Clean up; SHOULD be called once; subsequent Export SHOULD return Failure |
| `ForceFlush() -> result` | Flush pending data |

- Export MUST NOT be called after Shutdown
- Exporter MUST NOT be called concurrently with other Export calls for same instance
- Default SDK Processors SHOULD NOT implement retry logic — that's the exporter's responsibility
- MetricExporter additionally has: `Temporality(kind) -> temporality`, `DefaultAggregation(kind) -> aggregation`

### C.4 Batch Processor Configuration

| Config | Traces (BSP) env var | Logs (BLRP) env var | Traces default | Logs default |
|---|---|---|---|---|
| Schedule delay | `OTEL_BSP_SCHEDULE_DELAY` | `OTEL_BLRP_SCHEDULE_DELAY` | 5000ms | 1000ms |
| Export timeout | `OTEL_BSP_EXPORT_TIMEOUT` | `OTEL_BLRP_EXPORT_TIMEOUT` | 30000ms | 30000ms |
| Max queue size | `OTEL_BSP_MAX_QUEUE_SIZE` | `OTEL_BLRP_MAX_QUEUE_SIZE` | 2048 | 2048 |
| Max batch size | `OTEL_BSP_MAX_EXPORT_BATCH_SIZE` | `OTEL_BLRP_MAX_EXPORT_BATCH_SIZE` | 512 | 512 |

Max batch size MUST be ≤ max queue size.

Metrics uses PeriodicExportingMetricReader (not a batch processor): `OTEL_METRIC_EXPORT_INTERVAL` (60000ms), `OTEL_METRIC_EXPORT_TIMEOUT` (30000ms).

### C.5 Attribute Limits Pattern

| Limit | General env var | Span-specific | Log-specific | Metric-specific | Default |
|---|---|---|---|---|---|
| Count | `OTEL_ATTRIBUTE_COUNT_LIMIT` | `OTEL_SPAN_ATTRIBUTE_COUNT_LIMIT` | `OTEL_LOGRECORD_ATTRIBUTE_COUNT_LIMIT` | `OTEL_METRIC_ATTRIBUTE_COUNT_LIMIT` | 128 |
| Value length | `OTEL_ATTRIBUTE_VALUE_LENGTH_LIMIT` | `OTEL_SPAN_ATTRIBUTE_VALUE_LENGTH_LIMIT` | `OTEL_LOGRECORD_ATTRIBUTE_VALUE_LENGTH_LIMIT` | `OTEL_METRIC_ATTRIBUTE_VALUE_LENGTH_LIMIT` | unlimited |

Priority: signal-specific MUST override general.

Spans also have: `OTEL_SPAN_EVENT_COUNT_LIMIT` (128), `OTEL_SPAN_LINK_COUNT_LIMIT` (128), `OTEL_EVENT_ATTRIBUTE_COUNT_LIMIT` (128), `OTEL_LINK_ATTRIBUTE_COUNT_LIMIT` (128).

### C.6 No-Op Behavior

- When SDK not installed, API MUST return no-op instances
- No-op instances MUST be functional (accept all calls, return valid empty results)
- No-op MUST NOT throw
- No-op MUST NOT validate arguments
- No-op MUST NOT return non-empty error or log message
- No-op MUST NOT hold configuration or operational state
- No-op `Enabled()` MUST return false (Logger) / implementations may vary (Tracer, Meter)
- Examples:
  - No-op `Span.SetAttribute()` silently succeeds
  - No-op `Counter.Add()` silently succeeds
  - No-op `Logger.Emit()` silently succeeds

### C.7 Provider Shutdown Lifecycle

All three Providers follow the same shutdown pattern:

1. `Shutdown()` called once — MUST be called only once per Provider instance
2. After Shutdown — subsequent `Get{Tracer|Meter|Logger}()` calls return no-op instances (SDKs SHOULD)
3. Shutdown cascades — MUST invoke Shutdown on all registered Processors/Readers/Exporters
4. ForceFlush — MUST invoke ForceFlush on all registered Processors/Readers
5. Timeout — SHOULD provide configurable timeout; SHOULD complete or abort within timeout
6. Result — SHOULD provide way to know if succeeded, failed, or timed out

### C.8 SDK Configuration Update Pattern

For all signals, when Provider configuration is updated at runtime (e.g., adding a Processor):

> Updated configuration MUST also apply to all already-returned {Tracer|Meter|Logger} instances. It MUST NOT matter whether the instance was obtained before or after the configuration change.

This pattern applies to: SpanProcessors, MetricReaders, LogRecordProcessors, and Configurator functions.

### C.9 Resource Association Pattern

All three signals associate a single immutable Resource with their Provider:

```
TracerProvider.Resource -> Resource  (set at creation, immutable)
MeterProvider.Resource -> Resource   (set at creation, immutable)
LoggerProvider.Resource -> Resource  (set at creation, immutable)
```

- Resource MUST be set during provider creation; MUST NOT be changed after
- All Spans/metrics/LogRecords from any Tracer/Meter/Logger from that provider share the same Resource
- Resource attributes identify the entity producing telemetry (service.name, host.name, etc.)
- Resource is immutable and passed to all exporters for correlation
- If not explicitly set, the SDK's default Resource MUST be used

### C.10 Instrumentation Scope Association Pattern

Each Tracer/Meter/Logger carries its InstrumentationScope:

```
Span.InstrumentationScope -> (name, version, schema_url, attributes)
MetricPoint.InstrumentationScope -> (name, version, schema_url, attributes)
LogRecord.InstrumentationScope -> (name, version, schema_url, attributes)
```

- Scope is set when Tracer/Meter/Logger obtained via `Get{Signal}(name, version?, schema_url?, attributes?)`
- Same scope tuple → same provider instance (typically memoized)
- InstrumentationScope is immutable on the signal instance
- Exported to backend for attribution (which library produced this telemetry)
- Distinct from Resource (which identifies the deployment/service, not the instrumentation)
