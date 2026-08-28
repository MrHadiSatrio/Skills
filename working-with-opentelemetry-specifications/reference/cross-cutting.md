# OpenTelemetry Specification: Cross-Cutting Concerns

> Context, Propagation, Resource, Entities, Common Attributes, Instrumentation Scope

---

## 2. Cross-Cutting: Context & Propagation

### 2.1 Context API
[Source: context/README.md]

**Status: Stable**

Context is an immutable propagation mechanism carrying execution-scoped values across API boundaries.

**API contracts:**
- `CreateKey(name) -> Key` — MUST accept key name; MUST return opaque key object
- `Value(context, key) -> value` — MUST return value in Context for key
- `WithValue(context, key, value) -> Context` — MUST return new Context with value set

**Immutability:** Context MUST be immutable. Write operations MUST create a new Context.

**Implicit Context (languages with implicit propagation):**
- `GetCurrent() -> Context` — MUST return Context associated with caller's current execution unit
- `Attach(context) -> Token` — MUST accept Context; MUST return Token to restore previous Context
- `Detach(token)` — MUST accept Token from Attach(); MAY emit signal on wrong call order

### 2.2 Propagators API
[Source: context/api-propagators.md]

**Status: Stable**

**TextMapPropagator interface:**
- `Inject(context, carrier, [setter])` — Injects values into carrier (e.g., HTTP headers). MUST retrieve value from Context first.
- `Extract(context, carrier, [getter]) -> Context` — Extracts values from carrier. MUST NOT throw if value cannot be parsed. MUST NOT store new value in Context if extraction fails.
- `Fields() -> []string` — Returns list of header field names this propagator uses.

**"In order to increase compatibility, the key-value pairs MUST only consist of US-ASCII characters that make up valid HTTP header fields as per RFC 9110."**

**Getter interface:**
- MUST be stateless (save as constants)
- `Keys(carrier) -> []string` — MUST return all keys in carrier
- `Get(carrier, key) -> string` — MUST return first value of key or null; MUST be case-insensitive for HTTP
- `GetAll(carrier, key) -> []string` — MUST return all values; MUST be case-insensitive for HTTP

**Setter interface:**
- MUST be stateless
- `Set(carrier, key, value)` — MUST replace propagation field with given value; MUST preserve casing for case-sensitive protocols

**Composite Propagator:**
- Implementations MUST offer facility to group multiple Propagators
- `Create(propagators_list) -> CompositePropagator`
- Extract/Inject run all propagators in registration order

**Global Propagator:**
- `GetTextMapPropagator() -> TextMapPropagator` — MUST exist
- `SetTextMapPropagator(propagator)` — MUST exist
- MUST use no-op propagator unless explicitly configured
- Default: W3C TraceContext + W3C Baggage

**Distribution:** The official propagators (W3C TraceContext, W3C Baggage, B3) "MUST be maintained by the OpenTelemetry organization and MUST be distributed as OpenTelemetry Core packages" (W3C TraceContext MAY alternatively ship in the API). Jaeger (Deprecated) and OT Trace MAY be distributed as Core packages. Vendor-specific propagators such as AWS X-Ray "MUST NOT be maintained or distributed as part of the OpenTelemetry Core packages."

**Built-in propagators:**

| Propagator | Env var value | Headers |
|---|---|---|
| W3C TraceContext | `tracecontext` | `traceparent`, `tracestate` |
| W3C Baggage | `baggage` | `baggage` |
| B3 Single | `b3` | `b3` |
| B3 Multi | `b3multi` | `X-B3-*` |

**B3 requirements:**
- MUST attempt extract using both single and multi-header formats; single-header takes precedence
- MUST preserve debug trace flag; MUST set sampled flag when debug flag set
- MUST NOT reuse `X-B3-SpanId` as the ID for the server-side span
- MUST default to injecting B3 using single-header format; MUST provide configuration to change the default to multi-header
- MUST NOT propagate `X-B3-ParentSpanId`

**OTEL_PROPAGATORS** env var: comma-separated list (default: `tracecontext,baggage`); MUST be deduplicated.

### 2.3 Environment Carriers
[Source: context/env-carriers.md]

