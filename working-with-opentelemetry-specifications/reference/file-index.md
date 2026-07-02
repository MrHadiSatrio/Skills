# OpenTelemetry Specification: Compatibility, Lower-Priority Areas & File Index

<!-- lint:external-paths -->

> Compatibility shims, lower-priority signals, and the complete index of all 86 spec files.
> Every path in this file points into the UPSTREAM spec's `specification/` directory — resolve them with the retrieval recipe in this skill's SKILL.md, not on local disk.

---

## 10. Compatibility

### 10.1 OpenTracing Shim
[Source: compatibility/opentracing.md]

**Tier 2.** Implements OpenTracing API using OTel. OpenTracing span references become OTel span links with reference type as attribute. OpenTracing `error=true` tag → StatusCode Error; `error=false` → StatusCode Ok; absent → Unset. Log operations → span events. SpanContext Shim MUST be immutable; baggage operations MUST be thread-safe. Not recommended to use both OpenTracing Shim and OTel API in same codebase when OpenTracing code consumes baggage.

### 10.2 OpenCensus Bridge
[Source: compatibility/opencensus.md]

**Tier 2.** Shim implementing OpenCensus Trace API using OTel for migration. All OpenCensus Spans sent through OTel Tracer. Maintains parent-child relationships across both APIs ("OTel sandwich"). Known incompatibilities: parent spans must be specified at creation time; links added post-creation not supported; samplers are per-provider not per-span; trace flags only support sampled flag.

### 10.3 Prometheus & OpenMetrics Mapping
[Source: compatibility/prometheus_and_openmetrics.md]

**Tier 2.** Prometheus Counter → OTel monotonic Sum; Gauge → Gauge; Histogram → OTel Histogram with explicit bounds; Summary → OTel Summary with quantiles. Reverse: OTel monotonic cumulative Sum → Prometheus Counter (with `_total` suffix); non-monotonic Sum → Gauge or Info/StateSet via type metadata; OTel Histogram → Prometheus histogram family (`_bucket`, `_count`, `_sum`); OTel ExpHistogram → Prometheus Native Histogram. Resource attributes → target_info metric; scope labels use `otel_scope_*` prefix.

### 10.4 Trace Context in Logs
[Source: compatibility/logging_trace_context.md]

**Tier 2.** Non-OTLP log formats SHOULD record trace context using field names `trace_id` (hex), `span_id` (hex), `trace_flags` (W3C format). Syslog RFC5424: SHOULD use SD-ID "opentelemetry". All three fields optional.

---

## 11. Lower-Priority Areas

### 11.1 Entities [Tier 3]
[Source: entities/README.md, entities/data-model.md, entities/entity-propagation.md]

**Experimental.** Entities represent typed objects of interest (e.g., "service", "host") with immutable identifying attributes and mutable descriptive attributes. Associated with Resources for identity correlation across signals. Propagated via `OTEL_ENTITIES` env var.

### 11.2 Profiles Signal [Tier 3]
[Source: profiles/README.md, profiles/mappings.md, profiles/pprof.md]

**Experimental.** Fourth telemetry signal (alongside traces, metrics, logs). Provides granular CPU/memory profiling. Not yet stable. See `profiles/` for data model and pprof mapping.

### 11.3 Telemetry Schemas [Tier 3]
[Source: schemas/README.md, schemas/file_format_v1.0.0.md, schemas/file_format_v1.1.0.md]

Schema URLs identify semantic convention versions (e.g., `https://opentelemetry.io/schemas/1.x.y`). Schemas are immutable once published. Define transformations for attribute renaming across versions. OTLP carries schema URLs in ResourceSpans, ResourceMetrics, ResourceLogs.

### 11.4 OTLP Protocol [Tier 3]
[Source: protocol/README.md, protocol/exporter.md, protocol/otlp.md]

Wire protocol for exporting telemetry. Transports: gRPC (default port 4317), HTTP/protobuf and HTTP/JSON (default port 4318). Configured via `OTEL_EXPORTER_OTLP_*` env vars (endpoint, headers, compression, timeout, protocol). Default timeout: 10s. Per-signal endpoints (`OTEL_EXPORTER_OTLP_TRACES_ENDPOINT`) override base endpoint. See `protocol/` for retry, compression, and TLS requirements.

### 11.5 File Exporter [Tier 3]
[Source: protocol/file-exporter.md]

Exports telemetry to files in OTLP JSON format. Line-delimited JSON (one record per line). See `protocol/file-exporter.md` for file rotation and path configuration.

### 11.6 Glossary [Tier 3]
[Source: glossary.md]

Authoritative definitions of core OTel terms. See `glossary.md` for canonical definitions.

---

## Appendix B: Spec File Index

> All specification files sorted by area. Status: S=Stable, E=Experimental, D=Deprecated, Dev=Development.
> Line counts are actual counts from the source files.

