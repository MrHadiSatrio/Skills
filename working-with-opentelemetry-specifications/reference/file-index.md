# OpenTelemetry Specification: Compatibility, Lower-Priority Areas & File Index

<!-- lint:external-paths -->

> Compatibility shims, lower-priority signals, and the complete index of all 91 spec files.
> Every path in this file points into the UPSTREAM spec's `specification/` directory — resolve them with the retrieval recipe in this skill's SKILL.md, not on local disk.

---

## 10. Compatibility

### 10.1 OpenTracing Shim
[Source: compatibility/opentracing.md]

**Tier 2. Status: Deprecated** (as of March 2026; removal no earlier than March 2027). "Existing OpenTracing shims MAY continue to be supported for backwards compatibility, but implementing new OpenTracing compatibility is not required by this specification." The shim "MUST NOT publicly expose any upstream OpenTelemetry API"; the former requirement that it live in its own Shim Layer is now historical. Mapping retained for migration guidance: OpenTracing span references become OTel span links with reference type as attribute; `error=true` tag → StatusCode Error, `error=false` → Ok, absent → Unset; log operations → span events. "Semantic convention mapping SHOULD NOT be performed, with the exception of error mapping." Not recommended when OpenTracing code consumes baggage or mixes implicit/explicit context support.

### 10.2 OpenCensus Bridge
[Source: compatibility/opencensus.md]

**Tier 2. Status: Deprecated** (as of June 2026; removal no earlier than June 2027). "Existing OpenCensus shims MAY continue to be supported for backwards compatibility, but implementing new OpenCensus compatibility is not required by this specification." The bridge implements the OpenCensus Trace API on OTel so all OpenCensus spans flow through an OTel Tracer, preserving parent-child across both APIs ("OTel sandwich"). Known incompatibilities: parent spans must be specified at creation time; links added post-creation not supported; samplers are per-provider not per-span; trace flags only support the sampled flag.

### 10.3 Prometheus & OpenMetrics Mapping
[Source: compatibility/prometheus_and_openmetrics.md]

**Tier 2. Status: Mixed** (per-section; Prometheus→OTLP direction is Development overall, most subsections Stable). "Prometheus" here means the union of text exposition, Prometheus protobuf, OpenMetrics text/proto, and Remote Write formats. Where a feature is unsupported by a format: "Exemplars MUST be dropped if they are not supported"; Info → Gauge with `_info` suffix; StateSet → Gauge; native histograms "SHOULD be dropped if they are not supported, or MAY be converted to fixed-bucket histograms".

**Prometheus → OTLP.** Metric name MUST become the OTLP name unaltered; UNIT MUST be converted to UCUM via the fixed word→abbreviation table (e.g. `seconds`→`s`, `bytes`→`By`, `percent`→`%`); HELP → description; TYPE MUST select the data type and "MUST also be added to the OTLP metric.metadata under the `prometheus.type` key". Start (Created) timestamp MUST become the OTLP start timestamp, otherwise unset; scrapes without an explicit timestamp MUST use scrape time. Counter → monotonic Sum; Gauge → Gauge; Info and StateSet → Non-Monotonic Sum (Development); Unknown → Gauge (Development); Histogram → Histogram (+Inf bound dropped; drop metric if `_count` absent, unset sum if `_sum` absent); Summary → Summary (drop if `_count` absent; sum set to zero if `_sum` absent). Native Histograms (Stable): standard schema [-4, 8], integer counter flavor → Exponential Histogram (offset = first span offset minus 1; overflow buckets MUST be dropped); NHCB schema -53 → OTLP Histogram with `CustomValues` as bounds; "Native histograms of the float or gauge flavors MUST be dropped"; schemas outside the range and not -53 MUST be dropped. GaugeHistogram and Native GaugeHistogram MUST be dropped. Exemplar `trace_id`/`span_id` labels MUST map to Trace/Span ID when valid; other labels become filtered attributes. `otel_scope_*` labels MUST be dropped from points and used as scope name/version/schema URL/attributes; metrics without them MUST get a scope identifying the translator. `service.name` and `service.instance.id` MUST be resource attributes (default instance id `<host>:<port>`); `server.address`, `server.port`, `url.scheme` SHOULD be; the `target` info metric MUST be dropped and its labels MUST become resource attributes with keys unaltered.

