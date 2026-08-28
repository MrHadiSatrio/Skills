# OpenTelemetry Specification: Compliance Checklist

> **How to use:** Check boxes as your implementation satisfies each requirement. MUST NOT items are violations if present. Organized by component for targeted auditing. Items tagged `[Development]` come from spec sections at Development status; audit them only when the implementation opts into that feature. Each section names the reference file that carries the quoted requirement text.

---

## Appendix A: Compliance Checklist

### A.1 General / Error Handling
[Source: error-handling.md, performance.md, versioning-and-stability.md, self-observability.md] — see `overview.md` 1.2, 1.4, 1.7
- [ ] MUST NOT throw unhandled exceptions at runtime
- [ ] API methods MUST NOT throw unhandled exceptions when used incorrectly by end users
- [ ] SDK MUST NOT throw unhandled exceptions for errors in their own operations
- [ ] API methods accepting external callbacks MUST handle all errors
- [ ] SDK MUST return a "no-op" or default object when API returns non-null value and error occurs
- [ ] Library SHOULD log suppressed errors using language-specific conventions
- [ ] SDK MUST allow end users to change the library's default error handling behavior
- [ ] MUST NOT cause the application to fail later at runtime due to dynamic config settings
- [ ] Each language implementation MUST produce a `VERSIONING` / `VERSIONING.md` document at the repository root
- [ ] Backward-incompatible changes to stable API packages MUST NOT be made without major version bump
- [ ] All existing API calls MUST continue to compile and function against all future minor versions of same major
- [ ] Public portions of SDK packages MUST remain backwards compatible
- [ ] Signals MUST NOT be marked deprecated unless replacement is stable
- [ ] Major version MUST be bumped when breaking change to stable interface or deprecated signal removed
- [ ] OpenTelemetry clients MUST follow Semantic Versioning 2.0.0
- [ ] All stable API packages MUST version together across all signals (no separate version numbers)
- [ ] SDK packages for all signals MUST version together across all signals
- [ ] Major API versions MUST be supported for minimum of 3 years after next major API version; API stability MUST be maintained and bug/security fixes MUST be backported in that window
- [ ] Terms denoting stability MUST NOT be used as part of directory or import names
- [ ] SDK SHOULD emit self-observability telemetry about its own behavior; SDKs implementing self-observability metrics SHOULD follow the SDK Metrics semantic conventions [Development]