### Core (Root-level)
| File | Status | Lines | Description |
|---|---|---|---|
| `README.md` | S | 92 | Main specification index and navigation guide |
| `overview.md` | S | 400 | High-level architecture: API/SDK/Exporter pipeline, signals (Trace, Metric, Log, Baggage), Resources |
| `error-handling.md` | S | 121 | Error handling: MUST NOT throw to user code, no-op fallbacks |
| `performance.md` | S | 44 | Non-blocking, bounded memory, configurable tradeoffs |
| `performance-benchmark.md` | S | 70 | Benchmark guidelines: span creation throughput, CPU usage |
| `versioning-and-stability.md` | S | 438 | Signal lifecycle (Development/Stable/Deprecated/Removed), LTS support |
| `library-guidelines.md` | S | 136 | API/SDK separation, extensibility, instrument naming |
| `library-layout.md` | S | 111 | Package structure for API and SDK artifacts across languages |
| `glossary.md` | S | 247 | Terminology: user roles, signals, packages, instrumentation |
| `document-status.md` | S | 29 | Maturity level definitions (Development/Alpha/Beta/RC/Stable/Deprecated) |
| `semantic-conventions.md` | Dev | 39 | Link to semantic conventions repo; reserved attributes/namespaces |
| `specification-principles.md` | S | 111 | Core principles: user-driven, general, stable, consistent, simple |
| `telemetry-stability.md` | Dev | 97 | Stability requirements for telemetry produced by instrumentation |
| `upgrading.md` | S | 164 | Component overview (API/SDK/Plugins/Instrumentation), upgrade strategies |
| `vendors.md` | S | 57 | Vendor support requirements |

### Baggage
| File | Status | Lines | Description |
|---|---|---|---|
| `baggage/README.md` | S | 7 | Baggage signal overview |
| `baggage/api.md` | S | 210 | Baggage API: Get/Set/Remove, context interaction, W3C propagation |

### Common
| File | Status | Lines | Description |
|---|---|---|---|
| `common/README.md` | S | 320 | AnyValue, Attributes, attribute collections, limits |
| `common/attribute-naming.md` | S | 8 | Redirect to semantic conventions naming specification |
| `common/attribute-requirement-level.md` | S | 9 | Redirect to semantic conventions attribute requirement levels |
| `common/attribute-type-mapping.md` | Dev | 259 | Mapping arbitrary data to OTLP AnyValue (primitives, arrays, maps) |
| `common/instrumentation-scope.md` | S | 52 | InstrumentationScope: name, version, schema_url, attributes tuple |
| `common/mapping-to-non-otlp.md` | S | 99 | Generic rules for mapping OTel data to non-OTLP formats |

### Compatibility
| File | Status | Lines | Description |
|---|---|---|---|
| `compatibility/README.md` | S | 7 | Compatibility section overview |
| `compatibility/logging_trace_context.md` | S | 70 | Trace context in non-OTLP log formats: trace_id, span_id, trace_flags |
| `compatibility/opencensus.md` | S | 255 | OpenCensus migration path, breaking changes, bridges |
| `compatibility/opentracing.md` | S | 596 | OpenTracing shim: Tracer, Span, ScopeManager mapping |
| `compatibility/prometheus_and_openmetrics.md` | Mixed | 535 | Prometheus/OpenMetrics ↔ OTel: metric types, exemplars, native histograms |

### Configuration
| File | Status | Lines | Description |
|---|---|---|---|
| `configuration/README.md` | S | 64 | Configuration mechanisms: programmatic, env vars, file-based |
| `configuration/api.md` | Mixed | 88 | Instrumentation configuration API: ConfigProvider, ConfigProperties |
| `configuration/common.md` | S | 122 | Common guidance: numeric types, duration, timeout, enum parsing |
| `configuration/data-model.md` | S | 211 | YAML/JSON config model: versioning, env var substitution |
| `configuration/sdk.md` | S | 444 | SDK config: in-memory model, ConfigProvider, PluginComponentProvider |
| `configuration/sdk-environment-variables.md` | S | 370 | All OTEL_* env vars with defaults and valid values |
| `configuration/supplementary-guidelines.md` | S | 65 | Config interface prioritization and programmatic customization |

### Context
| File | Status | Lines | Description |
|---|---|---|---|
| `context/README.md` | S | 136 | Context API: create key, get/set value, global context operations |
| `context/api-propagators.md` | S | 435 | TextMapPropagator, Inject/Extract, Composite, Global, B3, W3C |
| `context/env-carriers.md` | E | 208 | Environment variables as context propagation carriers |

### Entities
| File | Status | Lines | Description |
|---|---|---|---|
| `entities/README.md` | S | 35 | Entities concept: objects of interest producing telemetry |
| `entities/data-model.md` | Dev | 243 | Entity data model: minimally sufficient identity, attributes |
| `entities/entity-propagation.md` | Dev | 192 | Entity propagation via env vars: format, parsing, EnvEntityDetector |

