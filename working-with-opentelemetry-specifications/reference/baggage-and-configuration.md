# OpenTelemetry Specification: Baggage & Configuration

> Baggage API, Environment Variable Carriers, OTEL_* Environment Variables, Declarative Configuration (YAML)

---

## 8. Baggage Signal

### 8.1 Baggage API
[Source: baggage/api.md]

Baggage is an immutable set of application-defined name/value pairs propagated via Context per W3C Baggage Specification.

**Baggage names:**
- Any valid, non-empty UTF-8 strings
- Language API MUST treat baggage names as case-sensitive
- For maximum compatibility, alphanumeric names strongly recommended
- W3C propagator restricts keys to RFC7230 token definition

**Baggage values:**
- Any valid UTF-8 strings
- Language API MUST accept any valid UTF-8 string as value
- Language API MUST treat baggage values as case-sensitive

**Entry:** `{name, value, metadata?}` — metadata is opaque string, no semantic meaning.

**Each name MUST be associated with exactly one value (no duplicate names).**

**Operations:**
- `GetValue(name) -> value|null` — MUST take name as input; returns value or null if absent
- `GetAllValues() -> []Entry` — order MUST NOT be significant
- `SetValue(name, value, metadata?) -> Baggage` — MUST take name+value as input; returns NEW Baggage with entry added; if same name exists, new value MUST take precedence
- `RemoveValue(name) -> Baggage` — MUST take name as input; returns NEW Baggage without that entry
- `Len() -> int`
- `FromContext(context) -> Baggage`
- `ContextWithBaggage(context, baggage) -> Context`
- `ContextWithoutBaggage(context) -> Context` — API MUST provide way to remove all baggage entries

**Baggage container MUST be immutable.** MUST be fully functional without SDK installed.

**Propagation:**
- API layer MUST include TextMapPropagator implementing W3C Baggage Specification
- W3C format: `key=value,key2=value2;metadata`
- On extract: metadata stored as single metadata instance per entry
- On inject: metadata appended per W3C format

### 8.2 Environment Variables as Propagation Carriers
[Source: context/env-carriers.md]

**Status: Release Candidate.** Environment variables carry trace context and baggage between a parent and a spawned child process. "A `TextMapPropagator` SHOULD be used alongside its normal `Get`, `Set`, `Extract`, and `Inject` functionality."

**Division of responsibility:**
- "The **environment variable carrier** MUST be format-agnostic and MUST treat values as opaque strings and MUST NOT apply propagation-format-specific logic such as validating, parsing values, or enforcing other format-specific constraints."
- The propagators (W3C Trace Context, W3C Baggage, ...) remain solely responsible for choosing key names, enforcing format naming conventions, validating/parsing values, and truncation.
- "Language implementations MUST NOT spawn child processes as part of environment variable context propagation."
- Language implementations SHOULD document operational guidance (initialization-time extraction, child process environment handling, security).

**Key name normalization** (applies to whichever component implements `Get`/`Set`/`Keys` — carrier, `Getter`, `Setter`, or other API). "To normalize a key name, implementations MUST:"
- replace an empty key name with a single underscore (`_`)
- uppercase ASCII letters
- replace every character that is not an ASCII letter, digit, or underscore with `_`
- prefix with `_` if the name would otherwise start with an ASCII digit

A normalized name matches `^[A-Z_][A-Z0-9_]*$`.
- "`Set` MUST write values using the normalized form of the key provided by the propagator."
- "`Get` MUST normalize the key requested by the propagator and MUST use the normalized key name to read from the carrier."
- "`Keys` MUST return only key names that are already normalized."
- Example: propagator key `x-b3-traceid` → `Get` reads `X_B3_TRACEID`; it "MUST NOT read a non-normalized environment variable named `x-b3-traceid`". Thus W3C keys land as `TRACEPARENT`, `TRACESTATE`, `BAGGAGE`.
- Note: on case-insensitive platforms (Windows) the platform lookup may match a variable differing only by case.

The Operational Guidance and Implementation Guidelines sections are non-normative: parent copies the environment, injects into the copy, and passes it to its own spawning mechanism; child extracts at startup; sensitive data is not appropriate in environment variables.

