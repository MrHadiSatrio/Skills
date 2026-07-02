---
name: exploring-well-tested-code
description: Token-efficient codebase exploration through test files — test names as behavioral catalogs, test setup as construction patterns, and fakes as contract documentation. Use only when explicitly triggered by the user, or when directed by another skill.
---

# Exploring Well-Tested Code

Understand a codebase through its test suite — test method names are a behavioral catalog, test setup reveals construction patterns and the dependency graph, and fakes document the contracts they implement. The tests are the specification. The production code is just one way to satisfy it.

## 1. Reading Strategy

Read test names. Read test setup. Read fakes. Skip test bodies. Build understanding layer by layer.

1. **Map the test file tree** — Glob for test files to understand which domains and classes have coverage. The test directory structure mirrors the production structure and reveals the project's domain boundaries.
2. **Read test method names** — test names in a well-tested codebase are behavioral specifications written in natural language. A class with tests named `reports its coordinates`, `throws given invalid input`, `caches the result after first call` tells you everything about its contract without reading a line of production code.
3. **Read test setup and fixtures** — constructors, factory methods, `@Before`/`setUp` blocks, and builder patterns in tests reveal how to instantiate the system under test, what its dependencies are, and what the typical dependency graph looks like.
4. **Read fake implementations** — fakes implement the same interface as the real dependency. Their method bodies are simple enough to read in full and they document the contract that every implementation must satisfy.
5. **Stop** — the test names, setup, and fakes tell you what the code does, how to construct it, and what contracts it depends on. Do not read production code yet.

### What to read

- Test class declarations and their names — these mirror production class names and reveal coverage
- Test method names / function names — the behavioral catalog
- `@Before`, `setUp`, `beforeEach`, `beforeAll`, test fixtures, and companion object / test factory methods — construction patterns
- Fake classes in full — they are small and they ARE the contract documentation
- Test constants, shared test data, and named test fixtures — these reveal domain-realistic values and edge cases
- Parameterized test data sources (`@MethodSource`, `@CsvSource`, `pytest.mark.parametrize`, `test.each`) — these enumerate the input space

### What to skip

- Test method bodies (assertions, arrange-act-assert blocks) — the method name already told you what is being verified
- Mock setup and verification (`when().thenReturn()`, `verify()`, `expect().toHaveBeenCalledWith()`) — mocks describe test wiring, not contracts
- Integration and end-to-end test files — these test configuration and orchestration, not behavioral contracts
- Test utility classes (`TestRule`, custom JUnit extensions, test helpers) — infrastructure, not specification
- Generated test reports, coverage reports, snapshot files

## 2. Execution

### Broad exploration — Explore subagents

For surveying test coverage across a module, discovering domain boundaries through test structure, or cataloging behaviors of a subsystem, delegate to Explore subagents. Subagents run in a separate context window — only their summary returns to the main conversation — making them inherently token-efficient. If subagents are unavailable in this runtime, perform the same constrained reading directly with Glob, Grep, and Read, keeping reads bounded as described below.

When spawning an Explore subagent, include these constraints in the prompt:

