---
name: writing-prose-like-code
description: Conventions on writing code that reads like English prose. Use when writing new code, or when refactoring code toward these conventions, in object-oriented codebases and/or languages.
---

# Writing Prose-Like Code

Code is read far more than it is written. Every method body is a paragraph, every variable name is a noun or predicate, every call site is a sentence. Write code that a domain expert can read aloud and understand without deciphering technical notation.

**Precedence:** These conventions apply in full to new code and to user-approved migrations toward them. Where the existing codebase demonstrably follows different conventions, match those for changes within existing structures and surface the tension to the user — never mass-refactor toward these conventions uninvited. Identical copies of this rule live in each convention skill; if they diverge, the copy in `writing-organism-oriented-code` wins.

## 1. Method Bodies as Narratives

A method body tells a story from top to bottom. Each statement is a sentence; each block is a paragraph. A reader should follow the logic without backtracking.

- **Extract intermediate results into named variables** — each variable name narrates what happened or what is true at that point in the story.
- **Group related statements into visual paragraphs** — separate logical steps with blank lines, just as prose uses paragraph breaks.
- **Guard clauses first** — state the reasons to stop early, then proceed with the happy path. Guards read as "if this is true, we are done."
- **Limit nesting depth** — deeply nested code forces readers to hold multiple conditions in their head. Extract inner blocks into well-named methods or variables.

```kotlin
val userIsMoving = speed.value > SPEED_LIMIT_METER_PER_SECOND
val coordinatesIsInaccurate = coordinates.accuracyInMeters > ACCURACY_LIMIT_METER
if (userIsMoving || coordinatesIsInaccurate) return

val cached = CachingMoments(moments)
val currentTimestamp = LiteralTimestamp(clock.now())
val last24h = (currentTimestamp - 24.hours)..currentTimestamp
val todaysMoments = TimeRangedMoments(last24h, cached)

val beenHereRecently = todaysMoments.any { it.place.id == place.id }
if (beenHereRecently) return

val moment = moments.new()
moment.update(currentTimestamp)
moment.update(isNotable = false)
moment.update(place)
moment.commit()
```

## 2. Boolean Names as English Predicates

Every boolean variable or method reads as a natural language assertion that is either true or false.

- **Variables**: subject + `is` / `has` / `was` + adjective or state — `userIsMoving`, `coordinatesIsInaccurate`, `isEditCancelled`, `isSentimentOverridden`.
- **Past-tense predicates for state checks** — `beenHereRecently`, `updatesMade()`.
- **Methods**: `is` + adjective or `has` + noun — `isNewlyCreated()`, `isAlertNecessary()`.
- **Avoid negated names** — prefer `isValid` over `isNotInvalid`; invert at the call site with `!isValid`.

## 3. Domain Vocabulary over Technical Vocabulary

Choose words that belong to the problem domain, not the solution domain. A reader should feel they are reading about the real world, not about data structures.

| Prefer (domain)    | Avoid (technical)    | Why                                          |
|--------------------|----------------------|----------------------------------------------|
| `forget()`         | `delete()`           | People forget moments; databases delete rows |
| `Moment`           | `Entry`              | The domain is journaling, not data entry     |
| `Memorable`        | `Linkable`           | Describes what it means to the user          |
| `sink(event)`      | `handle(event)`      | An event sink sinks events; "handle" is generic |
| `NullIsland`       | `NoPlace`            | A real cartographic concept for 0,0 coordinates |
| `coordinates`      | `coords`             | Full words, no abbreviations                 |

When naming, ask: "Would a domain expert use this word in conversation?" If the answer is no, find the word they would use.

## 4. Natural Syntax via Language Features

Use language features to make expressions read as close to English as the language allows.

- **Operator overloading** — `currentTimestamp - 24.hours`, `event["name"]`. Arithmetic and indexing read naturally when the semantics match.
- **Range operators** — `it.sentiment in sentimentRange`, `it.timestamp in timeRange`. "X in range" reads as an English predicate.
- **Extension properties for units** — `24.hours`, `7.days`, `3.hours`. Numeric literals with unit suffixes read as quantities.
- **Delegation** — `EditableMoment by origin`. "X by Y" reads as "X backed by Y."
- **Functional interfaces** — `Decor { ... }`, `UseCase { ... }`. A single-method interface invoked as a lambda reads as a verb.