### A.2 Context & Propagation
[Source: context/README.md, context/api-propagators.md, context/env-carriers.md] — see `cross-cutting.md` 2.1–2.3
- [ ] Context MUST be immutable
- [ ] Write operations on Context MUST result in creation of new Context
- [ ] CreateKey() MUST accept key name parameter
- [ ] CreateKey() MUST return opaque object representing newly created key
- [ ] Value() MUST accept Context and key; MUST return value for key
- [ ] WithValue() MUST accept Context, key, value; MUST return new Context
- [ ] GetCurrent() MUST return Context for caller's current execution unit
- [ ] Attach() MUST accept Context; MUST return Token to restore previous Context
- [ ] Detach() MUST accept Token from previous Attach()
- [ ] Propagators MUST define Inject and Extract operations
- [ ] Extract MUST NOT throw if value cannot be parsed from carrier
- [ ] Extract MUST NOT store new value in Context if extraction fails
- [ ] TextMapCarrier key/value pairs MUST only consist of US-ASCII valid HTTP header characters (RFC 9110)
- [ ] Getter and Setter MUST be stateless
- [ ] Setter.Set() MUST preserve casing for case-sensitive protocols
- [ ] Getter.Keys() MUST return all keys in carrier
- [ ] Getter.Get() MUST return first value or null; MUST be case-insensitive for HTTP
- [ ] Getter.GetAll() MUST return all values; MUST be case-insensitive for HTTP
- [ ] Implementations MUST offer facility to group multiple Propagators (CompositePropagator)
- [ ] GetTextMapPropagator() MUST exist
- [ ] SetTextMapPropagator() MUST exist
- [ ] API MUST use no-op propagator unless explicitly configured
- [ ] Pre-configured propagators MUST allow to be disabled or overridden
- [ ] W3C TraceContext, W3C Baggage, and B3 propagators MUST be distributed as OpenTelemetry Core packages; vendor-specific propagators (e.g. AWS X-Ray) MUST NOT be
- [ ] W3C TraceContext propagator MUST parse and validate traceparent and tracestate headers
- [ ] B3: MUST attempt extract using single and multi-header formats; single-header takes precedence
- [ ] B3: MUST preserve debug trace flag; MUST set sampled flag when debug flag set
- [ ] B3: MUST NOT reuse X-B3-SpanId as server-side span id
- [ ] B3: MUST default to injecting using single-header format
- [ ] B3: MUST provide configuration to change injection to multi-header format
- [ ] B3: MUST NOT propagate X-B3-ParentSpanId
- [ ] OTEL_PROPAGATORS values MUST be deduplicated
- [ ] Env carrier: MUST be format-agnostic; MUST treat values as opaque strings; MUST NOT apply propagation-format-specific logic (validating, parsing)
- [ ] Env carrier: implementations MUST NOT spawn child processes as part of environment variable context propagation
- [ ] Env carrier: key names MUST be normalized (empty → `_`; uppercase ASCII letters; non-alphanumeric/underscore → `_`; leading digit → prefix `_`)
- [ ] Env carrier: Set MUST write using the normalized key; Get MUST normalize the requested key and MUST read the normalized name (MUST NOT read the non-normalized name); Keys MUST return only normalized names

### A.3 Resource SDK
[Source: resource/sdk.md, resource/data-model.md] — see `cross-cutting.md` 3.1–3.2
- [ ] SDK MUST allow creation of Resources and associating them with telemetry
- [ ] Resource MUST identify the observed entity for which telemetry is produced (not the emitting agent)
- [ ] All Spans from TracerProvider MUST be associated with its Resource
- [ ] SDK MUST provide access to Resource with SDK-provided default attributes
- [ ] Default Resource MUST be associated with TracerProvider/MeterProvider/LoggerProvider if not explicitly specified
- [ ] Resource.Create() interface MUST be provided
- [ ] Resource.Merge() interface MUST be provided
- [ ] Merge without entities: resulting resource MUST have all attributes from both inputs
- [ ] Merge without entities: if key exists on both, updating_resource value MUST be picked (even if empty)
- [ ] Merge: if either resource contains Entities, merge behavior with Entities MUST be used, otherwise merge behavior without Entities MUST be used [Development]
- [ ] Merge with entities: MUST follow the resource data model's merge algorithm; resulting SchemaURL MUST match that algorithm [Development]
- [ ] Create() with both Entities and Attributes MUST behave as if a Resource created with just Attributes is merged with one created with just Entities [Development]
- [ ] Retrieve-attributes MUST include all attributes, including those associated with entities, when entities are present [Development]
- [ ] Custom resource detectors MUST be implemented as packages separate from SDK
- [ ] Resource detector packages MUST provide method returning a Resource
- [ ] Failure to detect resource information MUST NOT be considered an error
- [ ] Detectors populating semantic convention attributes MUST set Schema URL
- [ ] Multiple detectors with different non-empty Schema URLs MUST be an error
- [ ] SDK MUST extract information from OTEL_RESOURCE_ATTRIBUTES and merge it as the secondary resource (user resource wins)
- [ ] All attribute values in OTEL_RESOURCE_ATTRIBUTES MUST be treated as strings
- [ ] `,` and `=` in OTEL_RESOURCE_ATTRIBUTES keys/values MUST be percent-encoded