> Read only test class names, test method/function names, setUp/beforeEach blocks, and fake implementations. Do not read test method bodies. Use Grep to extract test method signatures — for JUnit/Kotlin: `` fun ` ``, for Java: `@Test` with `-A 1`, for Jest/Vitest: `(it|test)\(`, for pytest: `def test_`, for RSpec: `(it|describe|context) `. Use `-A 0` to capture only the name, not the body. For fakes, Glob for files matching `Fake*`, `*Fake.*`, `fake_*`, or `*_fake.*` and read them in full — they are contract documentation. Skip mock setup, assertion blocks, and integration/e2e test directories.

### Targeted follow-ups — direct tools

For reading a specific class's behavioral catalog or understanding a single component's construction pattern, use Glob, Grep, and Read directly.

**Discovering test files:**
- Glob for `**/test/**`, `**/tests/**`, `**/*Test.*`, `**/*_test.*`, `**/*.test.*`, `**/*.spec.*` to find test files.
- Glob for `**/Fake*.*`, `**/*Fake.*`, `**/fake_*.*`, `**/*_fake.*` to find fake implementations.

**Extracting test method names (the behavioral catalog):**
- JUnit / Kotlin: Grep for `` fun ` `` (backtick-quoted method names are the natural-language descriptions) with `-A 0`.
- JUnit / Java: Grep for `@Test` with `-A 1` to capture the method name on the next line, or Grep for `@DisplayName` with `-A 0`.
- Jest / Vitest / Mocha: Grep for `(it|test)\(` with `-A 0`. For `describe` blocks that provide grouping context, Grep for `describe\(` as well.
- pytest: Grep for `def test_` with `-A 0`.
- RSpec: Grep for `(it|context|describe) ` with `-A 0`.
- Go: Grep for `func Test` with `-A 0`.

**Reading setup and construction patterns:**
- Grep for `@Before`, `setUp`, `beforeEach`, `beforeAll`, `@BeforeEach`, `@BeforeAll` to locate setup blocks, then Read with `offset` and `limit` to capture the full block (typically 10–30 lines).
- In the setup block, look for constructor calls — these reveal what dependencies the system under test requires and how it is wired.

**Reading fakes:**
- After Globbing for fake files, Read them in full. Fakes are typically small (under 100 lines) and every line is meaningful — they are the simplest correct implementation of a contract.

## 3. When to Escalate

This strategy requires well-named tests and clear setup. Read the specific test body (not the whole file) when:

- **Test names are cryptic or numbered** — `test1`, `testCase3`, `should work` tell you nothing. The body is the only way to understand what behavior is being verified.
- **Setup is complex or indirect** — if the `@Before` block delegates to a builder chain, factory, or external fixture file that is not self-explanatory, trace into it to understand the construction pattern.
- **Parameterized tests with opaque data** — when the parameterized data source is a list of numbers or encoded strings without descriptive names, the assertions inside the body reveal what the parameters mean.
- **The user asks about edge cases or failure modes** — "what happens when X is null" requires reading the specific test that covers that case.
- **Fakes contain non-trivial logic** — a fake with branching, state machines, or more than ~50 lines has become a test double worth reading carefully rather than skimming.

If early exploration reveals consistently poor test names (`test1`, `testSave`, `testProcess` with no behavioral description), warn the user and suggest switching to normal exploration or to `exploring-well-documented-code` if inline documentation is available.

## 4. Integration with exploring-well-documented-code

These two skills are complementary halves of the same exploration strategy. Documentation tells you the *intended* contract — what the author promised. Tests tell you the *verified* contract — what the code actually does, including edge cases the documentation may not mention.

**Using both together (recommended for well-documented, well-tested codebases):**

1. Start with `exploring-well-documented-code` to map types, interfaces, and public API signatures — this gives you the architectural skeleton.
2. Switch to `exploring-well-tested-code` to fill in behavioral detail — edge cases, error conditions, construction patterns, and the dependency graph as it is actually wired.
3. Cross-reference: if a method's documentation says "throws given invalid input" and a test named `throws given invalid input` exists, the contract is confirmed. If tests cover behaviors not mentioned in the docs, those are the undocumented contracts you would otherwise miss.

**When to prefer one over the other:**

- Documentation is strong but tests are sparse or poorly named: use `exploring-well-documented-code` alone.
- Tests are well-named but documentation is sparse: use `exploring-well-tested-code` alone.
- Both are strong: use both together as described above — this is the most token-efficient path to complete understanding.

## 5. What NOT to Do

- Do not read test method bodies unless escalation criteria from section 3 are met — the method name is the specification.
- Do not read mock setup (`when().thenReturn()`, `jest.fn()`, `unittest.mock.patch`) — mocks describe test wiring, not production contracts. Fakes are the contract documentation; mocks are noise.
- Do not read full test files — Grep to extract method names, then Read with `offset` and `limit` for setup blocks. Exception: fake implementations, which should be read in full.
- Do not read integration tests, end-to-end tests, or UI tests to understand domain behavior — these test orchestration and configuration, not unit-level contracts.
- Do not conflate test count with understanding — 200 test names skimmed are worth more than 20 test bodies read in full.
- Do not read production code to understand what a well-named test already told you — `throws given invalid input` means the code throws given invalid input.
- Do not skip fake implementations — they are the cheapest, most precise contract documentation in the codebase.