---

## 9. Configuration

### 9.1 Environment Variables
[Source: configuration/sdk-environment-variables.md]

**General rules:**
- Implementations MAY support these env vars; if they do, they SHOULD use the names and value parsing here and SHOULD follow configuration/common.md (Source pointer in section 9.5)
- "The environment-based configuration MUST have a direct code configuration equivalent."
- "The SDK MUST interpret an empty value of an environment variable the same way as when the variable is unset."
- Boolean: "MUST be set to true only by the case-insensitive string `"true"`"; "An implementation MUST NOT extend this definition"; any other value, including unset and empty, "MUST be interpreted as false"; for a value other than true/`"false"`/empty/unset "a warning SHOULD be logged"; renaming or changing the default "MUST NOT happen without a major version upgrade"
- Numeric: unparseable value — implementation SHOULD generate a warning and ignore the setting (treat as not set); new implementations should treat this as MUST
- Enum: "Enum values SHOULD be interpreted in a case-insensitive manner"; unrecognized value — "the implementation MUST generate a warning and gracefully ignore the setting"
- Language-specific variables follow `OTEL_{LANGUAGE}_{FEATURE}`

**Full Environment Variable Table** (matches the spec tables at the pinned commit):

| Variable | Default | Description |
|---|---|---|
| `OTEL_SDK_DISABLED` | `false` | Disable SDK; if "true", no-op SDK for all signals; no effect on propagators from `OTEL_PROPAGATORS` |
| `OTEL_ENTITIES` | (none) | Entity information associated with the resource (see entities/entity-propagation.md, covered in cross-cutting.md) |
| `OTEL_RESOURCE_ATTRIBUTES` | (see semconv) | Resource attributes as key=value pairs |
| `OTEL_SERVICE_NAME` | (none) | Sets `service.name`; takes precedence over `OTEL_RESOURCE_ATTRIBUTES` |
| `OTEL_LOG_LEVEL` | `"info"` | SDK internal logger level |
| `OTEL_PROPAGATORS` | `"tracecontext,baggage"` | Comma-separated propagators; "Values MUST be deduplicated" |
| `OTEL_TRACES_SAMPLER` | `"parentbased_always_on"` | Sampler for traces |
| `OTEL_TRACES_SAMPLER_ARG` | (none) | Sampler argument; only used if `OTEL_TRACES_SAMPLER` set; invalid input "MUST be logged and MUST be otherwise ignored" |
| `OTEL_TRACES_EXPORTER` | `otlp` | Trace exporter(s); MAY accept comma-separated list |
| `OTEL_METRICS_EXPORTER` | `otlp` | Metrics exporter(s); MAY accept comma-separated list |
| `OTEL_LOGS_EXPORTER` | `otlp` | Logs exporter(s); MAY accept comma-separated list |
| `OTEL_METRICS_EXEMPLAR_FILTER` | `"trace_based"` | Exemplar filter: `trace_based`\|`always_on`\|`always_off` |
| `OTEL_METRIC_EXPORT_INTERVAL` | `60000` | ms between start of two export attempts (periodic MetricReader) |
| `OTEL_METRIC_EXPORT_TIMEOUT` | `30000` | ms max metric export time |
| `OTEL_EXPORTER_PROMETHEUS_HOST` | `"localhost"` | Prometheus exporter host [Development] |
| `OTEL_EXPORTER_PROMETHEUS_PORT` | `9464` | Prometheus exporter port [Development] |
| `OTEL_EXPORTER_ZIPKIN_ENDPOINT` | `http://localhost:9411/api/v2/spans` | Zipkin endpoint [Deprecated] |
| `OTEL_EXPORTER_ZIPKIN_TIMEOUT` | `10000` | Zipkin timeout ms [Deprecated]; `OTEL_EXPORTER_ZIPKIN_PROTOCOL` reserved, undefined |
| `OTEL_BSP_SCHEDULE_DELAY` | `5000` | BatchSpanProcessor export delay ms |
| `OTEL_BSP_EXPORT_TIMEOUT` | `30000` | BatchSpanProcessor export timeout ms |
| `OTEL_BSP_MAX_QUEUE_SIZE` | `2048` | BatchSpanProcessor queue size; positive |
| `OTEL_BSP_MAX_EXPORT_BATCH_SIZE` | `512` | BatchSpanProcessor batch size (≤ queue size); positive |
| `OTEL_BLRP_SCHEDULE_DELAY` | `1000` | BatchLogRecordProcessor export delay ms |
| `OTEL_BLRP_EXPORT_TIMEOUT` | `30000` | BatchLogRecordProcessor export timeout ms |
| `OTEL_BLRP_MAX_QUEUE_SIZE` | `2048` | BatchLogRecordProcessor queue size; positive |
| `OTEL_BLRP_MAX_EXPORT_BATCH_SIZE` | `512` | BatchLogRecordProcessor batch size (≤ queue size); positive |
| `OTEL_ATTRIBUTE_VALUE_LENGTH_LIMIT` | no limit | Global max attribute value length; non-negative |
| `OTEL_ATTRIBUTE_COUNT_LIMIT` | `128` | Global max attribute count; non-negative |
| `OTEL_SPAN_ATTRIBUTE_VALUE_LENGTH_LIMIT` | no limit | Span max attribute value length |
| `OTEL_SPAN_ATTRIBUTE_COUNT_LIMIT` | `128` | Span max attribute count |
| `OTEL_SPAN_EVENT_COUNT_LIMIT` | `128` | Max span event count |
| `OTEL_SPAN_LINK_COUNT_LIMIT` | `128` | Max span link count |
| `OTEL_EVENT_ATTRIBUTE_COUNT_LIMIT` | `128` | Max attributes per span event |
| `OTEL_LINK_ATTRIBUTE_COUNT_LIMIT` | `128` | Max attributes per span link |
| `OTEL_LOGRECORD_ATTRIBUTE_VALUE_LENGTH_LIMIT` | no limit | LogRecord max attribute value length |
| `OTEL_LOGRECORD_ATTRIBUTE_COUNT_LIMIT` | `128` | LogRecord max attribute count |
| `OTEL_CONFIG_FILE` | (none) | Path to config file; takes precedence over all other SDK config env vars |
| `OTEL_EXPERIMENTAL_CONFIG_FILE` | (none) | **Deprecated** — use `OTEL_CONFIG_FILE` |