### A.4 Common / Attributes
[Source: common/README.md, common/instrumentation-scope.md] — see `cross-cutting.md` 4.1–4.4
- [ ] Homogeneous arrays MUST NOT contain values of different types
- [ ] Empty values, zero, empty string, empty array MUST be stored and passed to processors/exporters
- [ ] Null values within arrays MUST be preserved as-is
- [ ] Attribute key MUST be non-null and non-empty string
- [ ] Attribute value MUST be one of types defined in AnyValue
- [ ] Implementation MUST by default enforce unique keys in exported attribute collections
- [ ] If option provided for duplicate keys, MUST be documented
- [ ] SDK MUST truncate string attribute value if exceeding length limit
- [ ] SDK MUST truncate byte array if length exceeds limit
- [ ] SDK MUST discard attribute if adding would exceed count limit
- [ ] Count limit MUST NOT apply to nested key-value pairs in maps
- [ ] AttributeValueDepthLimit (default 64): SDK MUST count depth from 1 at the top-level value and increment when descending into arrays or maps
- [ ] Arrays or maps at a depth greater than the limit MUST be replaced with an empty value; otherwise a value MUST NOT be changed due to the depth limit
- [ ] Log MUST NOT be emitted more than once per record on truncation/discard/replacement
- [ ] SDK MUST provide way to change attribute limits programmatically

### A.5 Traces API
[Source: trace/api.md] — see `traces.md` 5.1
- [ ] GetTracer() MUST accept name, version, schema_url, attributes parameters
- [ ] Working Tracer MUST be returned as fallback (not null, not exception) for invalid name
- [ ] Implementations MUST NOT require repeatedly obtaining Tracer with same identity for config changes
- [ ] Tracer SHOULD provide Enabled(); if provided it MUST return a language idiomatic boolean type and MUST be structured so parameters can be added
- [ ] MUST NOT be any API for creating Span other than with Tracer
- [ ] Span creation MUST NOT set newly created Span as active in current Context by default
- [ ] StartSpan MUST NOT accept Span or SpanContext as parent — only full Context
- [ ] Each root span MUST be created with new TraceId
- [ ] Child span TraceId MUST match parent TraceId
- [ ] Child span MUST inherit all TraceState values of parent by default
- [ ] Empty non-recording Span MUST be returned when parent Context contains no Span
- [ ] IsRemote MUST return true when extracted via Propagators
- [ ] IsRemote MUST return false for child spans
- [ ] TraceId MUST be 32-hex-character lowercase string in hex form
- [ ] SpanId MUST be 16-hex-character lowercase string in hex form
- [ ] Binary TraceId MUST be 16-byte array; Binary SpanId MUST be 8-byte array
- [ ] IsValid MUST be provided (true if non-zero TraceId AND non-zero SpanId)
- [ ] IsRemote MUST be provided
- [ ] All TraceState mutations MUST return new TraceState
- [ ] TraceState MUST always be valid per W3C Trace Context spec
- [ ] TraceState mutations MUST validate input; MUST NOT return invalid data
- [ ] Links with empty TraceId/SpanId MUST be recorded if attributes or TraceState non-empty
- [ ] Any span that is created MUST also be ended (user responsibility)
- [ ] GetContext() MUST return same SpanContext for entire Span lifetime
- [ ] IsRecording MUST return false to signal events/attributes not being recorded
- [ ] SetStatus() MUST be provided; Description MUST be IGNORED for Ok and Unset
- [ ] Ok status MUST override any prior or future Error/Unset attempts
- [ ] End() without end_time MUST use current time
- [ ] End() MUST NOT block on calling thread
- [ ] End() MUST NOT affect child spans
- [ ] End() MUST NOT inactivate Span in any Context it is active in
- [ ] RecordException() MUST record as Event named "exception"
- [ ] NonRecordingSpan: GetContext MUST return wrapped SpanContext; IsRecording MUST return false
- [ ] NonRecordingSpan MUST be fully implemented in API
- [ ] TracerProvider all methods MUST be safe for concurrent use
- [ ] Tracer all methods MUST be safe for concurrent use
- [ ] Span all methods MUST be safe for concurrent use
- [ ] API documentation MUST state adding attributes at span creation is preferred
- [ ] API documentation MUST state adding links at span creation is preferred

