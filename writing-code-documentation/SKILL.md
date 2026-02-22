---
name: writing-code-documentation
description: Conventions on writing code documentation for public APIs. Always use when writing new features or greenfield code. Always use, with-user-approval, when refactoring existing code.
---

# Code Documentation

Every public API gets documented in the language's mandated documentation format. Documentation describes the service a unit of code provides to its callers — not how it works internally.

## 1. Documentation Segments

Documentation consists of up to four ordered segments.

### Service Brief (required)

What service the code provides to callers. Max two lines. Written from the caller's perspective, answering "what do I get from this?"

For **types** (classes, interfaces, objects), open with an identity phrase — a noun describing what the type *is*: `"An [Event] signalling..."`, `"A repository for..."`. For **callables** (functions, methods), open with a verb describing what the caller *gets*: `"Persists a..."`, `"Returns the..."`.

### Nuance Extension (optional)

Additional context a caller needs: edge cases, threading guarantees, preconditions, error behavior, performance characteristics. Skip entirely if the brief says it all.

### Usage Snippet (optional, class-level only)

A short code example showing how to obtain the service described. Skip if usage is trivial or inferrable from the constructor/method signatures.

### Parameter & Return Tags (non-optional where the language supports them)

`@param`, `@return` / `@returns` with a one-liner summary each. One line per tag — never multi-paragraph.

## 2. What NOT to Do

- Don't restate the declared name — "This class is a...", "This method does...", "A CompletionEvent that..."
- Don't use filler phrases — "This is used to...", "A helper that...", "Responsible for..."
- Don't document private/internal APIs unless their complexity warrants it
- Don't write implementation details (how) — write caller-facing contracts (what)
- Don't force optional segments — skip nuance if the brief is enough, skip usage if trivial
- Don't write multi-paragraph `@param`/`@return` — one line each
- Don't document getters/properties unless semantics are non-obvious

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
 * @param moment Moment to persist.
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

| Language          | Format                  | Tags                         |
|-------------------|-------------------------|------------------------------|
| Kotlin            | KDoc (`/** */`)         | `@param`, `@return`          |
| Java              | Javadoc (`/** */`)      | `@param`, `@return`          |
| JavaScript / TS   | JSDoc (`/** */`)        | `@param`, `@returns`         |
| Python            | Docstrings (`"""`)      | `:param`, `:return`          |
| Rust              | `///`                   | Inline prose, no tags        |
| Swift             | `///`                   | `- Parameter`, `- Returns`   |
| Go                | `//` (preceding decl)   | Inline prose, no tags        |