**Status: Release Candidate.** Environment variables as `TextMapPropagator` carriers across process boundaries (batch systems, CI/CD, command-line tools).

**Carrier vs. propagator split:**
- "The environment variable carrier MUST be format-agnostic and MUST treat values as opaque strings and MUST NOT apply propagation-format-specific logic such as validating, parsing values, or enforcing other format-specific constraints."
- The propagators (W3C Trace Context, W3C Baggage, ...) remain solely responsible for key names, naming conventions, validation/parsing, and truncation.
- "Language implementations MUST NOT spawn child processes as part of environment variable context propagation."
- Language implementations SHOULD document operational guidance (initialization-time extraction, child-process environment handling, security).

**Key name normalization** (applies to whichever component implements `Get`, `Set`, `Keys` — carrier, Getter, Setter, or other API). "To normalize a key name, implementations MUST:"
- replace an empty key name with a single underscore (`_`),
- uppercase ASCII letters,
- replace every character that is not an ASCII letter, digit, or underscore with `_`,
- prefix with `_` if it would otherwise start with an ASCII digit.

Normalized names match `^[A-Z_][A-Z0-9_]*$`.
- "`Set` MUST write values using the normalized form of the key provided by the propagator."
- "`Get` MUST normalize the key requested by the propagator and MUST use the normalized key name to read from the carrier." (e.g. `x-b3-traceid` → read `X_B3_TRACEID`; MUST NOT read a non-normalized variable named `x-b3-traceid`)
- "`Keys` MUST return only key names that are already normalized."
- Note: case-insensitive platforms (Windows) may match a variable differing only by case.

Operational guidance (immutability, process spawning, security) and implementation guidelines are non-normative. Context via environment variables is not appropriate for sensitive information.

---

## 3. Cross-Cutting: Resource

### 3.1 Resource SDK
[Source: resource/sdk.md]

**Status: Stable** except where otherwise specified. A Resource "is an immutable representation of the observed entity for which telemetry is being produced, expressed as Attributes." The SDK MUST allow creation of Resources and association with telemetry. Note (resource/README.md): the Resource describes the *observed* entity, not the agent that technically emits (e.g. eBPF auto-instrumentation); "It MUST identify the observed entity for which telemetry is being produced."

**API contracts:**
- `Create(attributes, schema_url?, entities?) -> Resource` — "The interface MUST provide a way to create a new resource." `schema_url` (since 1.4.0, optional; empty when unspecified). `Entities` (Development, since 1.60.0, optional; no entities when unspecified). "When both `Entities` and `Attributes` are provided in the create method, the system MUST behave as if a Resource is created with just `Attributes` and then merges with another Resource created with just `Entities`."
- `Merge(old_resource, updating_resource) -> Resource` — updating resource's attributes take precedence. "If either resource contains `Entities` then merge behavior with Entities MUST be used, otherwise merge behavior without Entities MUST be used."
  - **Without entities:** result MUST have all attributes from both inputs; if a key exists on both, "the value of the updating resource MUST be picked (even if the updated value is empty)". Schema URL: take whichever is non-empty; same → keep; both non-empty and different → merging error, result undefined.
  - **With entities (Development):** "the merge operation MUST follow the resource data model's merge algorithm" (3.2); "The resulting `SchemaURL` MUST match the behavior defined in the merge algorithm." Resource `SchemaURL` is kept only for backwards compatibility.
- Empty resource — recommended, not required.
- Retrieve attributes — read-only collection; order not guaranteed. "When entities are enabled and present for the Resource, this list MUST include all attributes, including those associated with entities."
- Retrieve entities (Development) — SDK SHOULD provide; order not guaranteed.
- Retrieve unassociated attributes (Development) — SDK SHOULD provide attributes NOT associated with any entity.

**SDK-provided resource attributes:**
- "The SDK MUST provide access to a Resource with at least the attributes listed at Semantic Attributes with SDK-provided Default Value."
- "This resource MUST be associated with a `TracerProvider`, `MeterProvider`, or `LoggerProvider` if another resource was not explicitly specified."
- When associated with a `TracerProvider`, "all `Span`s produced by any `Tracer` from the provider MUST be associated with this `Resource`." Metrics and log records from a `MeterProvider`/`LoggerProvider` will be associated likewise. The association cannot be changed later.

