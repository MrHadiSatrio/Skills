# OpenTelemetry Specification: Logs Signal

> Logs Data Model, LoggerProvider, Logger, LogRecordProcessor, LogRecordExporter, Bridge Pattern

---

## 7. Logs Signal

### 7.1 Logs Data Model
[Source: logs/data-model.md]

#### LogRecord Fields

| Field | Type | Required? |
|---|---|---|
| Timestamp | uint64 Unix nanos | Optional |
| ObservedTimestamp | uint64 Unix nanos | SHOULD be set once observed |
| TraceId | bytes (16) | Optional |
| SpanId | bytes (8) | Optional; "If SpanId is present TraceId SHOULD be also present" |
| TraceFlags | byte (1) | Optional |
| SeverityNumber | int (1-24) | Optional; 0 = unspecified |
| SeverityText | string | Optional |
| Body | AnyValue | Optional; MUST support AnyValue semantics |
| Resource | Resource | "Describes the observed entity that generated the log" |
| InstrumentationScope | InstrumentationScope | — |
| Attributes | map<string, AnyValue> | Optional |
| EventName | string | Optional; non-empty = Event format |

#### Severity Ranges

| Range | Name | Values |
|---|---|---|
| 1-4 | TRACE | TRACE, TRACE2, TRACE3, TRACE4 |
| 5-8 | DEBUG | DEBUG, DEBUG2, DEBUG3, DEBUG4 |
| 9-12 | INFO | INFO, INFO2, INFO3, INFO4 |
| 13-16 | WARN | WARN, WARN2, WARN3, WARN4 |
| 17-20 | ERROR | ERROR, ERROR2, ERROR3, ERROR4 |
| 21-24 | FATAL | FATAL, FATAL2, FATAL3, FATAL4 |

- SeverityNumber >= 17 indicates erroneous situation; readers MAY apply special handling
- When reverse-mapping, choose target severity in same range closest numerically

#### Events (Named Log Records)
- Log record with non-empty EventName is an Event
- EventName SHOULD uniquely identify event structure (both attributes and body)
- Events SHOULD be used by OTel instrumentation per semantic conventions

#### Example Mappings (Appendix)
[Source: logs/data-model-appendix.md]

**Tier 3.** Non-normative mappings from Syslog RFC5424, Windows Event Log, SignalFx, Splunk HEC, Log4j, Zap, Apache HTTP, CloudTrail, Google Cloud Logging, Elastic Common Schema, and (new) ETW. ETW: header metadata goes under `etw.*` attributes, Level 0 `LOG_ALWAYS` maps to SeverityNumber 0 (a filter directive, not a severity), levels 1-5 map to FATAL/ERROR/WARN/INFO/DEBUG (21/17/13/9/5), and Body is left empty. Appendix B gives the cross-library SeverityNumber table with numeric values.

#### Trace Context in Legacy Log Formats
[Source: compatibility/logging_trace_context.md]

**Tier 2.** For logs that stay in legacy formats: Syslog RFC5424 — "Trace ID, span ID and traceflags SHOULD be recorded via SD-ID \"OpenTelemetry\"" (was lowercase `opentelemetry` at OLD). Plain-text and JSON formats carry `trace_id`, `span_id`, `trace_flags` fields; other structured formats follow the same key names.

#### Overview
[Source: logs/README.md]

**Tier 3.** Rationale and correlation model (resource context, execution context, time); collection paths for system, third-party, and first-party application logs. No requirements.

---

### 7.2 Logs API
[Source: logs/api.md]

#### LoggerProvider

- `GetLogger(name, version?, schema_url?, attributes?) -> Logger`
  - MUST return working Logger as fallback for null/empty name (not null, not exception); SHOULD log warning
- Global: `SetLoggerProvider(provider)`, `GetLoggerProvider() -> LoggerProvider`
- All methods MUST be documented as safe for concurrent use

#### Logger

**`Emit(LogRecord)`** — MUST support:
- Parameters API MUST accept: Timestamp, ObservedTimestamp, Context (explicit or current), SeverityNumber, SeverityText, Body, Attributes, EventName
- Parameters API MAY accept: Exception
- When implicit Context supported: Context SHOULD be optional; if unspecified MUST use current Context
- When only explicit Context supported: Context SHOULD be required

