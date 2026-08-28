# OpenTelemetry Specification: Metrics Signal

> MeterProvider, Meter, 7 Instrument Types, Bind, Views (independent/composable), Aggregation, Cardinality, Exemplars, MetricReader, MetricExporter

---

## 6. Metrics Signal

### 6.1 Metrics API
[Source: metrics/api.md]

#### MeterProvider

- `GetMeter(name, version?, schema_url?, attributes?) -> Meter`
  - MUST return working Meter as fallback (not null, not exception) for null/empty name; SHOULD log warning
- Global: `SetMeterProvider(provider)`, `GetMeterProvider() -> MeterProvider`
- All methods MUST be documented as safe for concurrent use

#### Meter

Creates instruments. MUST provide functions to create all 7 instrument types.

**Instrument naming rules (ABNF):**
```
instrument-name = ALPHA 0*254 ("_" / "." / "-" / "/" / ALPHA / DIGIT)
```
- Case-insensitive, ASCII, 1-255 characters, MUST start with letter
- Unit: optional, case-sensitive ASCII, max 63 chars
- Description: optional, MUST support BMP Unicode, min 1023 chars

**Instrument creation common parameters:**
- `name` (required)
- `unit` (optional, MUST NOT obligate)
- `description` (optional, MUST NOT obligate)
- `advisory` (optional, MUST NOT obligate — e.g., ExplicitBucketBoundaries for Histogram, Attributes list)

#### The 7 Instrument Types

| Instrument | Sync/Async | Measurement | API Method | Default Aggregation | Monotonic |
|---|---|---|---|---|---|
| Counter | Sync | non-negative delta | `Add(value, attrs?)` | Sum | Yes |
| UpDownCounter | Sync | any delta | `Add(value, attrs?)` | Sum | No |
| Histogram | Sync | any value | `Record(value, attrs?)` | ExplicitBucketHistogram | N/A |
| Gauge | Sync | current/instantaneous | `Record(value, attrs?)` | LastValue | N/A |
| ObservableCounter | Async | non-negative cumulative | `Observe(value, attrs?)` in callback | Sum | Yes |
| ObservableUpDownCounter | Async | any cumulative | `Observe(value, attrs?)` in callback | Sum | No |
| ObservableGauge | Async | any current value | `Observe(value, attrs?)` in callback | LastValue | N/A |

**Counter/UpDownCounter MUST NOT have API for creation other than via Meter** (same for all instrument types).

**Synchronous instruments:**
- API MUST allow flexible attributes at invocation time (dict/map or key-value args)
- SHOULD NOT return a value
- MUST accept variable number of attributes including none
- Counter `Add()`: increment value expected non-negative; SHOULD NOT validate, SHOULD document

**Asynchronous instruments (Callbacks):**
- MUST support creation by passing zero or more callbacks
- Every registered Callback MUST be evaluated exactly once per collection cycle
- Callbacks MUST be documented as: SHOULD be reentrant-safe; SHOULD NOT take indefinite time; SHOULD NOT make duplicate observations (multiple measurements with same attributes)
- API MUST treat observations from single Callback as logically at single instant — MUST report with identical timestamps
- User MUST be able to undo callback registration
- Multiple-instrument Callbacks MUST be associated with declared set of instruments at registration time

**Enabled() function (SHOULD support on sync instruments):**
- MUST return bool: true=enabled, false=disabled
- Value not static; can change over time

**Bind() function — Status: Development (sync instruments MAY provide):**
- "The `Bind` API associates a fixed set of Attributes with every measurement recorded on the returned bound instrument."
- "This API MUST be structured to accept a variable number of attributes, including none."
- "This API MUST return a language-idiomatic type representing the instrument bound to those attributes."
- "The returned bound instrument MUST support the instrument's core recording operation." Counter → `Add`, Histogram → `Record`, Gauge → `Record`, UpDownCounter → `Add`
- MAY be a dedicated bound type or reuse the instrument interface; if reused, "the `Bind` API MUST be documented to communicate to users that invoking attribute-bearing recording operations on the returned bound instrument negates the performance benefits of binding."

**Duplicate instrument registration:**
- If >1 instrument of same name created for same Meter with different identifying fields → warning SHOULD be emitted
- Meter MUST return functional instrument; SDKs MUST aggregate data from identical instruments together