In languages without these features, keep the sentence-like reading with what the language offers: no operator overloading → intention-named methods (`timestamp.minus(hours(24))`); no extension properties → factory functions (`Duration.ofHours(24)`); no range operators → named predicates (`timeRange.contains(timestamp)`); no delegation keyword → explicit forwarding inside a wrapper.

## 5. Named Arguments as Prose Clarifiers

At call sites, use named arguments to make construction and invocation self-documenting. Each argument label reads as a clause in a sentence.

```kotlin
CountLimitingMoments(
    limit = 10,
    origin = OrderRandomizingMoments(
        origin = VicinityMoments(
            coordinates = coordinates,
            distanceLimitInMeters = 100.0,
            origin = notableMoments
        )
    )
)
```

Named arguments are especially important for:
- **Boolean parameters** — `update(isNotable = false)` instead of `update(false)`.
- **Numeric parameters** — `distanceLimitInMeters = 100.0` instead of a bare `100.0`.
- **Nested construction** — each `origin =` label clarifies the wrapping chain.

## 6. Commands as Imperative Verb Phrases

Use cases, commands, and actions are named as imperative verb phrases, optionally with articles. The name reads as an instruction to the system.

- **With article for single-entity operations** — "Edit A Moment", "Capture A Moment", "Select A Place".
- **Without article for aggregate operations** — "Show Stories", "Alert Inactivity".
- **The article "A" signals** that the operation targets one specific entity.

As identifiers, the phrases keep their words and drop the spaces:

```kotlin
class EditAMoment(private val moments: Moments) : UseCase
class ShowStories(private val presenter: Presenter) : UseCase
```

## 7. Fluent Mutation via Method Overloading

Multiple overloads of the same method name accepting different argument types create a narrative mutation sequence. Each call reads as a step in a story.

```kotlin
moment.update(currentTimestamp)
moment.update(isNotable = false)
moment.update(place)
moment.commit()
```

This reads as: "Update the moment's timestamp. Mark it as not notable. Set its place. Commit."

## 8. Decision Tables via Pattern Matching

`when` expressions (or `switch`/`match` in other languages) read as English decision lists. Keep each branch to a single expression or delegation — multi-line branches break the tabular rhythm.

```kotlin
when (event) {
    is TextInputEvent -> handleTextInput(event)
    is SelectionEvent -> handleSelection(event)
    is RefreshRequestEvent -> present()
    is CancellationEvent -> handleCancellation(event)
}
```

Type-dispatch like this belongs at system boundaries — event routing, deserialization, protocol handling — where the protocol closes the set of cases. Inside the domain, prefer polymorphic dispatch through the interface; see `writing-organism-oriented-code`, "What NOT to Do".

## 9. Validation as Complete Sentences

Error messages in precondition checks (`require`, `check`, `assert`) are full English sentences with punctuation. They describe the violated contract, not an implementation detail.

- **Good**: `"Sentiment value must be between 0.0 and 1.0; given was $value."`
- **Bad**: `"invalid sentiment"` or `"value out of range"`

## 10. Composition as Specification

When constructing object graphs through nested decoration and named arguments, the result reads as a declarative specification — a description of *what something is*, not imperative steps for *how to build it*. The application root or dependency graph should read like a specification document.

## 11. What NOT to Do

- No abbreviations in names — `coordinates` not `coords`, `timestamp` not `ts`, `configuration` not `config`. Universally-lexicalized short forms are permitted: `id`, `url`, and unit-suffixed quantities in names like `last24h`.
- No technical jargon where a domain word exists — consult the domain vocabulary first.
- No deeply nested control flow — extract conditions to named booleans or blocks to named methods.
- No unnamed boolean or numeric literals at call sites — use named arguments or named constants.
- No `// this does X` comments to explain what code does — rename so the code says it itself.
- No procedural scripts — even utility logic should read as coherent paragraphs with narrative flow.
- No single-letter variable names outside of trivial lambdas.
- No verb-less class names for actions — use imperative verb phrases, not nouns like `MomentEditor`.
