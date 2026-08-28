# OpenTelemetry Specification: Traces Signal

> TracerProvider, Tracer, Span, SpanContext, Sampling, SpanProcessor, SpanExporter, IdGenerator

---

## 5. Traces Signal

### 5.1 Trace API
[Source: trace/api.md]

#### TracerProvider

- `GetTracer(name, version?, schema_url?, attributes?) -> Tracer`
  - MUST return working Tracer as fallback (not null, not exception) even for null/empty name; SHOULD log warning
  - Implementations MUST NOT require users to repeatedly obtain Tracer with same identity to pick up config changes
- Implementations of `TracerProvider` SHOULD allow creating an arbitrary number of `TracerProvider` instances
- Global: `SetTracerProvider(provider)`, `GetTracerProvider() -> TracerProvider`

#### Tracer

- `StartSpan(name, kind?, attributes?, links?, start_time?, parent_context?) -> Span`
  - MUST NOT accept Span or SpanContext as parent — only full Context
  - Span creation MUST NOT set newly created Span as active in current Context by default
  - All Spans MUST be created via Tracer — MUST NOT be any other API for creating Spans
- `Enabled() -> bool` (Stable as of NEW commit; no longer marked Development) — "a `Tracer` SHOULD provide this `Enabled` API"; "the API MUST be structured in a way for parameters to be added"; "This API MUST return a language idiomatic boolean type"; returned value is not static and instrumentation SHOULD be documented to call it on each use

#### Span

**SpanContext (immutable):**
- `TraceId` — 16-byte array; valid if at least one non-zero byte
- `SpanId` — 8-byte array; valid if at least one non-zero byte
- `TraceFlags` — 1 byte; bit 0 = Sampled flag; bit 1 = Random flag (W3C Level 2)
- `TraceState` — W3C tracestate key-value pairs
- `IsRemote` — bool; MUST be true when extracted via Propagators; MUST be false for child spans
- `IsValid` — true if TraceId != 0 AND SpanId != 0
- Hex form: TraceId MUST be 32-hex lowercase string; SpanId MUST be 16-hex lowercase string
- TraceState: API MUST provide get / add / update / delete of key-value pairs; "All mutating operations MUST return a new `TraceState`"; input MUST be validated; MUST NOT return invalid data

**SpanKind:**
| Kind | Description |
|---|---|
| `INTERNAL` (default) | Internal operation within application |
| `SERVER` | Server-side handling of remote request |
| `CLIENT` | Outgoing request to remote service, awaits response |
| `PRODUCER` | Initiates operation; does not wait for outcome |
| `CONSUMER` | Processes operation initiated by PRODUCER |

**Span operations (MUST NOT be called after End, except GetContext and IsRecording):**

- `GetContext() -> SpanContext` — MUST return same SpanContext for Span lifetime; MAY be called after End
- `IsRecording() -> bool` — true means events/attributes are being captured; SHOULD return false after End
- `SetAttribute(key, value)` — duplicate key SHOULD overwrite; API documentation MUST state adding attributes at creation preferred
- `AddEvent(name, attrs?, timestamp?)` — timestamp defaults to current time; events SHOULD preserve order
- `AddLink(spanContext, attrs?)` — Links added after creation may not be considered by Samplers
- `SetStatus(code, description?)` — StatusCodes: `Unset` (default), `Ok`, `Error`; Description MUST only be used with Error; Description MUST be IGNORED for Ok and Unset; Ok MUST override any prior or future Error/Unset attempts; SHOULD remain Unset unless error occurred
- `UpdateName(name)`
- `End(end_time?)` — if omitted, MUST use current time; MUST NOT block on calling thread; MUST NOT affect child spans; MUST NOT deactivate Span in any Context
- `RecordException(exception, attrs?, escaped?)` — MUST record as Event named `"exception"` with attributes per exceptions semantic conventions

**Parent determination:**
- Parent comes from Context passed to StartSpan; if no Span in Context → root span
- Each root span MUST get new TraceId; child spans inherit parent TraceId
- Child span MUST inherit all TraceState values of parent by default
- Remote parent (from propagation): IsRemote MUST be true

**Links:**
- SpanContext + zero or more Attributes
- MUST record links with empty TraceId/SpanId if attributes or TraceState non-empty
- API documentation MUST state adding links at creation preferred (head sampler can only see creation-time info)

**Events:**
- name (string) + timestamp + attributes + dropped_attributes_count