### A.6 Traces SDK
[Source: trace/sdk.md, trace/tracestate-handling.md] — see `traces.md` 5.2, 5.5
- [ ] TracerProvider MUST implement Get a Tracer API
- [ ] Input MUST be used to create InstrumentationScope on Tracer
- [ ] Configuration MUST be owned by TracerProvider
- [ ] Updated configuration MUST apply to all already-returned Tracers
- [ ] TracerProvider.Shutdown() MUST be called only once; subsequent Tracer gets return no-op
- [ ] TracerProvider.Shutdown() MUST invoke Shutdown on all SpanProcessors
- [ ] TracerProvider.ForceFlush() MUST invoke ForceFlush on all SpanProcessors
- [ ] Tracer.Enabled MUST return false when there are no registered SpanProcessors
- [ ] Tracer.Enabled MUST return false when Tracer is disabled (TracerConfig.enabled=false) [Development]
- [ ] SDK MUST NOT allow SampledFlag=true with IsRecording=false
- [ ] AlwaysRecord decorator MUST convert DROP → RECORD_ONLY and pass RECORD_ONLY / RECORD_AND_SAMPLE through unchanged
- [ ] ComposableSamplers MUST NOT modify the OpenTelemetry TraceState (`ot` sub-key); explicit randomness values MUST not be modified [Development]
- [ ] SDKs and Samplers MUST NOT overwrite explicit randomness (`rv`) in an OpenTelemetry TraceState value [Development]
- [ ] OTel tracestate values MUST all be contained in a single entry using the `ot` key; list length MUST NOT exceed 256 characters; keys MUST be unique
- [ ] Instrumentation libraries and clients MUST NOT use the `ot` tracestate entry; `rv` MUST be exactly 14 lower-case hexadecimal digits
- [ ] SpanProcessor.OnStart() SHOULD NOT block or throw
- [ ] SpanProcessor.Shutdown() MUST be called only once; MUST include effects of ForceFlush
- [ ] SpanProcessor.ForceFlush() MUST prioritize timeout over completeness
- [ ] Built-in SpanProcessors MUST call exporter's Export then ForceFlush during ForceFlush
- [ ] SimpleSpanProcessor and BatchSpanProcessor MUST synchronize Export calls
- [ ] SDK MUST randomly generate both TraceId and SpanId by default
- [ ] SDK MUST provide mechanism for customizing ID generation
- [ ] Custom IdGenerators for vendor-specific protocols MUST NOT be in Core OTel packages
- [ ] BatchSpanProcessor.maxExportBatchSize MUST be ≤ maxQueueSize
- [ ] SpanExporter.Export() MUST NOT block indefinitely
- [ ] SpanExporter.Shutdown() — subsequent Export SHOULD return Failure
- [ ] Default SDK SpanProcessors SHOULD NOT implement retry logic
- [ ] SpanExporter.ForceFlush() and Shutdown() MUST be safe for concurrent use
- [ ] Span attributes MUST adhere to the common attribute-limit rules (count, length, depth)
- [ ] If SDK implements span limits, MUST provide way to change via config
- [ ] Discard message MUST be logged at most once per Span
- [ ] Tracing SDK SHOULD support SDK self-observability [Development]

