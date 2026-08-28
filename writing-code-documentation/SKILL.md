---
name: writing-code-documentation
description: Conventions on writing code documentation for public APIs. Always use when writing new features or greenfield code. When refactoring existing code, also use — but ask the user before adding documentation to previously undocumented APIs.
---

# Code Documentation

Every public API gets documented in the language's mandated documentation format. Documentation describes the service a unit of code provides to its callers — not how it works internally.

**Precedence:** These conventions apply in full to new code and to user-approved migrations toward them. Where the existing codebase demonstrably follows different conventions, match those for changes within existing structures and surface the tension to the user — never mass-refactor toward these conventions uninvited. Identical copies of this rule live in each convention skill; if they diverge, the copy in `writing-organism-oriented-code` wins.

## 1. Documentation Segments

Documentation consists of up to four ordered segments.

### Service Brief (required)

What service the code provides to callers. Max two lines. Written from the caller's perspective, answering "what do I get from this?"

For **types** (classes, interfaces, objects), open with an identity phrase — a noun describing what the type *is*: `"An [Event] signalling..."`, `"A repository for..."`. When the type implements or extends a named super, the identity phrase names that super: `"An [Activity] that..."`, `"A [BroadcastReceiver] for..."`. When the identity phrase alone says enough, the brief ends there — do not force a second sentence. For **callables** (functions, methods), open with a verb describing what the caller *gets*: `"Persists a..."`, `"Returns the..."`.

### Nuance Extension (optional)

Additional context a caller needs: edge cases, threading guarantees, preconditions, error behavior, performance characteristics. Skip entirely if the brief says it all.

### Usage Snippet (optional, class-level only)

A short code example showing how to obtain the service described. Skip if usage is trivial or inferrable from the constructor/method signatures.

### Annotation Tags (use where they add caller-facing information)