Attribute-limit variables: "Implementations SHOULD only offer environment variables for the types of attributes, for which that SDK implements truncation mechanism." OTLP exporter variables live in protocol/exporter.md (summarized in file-index.md).

**Known values for `OTEL_PROPAGATORS`:** `tracecontext`, `baggage`, `b3`, `b3multi`, `jaeger` (Deprecated), `xray` (3rd party), `ottrace` (3rd party, Deprecated), `none`

**Known values for `OTEL_TRACES_SAMPLER`:** `always_on`, `always_off`, `traceidratio`, `parentbased_always_on`, `parentbased_always_off`, `parentbased_traceidratio`, `parentbased_jaeger_remote`, `jaeger_remote`, `xray` (3rd party). `OTEL_TRACES_SAMPLER_ARG`: for `traceidratio`/`parentbased_traceidratio` a probability in [0..1], default 1.0; for `jaeger_remote`/`parentbased_jaeger_remote` a comma-separated `endpoint=...,pollingIntervalMs=...,initialSamplingRate=...` list.

**Known exporter values:** traces `otlp`, `zipkin`, `console`, `logging` (deprecated; "SHOULD NOT be supported by new implementations"), `none`; metrics `otlp`, `prometheus`, `console`, `logging` (deprecated), `none`; logs `otlp`, `console`, `logging` (deprecated), `none`. [Development] all three also accept `otlp/stdout` (OTLP File to standard output).

**`OTEL_CONFIG_FILE` behaviour:** the file is passed to Parse, the resulting model to Create. "When `OTEL_CONFIG_FILE` is set, all other environment variables besides those referenced in the configuration file for environment variable substitution MUST be ignored." Implementations MAY provide a mechanism to customize the parsed model before Create.

### 9.2 Declarative Configuration (SDK)
[Source: configuration/sdk.md]