### A.7 Metrics API
[Source: metrics/api.md] — see `metrics.md` 6.1
- [ ] GetMeter() MUST accept name, version, schema_url, attributes parameters
- [ ] Working Meter MUST be returned as fallback (not null, not exception) for invalid name
- [ ] Meter MUST provide functions to create all instrument types
- [ ] MUST NOT be any API for creating Counter other than with Meter (same for all instrument types)
- [ ] Instrument name MUST start with letter; MUST be 1-255 chars; alphanumeric+_-./
- [ ] Instrument unit MUST be case-sensitive ASCII, max 63 chars
- [ ] Instrument description MUST support BMP Unicode, min 1023 chars
- [ ] unit, description, and advisory parameters MUST NOT obligate the user to provide them
- [ ] API MUST allow flexible attributes at invocation time (variable number including none)
- [ ] Async: Every registered Callback MUST be evaluated exactly once per collection cycle
- [ ] Async: API MUST treat observations from single Callback as at single instant (identical timestamps)
- [ ] Async: User MUST be able to undo callback registration
- [ ] Async: Multiple-instrument Callbacks MUST be associated with declared instruments at registration
- [ ] Bind(): MUST accept a variable number of attributes, including none; MUST return a language-idiomatic bound-instrument type [Development]
- [ ] Bind(): returned bound instrument MUST support the instrument's core recording operation (Add / Record) [Development]
- [ ] Bind(): if the instrument interface is reused, Bind MUST be documented to state that attribute-bearing recording on the bound instrument negates the performance benefit [Development]
- [ ] Duplicate instrument registration: Meter MUST return a functional instrument; a warning SHOULD be emitted
- [ ] MeterProvider all methods MUST be safe for concurrent use
- [ ] Meter all methods MUST be safe for concurrent use
- [ ] Instrument all methods MUST be safe for concurrent use

### A.8 Metrics SDK
[Source: metrics/sdk.md, metrics/sdk_exporters/otlp.md, metrics/sdk_exporters/prometheus.md] — see `metrics.md` 6.2, 6.4
- [ ] MeterProvider MUST implement Get a Meter API
- [ ] Input MUST be used to create InstrumentationScope on Meter
- [ ] Configuration MUST be owned by MeterProvider
- [ ] Updated configuration MUST apply to all already-returned Meters
- [ ] MeterProvider.Shutdown() MUST be called only once; MUST invoke Shutdown on all MetricReaders/Exporters
- [ ] MeterProvider.ForceFlush() MUST invoke ForceFlush on all MetricReader instances
- [ ] view_matching_mode: if accepted, MUST support `independent` and `composable`; if unspecified the SDK MUST use `independent` [Development]
- [ ] view_matching_mode: any other value MUST be treated as unsupported — SDK MUST either fail fast at initialization or warn, ignore, and use `independent` [Development]
- [ ] SDK MUST provide functionality to create Views and register them with MeterProvider
- [ ] Views MUST accept Instrument selection criteria AND stream configuration
- [ ] SDK MUST accept name, type, unit, meter_name, meter_version, meter_schema_url as selection criteria
- [ ] View name selection MUST support at least a single wildcard `*`
- [ ] Stream-configuration `name` MUST NOT be validated against the instrument name syntax
- [ ] Attributes not in the View's `attribute_keys` allow-list MUST be ignored
- [ ] If View and advisory params conflict on same aspect, View MUST take precedence
- [ ] SDK MUST provide Drop, Default, Sum, LastValue, ExplicitBucketHistogram aggregations
- [ ] SDK SHOULD provide Base2ExponentialBucketHistogram aggregation
- [ ] Cardinality overflow: SDK MUST create overflow Aggregator (`otel.metric.overflow=true`) before reaching limit
- [ ] Cardinality: SDK MUST guarantee no overflow when distinct non-overflow attribute sets ≤ limit
- [ ] Cardinality: MUST NOT double-count or drop any measurement
- [ ] Cardinality cumulative: MUST continue exporting all attribute sets observed prior to overflow
- [ ] Bound instrument MUST behave identically to the unbound recording operation with the pre-bound attributes [Development]
- [ ] Bind: attribute processing and cardinality evaluation MUST be performed at bind time; each Bind call MUST be evaluated independently; resolved aggregator MUST be fixed across collection cycles [Development]
- [ ] Bind: measurements MUST be candidates for Exemplar sampling; attribute-free recordings MUST bypass per-recording map lookup [Development]
- [ ] MetricReader MUST NOT be registered on >1 MeterProvider
- [ ] SDK MUST support multiple MetricReader instances
- [ ] MetricReader.Collect() MUST return data per reader's temporality preference
- [ ] PeriodicExportingMetricReader MUST synchronize Export calls; if an export is still in progress at the next interval, MUST either delay the collection or skip that interval
- [ ] PeriodicExportingMetricReader.maxExportBatchSize: no batch given to Export may exceed it; initial data MUST be split into as many full batches as possible; batches from one Collect() MUST be exported serially and in order; MUST NOT combine metrics from different Collect() calls into one batch [Development]
- [ ] MetricExporter.Export() MUST NOT block indefinitely
- [ ] MetricExporter.ForceFlush() and Shutdown() MUST be safe for concurrent use
- [ ] When exemplar filter off, SDK MUST NOT have overhead related to exemplar sampling
- [ ] ExemplarReservoir MUST provide offer and collect methods; a new reservoir MUST be created per known timeseries data point
- [ ] ExemplarReservoir MUST be cleared/reset during collection before reading
- [ ] SDK MUST include SimpleFixedSizeExemplarReservoir and AlignedHistogramBucketExemplarReservoir; custom reservoirs MUST be configurable on a View
- [ ] Meter MUST return instrument using first-seen name casing; MUST log error on name conflict
- [ ] SDK MUST aggregate data from identical instruments together
- [ ] Metric attributes MUST adhere to the common attribute-limit rules (OTEL_METRIC_ATTRIBUTE_*)
- [ ] OTLP exporter MUST provide temporality configuration per OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE (default cumulative) and default histogram aggregation per OTEL_EXPORTER_OTLP_METRICS_DEFAULT_HISTOGRAM_AGGREGATION
- [ ] Prometheus exporter MUST support text format 0.0.4; MUST NOT use Prometheus Remote Write or OpenMetrics protobuf format
- [ ] Prometheus exporter SHOULD NOT add explicit timestamps on Metric points
- [ ] Prometheus exporter MUST have at most one `target` info metric; MUST set MetricReader temporality to CUMULATIVE for all instrument kinds
- [ ] Prometheus exporter `host` MUST default to `localhost`; `port` MUST default to 9464
- [ ] Prometheus exporter `scope_info_enabled` MUST be true by default; `target_info_enabled` MUST be true by default [Development for target_info_enabled]
- [ ] Prometheus exporter MUST NOT add resource attributes as metric labels by default [Development]
- [ ] Prometheus exporter: `translation_strategy` MUST be applied first, then content negotiation per `Accept` header; with no `Accept` and no fallback MUST use text format 0.0.4 with `underscores` escaping
- [ ] Metrics SDK SHOULD support SDK self-observability [Development]

