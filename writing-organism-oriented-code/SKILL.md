---
name: writing-organism-oriented-code
description: Conventions on writing Organism-Oriented Programming. Use when writing or modifying code in object-oriented codebases and/or languages.
---

# Organism-Oriented Programming

Objects are alive. They are autonomous organisms that own their behavior, interact through focused contracts, and grow through composition — not inheritance, not annotation magic, not manager classes.

## 1. Object Design

- **Objects own behavior** — no anemic models. A domain object is never a data bag manipulated by external "service" logic; it encapsulates the rules that govern it.
- **Value types for domain primitives** — self-validating, self-describing, comparable. A `Timestamp` validates its range at construction; a `Uuid` refuses invalid strings.
- **Null Object pattern over nullable types** — represent absence with a behavioral object (`Nobody`, `NoPlace`, `EmptyMoments`) rather than `null`.
- **Read/write interface split** — an immutable interface for reading, extended by a mutable interface for mutation. Callers that only read never see mutation methods.
- **Single-method interfaces** — contracts should be focused. One interface, one responsibility.
- **No `I` prefix or `Impl` suffix** — `Place`, not `IPlace`; `FilesystemMoment`, not `MomentImpl`.

## 2. Naming

- **Interfaces** are named after the domain concept itself — `Place`, `Moment`, `Coordinates`, `EventSink`.
- **Implementations** are prefixed by their mechanism or source — `FilesystemMoment` (storage), `GmsCoordinates` (GMS SDK), `GoogleNearbyPlaces` (Google API), `LiteralTimestamp` (literal value).
- **Wrappers** are prefixed by their concern — `CachingPlaces`, `FilteringMoments`, `UpdateDeferringMoment`, `PermissionCheckingNearbyPlaces`, `SentimentAnalyzingMoment`.
- **Fakes** are prefixed with `Fake` — `FakeMoments`, `FakeEventSink`.
- **Composites** use the plural form of the interface — `Presenters`, `EventSinks`, `EventSources`.
- Names eliminate the need for inline code comments. This does NOT replace public API documentation — document public contracts.

## 3. Developer Experience

DevEx is a first-class design concern. Reduce friction for callers.

- **Constructor overloads**: a primary constructor exposing full control; secondary constructors with sensible defaults for common use (e.g., `DebouncingEventSource(origin)` provides defaults for timeout and scheduler).
- **Interface method overloads**: convenience overloads accepting related types (e.g., `Place.distanceTo(Place)` delegates to `Place.distanceTo(Coordinates)`; `Places.findPlace(Uuid)` alongside `Places.findPlace(String)`).
- **Vararg constructors**: when callers typically pass items inline (e.g., `EventSinks(vararg sinks)` alongside `EventSinks(Iterable)`).

## 4. Composition

Composition is the primary means to extend and control behavior.

- **Wrappers** implement the same interface as the wrapped `origin`. They may decorate (add behavior), proxy (control access), filter, cache, defer, merge, or adapt.
- **Composite / fan-out** classes for multi-dispatch (e.g., `EventSinks` forwards events to every wrapped sink).
- **All dependencies via constructor injection.** No service locators. No DI framework annotations in domain code.

## 5. Packaging

- **Domain-oriented packages**: `moment/`, `geography/`, `sentiment/` — NOT `models/`, `views/`, `services/`, `utils/`.
- **Implementation variants in subpackages**: `filesystem/`, `cache/`, `google/`.
- **Library modules by capability domain.**

## 6. Testing

- **Blackbox only** — test through public interfaces, never internals.
- **Prefer fakes over mocks.** Use mocks only for call-count verification or controlling external dependencies.
- **Test method names describe behavior in natural language** — `reports its coordinates`, `throws given invalid input`.
- **Flat test classes** — no abstract test bases, no test inheritance.

## 7. What NOT to Do

- No `*Utils`, `*Helper`, `*Manager`, `*Service` classes.
- No data-only classes for objects that should own behavior.
- No nullable types where a null object can exist.
- No sealed classes/enums for polymorphism — use interface composition.
- No annotation-driven frameworks inside domain logic.
- No getter/setter methods — use language-native properties.
- No base classes for code reuse — use composition.

