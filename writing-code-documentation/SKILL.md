---
name: writing-code-documentation
description: Conventions on writing code documentation for public APIs. Always use when writing new features or greenfield code. When refactoring existing code, also use — but ask the user before adding documentation to previously undocumented APIs.
---

# Code Documentation

Every public API gets documented in the language's mandated documentation format. Documentation is a narrative of the unit it sits on, as that unit stands at the instant the documentation is written. It says mostly *what* the unit gives its callers, a little *how* only where a caller can observe it, and never *why*.

**Precedence:** These conventions apply in full to new code and to user-approved migrations toward them. Where the existing codebase demonstrably follows different conventions, match those for changes within existing structures and surface the tension to the user — never mass-refactor toward these conventions uninvited. Identical copies of this rule live in each convention skill; if they diverge, the copy in `writing-organism-oriented-code` wins.

## 1. Documentation Segments

Documentation consists of up to four ordered segments. Most blocks need only the brief and the tags.

### Service Brief (required)

What service the code provides to callers. Max two lines. Written from the caller's perspective, answering "what do I get from this?"

For **types** (classes, interfaces, objects), open with an identity phrase — a noun describing what the type *is*: `"An [Event] signalling..."`, `"A repository for..."`. When the type implements or extends a named super, the identity phrase names that super: `"An [Activity] that..."`, `"A [BroadcastReceiver] for..."`. When the identity phrase alone says enough, the brief ends there — do not force a second sentence. For **callables** (functions, methods), open with a verb describing what the caller *gets*: `"Persists a..."`, `"Returns the..."`.

### Nuance Extension (optional, rare)

One to three short sentences on an outcome the caller observes and the signature cannot show: an error outcome, a threading guarantee, a precondition, a lifecycle rule such as `"Call [close] when done."` Skip it when the brief says it all — the common case.

A type's documentation is usually the identity phrase, a lifecycle line where the type has one, and the `@param` list. Nothing else. The nuance extension is never a home for mechanisms, reasons, or history (see Narrative at One Instant).

### Usage Snippet (optional, class-level only)

A short code example showing how to obtain the service described. Skip if usage is trivial or inferrable from the constructor/method signatures. The snippet is code alone — no prose scenario around it.

### Annotation Tags (use where they add caller-facing information)