**OTLP → Prometheus.** Exporters MUST NOT emit duplicate UNIT/HELP/TYPE for one name; MUST drop whole metrics on TYPE conflict but SHOULD NOT drop points on UNIT/HELP conflict. Discouraged name characters SHOULD become `_`, runs collapsed. Unit: UCUM → word via the same table; bracketed portions MUST be dropped; rates MUST become words (`meters_per_second`); a unit suffix SHOULD be added before type suffixes. Scope MUST be emitted as `otel_scope_name`, `otel_scope_version`, `otel_scope_schema_url`, and `otel_scope_<attr>` labels; scope attributes that would collide with those three MUST be dropped. Gauge conversion follows the `prometheus.type` metadata hint (absent/`gauge` → Gauge; `unkown` [sic] → Unknown; `info` SHOULD → Info; `stateset` SHOULD → StateSet); Gauge exemplars SHOULD be dropped. Cumulative monotonic Sum MUST → Counter (`_total` suffix SHOULD be added unless present); cumulative non-monotonic follows the Gauge rules; delta monotonic MAY be accumulated. Cumulative Histogram MUST → Prometheus Histogram by default; users may opt in (Development) to NHCB (Remote-Write 2.0+ only; schema -53, `ResetHint` UNKNOWN, `+Inf` MUST NOT be written into `CustomValues`); delta Histograms MAY be accumulated "or MUST be dropped". Exponential Histogram (Development) → Native Histogram: `ResetHint` MUST be UNKNOWN; scale > 8 SHOULD be downscaled, scale < -4 MUST be dropped; default `ZeroThreshold` 1e-128; `NoRecordedValue` marks staleness (Sum = Stale NaN, Count 0); bucket index of array position `i` is `Offset + i + 1`. Summary → Summary with stringified `quantile` labels; exemplars SHOULD be dropped. Attributes MUST become labels, non-strings stringified per `common/README.md`; colliding keys' values MUST be concatenated with `;` ordered by original key. Exemplar conversion: Trace/Span ID MUST become `trace_id`/`span_id` labels taking precedence over `filtered_attributes`; timestamps MUST carry; `filtered_attributes` MUST become labels unless exceeding protocol limits (OpenMetrics 1.0: 128 characters). Resource SHOULD become a `target` info metric (labels MUST be exactly the resource attributes); in Collector exporters, `job` MUST be `<service.namespace>/<service.name>` (or `<service.name>`) and `service.instance.id` MUST become `instance`, with at most one `target` per `job`+`instance`; where info type is unsupported, a gauge `target_info` with value 1 MUST be used.

### 10.4 Trace Context in Logs
[Source: compatibility/logging_trace_context.md]

**Tier 2.** Non-OTLP log formats SHOULD record trace context using field names `trace_id` (hex), `span_id` (hex), `trace_flags` (W3C format). Syslog RFC5424: "Trace ID, span ID and traceflags SHOULD be recorded via SD-ID "OpenTelemetry"" (the SD-ID casing changed from `opentelemetry`). All three fields optional.

---

## 11. Lower-Priority Areas

### 11.1 Entities [Tier 3]
[Source: entities/README.md, entities/data-model.md, entities/entity-propagation.md, entities/entity-events.md]

**Development.** Entities represent typed objects of interest (e.g., "service", "host") with an immutable identifying `ID` (renamed from `Id`; "MUST not change during the lifetime of the entity", at least one attribute) and mutable `Description` attributes. Associated with Resources for identity correlation across signals; propagated via the `OTEL_ENTITIES` env var and the `EnvEntityDetector`. New in data-model: "Entities MAY be merged if and only if their types are the same, their identity attributes are exactly the same AND their schema_url is the same"; description attributes merge with the new entity taking precedence; differing `schema_url`s SHOULD be converted to one version before merging. New file `entity-events.md` (Development) communicates entity information as structured log Events: `entity.state` (required `entity.type`, `entity.id` map<string,string>; optional `entity.description` as AnyValue map, `entity.relationships`, `entity.report.interval` in seconds, MUST be non-negative, 0 = no periodic events) and `entity.delete` (optional `entity.delete.reason`). "Implementations SHOULD emit Entity State events whenever entity descriptive attributes change, and periodically". Delete delivery is not guaranteed: "Recipients of entity signals MUST be prepared to handle this situation by expiring entities" using the reported interval, and "MUST also be prepared to receive an Entity Delete event out of order". Relationships (`relationship.type`, target `entity.type`, `entity.id`) are directional source→target; standard types SHOULD be defined in semantic conventions; placement SHOULD prefer the shorter-lived/higher-churn entity (pod→replicaset, container→pod, process→host); deleting an entity implicitly deletes its relationships.

