---
name: practicing-test-driven-development
description: Conventions on practicing classical test-driven development — red-green-refactor, inside-out from value types, and tests as design pressure. Use when writing new behavior-bearing code, or when changing behavior in existing code, in object-oriented codebases and/or languages.
---

# Practicing Test-Driven Development

Tests are design pressure, not verification. Every failing test is a conversation with the object about to be built — about what it should do, how it should be called, and what it should refuse. TDD is how organisms earn their shape.

**Precedence:** These conventions apply in full to new code and to user-approved migrations toward them. Where the existing codebase demonstrably follows different conventions, match those for changes within existing structures and surface the tension to the user — never mass-refactor toward these conventions uninvited. Identical copies of this rule live in each convention skill; if they diverge, the copy in `writing-organism-oriented-code` wins.

## 1. The Cycle

Red, Green, Refactor — in that order, every time.

- **Red** — Write the smallest test that expresses one new behavior. Run it. Confirm it fails *for the right reason* (the behavior is missing), not for the wrong reason (a typo, a missing import, a compile error).
- **Green** — Write the simplest production code that makes the test pass. Not clever, not general, not "while I'm here" — simplest. Hard-code the return value if that is enough. A failing test is the only license to write production code.
- **Refactor** — With every test green, reshape the code and the tests to express intent more clearly. Rename, extract, inline, collapse duplication. Re-run tests after each small change. If a refactor turns the bar red, undo — refactoring is never a feature.

Never skip a step. Never write production code without a failing test. Never leave the bar red at the end of a cycle.

## 2. Inside-Out, from Domain Primitives

Classical / Detroit TDD. Start at the center of the object graph and grow outward.

- **Begin with the value types** — `Timestamp`, `Uuid`, `Coordinates`. These are self-validating and have no collaborators; they are the easiest unit to test-drive and they anchor the domain vocabulary.
- **Add behavior in layers** — once a value type is green, test-drive the domain object that uses it, then the repository that stores it, then the wrapper that caches it. Each new layer is built on already-green primitives.
- **Real collaborators or fakes, not mocks** — when the object under test needs a dependency, prefer the real implementation (if it is cheap, pure, and already green) or a `Fake`. Mocks belong only at the system boundary — where a real dependency is a network, a clock, or a filesystem — or wherever call-count verification is the very behavior under test (see "Test Design Rules").
- **Fakes grow alongside the interface they mimic** — when a new method appears on an interface, the `Fake` gets the same method. The `Fake` is the second implementation of the contract, and its simplicity is proof that the contract is small enough.

## 3. One Behavior per Test

Each test expresses exactly one behavior in its name and verifies exactly one behavior in its body.

- **Test names are English sentences** — `reports its coordinates`, `refuses a timestamp from the future`, `caches the result after first call`. If you cannot name the behavior in one sentence, the test is covering two things. In languages without free-form method names, keep the sentence in the idiom available: `it("reports its coordinates")` (Jest/RSpec), `test_reports_its_coordinates` (pytest), `@DisplayName("reports its coordinates")` (JUnit/Java).
- **One assertion concept per test** — multiple assertion calls are fine when they describe the same concept ("the moment is committed, with the current timestamp, at the given place"). Multiple concepts per test mean a missing test.
- **Triangulate to generalize** — when one test passes with a hard-coded value, add a second test with different inputs to force the generalization. Do not write general code preemptively; let the second red bar pull it out of you.

## 4. Tests as Design Pressure

If a test is hard to write, the production design is wrong. Listen to the test.

- **Hard to construct** — the object has too many collaborators, or its constructor is doing work. Extract collaborators, or move the work to a first method call.
- **Hard to isolate** — the object reaches into statics, service locators, or globals. Inject collaborators via the constructor (see `writing-organism-oriented-code`, "Composition").
- **Hard to verify** — the object communicates through side effects you cannot observe. Replace the side effect with a return value, or introduce an `EventSink` the test can inspect.
- **Hard to name** — the object has no single responsibility. Split it until each piece has a name you can say out loud.

Every friction in the test is a message. Answer it in the production code, not by bending the test.

## 5. Test Design Rules

TDD compounds with the test-design rules from `writing-organism-oriented-code`'s "Testing" section. Restated here so this skill stands on its own:

- **Blackbox only** — test through public interfaces, never internals. The test exercises the organism's skin, not its organs.
- **Prefer fakes over mocks** — use mocks only for call-count verification or for controlling external dependencies.
- **Test method names describe behavior in natural language** — `reports its coordinates`, `throws given invalid input`.
- **Flat test classes** — no abstract test bases, no test inheritance.

These rules govern *what a test looks like*. TDD governs *when and why you write it*. Apply both together. The canonical statement of these rules lives in `writing-organism-oriented-code`'s "Testing" section — if these copies diverge, that section wins.

## 6. Commits Around the Cycle

TDD and `working-with-git-repositories` reinforce each other. The cycle maps naturally onto granular commits.

- **Commit per green cycle** — when a red-green-refactor cycle completes, the working tree holds one new behavior plus the code that implements it. That is exactly the "one idea describable in one sentence" a commit represents.
- **Refactor commits are separate from behavior commits** — a refactor that spans multiple cycles gets its own commit, with a subject like `Extract CachingMoments from FilesystemMoments`. Behavior changes and structural changes stay reviewable in isolation.
- **Never commit red** — the quality gate must pass before the commit lands. A commit that leaves a test failing is broken history.

## 7. Planning

When writing an implementation plan (rather than executing directly), embed the TDD workflow into the plan so the executing agent has explicit instructions to follow:

- **Test plan** — list the behaviors to be test-driven as natural-language test names, in the order they will be written (inside-out: value types first, then the objects that use them). One line per behavior; add a concise description only where the name alone is ambiguous.
- **Cycle discipline** — state that each behavior follows red-green-refactor and that commits land per green cycle (see "Commits Around the Cycle").
- **Fakes** — name the fakes to be created or extended alongside the interfaces they mimic.

These details must appear in the plan itself — do not assume the executing agent has access to this skill's conventions.

## 8. What NOT to Do

- No writing production code without a failing test — the test is the license. This governs behavior-bearing production code; configuration, build scripts, documentation, and pure formatting changes are exempt — but a bug fix always starts with a failing reproduction test. Sole exception: a production emergency, where the smallest mitigating change may land first and the reproduction test follows in the same pull request (see `fixing-defects`, "The Hotfix Escape Hatch").
- No writing multiple tests before a green bar — red-green-refactor is a tight loop, not a phase.
- No refactoring on red — refactor is a no-op on behavior; you need green to prove it.
- No "I'll add the test later" — later never comes, and the design pressure is lost.
- No skipping the "watch it fail" step — a test that was green from the start may be testing nothing.
- No commented-out tests — delete them; version control remembers.
- No test names like `test1`, `testMoment`, `shouldWork` — name the behavior, or do not write the test.
- No interaction verification (`verify()`, `toHaveBeenCalled`) where a state check would suffice — tests should describe what the system *is*, not how it talked to its neighbors.