### Logs
| File | Status | Lines | Description |
|---|---|---|---|
| `logs/README.md` | S | 479 | Logging overview: legacy sources, modern first-party logs, correlation |
| `logs/api.md` | S | 191 | Logs API: LoggerProvider, Logger, Emit, Enabled |
| `logs/data-model.md` | S | 469 | Log data model: timestamp, severity, trace context, body, attributes |
| `logs/data-model-appendix.md` | S | 822 | Example mappings: syslog, Windows Event Log, CloudTrail, Splunk HEC |
| `logs/noop.md` | S | 62 | No-op logger implementation requirements |
| `logs/sdk.md` | S | 660 | Logs SDK: LoggerProvider, LogRecordProcessor, LogRecordExporter, limits |
| `logs/supplementary-guidelines.md` | S | 395 | Bridge pattern, context injection, filtering, routing |
| `logs/sdk_exporters/README.md` | S | 8 | Logs exporters overview |
| `logs/sdk_exporters/stdout.md` | S | 34 | Stdout LogRecord exporter for debugging/testing |

### Metrics
| File | Status | Lines | Description |
|---|---|---|---|
| `metrics/README.md` | S | 112 | Metrics overview: API, SDK, instruments, views |
| `metrics/api.md` | S | 1368 | MeterProvider, Meter, 7 instrument types, callbacks, naming rules |
| `metrics/data-model.md` | Mixed | 1326 | Sum, Gauge, Histogram, ExpHistogram, Summary; temporality semantics |
| `metrics/metric-requirement-level.md` | S | 9 | Redirect to semantic conventions metric requirement levels |
| `metrics/noop.md` | S | 270 | No-op Meter and instrument implementation requirements |
| `metrics/sdk.md` | Mixed | 1890 | MeterProvider, Views, Aggregations, Cardinality, Exemplars, MetricReader |
| `metrics/supplementary-guidelines.md` | S | 676 | Instrument selection, additive property, monotonicity, temporality |
| `metrics/sdk_exporters/README.md` | S | 8 | Metrics exporters overview |
| `metrics/sdk_exporters/in-memory.md` | S | 28 | In-memory metrics exporter for testing |
| `metrics/sdk_exporters/otlp.md` | S | 75 | OTLP metrics exporter with temporality and aggregation config |
| `metrics/sdk_exporters/prometheus.md` | Dev | 93 | Prometheus pull exporter: format negotiation, custom collectors |
| `metrics/sdk_exporters/stdout.md` | S | 46 | Stdout metrics exporter for debugging/testing |

### Profiles
| File | Status | Lines | Description |
|---|---|---|---|
| `profiles/README.md` | Dev | 63 | Profiles signal (4th signal): CPU, memory, code execution |
| `profiles/mappings.md` | Dev | 36 | Profile Mapping attributes: process.executable.build_id |
| `profiles/pprof.md` | Dev | 19 | Pprof compatibility with OpenTelemetry Profiles |

### Protocol
| File | Status | Lines | Description |
|---|---|---|---|
| `protocol/README.md` | S | 19 | OTLP protocol overview; links to proto repo |
| `protocol/design-goals.md` | S | 10 | Redirect to opentelemetry-proto design goals |
| `protocol/exporter.md` | S | 232 | OTLP exporter config: endpoint, timeout, headers, compression, auth |
| `protocol/file-exporter.md` | Dev | 115 | File/stdout exporter: JSON lines format, FaaS/testing use cases |
| `protocol/otlp.md` | S | 8 | Redirect to official OTLP specification |
| `protocol/requirements.md` | S | 10 | Redirect to opentelemetry-proto requirements |

### Resource
| File | Status | Lines | Description |
|---|---|---|---|
| `resource/README.md` | S | 103 | Resource concept: entity identity, navigation, telescoping |
| `resource/data-model.md` | Dev | 49 | Resource as attributes representing entity, composition with entities |
| `resource/sdk.md` | S | 210 | Resource SDK: Create, Merge, immutability, Detectors, env vars |

### Schemas
| File | Status | Lines | Description |
|---|---|---|---|
| `schemas/README.md` | S | 279 | Schema URL format, versioning, schema-aware transformation |
| `schemas/file_format_v1.0.0.md` | Dev | 543 | Schema file format 1.0.0: structure, rename/split/merge transforms |
| `schemas/file_format_v1.1.0.md` | Dev | 580 | Schema file format 1.1.0: enhancements + metric unit transforms |

### Trace
| File | Status | Lines | Description |
|---|---|---|---|
| `trace/README.md` | S | 7 | Traces signal overview |
| `trace/api.md` | S | 874 | TracerProvider, Tracer, Span, SpanContext, Events, Links, Status |
| `trace/exceptions.md` | S | 55 | Exception recording: "exception" event, type/message/stacktrace attrs |
| `trace/sdk.md` | S | 1290 | Sampling, SpanLimits, SpanProcessor, SpanExporter, IdGenerator |
| `trace/tracestate-handling.md` | Dev | 180 | TraceState: OTel sub-keys (sampling threshold `th`, randomness `rv`) |
| `trace/tracestate-probability-sampling.md` | Dev | 497 | Consistent probability sampling via TraceState |
| `trace/sdk_exporters/README.md` | S | 8 | Trace exporters overview |
| `trace/sdk_exporters/stdout.md` | S | 35 | Stdout span exporter for debugging/testing |
| `trace/sdk_exporters/zipkin.md` | S | 204 | Zipkin exporter (Deprecated, removal Dec 2026); format mapping |
