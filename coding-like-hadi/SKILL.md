---
name: coding-like-hadi
description: Hadi's coding conventions — organism-oriented design, prose-like code, code documentation, test-driven development, and Git workflow. Use only when explicitly triggered by the user.
---

# Coding Like Hadi

This is a composite skill. It exists to guarantee that all five convention skills load together, even when their individual triggers would not fire — invoking it is shorthand for "apply the full house style".

Load the following five skills using the Skill tool — invoke all five in parallel (single message, multiple tool calls):

1. `writing-organism-oriented-code`
2. `writing-prose-like-code`
3. `writing-code-documentation`
4. `practicing-test-driven-development`
5. `working-with-git-repositories`

If parallel invocation is unsupported in this runtime, load them sequentially. If a skill fails to load through the Skill tool, read its `SKILL.md` directly from the sibling directory `../<skill-name>/SKILL.md` (relative to this file) and apply it as if loaded. If a skill cannot be obtained either way, tell the user which convention is missing and proceed with the rest.

After all five are loaded, proceed with the user's task applying all loaded conventions.