### 11.2 Profiles Signal [Tier 3]
[Source: profiles/README.md, profiles/data-format.md, profiles/mappings.md, profiles/pprof.md]

**Alpha** (all four files moved from Development to Alpha). A profile is "a collection of stack traces with associated values representing resource consumption and code execution". Design goals: low overhead, dictionary-deduplicated representation, pprof compatibility (with `original_payload_format` for lossless carriage of `pprof`, `jfr`, or `linux_perf`), and correlation: "Profiles MUST be linkable to logs, metrics and traces through shared resource context and, where applicable, direct trace/span references"; samples MAY carry a `Link` (trace ID + span ID). New file `data-format.md` documents the `profiles.proto` (v1development) messages: `ProfilesData` → `ResourceProfiles` → `ScopeProfiles` → `Profile` → `Sample` are embedded by value; `Stack`, `Location`, `Mapping`, `Function`, `Link`, `KeyValueAndUnit` and strings are referenced by index into a top-level `ProfilesDictionary` whose tables reserve index 0 as a null entry. Attributes are `KeyValueAndUnit` (key/value/unit as string indices); resource and scope `KeyValue`s also use string indices into the dictionary. `mappings.md` defines required `Mapping` attributes (`process.executable.build_id.*`) and the `htlhash` algorithm. `pprof.md`: pprof is convertible to OTel Profiles and back without loss ("convertibility but not wire compatibility"); the conversion guidelines live in semantic conventions.

### 11.3 Telemetry Schemas [Tier 3]
[Source: schemas/README.md, schemas/file_format_v1.0.0.md, schemas/file_format_v1.1.0.md]

Schema URLs identify semantic convention versions (e.g., `https://opentelemetry.io/schemas/1.x.y`). Schemas are immutable once published. Version numbers follow MAJOR.MINOR.PATCH with SemVer 2.0 ordering rules and carry no other meaning. Schema files define transformations for attribute renaming across versions. OTLP carries schema URLs in ResourceSpans, ResourceMetrics, ResourceLogs.

### 11.4 OTLP Protocol [Tier 3]
[Source: protocol/README.md, protocol/exporter.md, protocol/otlp.md]

Wire protocol for exporting telemetry. Transports: gRPC (default port 4317), HTTP/protobuf and HTTP/JSON (default port 4318). Configured via `OTEL_EXPORTER_OTLP_*` env vars (endpoint, headers, compression, timeout, protocol). Default timeout: 10s. Exporter options: Max Request Size (Integer, default 67108864 bytes = 64 MiB) and Max Response Size (Integer, default 4194304 bytes = 4 MiB). Per-signal endpoints (`OTEL_EXPORTER_OTLP_TRACES_ENDPOINT`) override base endpoint. `protocol/exporter.md` adds two Integer-typed options: **Max Request Size**, the maximum bytes of a request message the exporter will send (default 67108864, 64 MiB), and **Max Response Size**, the maximum bytes of a response message the exporter will accept (default 4194304, 4 MiB). See `protocol/` for retry, compression, and TLS requirements.

### 11.5 File Exporter [Tier 3]
[Source: protocol/file-exporter.md]

Exports telemetry to files in OTLP JSON format. Line-delimited JSON (one record per line). See `protocol/file-exporter.md` for file rotation and path configuration.

### 11.6 Glossary [Tier 3]
[Source: glossary.md]

Authoritative definitions of core OTel terms. See `glossary.md` for canonical definitions.