**Environment variables:**
- `OTEL_RESOURCE_ATTRIBUTES` — `key1=value1,key2=value2`. "The SDK MUST extract information from the `OTEL_RESOURCE_ATTRIBUTES` environment variable and merge this, as the secondary resource, with any resource information provided by the user" (user resource wins). "All attribute values MUST be considered strings. The `,` and `=` characters in keys and values MUST be percent encoded." Other characters MAY be percent-encoded (RFC 3986). On any error "the entire environment variable value SHOULD be discarded and an error SHOULD be reported".
- `OTEL_SERVICE_NAME` — sets `service.name`; "If `service.name` is also provided in `OTEL_RESOURCE_ATTRIBUTES`, then `OTEL_SERVICE_NAME` takes precedence." [Source: configuration/sdk-environment-variables.md]

**Resource Detectors:**
- Platform/vendor detectors (Docker, Kubernetes, EKS, ...) "MUST be implemented as packages separate from the SDK."
- "Resource detector packages MUST provide a method that returns a resource." They MAY detect from multiple sources and merge with `Merge`.
- "failure to detect any resource information MUST NOT be considered an error, whereas an error that occurs during an attempt to detect resource information SHOULD be considered an error."
- Detectors populating semantic-convention attributes "MUST ensure that the resource has a Schema URL set to a value that matches the semantic conventions." Empty Schema URL SHOULD be used if the detector populates no known attributes or does not know what it will populate. "If multiple detectors are combined and the detectors use different non-empty Schema URL it MUST be an error".
- **Detector name (Development):** detectors SHOULD have a unique snake_case name (lowercase alphanumeric and `_`) reflecting the root namespace of the attributes they populate; an SDK seeing duplicate names SHOULD report an error. Reserved built-in names: `container`, `host` (host.* and os.*), `process`, `service` (`service.name` from `OTEL_SERVICE_NAME`, plus `service.instance.id`).

### 3.2 Resource Data Model
[Source: resource/data-model.md]

**Status: Development.** Resource = set of `Entities` (0 or more) + `Attributes` not associated with any entity ("MUST not change during the lifetime of the resource").

**Identity:** the identity of a resource is the set of entities it contains; two resources differ if one contains an entity not in the other. Raw attributes are also identifying: different key-value pairs → different resource.

**Merging (entity-aware algorithm):** "SDKs SHOULD NOT update their merge algorithm until full Entity SDK support is provided." A merge SHOULD preserve existing identity while adding new identifying or descriptive information. Algorithm, for each new entity in priority order (highest first):
- if an entity of the same type exists in the set `E`: perform the Entity Data Model merge (4.x below); if they cannot merge, no change;
- otherwise add it to `E`;
- then: if all entities in `E` share one `schema_url`, set the Resource `schema_url` to it, otherwise blank; remove from `Attributes` any key present in the identity or description of an entity in `E`;
- if two entities use the same attribute key, remove the lower-priority entity.

Priority is generally implicit in configuration order (e.g. resource detector order). Worked examples 1-3 in the source show: an entity displaces a loose attribute; a loose attribute displaces a whole entity with a conflicting key; an entity of the same type but different identity is rejected.

---

## 3A. Cross-Cutting: Entities

### 3A.1 Entity Data Model
[Source: entities/data-model.md]

**Status: Development.** "Entity represents an object of interest associated with produced telemetry." Fields:
- `Type` (string) — required, "MUST not be empty for valid entities", MUST not change during the entity's lifetime.
- `ID` (map<string, attribute value>) — identifying attributes; MUST not change; must contain at least one attribute; SHOULD follow semantic conventions.
- `Description` (map<string, attribute value>) — non-identifying; MAY change; MAY be empty.

**Identity rules:**
- Minimally Sufficient Identity: the ID should include the minimal set of attributes that uniquely identifies the entity (e.g. `process.pid` + `process.start_time`, not `process.executable.name`).
- Repeatable Identity: identifying attributes SHOULD be repeatably obtainable by any observer of the entity.
- "OpenTelemetry Semantic Conventions MUST define a set of identifying attribute keys for every defined entity type." Identifying attribute names SHOULD use the entity type as prefix (`k8s.node.uid`).
- "Two independent observers that report the same entity MUST be able to supply identical values for all identifying attributes."
- "If an observer cannot reliably obtain one or more identifying attributes, it MUST NOT emit telemetry using that entity type." It SHOULD instead delegate to the observer that can, or emit a different entity type it can populate reliably.