### A.9 Logs API
[Source: logs/api.md] — see `logs.md` 7.2
- [ ] GetLogger() MUST accept name, version, schema_url, attributes parameters
- [ ] Working Logger MUST be returned as fallback (not null, not exception) for invalid name
- [ ] Logger MUST provide Emit function
- [ ] Logger SHOULD provide Enabled function; if provided it MUST return a language idiomatic boolean type
- [ ] Emit MUST accept Timestamp, ObservedTimestamp, Context, SeverityNumber, SeverityText, Body, Attributes, EventName
- [ ] When implicit Context supported: unspecified Context MUST use current Context
- [ ] Optional parameters: API MUST accept but MUST NOT obligate user to provide
- [ ] Required parameters: API MUST obligate user to provide
- [ ] LoggerProvider all methods MUST be safe for concurrent use
- [ ] Logger all methods MUST be safe for concurrent use

### A.10 Logs SDK
[Source: logs/sdk.md] — see `logs.md` 7.3
- [ ] LoggerProvider MUST implement Get a Logger API
- [ ] Input MUST be used to create InstrumentationScope on Logger
- [ ] Configuration MUST be owned by LoggerProvider
- [ ] Updated configuration MUST apply to all already-returned Loggers
- [ ] LoggerProvider.Shutdown() MUST be called only once; MUST invoke Shutdown on all LogRecordProcessors
- [ ] LoggerProvider.ForceFlush() MUST invoke ForceFlush on all LogRecordProcessors
- [ ] If Logger disabled (LoggerConfig.enabled=false), MUST behave as No-op Logger [Development]
- [ ] If LogRecord's SeverityNumber is specified (≠0) and < minimum_severity, MUST drop [Development]
- [ ] If trace_based=false, log records MUST NOT be affected by that parameter; if true, records associated with unsampled traces MUST be dropped [Development]
- [ ] If Exception provided, SDK MUST set attributes from exception; user attrs MUST take precedence
- [ ] User-provided attributes MUST NOT be overwritten by exception-derived attributes
- [ ] Before processing, MUST apply the LoggerConfig filtering rules unconditionally, in order: enabled, minimum_severity, trace_based [Development]
- [ ] Enabled MUST return false when no registered LogRecordProcessors
- [ ] Enabled MUST return false when Logger disabled, severity below minimum_severity, or trace_based=true with unsampled current context [Development]
- [ ] Enabled MUST return false when all registered processors implement Enabled and each returns false
- [ ] ReadableLogRecord: MUST access InstrumentationScope and Resource
- [ ] Trace context fields MUST be populated from resolved Context
- [ ] Dropped-attribute counts MUST be available to exporters
- [ ] LogRecordProcessor.OnEmit() mutations MUST be visible to next registered processors
- [ ] LogRecordProcessor.Shutdown() MUST be called only once; MUST include effects of ForceFlush
- [ ] LogRecordProcessor.ForceFlush() with an exporter MUST call Export with pending records then exporter ForceFlush
- [ ] SimpleLogRecordProcessor and BatchLogRecordProcessor MUST synchronize Export calls
- [ ] BatchLogRecordProcessor.maxExportBatchSize MUST be ≤ maxQueueSize
- [ ] Event-to-span-event bridge MUST bridge a LogRecord if and only if: non-empty EventName, valid TraceId/SpanId, current span IsRecording, and ids match the current span; otherwise MUST do nothing [Development]
- [ ] Event-to-span-event bridge MUST add exactly one span event (name = EventName; timestamp from Timestamp else ObservedTimestamp; all attributes copied); MUST NOT prevent the LogRecord from continuing through the pipeline [Development]
- [ ] LogRecordExporter.Export() MUST NOT block indefinitely
- [ ] LogRecordExporter.ForceFlush() and Shutdown() MUST be safe for concurrent use
- [ ] LogRecord attributes MUST adhere to the common attribute-limit rules (count, length, depth); limits do not apply to Body
- [ ] If SDK implements log limits, MUST provide way to change per LoggerProvider config
- [ ] Discard message MUST be logged at most once per LogRecord
- [ ] Logs SDK SHOULD support SDK self-observability [Development]