### 11.7 Maturity Levels and Self-Observability [Tier 3]
[Source: maturity-levels.md, document-status.md, self-observability.md, self-observability-supplementary-guidelines.md]

`maturity-levels.md` (Stable, new) defines the levels a SIG deliverable MUST declare: Development, Alpha (the default when unstated), Beta, Release Candidate, Stable, Deprecated, Unmaintained. "Components SHOULD NOT be marked as Stable if their user-visible interfaces are not Stable." Deprecated components "MUST communicate in which version they will be removed". `document-status.md` now only delegates to it and defines `Mixed`. `self-observability.md` (Development, new): "OpenTelemetry SDKs SHOULD emit self-observability ("internal") telemetry about their own behavior"; metric names come from the semconv SDK Metrics page and SDKs "SHOULD follow these conventions"; startup/shutdown telemetry is best-effort. The supplementary guidelines are non-normative advice on lifecycle ordering, obtaining the Meter/Logger, and avoiding telemetry-induced-telemetry loops.

---

## Appendix B: Spec File Index

> All 91 specification files sorted by area. Status: S=Stable, E=Experimental, D=Deprecated, Dev=Development, A=Alpha, RC=Release Candidate. "-" means the file declares no status.
> Line counts are actual counts from the source files.

### Core (Root-level)
| File | Status | Lines | Description |
|---|---|---|---|
| `README.md` | - | 93 | Main specification index and navigation guide |
| `overview.md` | - | 415 | High-level architecture: API/SDK/Exporter pipeline, signals (Trace, Metric, Log, Baggage), Resources |
| `error-handling.md` | - | 124 | Error handling: MUST NOT throw to user code, no-op fallbacks, self-diagnostics |
| `performance.md` | - | 44 | Non-blocking, bounded memory, configurable tradeoffs |
| `performance-benchmark.md` | - | 70 | Benchmark guidelines: span creation throughput, CPU usage |
| `versioning-and-stability.md` | S | 436 | Signal lifecycle (Development/Stable/Deprecated/Removed), LTS support |
| `library-guidelines.md` | - | 136 | API/SDK separation, extensibility, instrument naming |
| `library-layout.md` | - | 111 | Package structure for API and SDK artifacts across languages |
| `glossary.md` | - | 247 | Terminology: user roles, signals, packages, instrumentation |
| `document-status.md` | - | 15 | Document status: defers to maturity-levels.md; defines Mixed |
| `maturity-levels.md` | S | 103 | Maturity levels: Development, Alpha, Beta, RC, Stable, Deprecated, Unmaintained |
| `self-observability.md` | Dev | 26 | SDKs SHOULD emit internal telemetry; names from semconv SDK metrics |
| `self-observability-supplementary-guidelines.md` | - | 145 | Non-normative: lifecycle ordering, obtaining Meter/Logger, avoiding loops |
| `semantic-conventions.md` | Dev | 39 | Link to semantic conventions repo; reserved attributes/namespaces |
| `specification-principles.md` | - | 111 | Core principles: user-driven, general, stable, consistent, simple |
| `telemetry-stability.md` | Dev | 97 | Stability requirements for telemetry produced by instrumentation |
| `upgrading.md` | - | 164 | Component overview (API/SDK/Plugins/Instrumentation), upgrade strategies |
| `vendors.md` | - | 57 | Vendor support requirements |

### Baggage
| File | Status | Lines | Description |
|---|---|---|---|
| `baggage/README.md` | - | 7 | Baggage signal overview |
| `baggage/api.md` | S | 210 | Baggage API: Get/Set/Remove, context interaction, W3C propagation |

### Common
| File | Status | Lines | Description |
|---|---|---|---|
| `common/README.md` | S | 393 | AnyValue, Attributes, attribute collections, limits |
| `common/attribute-naming.md` | - | 8 | Redirect to semantic conventions naming specification |
| `common/attribute-requirement-level.md` | - | 9 | Redirect to semantic conventions attribute requirement levels |
| `common/attribute-type-mapping.md` | Dev | 259 | Mapping arbitrary data to OTLP AnyValue (primitives, arrays, maps) |
| `common/instrumentation-scope.md` | S | 52 | InstrumentationScope: name, version, schema_url, attributes tuple |
| `common/mapping-to-non-otlp.md` | S | 99 | Generic rules for mapping OTel data to non-OTLP formats |