**`Enabled(context?, severity?, event_name?) -> bool`** — SHOULD support:
- "This API MUST return a language idiomatic boolean type"; true = Logger is enabled for provided arguments
- "The API documentation SHOULD state that calling `Enabled` is optional and is not required before emitting a `LogRecord`." It is a performance optimization for when constructing the LogRecord is expensive (e.g. body/attributes computed from a database fetch); inexpensive records can be emitted directly.
- "The documentation SHOULD also state that the returned value is not static and can change over time, so a cached value can become stale."

**All Logger methods MUST be documented as safe for concurrent use.**

#### No-op API
[Source: logs/noop.md]

**Tier 3.** No-op LoggerProvider returns a no-op Logger; no-op Logger's Emit does nothing and Enabled returns false.

---

### 7.3 Logs SDK
[Source: logs/sdk.md]

#### LoggerProvider (SDK)

- MUST implement Get a Logger API
- Configuration (LogRecordProcessors, LoggerConfigurator) MUST be owned by LoggerProvider
- If config updated, MUST apply to all already-returned Loggers
- `Shutdown()` — MUST be called only once; MUST invoke Shutdown on all LogRecordProcessors; MUST include effects of ForceFlush
- `ForceFlush()` — MUST invoke ForceFlush on all registered LogRecordProcessors

#### Logger (SDK)

**LoggerConfig [Development]:**
| Parameter | Type | Default | Rule |
|---|---|---|---|
| `enabled` | bool | true | If false, Logger MUST behave as No-op Logger |
| `minimum_severity` | SeverityNumber | 0 | If LogRecord's SeverityNumber specified (≠0) and < minimum_severity, MUST drop |
| `trace_based` | bool | false | "If `trace_based` is `false`, log records MUST NOT be affected because of this parameter." If true, "log records associated with unsampled traces MUST be dropped by the `Logger`" (valid SpanId + TraceFlags unsampled) |

**Emit processing:**
- If ObservedTimestamp unspecified, SHOULD set to current time
- If Exception provided, SDK MUST set attributes from exception per exception semantic conventions; user-provided attrs MUST take precedence (MUST NOT be overwritten)
- [Development] "Before processing a log record, the implementation MUST apply the filtering rules defined by the LoggerConfig", in order: (1) **Enabled** — if `LoggerConfig.enabled` is false, "the log record MUST be dropped"; (2) **Minimum severity** — SeverityNumber specified (≠0) and < `minimum_severity`, MUST drop; (3) **Trace-based** — `trace_based` true, SpanId present and SAMPLED flag unset, MUST drop. (At OLD the list had two rules and applied only "in case `Enabled` was not called"; NEW applies unconditionally and adds the Enabled rule.)

**Enabled MUST return false when:**
- No registered LogRecordProcessors
- Logger disabled (LoggerConfig.enabled=false) [Development]
- Provided severity specified (≠0) and < configured minimum_severity [Development]
- trace_based=true and current context is unsampled [Development]
- All registered processors implement Enabled AND all return false
- "Otherwise, it SHOULD return `true`. It MAY return `false` to support additional optimizations and features."

#### LogRecord Limits