### A.11 Baggage API
[Source: baggage/api.md] — see `baggage-and-configuration.md` 8.1
- [ ] Each name MUST be associated with exactly one value
- [ ] Language API MUST accept any valid UTF-8 string as baggage value
- [ ] Language API MUST treat baggage names as case-sensitive
- [ ] Language API MUST treat baggage values as case-sensitive
- [ ] Baggage MUST be fully functional without SDK installed
- [ ] Baggage container MUST be immutable
- [ ] GetValue() MUST take name as input; return value or null
- [ ] GetAllValues() order MUST NOT be significant
- [ ] SetValue() MUST take name+value; return new Baggage; new value MUST take precedence on conflict
- [ ] RemoveValue() MUST take name; return new Baggage without that entry
- [ ] MUST provide FromContext(), ContextWithBaggage(), ContextWithoutBaggage()
- [ ] API MUST provide way to remove all baggage entries from context
- [ ] API layer MUST include TextMapPropagator implementing W3C Baggage Specification

### A.12 Configuration
[Source: configuration/sdk-environment-variables.md, configuration/sdk.md, configuration/data-model.md] — see `baggage-and-configuration.md` 9.1–9.3
- [ ] SDK MUST interpret empty value of env var same as unset
- [ ] Boolean: MUST be true only by case-insensitive "true"; MUST NOT extend this definition; any other value MUST be interpreted as false
- [ ] Boolean: renaming a variable or changing its default MUST NOT happen without a major version upgrade
- [ ] Enum values: unrecognized MUST generate warning and be gracefully ignored; SHOULD be interpreted case-insensitively
- [ ] Numeric values: if invalid, SHOULD generate warning and ignore
- [ ] Environment-based configuration MUST have direct code configuration equivalent
- [ ] OTEL_PROPAGATORS values MUST be deduplicated
- [ ] OTEL_TRACES_SAMPLER_ARG: invalid input MUST be logged; MUST be otherwise ignored
- [ ] OTEL_SERVICE_NAME takes precedence over `service.name` in OTEL_RESOURCE_ATTRIBUTES
- [ ] When OTEL_CONFIG_FILE set, all other env vars (except substitution refs) MUST be ignored
- [ ] YAML configuration files MUST use `.yaml` or `.yml` extensions
- [ ] SDK implementations of configuration MUST provide Parse, Create, and Register PluginComponentProvider operations
- [ ] Parse MUST perform environment variable substitution
- [ ] Parse MUST differentiate between properties that are missing and properties present but null
- [ ] Parse MUST resolve non-built-in extension component configuration to a generic ConfigProperties representation
- [ ] Create: if a property is present and null, MUST use `nullBehavior`, or `defaultBehavior` if `nullBehavior` is not set
- [ ] Create: if a required property is not present, MUST return an error
- [ ] Create MUST resolve non-built-in plugins via Create Component of the PluginComponentProvider of the matching `type` and `name`
- [ ] Create SHOULD return an error on invalid configuration (fail fast); if Create Component fails, SHOULD propagate the error
- [ ] SDK MUST provide a mechanism to register custom PluginComponentProviders
- [ ] Register MUST return an error if called multiple times with the same `type` and `name`
- [ ] PluginComponentProvider MUST provide Create Component(properties) -> component
- [ ] ConfigProvider MUST be created using a ConfigProperties representing the `.instrumentation` mapping node [Development]