**Attribute referencing model:** in OTLP entities do not carry their own key-value pairs; they reference keys in `resource.attributes` (backward compatible with OTLP 1.x). Shared descriptive keys with potentially conflicting values: "the attribute MUST logically belong to only one of them. All others SHOULD NOT reference it. The attribute MUST be referenced by the most specific entity" (closest in topology to the signal's entity; e.g. `k8s.node` over `k8s.cluster` for `cloud.availability_zone`).

**Merging of entities:** "Entities MAY be merged if and only if their types are the same, their identity attributes are exactly the same AND their schema_url is the same." Description attributes are merged with one entity as "primary" whose values win on conflict (in the example algorithm the new entity's descriptions take precedence). Entities with different `schema_url`s SHOULD be converted to the same schema version before merging.

### 3A.2 Entity Propagation
[Source: entities/entity-propagation.md]

**Status: Development.** Push-based entity instantiation via the `OTEL_ENTITIES` environment variable. "The SDK that has access to environment variables MUST provide an `EnvEntityDetector`" that uses it.

**Format:** `type{id_key=id_value,...}[desc_key=desc_value,...]@schema_url`, entities separated by `;` (empty segments ignored). `type` and keys match `[a-zA-Z][a-zA-Z0-9._-]*`; `{...}` required with at least one pair; `[...]` and `@schema_url` optional.
- "All attribute values MUST be considered strings and characters outside the `baggage-octet` range MUST be percent-encoded following the W3C Baggage specification." Reserved characters `{}[]@;,=` "MUST be percent-encoded when they appear literally in attribute values."
- Validation: entity type MUST NOT be empty; at least one identifying attribute MUST be present; keys MUST NOT be empty; schema URL, if present, MUST be a valid URI.
- Error handling (the SDK SHOULD be resilient): invalid syntax → SHOULD log a warning and ignore only the malformed portions; missing type/identity → skip that entity; duplicate entity (same type + identity) → SHOULD use the last occurrence; invalid schema URL → ignore the URL, keep the entity; conflicting identifying values of the same type → preserve only the last entity; conflicting descriptive keys across entities → last entity's value wins and the key SHOULD NOT be recorded on the others.

The `EnvEntityDetector` section itself is still a TODO in the source.

### 3A.3 Entity Events
[Source: entities/entity-events.md]

**Status: Development.** Entity information carried as Log Data Model Events, complementary to entities in Resource; useful when an entity has no telemetry of its own, its description needs complex values (maps/arrays), it needs relationships to other entities, or lifecycle must be tracked explicitly.
- `entity.state` — required attributes `entity.type` (string) and `entity.id` (map<string,string>, MUST contain at least one attribute; keys and values MUST be strings); optional `entity.description` (map<string, AnyValue>, complete current state; absent → empty map), `entity.relationships` (array of maps with `type`, `entity.type`, `entity.id`; absent → empty array), `entity.report.interval` (int64 seconds, MUST be non-negative when present; `0` → no periodic events). Implementations SHOULD emit on descriptive-attribute change and periodically.
- `entity.delete` — required `entity.type` and `entity.id`; optional `entity.delete.reason`. Implementations SHOULD emit on removal, but recipients MUST be prepared to expire entities whose events stop, and MUST be prepared to receive a delete out of order (recipients SHOULD then apply state updates by timestamp).
- Relationships (`relationship.type`, target `entity.type`, `entity.id`): standard types SHOULD be defined in semantic conventions; custom types MAY be defined; placement SHOULD prefer the entity with the shorter lifecycle; deleting an entity implicitly deletes its relationships, which backends SHOULD handle.

---

## 4. Cross-Cutting: Common

### 4.1 AnyValue
[Source: common/README.md]

AnyValue supports: `string`, `bool`, `int64`, `double` (IEEE 754), `bytes`, `ArrayValue` (list of AnyValue), `KeyValueList` (ordered list of key-AnyValue pairs), or empty/null.

- Arbitrary deep nesting allowed for arrays and maps
- Empty values, zero values, empty strings, empty arrays MUST be stored and passed to processors/exporters
- For homogeneous arrays: null values SHOULD be avoided; if unavoidable, MUST be preserved as-is
- Exporters not supporting null MAY replace with 0, false, or empty strings

**Non-OTLP string representation** (SHOULD-level): arrays as JSON arrays, maps as JSON objects with keys as member names. Elements/values: strings as JSON strings, booleans as JSON booleans, numbers as JSON numbers except NaN/Infinity as the JSON strings `"NaN"`, `"Infinity"`, `"-Infinity"`; byte arrays as Base64 (RFC 4648 §4) JSON strings; empty values as JSON `null`; nested arrays/maps recursively.

### 4.2 Attributes
[Source: common/README.md]

- Attribute key MUST be non-null and non-empty string (case-sensitive)
- Attribute value MUST be one of types defined in AnyValue
- Implementation MUST by default enforce unique keys in exported collections
- Setting attribute with duplicate key SHOULD overwrite existing value
- If option provided for duplicate keys, MUST be documented that handling is unpredictable
- Attribute collections are equal when they contain the same attributes irrespective of order

**Non-OTLP representation (Development):** a single Attribute is RECOMMENDED as a JSON object with one member (`{"http.request.method": "GET"}`); an Attribute Collection as a JSON object with one member per attribute; values follow the AnyValue rules in 4.1. The spec notes this representation is lossy (type and numeric precision).

### 4.3 Attribute Limits
[Source: common/README.md]

**Defaults (Configurable Parameters):**
- `AttributeCountLimit` = 128 (max attributes per record)
- `AttributeValueLengthLimit` = Infinity/unlimited (max string/byte length)
- `AttributeValueDepthLimit` = 64 (max attribute value depth; applies to arrays and maps)

**Truncation rules (when limit configured):**
- String values MUST be truncated if exceeding limit (each character = 1)
- Byte arrays MUST be truncated if exceeding limit (each byte = 1)
- Array of strings: limit applied per element
- Otherwise: value MUST NOT be truncated

**Drop rules:**
- Adding attribute exceeding count limit: SDK MUST discard that attribute
- Count limit applies only to top-level attributes, not to nested key-value pairs in maps
- Otherwise: attribute MUST NOT be discarded

**Depth rules:** "the SDK MUST start counting depth at 1 for the top-level attribute value, and increment depth when descending into arrays (both homogeneous and heterogeneous) or maps; arrays or map at a depth greater than the limit MUST be replaced with an empty value; otherwise a value MUST NOT be changed due to the depth limit."

If the SDK implements these limits it MUST provide a way to change them programmatically. Value length and depth limits apply recursively to attribute values; none of the limits apply to other structures such as `LogRecord.Body`.

**Signal-specific overrides:** MUST attempt model-specific first, then general, then model-specific default, then global default.

**Logging:** MAY emit a log when an attribute is "truncated, discarded, or replaced due to a limit"; "the log MUST NOT be emitted more than once per record on which an attribute is set."

**Exemptions:** Resource attributes SHOULD be exempt. Metric attributes exempt (see metrics SDK).

### 4.4 Instrumentation Scope
[Source: common/instrumentation-scope.md]

Identity tuple: `(name, version, schema_url, attributes)` — same tuple = same scope.

- `name` (required): Identifies scope (e.g., library/package fully-qualified name)
- `version` (optional): Version of the scope
- `schema_url` (optional): Telemetry Schema URL
- `attributes` (optional): Additional scope metadata

Obtained via `Provider.GetTracer/GetMeter/GetLogger(name, version?, schema_url?, attributes?)`.

### 4.5 Attribute Naming
[Source: common/attribute-naming.md]

Moved to [Semantic Conventions Naming](https://opentelemetry.io/docs/specs/semconv/general/naming/). See semantic conventions repo for guidelines.

### 4.6 Attribute Type Mapping
[Source: common/attribute-type-mapping.md]

**Tier 3.** Rules for converting values obtained outside OpenTelemetry (primitives, arrays, maps, composite/other/empty values) into AnyValue. Only the table-of-contents markers changed at this commit.
