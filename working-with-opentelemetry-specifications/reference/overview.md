# OpenTelemetry Specification: Overview & Architecture

> **Source commit:** `0651981a9597850b8fed3a31ff07a262901dd341`
> **Repository:** https://github.com/open-telemetry/opentelemetry-specification
> **Spec root:** `specification/` (relative paths used throughout)
> **Semantic Conventions:** In a SEPARATE repository — `opentelemetry/semantic-conventions`. Not covered here.

---

## How to Use These Reference Files

**Tier system:**
- **Tier 1 (Inline):** Full distilled content — API contracts, MUST requirements, defaults, env vars
- **Tier 2 (Summary + Pointer):** 2-5 sentence summary + file path
- **Tier 3 (Pointer Only):** File path + one-line description

**RFC 2119 notation:** MUST = mandatory, MUST NOT = prohibited, SHOULD = recommended, MAY = optional.

**Source pointers:** Every subsection has `[Source: path]` — jump to those files for full normative text.

**For compliance auditing:** Read `reference/compliance-checklist.md` for checkbox-formatted MUST/MUST NOT requirements per component.

---

## 1. Architecture & Principles

### 1.1 Core Architecture
[Source: overview.md, library-guidelines.md]

OpenTelemetry clients are organized into four package types per signal:

- **API Packages** — Cross-cutting public interfaces consumed by instrumentation libraries and applications. Must be well-defined and clearly decoupled from SDK.
- **SDK Packages** — OpenTelemetry's implementation of the API, installed by application owners.
- **Semantic Conventions** — Attribute keys and values for common concepts (separate repo).
- **Contrib Packages** — Optional OSS integrations, separate from SDK.

**Component pipeline:** API → SDK (batching, enrichment) → Exporters (protocol-dependent)

**Key rules:**
- MUST separate API packages from SDK packages as independent artifacts
- MUST provide minimal no-op implementations in API when SDK not installed — API calls return valid, non-null objects with negligible performance penalty
- Instrumentation authors MUST NOT directly reference any SDK package — only API
- API package MUST be self-sufficient: application builds and runs without SDK (no telemetry delivered)
- Values returned from minimal API implementation MUST be valid and non-null

### 1.2 Error Handling
[Source: error-handling.md]

- OpenTelemetry implementations MUST NOT throw unhandled exceptions at runtime
- API methods MUST NOT throw unhandled exceptions when used incorrectly by end users
- SDK MUST NOT throw unhandled exceptions for errors in their own operations (e.g., exporter failures)
- API methods accepting external callbacks MUST handle all errors
- Whenever API returns values expected to be non-null, SDK MUST return a "no-op" or "default" object on error
- Library SHOULD log suppressed errors using language-specific conventions
- SDK MUST allow end users to change the library's default error handling behavior
- MUST NOT cause application to fail later at runtime due to dynamic config settings
- Implementations MAY fail fast on initialization (bad config) but MUST NOT on runtime dynamic config

### 1.3 Performance
[Source: performance.md]

- Library SHOULD NOT block end-user application by default
- Library SHOULD NOT consume unbounded memory resources
- Shutdown and explicit flushing MAY block; MUST support user-configurable timeout
- SDK SHOULD provide way to filter logs to prevent excessive memory consumption

### 1.4 Versioning & Stability
[Source: versioning-and-stability.md]

**Stability levels:** Development → Stable → Deprecated → Removed

**For Stable signals:**
- Backward-incompatible changes to API packages MUST NOT be made without major version bump
- All existing API calls MUST continue to compile and function against all future minor versions of same major version
- Public portions of SDK packages MUST remain backwards compatible
- Signals MUST NOT be marked deprecated unless replacement is stable
- Deprecated code MUST abide by same support guarantees as stable code
- Major version MUST be bumped when deprecated signal removed

**Versioning:**
- OpenTelemetry clients MUST follow Semantic Versioning 2.0.0
- All stable API packages MUST version together across all signals (no separate version numbers)
- SDK packages for all signals MUST version together across all signals
- API stability MUST be maintained for minimum of 3 years after next major API version release
- SDK stability MUST be maintained for minimum of 1 year after next major SDK version release

### 1.5 Library Guidelines
[Source: library-guidelines.md, library-layout.md]

- SDK MUST be clearly separated into wire protocol-independent parts and protocol-dependent exporters
- Exporters MUST contain minimal functionality to enable vendors to add protocol support easily
- SDK SHOULD include standard exporters: OTLP, stdout/logging, in-memory (mock); Prometheus for metrics; Zipkin for traces
- Vendor-specific exporters SHOULD NOT be included in SDK

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