| Config | Env var (specific) | Fallback env var | Default |
|---|---|---|---|
| AttributeCountLimit | `OTEL_LOGRECORD_ATTRIBUTE_COUNT_LIMIT` | `OTEL_ATTRIBUTE_COUNT_LIMIT` | 128 |
| AttributeValueLengthLimit | `OTEL_LOGRECORD_ATTRIBUTE_VALUE_LENGTH_LIMIT` | `OTEL_ATTRIBUTE_VALUE_LENGTH_LIMIT` | unlimited |
| AttributeValueDepthLimit (new) | none defined | none defined | 64 (common/README.md#configurable-parameters) |

- "`LogRecord` attributes MUST adhere to the common rules of attribute limits" (common/README.md#attribute-limits); length and depth limits do not apply to `LogRecord.Body`
- If SDK implements limits, MUST provide way to change per LoggerProvider config; `LogRecordLimits` example now includes `getAttributeValueDepthLimit()`
- Discard message SHOULD be printed; MUST be printed at most once per LogRecord

#### ReadableLogRecord / ReadWriteLogRecord

**ReadableLogRecord:** Access all info added to LogRecord; MUST access InstrumentationScope and Resource; trace context fields MUST be populated from resolved Context; dropped-attribute counts MUST be available to exporters.

**ReadWriteLogRecord (superset):** Additionally allows modifying Timestamp, ObservedTimestamp, SeverityText, SeverityNumber, Body, Attributes, TraceId, SpanId, TraceFlags, EventName. SDK MAY provide a deep-clone operation.

#### LogRecordProcessor

**Interface:**
- `OnEmit(logRecord, context)` — called synchronously on emit thread; SHOULD NOT block; logRecord mutations MUST be visible to next registered processors; processor MAY freely modify logRecord during OnEmit
- `Enabled(context?, scope?, severity?, event_name?) -> bool` (optional) — for filtering via Logger.Enabled; filtering logic in OnEmit and Enabled MAY differ
- `Shutdown() -> result` — MUST be called only once; MUST include effects of ForceFlush
- `ForceFlush() -> result` — if has associated exporter, MUST call Export with pending records then ForceFlush on exporter
- "Additional processors defined in this document SHOULD be provided by SDK packages."

**Built-in: SimpleLogRecordProcessor** — passes each record to exporter immediately; MUST synchronize Export calls.

**Built-in: BatchLogRecordProcessor** — MUST synchronize Export calls.
| Config | Env var | Default |
|---|---|---|
| maxQueueSize | `OTEL_BLRP_MAX_QUEUE_SIZE` | 2048 |
| scheduledDelayMillis | `OTEL_BLRP_SCHEDULE_DELAY` | 1000ms |
| exportTimeoutMillis | `OTEL_BLRP_EXPORT_TIMEOUT` | 30000ms |
| maxExportBatchSize | `OTEL_BLRP_MAX_EXPORT_BATCH_SIZE` | 512 (MUST be ≤ maxQueueSize) |

**Built-in: Event to span event bridge [Development]** (new) — converts Events to span events on the current span. "This processor SHOULD be provided by SDK."
- "The processor MUST bridge a `LogRecord` to a span event if and only if all of the following conditions are met": non-empty EventName; valid TraceId and SpanId; resolved Context has a current span whose `IsRecording` is true; LogRecord's TraceId/SpanId equal the current span's. "If any of these conditions is not met, the processor MUST do nothing."
- When bridged, "the processor MUST add exactly one span event": name MUST be the EventName; Timestamp if set MUST be the span event timestamp, otherwise ObservedTimestamp if set MUST be; all Attributes MUST be copied as span event attributes.
- "bridging a `LogRecord` to a span event MUST NOT prevent that `LogRecord` from continuing through the normal log processing pipeline."
- Configurable parameters: none.

#### LogRecordExporter

**Interface:**
- `Export(batch) -> ExportResult` — MUST NOT block indefinitely; result: Success or Failure
- `Shutdown() -> result` — SHOULD be called only once; subsequent Export SHOULD return Failure
- `ForceFlush() -> result`
- **Default SDK processors SHOULD NOT implement retry logic**

**Concurrency:** LoggerProvider (Logger creation, ForceFlush, Shutdown), Logger (all methods), LogRecordExporter (ForceFlush, Shutdown) MUST all be safe to call concurrently.

#### Self-observability [Development] (new)
[Source: logs/sdk.md#self-observability]

"The Logs SDK SHOULD support SDK self-observability" (self-observability.md).

---

### 7.4 Logs SDK Exporters
[Source: logs/sdk_exporters/stdout.md]

**Stdout Exporter:** For debugging/learning only; output format unspecified. By default SHOULD be paired with SimpleLogRecordProcessor (when auto-configured via `OTEL_LOGS_EXPORTER=console`).

### 7.5 Supplementary Guidelines
[Source: logs/supplementary-guidelines.md]

**Tier 2.** Bridge pattern: Log appender acquires Logger, calls Emit for records from existing logging framework. Implicit Context injection: rely on automatic propagation (e.g., MDC in Log4j). Explicit Context injection: end user captures Context and passes to logging subsystem. Logger name from logging library (e.g., Log4j logger name, Monolog channel name) SHOULD be used as InstrumentationScope name.