### Compatibility
| File | Status | Lines | Description |
|---|---|---|---|
| `compatibility/README.md` | - | 7 | Compatibility section overview |
| `compatibility/logging_trace_context.md` | S | 70 | Trace context in non-OTLP log formats: trace_id, span_id, trace_flags |
| `compatibility/opencensus.md` | D | 265 | OpenCensus migration path, breaking changes, bridges (deprecated June 2026) |
| `compatibility/opentracing.md` | D | 609 | OpenTracing shim: Tracer, Span, ScopeManager mapping (deprecated March 2026) |
| `compatibility/prometheus_and_openmetrics.md` | Mixed | 788 | Prometheus/OpenMetrics ↔ OTel: metric types, units, exemplars, native histograms, NHCB |

### Configuration
| File | Status | Lines | Description |
|---|---|---|---|
| `configuration/README.md` | - | 64 | Configuration mechanisms: programmatic, env vars, file-based |
| `configuration/api.md` | Mixed | 88 | Instrumentation configuration API: ConfigProvider, ConfigProperties |
| `configuration/common.md` | S | 122 | Common guidance: numeric types, duration, timeout, enum parsing |
| `configuration/data-model.md` | S | 211 | YAML/JSON config model: versioning, env var substitution |
| `configuration/sdk.md` | S | 448 | SDK config: in-memory model, ConfigProvider, PluginComponentProvider |
| `configuration/sdk-environment-variables.md` | S | 370 | All OTEL_* env vars with defaults and valid values |
| `configuration/supplementary-guidelines.md` | - | 90 | Config interface prioritization, programmatic customization, strict YAML parsing |

### Context
| File | Status | Lines | Description |
|---|---|---|---|
| `context/README.md` | S | 136 | Context API: create key, get/set value, global context operations |
| `context/api-propagators.md` | S | 436 | TextMapPropagator, Inject/Extract, Composite, Global, B3, W3C |
| `context/env-carriers.md` | RC | 185 | Environment variables as context propagation carriers |

### Entities
| File | Status | Lines | Description |
|---|---|---|---|
| `entities/README.md` | - | 36 | Entities concept: objects of interest producing telemetry |
| `entities/data-model.md` | Dev | 282 | Entity data model: minimally sufficient identity, attributes, merging |
| `entities/entity-events.md` | Dev | 358 | Entity events as log Events: entity.state, entity.delete, relationships |
| `entities/entity-propagation.md` | Dev | 192 | Entity propagation via env vars: format, parsing, EnvEntityDetector |

### Logs
| File | Status | Lines | Description |
|---|---|---|---|
| `logs/README.md` | - | 479 | Logging overview: legacy sources, modern first-party logs, correlation |
| `logs/api.md` | S | 194 | Logs API: LoggerProvider, Logger, Emit, Enabled |
| `logs/data-model.md` | S | 465 | Log data model: timestamp, severity, trace context, body, attributes |
| `logs/data-model-appendix.md` | - | 881 | Example mappings: syslog, Windows Event Log, CloudTrail, Splunk HEC |
| `logs/noop.md` | S | 62 | No-op logger implementation requirements |
| `logs/sdk.md` | S | 719 | Logs SDK: LoggerProvider, LogRecordProcessor, LogRecordExporter, limits |
| `logs/supplementary-guidelines.md` | - | 393 | Bridge pattern, context injection, filtering, routing |
| `logs/sdk_exporters/README.md` | - | 8 | Logs exporters overview |
| `logs/sdk_exporters/stdout.md` | S | 34 | Stdout LogRecord exporter for debugging/testing |

