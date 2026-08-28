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

## 3. Examples

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

## 4. Language Format Reference

| Language        | Format             | Common annotation tags                                          |
|-----------------|--------------------|-----------------------------------------------------------------|
| Kotlin          | KDoc (`/** */`)    | `@param`, `@return`, `@throws`, `@see`, `@deprecated`           |
| Java            | Javadoc (`/** */`) | `@param`, `@return`, `@throws`, `@see`, `@deprecated`           |
| JavaScript / TS | JSDoc (`/** */`)   | `@param`, `@returns`, `@throws`, `@deprecated`, `@see`, `@type` |
| Python          | Docstrings (`"""`) | `:param`, `:return`, `:raises`, `:deprecated`                   |
| Rust            | `///`              | Inline prose sections: `# Errors`, `# Panics`, `# Examples`     |
| Swift           | `///`              | `- Parameter`, `- Returns`, `- Throws`, `- Note`, `- Warning`   |
| Go              | `//`               | Inline prose, `Deprecated:` prefix                              |

## 5. What NOT to Do

- Don't restate the declared name — "This class is a...", "This method does...", "A CompletionEvent that..."
- Don't use filler phrases — "This is used to...", "A helper that...", "Responsible for..."
- Don't document private/internal APIs unless their complexity warrants it
- Don't write implementation details (how) — write caller-facing contracts (what)
- Don't force optional segments — skip nuance if the brief is enough, skip usage if trivial
- Don't write multi-paragraph annotation tags — one line each
- Don't use `@author` (redundant with version control) or `@since` (callers shouldn't need release history) unless the project explicitly mandates them
- Don't document getters/properties unless semantics are non-obvious