**All Meter and Instrument methods MUST be documented as safe for concurrent use.**

---

### 6.2 Metrics SDK
[Source: metrics/sdk.md]

#### MeterProvider (SDK)

- MUST implement Get a Meter API
- Input MUST be used to create InstrumentationScope stored on Meter
- Configuration (MetricExporters, MetricReaders, Views, (Development) MeterConfigurator, (Development) `view_matching_mode`) MUST be owned by MeterProvider
- If config updated, MUST apply to all already-returned Meters
- `Shutdown()` — MUST be called only once; MUST invoke Shutdown on all MetricReaders and MetricExporters
- `ForceFlush()` — MUST invoke ForceFlush on all registered MetricReader instances

**View matching mode — Status: Development:**
- "A `MeterProvider` MAY accept a `view_matching_mode` parameter"; one that accepts it "MUST support the following values": `independent` (each matching View creates a separate stream) and `composable` (matching Views are merged)
- "If `view_matching_mode` is not specified, the SDK MUST use `independent`."
- "Any other value MUST be treated as unsupported." Then the SDK "MUST either fail fast during initialization ... or emit a warning, ignore the value, and use `independent`."

**Self-observability — Status: Development:** "The Metrics SDK SHOULD support SDK self-observability." [Source: self-observability.md]

#### View

- SDK MUST provide functionality to create Views and register them with MeterProvider
- SDK MUST accept Instrument selection criteria AND stream configuration as inputs

**Selection criteria (all optional, all additive — Instrument must match ALL provided):**
- `name` — exact match or wildcard (`*` matches all; SDK MUST support single `*` at minimum; `?` = single char)
- `type` — instrument kind
- `unit` — instrument unit
- `meter_name`, `meter_version`, `meter_schema_url`

**Stream configuration (all optional):**
- `name` — if set, View SHOULD select at most one instrument (ambiguous = warning). New: "The `name` provided via stream configuration is NOT REQUIRED to conform to the instrument name syntax, and the SDK MUST NOT validate it against that syntax."
- `description` — if not provided, use instrument's description
- `attribute_keys` — allow-list; all others MUST be ignored; if not provided, use Attributes advisory param or keep all. New: "SDK documentation SHOULD inform users that attributes excluded from a metric stream by View configuration may still be exported on Exemplars as filtered attributes, and describe how to disable or otherwise configure Exemplar sampling."
- `aggregation` — if not provided, use MetricReader's default aggregation for instrument kind
- `exemplar_reservoir` — factory for reservoir; if not provided, use MeterProvider default
- `aggregation_cardinality_limit` — if not provided, use MetricReader's default (or global default 2000)