**Status: Stable** except where marked. Components: in-memory configuration model (SHOULD reflect the schema; name `Configuration` RECOMMENDED), `ConfigProvider` SDK (Development — "MUST be created using a `ConfigProperties` representing the `.instrumentation` mapping node"), SDK extension components, SDK operations.

**Plugin components** (`PluginComponentProvider`, registered by `type` + `name`): resource detector, text map propagator, span exporter, span processor, sampler, ID generator (`IdGenerator`, now available), pull metric reader, push metric exporter, metric producer, log record exporter, log record processor; exemplar reservoir not yet available. "The `PluginComponentProvider` MUST provide" Create Component(`properties: ConfigProperties`) → component; it SHOULD document its configuration schema and SHOULD return an error when required properties are missing or mistyped.

**SDK operations** ("SDK implementations of configuration MUST provide"):
- **Parse**(`file`, `file_format`) → configuration model. "Parse MUST perform environment variable substitution." "Parse MUST differentiate between properties that are missing and properties that are present but null" (e.g. `drop:` present-but-null selects the drop aggregation; the user "MUST not be required to specify an empty object"). Non-built-in extension components: "Parse MUST resolve corresponding configuration to a generic `ConfigProperties` representation." Parse SHOULD return an error if the file does not exist / is invalid or does not conform to the schema. If `parse` accepts `file_format`, the API SHOULD oblige the user to provide it.
- **Create**(`configuration`) → TracerProvider, MeterProvider, LoggerProvider, Propagators, plus [Development] the resolved `Resource` and the `ConfigProvider`. "If a property is present and the value is null, Create MUST use the `nullBehavior`, or `defaultBehavior` if `nullBehavior` is not set." "If a property is required, and not present, Create MUST return an error." Create SHOULD return an error for values invalid per the property `description`. Non-built-in plugins: "Create MUST resolve the component using Create Component of the `PluginComponentProvider` of the corresponding `type` and `name`"; no provider registered → SHOULD return an error; Create Component error → SHOULD propagate. Fail fast: "This SHOULD return an error if it encounters an error in `configuration`." [Development] SDKs MAY offer programmatic customization hooks (e.g. a callback per initialized component).
- **Register PluginComponentProvider**(`plugin_component_provider`, `type`, `name`): "The SDK MUST provide a mechanism to register"; MAY be automatic (e.g. Java SPI). "Register MUST return an error if it is called multiple times with the same `type` and `name` combination."

### 9.3 Configuration Data Model
[Source: configuration/data-model.md]

**Tier 2.** Status Stable. The configuration model is defined in the `opentelemetry-configuration` GitHub repo using JSON Schema, with its own versioning policy (`defaultBehavior`/`nullBehavior` annotations are defined there). "YAML configuration files MUST use file extensions `.yaml` or `.yml`" and "SHOULD be parsed using v1.2 YAML core schema". Env var substitution (`${env:VAR}`, `${VAR}`, `${VAR:-default}`, `$$` escape to `$`) is defined here and performed by Parse.

### 9.4 Configuration API
[Source: configuration/api.md]

**Tier 2.** `ConfigProvider` API gives instrumentation libraries access to the `.instrumentation` mapping node via `GetInstrumentationConfig()`, returning a schemaless `ConfigProperties`. Supports global default and per-instance providers. `ConfigProperties` provides type-safe accessors for scalars, nested mappings, and sequences.

### 9.5 Configuration Common Guidance and Supplementary Guidelines
[Source: configuration/README.md] [Source: configuration/common.md] [Source: configuration/supplementary-guidelines.md]

**Tier 2.** `README.md`: the programmatic interface is primary; "All other configuration mechanisms SHOULD be built on top of this interface." `common.md` defines the shared value types (Integer, Duration, Timeout, String, Enum) that the env var tables reference. `supplementary-guidelines.md` is non-normative: `create` sits below programmatic configuration in priority; programmatic customization should not substitute for modeling features as plugin components; new **Strict YAML parsing** guidance — authors constrain files to the YAML 1.2 Core Schema types, and implementations use their library's safe/strict mode (e.g. `yaml.safe_load()`) to avoid type coercion, object-deserialization, and anchor/alias pitfalls.