**Status order:** Ok > Error > Unset

**Concurrency:** All TracerProvider, Tracer, and Span methods MUST be documented as safe for concurrent use.

#### No-Op / Non-Recording Spans

- `NonRecordingSpan` wraps SpanContext: `GetContext()` returns wrapped context; `IsRecording()` MUST return false; all operations are no-ops
- MUST be fully implemented in API; SHOULD NOT be overridable
- Empty non-recording Span MUST be returned when parent Context contains no Span

---

### 5.2 Trace SDK
[Source: trace/sdk.md]

#### TracerProvider (SDK)

- MUST implement Get a Tracer API
- Input MUST be used to create InstrumentationScope stored on Tracer
- Configuration (SpanProcessors, IdGenerator, SpanLimits, Sampler) MUST be owned by TracerProvider
- If config updated (e.g., adding SpanProcessor), MUST apply to all already-returned Tracers
- `Shutdown()` — MUST be called only once; subsequent Tracer gets return no-op; MUST invoke Shutdown on all SpanProcessors
- `ForceFlush()` — MUST invoke ForceFlush on all registered SpanProcessors
- `TracerConfigurator` / `TracerConfig.enabled` [Development] — disables a Tracer by scope

#### Tracer Enabled (SDK)

- "`Enabled` MUST return `false` when either: there are no registered `SpanProcessors`, [Development] `Tracer` is disabled (`TracerConfig.enabled` is `false`)."
- "Otherwise, it SHOULD return `true`. It MAY return `false` to support additional optimizations and features."
- The no-processors clause is Stable at NEW; only the `TracerConfig` clause remains Development

#### Sampling

**SamplerInterface:**
- `ShouldSample(context, traceId, name, kind, attrs, links) -> SamplingResult`
- `GetDescription() -> string`

**SamplingResult:**
- `Decision`: `DROP` | `RECORD_ONLY` | `RECORD_AND_SAMPLE`
- `Attributes`: added to Span
- `Tracestate`: for new SpanContext

**Decision semantics:**
| Decision | IsRecording | Sampled Flag | SpanProcessor receives | SpanExporter receives |
|---|---|---|---|---|
| DROP | false | false | no | no |
| RECORD_ONLY | true | false | yes | no |
| RECORD_AND_SAMPLE | true | true | yes | yes |

**SDK MUST NOT allow `SampledFlag=true` with `IsRecording=false`.**

**SDK Span creation order:**
1. Determine/generate TraceId (before calling ShouldSample)
2. Call ShouldSample
3. Generate new SpanId (always, independent of sampling decision)
4. Create Span based on decision

**Built-in samplers:**

| Sampler | Env var value | Behavior |
|---|---|---|
| `AlwaysOn` | `always_on` | Always RECORD_AND_SAMPLE; Description: "AlwaysOnSampler" |
| `AlwaysOff` | `always_off` | Always DROP; Description: "AlwaysOffSampler" |
| `TraceIdRatioBased(ratio)` | `traceidratio` | Deterministic hash of TraceId; Description: "TraceIdRatioBased{RATIO}" |
| `ParentBased(root, ...)` | `parentbased_always_on` etc. | Delegates to sub-sampler based on parent context |
| `ProbabilitySampler(ratio)` [Development] | — | W3C Level 2 56-bit consistent sampling: "MUST ignore the parent `SampledFlag`"; keep when `R >= T`; on keep, TraceState SHOULD include `th:T`; ratio range `2^-56` to 1.0 |
| `JaegerRemoteSampler` | — | Periodically loads sampling config from a Jaeger backend |
| `AlwaysRecord(root)` (Stable at NEW; was Development) | — | Decorator: "MUST behave as follows": DROP → RECORD_ONLY; RECORD_ONLY → RECORD_ONLY; RECORD_AND_SAMPLE → RECORD_AND_SAMPLE |
| `CompositeSampler(ComposableSampler)` [Development] | — | See below |

**ParentBased delegates:**
| Parent | IsRemote | IsSampled | Delegate |
|---|---|---|---|
| absent | n/a | n/a | `root` |
| present | true | true | `remoteParentSampled` (default: AlwaysOn) |
| present | true | false | `remoteParentNotSampled` (default: AlwaysOff) |
| present | false | true | `localParentSampled` (default: AlwaysOn) |
| present | false | false | `localParentNotSampled` (default: AlwaysOff) |