**Measurement processing (Status: Mixed):**
- If no View registered → apply default aggregation per instrument kind per MetricReader; advisory params MUST be honored
- `independent` mode (or unspecified): for each matching View, apply its stream config independently (Views not merged); if conflicting metric identities result, "the implementation SHOULD apply the View and emit a warning"; if applying would produce semantic errors (e.g. async instrument with ExplicitBucketHistogram), "the implementation SHOULD emit a warning and proceed as if that View did not exist"
- `composable` mode (Development): group matching Views by configured stream `name` (Views leaving `name` unset join every group; no configured name → one group with the Instrument's default name); apply Views in registration order — for `name`, `description`, `aggregation`, `exemplar_reservoir`, `aggregation_cardinality_limit` "the last matching View that specifies that aspect wins"; `aggregation` is atomic, not merged; `attribute_keys` merge by logical AND (kept only if in all allow-lists and excluded by no exclude-list); a semantically invalid setting → "SHOULD emit a warning and use the next valid setting for that aspect from a preceding View in the same group, or the Instrument default"
- In both modes, if View(s) and advisory params conflict on same aspect → the View setting MUST take precedence
- If instrument doesn't match any View → SDK SHOULD enable using default aggregation and temporality

#### Aggregations

**SDK MUST provide:** Drop, Default, Sum, LastValue, ExplicitBucketHistogram
**SDK SHOULD provide:** Base2ExponentialBucketHistogram

**Default aggregation by instrument kind:**
| Instrument | Default Aggregation |
|---|---|
| Counter, AsyncCounter, UpDownCounter, AsyncUpDownCounter | Sum |
| Gauge, AsyncGauge | LastValue |
| Histogram | ExplicitBucketHistogram (with ExplicitBucketBoundaries advisory param if provided) |

**ExplicitBucketHistogram config:**
| Key | Default |
|---|---|
| Boundaries | `[0,5,10,25,50,75,100,250,500,750,1000,2500,5000,7500,10000]` |
| RecordMinMax | true |

**Base2ExponentialBucketHistogram config:**
| Key | Default |
|---|---|
| MaxSize | 160 (buckets per range) |
| MaxScale | 20 |
| RecordMinMax | true |

**Sum:** collects arithmetic sum; monotonicity determined by instrument type.
**LastValue:** collects last measurement + timestamp.
**Histograms:** collect count, sum (SHOULD NOT be collected for instruments that record negative measurements, e.g. UpDownCounter/ObservableGauge), min (optional), max (optional).
**Explicit buckets:** (lower, upper] inclusive; `-∞` to first boundary; last boundary to `+∞`.
**Drop:** discards all measurements.

**Start timestamps (cumulative):** sync instruments SHOULD use the time of the first measurement for the series; async instruments SHOULD use the instrument creation time if first observed in the first collection interval, otherwise the prior collection interval's timestamp.

#### Cardinality Limits (Status: Stable)

Default: **2000** data points per instrument per collection cycle. "SDKs SHOULD support being configured with a cardinality limit." "Cardinality limit enforcement SHOULD occur _after_ attribute filtering, if any."

**Priority order (each SHOULD be used when defined):**
1. View's `aggregation_cardinality_limit`
2. MetricReader's default cardinality limit for instrument kind
3. Global default (2000)

**Overflow attribute set:** `{otel.metric.overflow=true}`
- "The SDK MUST create an Aggregator with the overflow attribute set prior to reaching the cardinality limit and use it to aggregate Measurements for which the correct Aggregator could not be created."
- "The SDK MUST provide the guarantee that overflow would not happen if the maximum number of distinct, non-overflow attribute sets is less than or equal to the limit."

**Cumulative temporality (sync):** aggregators "MUST continue to export all attribute sets that were observed prior to the beginning of overflow."
**Delta temporality (sync):** "MAY choose an arbitrary subset of attribute sets to output to maintain the stated cardinality limit."
**Async instruments:** "SHOULD prefer the first-observed attributes in the callback when limiting cardinality, regardless of temporality."
**"Measurements MUST NOT be double-counted or dropped during an overflow."**

#### Instrument Bind (SDK) — Status: Development

- "A bound instrument MUST behave identically to calling the equivalent unbound recording operation with the pre-bound Attributes on each measurement."
- "Attribute processing and cardinality limit evaluation MUST be performed at bind time. Each call to `Bind` MUST be independently evaluated against the cardinality state at that moment." Identical attributes bound twice may resolve to different aggregators (one concrete, one overflow). "The resolved aggregator MUST be fixed and not change across collection cycles."
- "Measurements recorded on a bound instrument MUST be candidates for Exemplar sampling." The Context of each recording "MUST be used for exemplar TraceBased filtering and passed to the ExemplarReservoir offer method."
- "The SDK MUST ensure attribute-free recordings on a bound instrument bypass per-recording map lookup."

#### Exemplars

`OTEL_METRICS_EXEMPLAR_FILTER` (default: `trace_based`): `trace_based` | `always_on` | `always_off` [Source: configuration/sdk-environment-variables.md]

Exemplars "preserve attributes that are dropped during aggregation (e.g. by View configuration), regardless of instrument type (including asynchronous instruments)." Trace ID and span ID are attached "for synchronous instruments" only.

**ExemplarFilter built-ins:**
- `AlwaysOn` — all measurements sampled
- `AlwaysOff` — no measurements sampled
- `TraceBased` (default) — only measurements associated with sampled trace span

**ExemplarReservoir:**
- "MUST provide a method to offer measurements to the reservoir and another to collect accumulated Exemplars"
- "A new `ExemplarReservoir` MUST be created for every known timeseries data point"
- MUST be cleared/reset during collection before reading
- `collect()` MUST return accumulated Exemplars
- MUST retain attributes available in measurement that filter did not exclude
- All methods MUST be safe to be called concurrently

**Built-in reservoirs:**
1. `SimpleFixedSizeExemplarReservoir` — uniformly-weighted sampling; default size: 1 for LastValue/Sum; count of histogram buckets for Histogram
2. `AlignedHistogramBucketExemplarReservoir` — at most one Exemplar per histogram bucket

SDK MUST provide mechanism for custom ExemplarReservoir; MUST be configurable on metric View.

#### MetricReader

**Interface:**
- `Collect(exporter) -> MetricCollection`
- `Shutdown() -> result`
- `ForceFlush() -> result`

**Temporality:**
- Default: CUMULATIVE for all instrument kinds
- Reader configures temporality preference (cumulative or delta) per instrument kind
- `Collect` MUST return data per reader's temporality preference
- Successive Collect calls MUST repeat same Cumulative data points OR advance start timestamp for Delta

**SDK MUST support multiple MetricReader instances.** A MetricReader MUST NOT be registered on >1 MeterProvider.

**Built-in: PeriodicExportingMetricReader**
| Config | Env var | Default |
|---|---|---|
| exportIntervalMillis (interval between collections) | `OTEL_METRIC_EXPORT_INTERVAL` | 60000ms |
| exportTimeoutMillis (per `Export(batch)` call when batching) | `OTEL_METRIC_EXPORT_TIMEOUT` | 30000ms |
| maxExportBatchSize (Development) | — | unset |

- `maxExportBatchSize` (Development): when configured, "the reader MUST ensure no batch provided to `Export` exceeds the `maxExportBatchSize` by splitting"; "The initial batch of metric data MUST be split into as many "full" batches of size `maxExportBatchSize` as possible -- even if this splits up data points that belong to the same metric into different batches."; batches from one `Collect()` MUST be provided to `Export` serially and in-order before the next `Collect()`'s data; "The reader MUST NOT combine metrics from different `Collect()` calls into the same batch provided to `Export`."
- "The reader MUST synchronize calls to `MetricExporter`'s `Export` to make sure that they are not invoked concurrently. If an export is still in progress when the next scheduled interval occurs, the reader MUST either delay the subsequent collection and export until the in-progress export finishes, or skip the scheduled collection for that interval."
- `ForceFlush` SHOULD collect, split into batches if necessary, call `Export(batch)` on each serially, then call exporter `ForceFlush()`; MAY skip `Export(batch)` if the timeout has expired but SHOULD still call exporter `ForceFlush()`; SHOULD return ERROR if any `Export(batch)` or exporter `ForceFlush()` fails or times out, else NO ERROR.

#### MetricExporter (Push)

**Interface:**
- `Export(metrics) -> ExportResult` — MUST NOT block indefinitely; `ExportResult`: Success, FailedNotRetryable, FailedRetryable
- `ForceFlush(timeout) -> result`
- `Shutdown(timeout) -> result`
- `Temporality(instrument_kind) -> temporality`
- `DefaultAggregation(instrument_kind) -> aggregation`

**Concurrency:** ForceFlush and Shutdown MUST be safe to call concurrently.

#### Metric Attribute Limits

| Config | Env var (specific) | Fallback env var | Default |
|---|---|---|---|
| AttributeCountLimit | `OTEL_METRIC_ATTRIBUTE_COUNT_LIMIT` | `OTEL_ATTRIBUTE_COUNT_LIMIT` | 128 |
| AttributeValueLengthLimit | `OTEL_METRIC_ATTRIBUTE_VALUE_LENGTH_LIMIT` | `OTEL_ATTRIBUTE_VALUE_LENGTH_LIMIT` | unlimited |

---

### 6.3 Metrics Data Model
[Source: metrics/data-model.md]

**Tier 2.** Five point types: Sum (arithmetic sum with monotonicity + temporality; each data point carries a numeric value that is a delta or cumulative sum per the temporality), Gauge (last observed value, no temporality), Histogram (explicit bucket distribution), ExponentialHistogram (base-2 auto-scaling buckets, MaxSize=160 default), Summary (quantiles; not recommended for new systems). Temporality: CUMULATIVE (start time = first observation or epoch), DELTA (start time = previous collection). Each timeseries MUST have one logical writer. Bucket inclusivity: (lower, upper] — measurement falls into greatest-numbered bucket with boundary ≥ measurement. ExponentialHistogram uses scale integer for resolution; zero_count + zero_threshold for near-zero values; producers SHOULD keep bucket indexes within a signed 32-bit integer; consumers SHOULD reject data whose scale/indexes overflow the IEEE double representation.

---

### 6.4 Metrics SDK Exporters
[Source: metrics/sdk_exporters/]

#### OTLP Exporter [metrics/sdk_exporters/otlp.md] — Status: Stable
- MUST provide temporality configuration (default: Cumulative for all instrument kinds)
- MUST configure per `OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE`:
  - `cumulative` (default): Cumulative for all
  - `delta`: Delta for Counter/AsyncCounter/Histogram; Cumulative for UpDownCounter/AsyncUpDownCounter
  - `lowmemory`: Delta for sync Counter/Histogram; Cumulative for others
- MUST configure per `OTEL_EXPORTER_OTLP_METRICS_DEFAULT_HISTOGRAM_AGGREGATION`: `explicit_bucket_histogram` (default) | `base2_exponential_bucket_histogram`
- When auto-configured, MUST pair with PeriodicExportingMetricReader

#### Prometheus Exporter [metrics/sdk_exporters/prometheus.md] — Status: Mixed (per-section)
- (Development) MUST be Pull Metric Exporter responding to HTTP requests
- (Development) MUST convert OTel metrics per Prometheus Compatibility spec [Source: compatibility/prometheus_and_openmetrics.md]
- (Stable) "SHOULD use an official Prometheus client library when one exists for the implementation language and it is practical to do so ... it SHOULD NOT use an unofficial Prometheus client library"; if used, SHOULD be modeled as a custom Collector
- (Stable) MUST support text format version 0.0.4; MAY support Exemplars and Exponential Histograms via other protocols
- MUST NOT use Prometheus Remote Write format or OpenMetrics protobuf format
- "SHOULD NOT add explicit timestamps on Metric points" (was MUST NOT)
- (Stable) MUST have at most one `target` info metric; MUST set MetricReader temporality as CUMULATIVE for all instrument kinds
- (Stable) Config: `host` (MUST default `localhost`), `port` (MUST default 9464), `default_aggregation` (MUST use the SDK default aggregation by default)
- (Development) Resource attributes as labels: MAY offer; "By default, it MUST NOT add any resource attributes as metric labels"; copied attributes MUST NOT be excluded from `target_info`; option SHOULD be named `resource_constant_labels` (was MAY be `with_resource_constant_labels`)
- (Development) `translation_strategy` (MUST be named to resemble it) — options MUST be: `UnderscoreEscapingWithSuffixes` (default), `UnderscoreEscapingWithoutSuffixes`, `NoUTF8EscapingWithSuffixes`, `NoTranslation`
- (Stable) `scope_info_enabled` MAY be the option name, MUST be `true` by default (replaces `without_scope_info=false`)
- (Development) `target_info_enabled` MAY be the option name, MUST be `true` by default (replaces `without_target_info=false`)
- (Stable) Content negotiation: MUST support per `Accept` header, MUST follow Prometheus Content Negotiation guidelines; "If no `Accept` header is provided and no fallback protocol is configured, the exporter MUST use Prometheus text format 0.0.4 (`text/plain; version=0.0.4`) and apply `underscores` escaping."
- (Stable) Interaction: "First, `translation_strategy` MUST be applied to construct metric names. Then, the Prometheus Exporter MUST apply content negotiation", which may re-escape names; e.g. counter `foo.bar` unit `By` with `NoTranslation` → `foo_bar` under `escaping=underscores`, `foo.bar` under `escaping=allow-utf-8`; `NoUTF8EscapingWithSuffixes` → `foo_bar_bytes_total` / `foo.bar_bytes_total`

#### Stdout Exporter [metrics/sdk_exporters/stdout.md] — Status: Stable
- Output format unspecified; SHOULD warn users it's for debugging only
- Default temporality: Cumulative; when auto-configured, pairs with PeriodicExportingMetricReader (default interval: 10000ms)

#### In-Memory Exporter [metrics/sdk_exporters/in-memory.md] — Status: Stable
- Accumulates metrics in local memory; useful for unit tests
- Default temporality: Cumulative; when auto-configured, pairs with PeriodicExportingMetricReader