### A.13 Entities [Development]
[Source: entities/data-model.md, entities/entity-propagation.md, entities/entity-events.md, resource/data-model.md] — see `cross-cutting.md` 3.2, 3A
- [ ] Entity Type MUST not be empty and MUST not change during the entity's lifetime; ID MUST not change
- [ ] Two independent observers reporting the same entity MUST be able to supply identical values for all identifying attributes
- [ ] If an observer cannot reliably obtain an identifying attribute, it MUST NOT emit telemetry using that entity type
- [ ] A descriptive attribute shared by several entities MUST belong to only one of them, the most specific entity
- [ ] Entities MAY be merged only if type, identity attributes, and schema_url are all the same
- [ ] Resource attributes not associated with an entity MUST not change during the lifetime of the resource
- [ ] SDKs SHOULD NOT update their resource merge algorithm until full Entity SDK support is provided
- [ ] SDK with access to environment variables MUST provide an EnvEntityDetector for OTEL_ENTITIES
- [ ] OTEL_ENTITIES: all attribute values MUST be treated as strings; characters outside `baggage-octet` MUST be percent-encoded; reserved `{}[]@;,=` MUST be percent-encoded in values
- [ ] OTEL_ENTITIES: entity type MUST NOT be empty and MUST match `[a-zA-Z][a-zA-Z0-9._-]*`; at least one identifying attribute MUST be present; keys MUST NOT be empty; schema URL if present MUST be a valid URI
- [ ] OTEL_ENTITIES: invalid syntax SHOULD log a warning and ignore only the malformed portions; duplicate entity SHOULD use the last occurrence
- [ ] Entity events: `entity.id` MUST contain at least one attribute with string keys and values; `entity.report.interval` MUST be non-negative when present
- [ ] Entity event recipients MUST be prepared to expire entities whose events stop and MUST be prepared to receive `entity.delete` out of order