- Use the language's annotation tags — `@param`, `@return`/`@returns`, `@throws`/`@exception`, `@deprecated`, `@see`, and so on — for every piece of caller-facing information not already clear from the signature.
- One line per tag — never multi-paragraph.
- Omit a tag entirely when the signature already says it all — a `@param moment the moment` line is noise, not documentation.
- A `@param` line says what the argument is to the caller, not what the unit does with it inside: `@param clock The source of each moment's timestamp.`, not `@param clock The clock. now() produces the millis in each file name.`
- A `@deprecated` tag names the replacement, in the present tense — not when or why the API was deprecated.
- Prefer annotations that document behaviour over metadata annotations: `@since` is rarely useful (callers shouldn't need to know when something was added) and `@author` is noise in a version-controlled codebase — skip both unless the project explicitly requires them.

## 2. Narrative at One Instant

A documentation block describes the unit as it is now, to a reader who knows nothing of its past, its plans, or the debates that shaped it. Every sentence must be true of the code beneath it, read on its own.

- **Mostly what.** Name the service, the outcomes, and the contract.
- **Little how.** Name a mechanism only when the caller observes it or must act on it: "A write is atomic", "Thread-safe". Leave out file layouts, lock choices, temporary files, retry loops, streaming, and internal state — the body says those.
- **Never why.** No reason, rationale, or justification of the design. A reason a code reader needs goes into an inline comment at the exact line (see Inline Comments). The reason for an architectural choice goes into an ADR, when the project keeps them. Every other "why" falls.
- **No history.** No "legacy", "previously", "no longer", "written before…", "carried forward from…", and no "now" set against a past. The unit has no past in its own documentation. State the present fact the history left behind: "Undated moments form one group", not "Moments written before dating was added land in one group".
- **No future.** No "a later change will…", "deferred until…", "for now", and no `TODO` or `FIXME` in a documentation block. An open defect or a plan goes to the issue tracker, or at most to one inline `// FIXME:` line at the code it concerns.
- **No defense.** No "by design", "not a gap", "intentionally", "only a thin wrapper", "this still works". A sentence that answers an imagined objection is a "why".
- **No test motivation.** "Injectable, so that a test can drive it" is a "why". A test seam needs no documentation.
- **A change does not append to the story.** When you change a unit, do not add a sentence about the change to its block. Rewrite a sentence only when the change made it false; otherwise leave the block alone.

**Red-flag words.** In a documentation block, these words usually open a "why", a history, or a plan: *because, since, so that, in order to, thus, as a result, by design, intentionally, legacy, previously, no longer, before, later, will, deferred, for now, currently, TODO, FIXME*. When one appears, apply the rules above to its sentence. Keep the sentence only when it still states a present fact the caller observes — "Returns `null` before [start] is called" stays.

Bad (every sentence after the first breaks a rule):

```kotlin
/**
 * A [Moments] that persists each moment as a file under [directory].
 *
 * The class writes each moment to a sibling `.tmp` file, then moves it onto
 * its final name, because a crash mid-write must never leave a partial file.
 * Files written before moments were grouped by day surface under the undated
 * group. A later change will migrate them. The removal of stale `.tmp` files
 * runs inside [all], by design, not as a gap. The sync worker in the cloud
 * module reads these files on its next pass.
 *
 * @param clock The clock. `now()` produces the millis in each file name.
 */
```

The mechanism (`.tmp` file, move), the reason (`because…`), the history (`written before…`), the plan (`A later change…`), the defense (`by design, not as a gap`), the neighbor (`The sync worker…`), and the internals in the `@param` line all fall.

Good:

```kotlin
/**
 * A [Moments] that keeps each moment as a file under [directory].
 *
 * A write is atomic: [all] returns whole moments only. Undated moments
 * form one group.
 *
 * @param clock The source of each moment's timestamp.
 */
```

The one reason a code reader needs sits at its line:

```kotlin
// A crash before this move leaves only the .tmp file, never a partial moment.
temporary.moveTo(target)
```

## 3. Register

Documentation is two or three very short sentences that carry only the essence. A reader understands each sentence on the first pass, without holding an earlier clause in mind.

- **Length.** The brief is at most two lines. The prose after it is at most three short sentences. A block that needs more is describing mechanisms, reasons, or neighbors — cut it back to the contract. Exception: a usage snippet can run longer, because it is code.

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

## 4. Scope of a Brief

A brief describes the unit it sits on, and nothing beyond it.

- **The whole block states the "what" alone.** Every "why" moves inline, as a comment at the exact code it explains (see Inline Comments), or falls to the deletion test (see Narrative at One Instant).
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

## 5. Inline Comments

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

## 6. Examples

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
 * Persists a [Moment] to the local filesystem.
 *
 * A write is atomic: a failure leaves the earlier data intact.
 * Concurrent writes to one [Moment] are serialized.
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

## 7. Language Format Reference

| Language        | Format             | Common annotation tags                                          |
|-----------------|--------------------|-----------------------------------------------------------------|
| Kotlin          | KDoc (`/** */`)    | `@param`, `@return`, `@throws`, `@see`, `@deprecated`           |
| Java            | Javadoc (`/** */`) | `@param`, `@return`, `@throws`, `@see`, `@deprecated`           |
| JavaScript / TS | JSDoc (`/** */`)   | `@param`, `@returns`, `@throws`, `@deprecated`, `@see`, `@type` |
| Python          | Docstrings (`"""`) | `:param`, `:return`, `:raises`, `:deprecated`                   |
| Rust            | `///`              | Inline prose sections: `# Errors`, `# Panics`, `# Examples`     |
| Swift           | `///`              | `- Parameter`, `- Returns`, `- Throws`, `- Note`, `- Warning`   |
| Go              | `//`               | Inline prose, `Deprecated:` prefix                              |

## 8. What NOT to Do

- Don't restate the declared name — "This class is a...", "This method does...", "A CompletionEvent that..."
- Don't use filler phrases — "This is used to...", "A helper that...", "Responsible for..."
- Don't document private/internal APIs unless their complexity warrants it
- Don't write implementation details (how) — write caller-facing contracts (what). Exception: a mechanism the caller observes, such as atomicity or thread safety
- Don't explain why — no reason, rationale, or defense in a documentation block. A reason the code reader needs goes inline at its line (see Narrative at One Instant)
- Don't narrate history or plans — no "legacy", "previously", "later", "deferred", `TODO`, or `FIXME` in a documentation block
- Don't append a sentence about your change to an existing block — rewrite only a sentence that the change made false
- Don't document why a seam exists for tests
- Don't force optional segments — skip nuance if the brief is enough, skip usage if trivial
- Don't write multi-paragraph annotation tags — one line each
- Don't use `@author` (redundant with version control) or `@since` (callers shouldn't need release history) unless the project explicitly mandates them
- Don't document getters/properties unless semantics are non-obvious
- Don't document `companion object`s — the members carry their own briefs
- Don't put a class-level brief on a test suite — the test names are the catalog
- Don't write "This class does not know..." or "does not care about..." — a brief names what the unit does, never what it omits
- Don't describe a collaborator's mechanism or a far-away component's behavior — name the contract and stop (see Scope of a Brief)
- Don't keep a sentence that survives only by charity — apply the deletion test (see Register)

