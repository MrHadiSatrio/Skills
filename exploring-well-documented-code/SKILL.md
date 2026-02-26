---
name: exploring-well-documented-code
description: Token-efficient codebase exploration through type definitions, signatures, and documentation only. Use only when explicitly triggered by the user.
---

# Exploring Well-Documented Code

Understand a codebase through its public contracts — types, signatures, doc comments, and dependency declarations — not through implementation bodies. The documentation is the source of truth. The code is just one way to fulfill that contract.

## 1. Reading Strategy

Read contracts. Skip bodies. Build understanding layer by layer.

1. **Map the file tree** — Glob for source files to understand package/module layout.
2. **Read dependency declarations** — imports, exports, and package statements reveal the dependency graph.
3. **Find type declarations** — interfaces, classes, structs, traits, enums, type aliases.
4. **Read signatures and their documentation** — method/function signatures with their attached doc blocks.
5. **Stop** — the signature and its documentation tell you what the code does. Do not read the body.

### What to read

- Interface, trait, and protocol definitions in full (these are pure contracts)
- Class and struct declarations with their fields/properties
- Method and function signatures — names, parameters, types, return types
- Documentation comments — KDoc, Javadoc, JSDoc, docstrings, `///`, `//`
- Type aliases, enums, sealed types, and constants
- Import/export statements and package declarations
- Annotations on declarations (`@Throws`, `@Deprecated`, visibility modifiers)

### What to skip

- Method and function bodies — everything between braces or after Python's signature colon
- Private/internal helper functions and utilities
- Variable assignments and control flow inside functions
- Test files and test classes
- Generated code, build outputs, vendor directories

## 2. Execution

### Broad exploration — Explore subagents

For understanding module architecture, discovering key types, or surveying a package, delegate to Explore subagents. Subagents run in a separate context window — only their summary returns to the main conversation — making them inherently token-efficient.

When spawning an Explore subagent, include these constraints in the prompt:

> Read only type/interface/class declarations, method/function signatures, and their documentation comments. Do not read method or function bodies. Use Grep with `-B` context (5–15 lines) to capture doc comments above declarations and `-A 0` or `-A 1` to capture only the signature, not the body. Use Read with offset/limit for multi-line signatures — never read full files unless the file is purely type definitions (interfaces, enums, constants). Skip test files, generated code, and build outputs.

### Targeted follow-ups — direct tools

For reading a specific type or signature after the broad picture is established, use Glob, Grep, and Read directly.

- **Grep** with `-B 5` to `-B 15` to capture doc comments above declarations. Use `-A 0` or `-A 1` to capture only the signature line, not the body.
- **Read** with `offset` and `limit` — after Grep locates a declaration at line N, Read with `offset: N-15, limit: 30` to capture the doc block and full signature. For interface/contract-only files, reading the full file is acceptable.
- **Read imports** — the first 30–50 lines of a file where imports typically reside.

## 3. When to Escalate

This strategy requires documentation to be present and meaningful. Read the specific body (not the whole file) when:

- **Documentation is absent** — a function with no doc comment and a vague name like `process()` cannot be understood from its signature alone.
- **Signatures are ambiguous** — generic return types (`Any`, `Object`, `interface{}`), unclear parameter names.
- **The user asks about implementation** — "how does this work" requires the body by definition.
- **Side effects or failure modes are undocumented** — if you need to know error behavior and the docs don't describe it.

If early exploration reveals consistently sparse documentation, warn the user and suggest switching to normal exploration.

## 4. What NOT to Do

- Do not read method or function bodies unless escalation criteria from section 3 are met.
- Do not read full files — Grep to locate, then Read with offset/limit to extract. Exception: pure contract files (interfaces, enums, type definitions).
- Do not read test files to understand production code.
- Do not use broad Read operations (hundreds of lines) hoping to find declarations — Grep to pinpoint first.
- Do not read generated code, build output, or vendored dependencies.
- Do not skip import/export statements — they are cheap to read and reveal the dependency graph.