**Env vars:**
- `OTEL_TRACES_SAMPLER` (default: `parentbased_always_on`)
- `OTEL_TRACES_SAMPLER_ARG` — only used when sampler is set; invalid/unrecognized MUST be logged and ignored

**TraceIdRatioBased:** MUST be deterministic (same TraceId always same decision, independent of language/time). MUST also sample all traces that lower-ratio sampler would sample.

**CompositeSampler / ComposableSampler [Development]** (Tier 2): `CompositeSampler` implements `Sampler` and delegates to a `ComposableSampler.GetSamplingIntent(...)`, which takes all `ShouldSample` parameters except `traceId` and returns a `SamplingIntent` of `threshold`, `adjusted_count_reliable` (renamed from `threshold_reliable` at NEW), `attributes_provider`, `trace_state_provider`. NEW spells out the decision procedure: a `null` threshold means `DROP`; otherwise R is read from TraceState/TraceId when `adjusted_count_reliable` is true, or freshly generated as a 56-bit random value when false; the decision compares threshold with R per the tracestate-probability-sampling decision algorithm; on a positive decision with `adjusted_count_reliable` true the `ot` `th` value is set to the threshold, otherwise `th` is removed. "ComposableSamplers MUST NOT modify the OpenTelemetry TraceState (i.e., the `ot` sub-key of TraceState)"; "explicit randomness values MUST not be modified". Built-ins: `ComposableAlwaysOn` (threshold 0, reliable true), `ComposableAlwaysOff` (no threshold, reliable false), `ComposableProbability(ratio)`, `ComposableParentThreshold(root)`, `ComposableRuleBased`, `ComposableAnnotating`.

**Sampling randomness [Development]:** for root contexts the SDK SHOULD generate TraceIds meeting W3C Level 2 randomness and SHOULD set the `Random` trace flag; "SDKs and Samplers MUST NOT overwrite explicit randomness in an OpenTelemetry TraceState value"; root samplers MAY insert an `rv` value when the Random flag is unset and `rv` is absent.

#### Span Limits

| Config | Env var | Default |
|---|---|---|
| AttributeCountLimit | `OTEL_SPAN_ATTRIBUTE_COUNT_LIMIT` | 128 |
| AttributeValueLengthLimit | `OTEL_SPAN_ATTRIBUTE_VALUE_LENGTH_LIMIT` | unlimited |
| EventCountLimit | `OTEL_SPAN_EVENT_COUNT_LIMIT` | 128 |
| LinkCountLimit | `OTEL_SPAN_LINK_COUNT_LIMIT` | 128 |
| AttributePerEventCountLimit | `OTEL_EVENT_ATTRIBUTE_COUNT_LIMIT` | 128 |
| AttributePerLinkCountLimit | `OTEL_LINK_ATTRIBUTE_COUNT_LIMIT` | 128 |

- Span attributes MUST adhere to the common attribute-limit rules (`common/README.md#attribute-limits`); the Java `SpanLimits` example now also lists `getAttributeValueDepthLimit()` (no trace-specific env var given in sdk.md)
- If SDK implements limits, MUST provide way to change programmatically
- Discard message MUST be logged at most once per Span (not per discarded item)

#### IdGenerator

- SDK MUST by default randomly generate both TraceId and SpanId (crypto-secure)
- SDK MUST provide mechanism for customizing ID generation
- "Additional `IdGenerator` implementing vendor-specific protocols such as AWS X-Ray trace ID generator MUST NOT be maintained or distributed as part of the OpenTelemetry Core packages" (`overview.md#core-packages`)

#### SpanProcessor

**Interface:**
- `OnStart(span, parentContext)` — called synchronously on span creation thread; SHOULD NOT block
- `OnEnding(span)` [Development] — called during End(); span still mutable; end timestamp already set
- `OnEnd(readableSpan)` — called synchronously after End(); span immutable
- `Shutdown() -> result` — MUST be called only once; MUST include effects of ForceFlush
- `ForceFlush() -> result` — MUST prioritize timeout over completeness

**Registration order:** processors invoked in registration order; SDK MUST allow each pipeline to end with individual exporter.

**Built-in: SimpleSpanProcessor**
- Passes each finished span to exporter immediately
- MUST synchronize Export calls (no concurrent invocation)

**Built-in: BatchSpanProcessor**
- MUST synchronize Export calls
- Config:

| Config | Env var | Default |
|---|---|---|
| maxQueueSize | `OTEL_BSP_MAX_QUEUE_SIZE` | 2048 |
| scheduledDelayMillis | `OTEL_BSP_SCHEDULE_DELAY` | 5000ms |
| exportTimeoutMillis | `OTEL_BSP_EXPORT_TIMEOUT` | 30000ms |
| maxExportBatchSize | `OTEL_BSP_MAX_EXPORT_BATCH_SIZE` | 512 (MUST be ≤ maxQueueSize) |

#### SpanExporter

**Interface:**
- `Export(batch) -> ExportResult` — MUST NOT block indefinitely; result: `Success` or `Failure`
- `Shutdown() -> result` — MUST be called only once; subsequent Export SHOULD return Failure
- `ForceFlush() -> result`

**Concurrency:** ForceFlush and Shutdown MUST be safe to call concurrently.

**Default SDK processors SHOULD NOT implement retry logic** — that's the exporter's responsibility.

#### Self-observability [Development] (new at NEW)

- "The Tracing SDK SHOULD support SDK self-observability" (`self-observability.md`)

---

### 5.3 Trace SDK Exporters
[Source: trace/sdk_exporters/stdout.md, trace/sdk_exporters/zipkin.md]

#### Stdout Exporter
- Intended for debugging/learning; NOT for production
- Output format unspecified and may change
- By default SHOULD be paired with SimpleSpanProcessor (when auto-configured via `OTEL_TRACES_EXPORTER=console`)

#### Zipkin Exporter (Deprecated)
- **Status: Deprecated.** Support removed December 2026. Existing exporters MUST be supported for at least 1 year after deprecation per SDK stability guarantees.
- Key mappings: `service.name` resource attr → Zipkin `localEndpoint.serviceName`; SpanKind.INTERNAL → null (omit kind); timestamps in microseconds (MUST convert from nanoseconds); Status: `otel.status_code` tag (OK or ERROR only, never UNSET); error description → `error` tag
- SpanKind.CLIENT/PRODUCER SHOULD set `remoteEndpoint` (prefer `peer.service` > `server.address` > network attrs)

### 5.4 Exception Recording
[Source: trace/exceptions.md]

- "An exception SHOULD be recorded as an `Event` on the span during which it occurred if and only if it remains unhandled when the span ends and causes the span status to be set to ERROR."
- "The name of the event MUST be `"exception"`."
- Recommended attributes: `exception.type`, `exception.message`, `exception.stacktrace`; [Development] cross-signal error reporting defers to semantic-conventions docs/general/recording-errors.md (semantic-conventions repository, not the spec)
- `RecordException()` MUST record as event with conventions from exceptions semantic conventions

### 5.5 OpenTelemetry TraceState Handling
[Source: trace/tracestate-handling.md]

- OTel values in W3C `tracestate` "MUST all be contained in a single entry using the `ot` key", value = `;`-separated `key:value` list (e.g. `ot=th:c;rv:...`)
- "The complete list length MUST NOT exceed 256 characters"; "the used keys MUST be unique"
- "Instrumentation libraries and clients MUST NOT use this entry, and they MUST instead use their own entry"
- Sub-keys "MUST be defined as part of the Specification"; set values "MUST be either updated or added to the `ot` entry"
- `th` (sampling threshold): 1-14 lowercase hex digits, right-padded with zeros to 14 digits = 56-bit rejection threshold; `th:0` = 100% sampling; `Probability = (2^56 - Threshold) / 2^56`; `AdjustedCount = 2^56 / (2^56 - Threshold)`; e.g. `th:c` = 25%
- `rv` (explicit randomness): "MUST be exactly 14 lower-case hexadecimal digits"; "SHOULD NOT be erased from the OpenTelemetry TraceState or modified once associated with a new TraceID"

### 5.6 TraceState Probability Sampling [Development]
[Source: trace/tracestate-probability-sampling.md]

Consistent probability sampling compares a 56-bit randomness value `R` (the `rv` sub-key, else the least-significant 56 bits of a W3C Level 2 random TraceId) against a 56-bit rejection threshold `T = (1 - probability) * 2^56`: "If `R` >= `T`, keep the span, else drop the span"; both values "MUST be present". Stages that change the effective threshold must re-encode `th`; stages with unknown probability (including parent-based samplers without a parent threshold) must erase `th`; a propagated `rv` must be carried unchanged. The file also gives the threshold-precision algorithm (4 hex digits recommended by default), the 1-in-N threshold table, and threshold-to-probability / adjusted-count conversions.