- Use the language's annotation tags — `@param`, `@return`/`@returns`, `@throws`/`@exception`, `@deprecated`, `@see`, and so on — for every piece of caller-facing information not already clear from the signature.
- One line per tag — never multi-paragraph.
- Omit a tag entirely when the signature already says it all — a `@param moment the moment` line is noise, not documentation.
- Prefer annotations that document behaviour over metadata annotations: `@since` is rarely useful (callers shouldn't need to know when something was added) and `@author` is noise in a version-controlled codebase — skip both unless the project explicitly requires them.

## 2. Register

Documentation is two or three very short sentences that carry only the essence. A reader understands each sentence on the first pass, without holding an earlier clause in mind.

- **The deletion test.** For every sentence and paragraph, delete it. If callers lose no important understanding, it was filler — leave it out. Apply the test to the brief, the nuance extension, and every tag line.
- **One fact per sentence.** Split a sentence that carries a condition, an example, and a consequence into separate sentences, or drop the parts that fail the deletion test.
- **Name outcomes, not mechanisms.** State what happens under each condition, not which callback or branch produces it.
- **Name the general concept, not one medium's form** — "telemetry name" when the rule covers span names and event names alike, not "span name". Exception: when the API genuinely handles only one form, name that form.

Bad (rejected as very hard to understand):

```kotlin
/**
 * The orphan-end case is the only drop that this platform reports through
 * Analytics. This case occurs when onActivityStopped runs for an Activity
 * whose matching onActivityStarted this platform never observed, for
 * example because the visit start faulted earlier. Every other fault is
 * swallowed without a report.
 */
```

Good:

```kotlin
/**
 * The platform reports one drop through [Analytics]: a stop with no
 * matching start. Every other fault stays silent.
 */
```

## 3. Scope of a Brief

A brief describes the unit it sits on, and nothing beyond it.

- **The brief states the "what" alone.** Every "why" moves inline, as a comment at the exact code it explains (see Inline Comments), or falls to the deletion test.
- **A type documents its own responsibility, never a collaborator's mechanism.** `"Ended if and only if [PersistedSession] reads it as ended"` names the contract and stops. How `PersistedSession` reaches that verdict is `PersistedSession`'s brief.
- **No references to far-away components.** A brief must not describe the behavior of another module's serializer or the platform's handler chain — such references drift as those components change. Exception: a `@see` tag that points at the component without describing it.
- **No usage-context narrative.** Where a type is created, who typically calls it, and what the caller does next belong to the caller's code, not the type's brief. The usage snippet segment shows *how to obtain* the service — it does not narrate a scenario.
- **Do not assume what a caller sees or wants.** "Caller's perspective" means naming the service the caller receives, not speculating about the caller's situation: `"Returns the visit that is open"`, not `"Returns the visit the caller is probably interested in"`.
- **A contract or vocabulary names meaning, not implementation.** A configuration type's brief names no telemetry name or storage detail. A key or constant catalog narrates only the semantic each entry conveys — no SDK behavior, no export path, no platform binding such as "one screen instance is one Activity". Those bindings belong to the code that uses the entries.

Bad:

```kotlin
/**
 * A [Drain] for ended sessions. It does not know how sessions end; the
 * serializer in the export module writes each session under the `session`
 * name, and the host's handler chain reads it back on the next launch.
 */
```

Good:

```kotlin
/**
 * A [Drain] for sessions that [PersistedSession] reads as ended.
 */
```

## 4. Inline Comments

An inline comment carries a "why" that the code cannot. The "what" and the "how" are the code's own job — rename until the code says them itself (`writing-prose-like-code` owns that rule; if these diverge, its "What NOT to Do" wins).

- **Comment the "why" at the exact line.** The reason for an oddity sits directly above the code that is odd, not in the class brief and not in the commit body.
- **Answer every reviewer's "Why?" in the code.** Either make the reason visible at the line with a comment, or remove the need for the oddity. Never answer only in the review thread.
- **No comment where the code already shows it.** A private constant needs no doc block, and a map entry needs no line above it, when the name and the value say it all. Exception: a value taken from an external source (a spec, a vendor limit) gets a one-line comment naming that source.

Bad:

```kotlin
// Set the timeout to 30 seconds.
val timeout = 30.seconds
```

Good:

```kotlin
// The vendor drops idle sockets at 35 seconds; stay under it.
val timeout = 30.seconds
```

## 5. Examples

### Types

Good:

```kotlin
/**
 * An [Event] signalling the successful completion of an operation.
 */
class CompletionEvent : Event()
```

Bad:

```kotlin
/**
 * Signals the successful completion of an operation.
 */
class CompletionEvent : Event()
```

### Callables

Good:

```kotlin
/**
 * Persists a [Moment] to the local filesystem, creating the backing
 * file if it doesn't exist.
 *
 * Writes are atomic — a partial failure won't corrupt existing data.
 * Thread-safe; concurrent writes to the same [Moment] are serialized.
 *
 * @return The persisted Moment with its updated timestamp.
 */
fun save(moment: Moment): Moment
```

Bad:

```kotlin
/**
 * This method saves a moment. It takes a moment and returns a moment.
 *
 * @param moment the moment
 * @return Moment
 */
fun save(moment: Moment): Moment
```

## 6. Language Format Reference

| Language        | Format             | Common annotation tags                                          |
|-----------------|--------------------|-----------------------------------------------------------------|
| Kotlin          | KDoc (`/** */`)    | `@param`, `@return`, `@throws`, `@see`, `@deprecated`           |
| Java            | Javadoc (`/** */`) | `@param`, `@return`, `@throws`, `@see`, `@deprecated`           |
| JavaScript / TS | JSDoc (`/** */`)   | `@param`, `@returns`, `@throws`, `@deprecated`, `@see`, `@type` |
| Python          | Docstrings (`"""`) | `:param`, `:return`, `:raises`, `:deprecated`                   |
| Rust            | `///`              | Inline prose sections: `# Errors`, `# Panics`, `# Examples`     |
| Swift           | `///`              | `- Parameter`, `- Returns`, `- Throws`, `- Note`, `- Warning`   |
| Go              | `//`               | Inline prose, `Deprecated:` prefix                              |

## 7. What NOT to Do

- Don't restate the declared name — "This class is a...", "This method does...", "A CompletionEvent that..."
- Don't use filler phrases — "This is used to...", "A helper that...", "Responsible for..."
- Don't document private/internal APIs unless their complexity warrants it
- Don't write implementation details (how) — write caller-facing contracts (what)
- Don't force optional segments — skip nuance if the brief is enough, skip usage if trivial
- Don't write multi-paragraph annotation tags — one line each
- Don't use `@author` (redundant with version control) or `@since` (callers shouldn't need release history) unless the project explicitly mandates them
- Don't document getters/properties unless semantics are non-obvious
- Don't document `companion object`s — the members carry their own briefs
- Don't put a class-level brief on a test suite — the test names are the catalog
- Don't write "This class does not know..." or "does not care about..." — a brief names what the unit does, never what it omits
- Don't describe a collaborator's mechanism or a far-away component's behavior — name the contract and stop (see Scope of a Brief)
- Don't keep a sentence that survives only by charity — apply the deletion test (see Register)