### Metrics
| File | Status | Lines | Description |
|---|---|---|---|
| `metrics/README.md` | - | 112 | Metrics overview: API, SDK, instruments, views |
| `metrics/api.md` | S | 1428 | MeterProvider, Meter, 7 instrument types, callbacks, naming rules |
| `metrics/data-model.md` | Mixed | 1328 | Sum, Gauge, Histogram, ExpHistogram, Summary; temporality semantics |
| `metrics/metric-requirement-level.md` | - | 9 | Redirect to semantic conventions metric requirement levels |
| `metrics/noop.md` | S | 270 | No-op Meter and instrument implementation requirements |
| `metrics/sdk.md` | Mixed | 2019 | MeterProvider, Views, Aggregations, Cardinality, Exemplars, MetricReader |
| `metrics/supplementary-guidelines.md` | - | 676 | Instrument selection, additive property, monotonicity, temporality |
| `metrics/sdk_exporters/README.md` | - | 8 | Metrics exporters overview |
| `metrics/sdk_exporters/in-memory.md` | S | 28 | In-memory metrics exporter for testing |
| `metrics/sdk_exporters/otlp.md` | S | 75 | OTLP metrics exporter with temporality and aggregation config |
| `metrics/sdk_exporters/prometheus.md` | Mixed | 199 | Prometheus pull exporter: exporter model, SDK output, configuration, content negotiation |
| `metrics/sdk_exporters/stdout.md` | S | 46 | Stdout metrics exporter for debugging/testing |

### Profiles
| File | Status | Lines | Description |
|---|---|---|---|
| `profiles/README.md` | A | 102 | Profiles signal: definition, design goals, data format overview, known values |
| `profiles/data-format.md` | A | 415 | Profiles data format: dictionary-based proto messages, span links, examples |
| `profiles/mappings.md` | A | 36 | Profile Mapping attributes: process.executable.build_id, htlhash algorithm |
| `profiles/pprof.md` | A | 20 | Pprof convertibility (not wire compatibility) with OpenTelemetry Profiles |

### Protocol
| File | Status | Lines | Description |
|---|---|---|---|
| `protocol/README.md` | - | 19 | OTLP protocol overview; links to proto repo |
| `protocol/design-goals.md` | - | 10 | Redirect to opentelemetry-proto design goals |
| `protocol/exporter.md` | S | 245 | OTLP exporter config: endpoint, timeout, headers, compression, auth |
| `protocol/file-exporter.md` | Dev | 115 | File/stdout exporter: JSON lines format, FaaS/testing use cases |
| `protocol/otlp.md` | - | 8 | Redirect to official OTLP specification |
| `protocol/requirements.md` | - | 10 | Redirect to opentelemetry-proto requirements |

### Resource
| File | Status | Lines | Description |
|---|---|---|---|
| `resource/README.md` | - | 114 | Resource concept: entity identity, navigation, telescoping |
| `resource/data-model.md` | Dev | 220 | Resource as attributes representing entities; identity; merging resources |
| `resource/sdk.md` | S | 268 | Resource SDK: Create, Merge, immutability, Detectors, env vars |

### Schemas
| File | Status | Lines | Description |
|---|---|---|---|
| `schemas/README.md` | S | 279 | Schema URL format, SemVer versioning, schema-aware transformation |
| `schemas/file_format_v1.0.0.md` | Dev | 543 | Schema file format 1.0.0: structure, rename/split/merge transforms |
| `schemas/file_format_v1.1.0.md` | Dev | 580 | Schema file format 1.1.0: enhancements + metric unit transforms |

### Trace
| File | Status | Lines | Description |
|---|---|---|---|
| `trace/README.md` | - | 7 | Traces signal overview |
| `trace/api.md` | S | 872 | TracerProvider, Tracer, Span, SpanContext, Events, Links, Status |
| `trace/exceptions.md` | S | 55 | Exception recording: "exception" event, type/message/stacktrace attrs |
| `trace/sdk.md` | S | 1308 | Sampling, SpanLimits, SpanProcessor, SpanExporter, IdGenerator |
| `trace/tracestate-handling.md` | Dev | 180 | TraceState: OTel sub-keys (sampling threshold `th`, randomness `rv`) |
| `trace/tracestate-probability-sampling.md` | Dev | 497 | Consistent probability sampling via TraceState |
| `trace/sdk_exporters/README.md` | - | 8 | Trace exporters overview |
| `trace/sdk_exporters/stdout.md` | S | 35 | Stdout span exporter for debugging/testing |
| `trace/sdk_exporters/zipkin.md` | D | 204 | Zipkin exporter (Deprecated, removal Dec 2026); format mapping |
