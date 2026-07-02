---
name: fixing-defects
description: A systematic workflow for fixing bugs — reproduce first, regression-test at the lowest layer, then fix, and commit test and fix together. Use when fixing a bug, defect, or regression.
---

# Fixing Defects

A defect is behavior the system has that nobody asked for. Fixing one means more than making the symptom disappear — it means pinning the correct behavior down so the defect cannot return unnoticed. The regression test is the fix's other half; a fix that ships without one is half a fix.

## 1. Reproduce Before Anything

- **Reproduce the failure first.** A fix for an unreproduced bug is a guess wearing a commit message. Run the failing scenario and observe the wrong behavior yourself.
- **Reduce the reproduction** to the smallest deterministic form — the fewest inputs, the least setup, no timing dependence — before reasoning about cause.
- **If you cannot reproduce it, say so.** Report what was tried and what additional information would help (logs, versions, exact inputs). Do not fix speculatively; a speculative fix that "can't hurt" hides the real defect.

## 2. Isolate to the Lowest Layer

Trace the symptom downward until you find the lowest layer that exhibits the wrong behavior — that layer is where both the test and the fix belong.

- A wrong number on a screen may be a presenter defect, a repository defect, or a value-type defect. Follow it down: call the layer below directly with the reproducing inputs and check its answer.
- **Distinguish the causing layer from the symptomatic layers.** Layers above the cause are innocent; patching them (a `!!`, a defensive `if`, a re-mapping) suppresses the symptom and leaves the defect in place.

## 3. The Regression Test Is the License

Per `practicing-test-driven-development`, production code changes require a failing test — a bug fix is no exception; the reproduction *is* the failing test.

- **Write the test at the layer isolated in step 2**, through its public interface.
- **Name the correct behavior, not the incident** — `refuses a timestamp from the future`, not `fixes bug 1234` or `regression test for crash`.
- **Watch it fail for the right reason** — it must fail by exhibiting the defect, not by a typo or missing fixture.

## 4. Fix, Then Let the Test Prove It

- Write the smallest change that makes the regression test pass while keeping every other test green.
- If the fix wants to grow ("while I'm here…"), stop — improvements beyond the defect belong in separate commits, or a separate branch.
- The test stays in the suite forever. It is the executable memory of the defect.

## 5. Commit Test and Fix Together

Per `working-with-git-repositories`: one commit carrying both the regression test and the fix, subject in imperative mood (`Fix …`), body explaining the root cause — the *why* the code was wrong, not a description of the diff. Run the project's quality gate before committing.

## 6. The Hotfix Escape Hatch

When production is burning and the full workflow is too slow: land the smallest symptom-stopping change first — but the reproduction test and root-cause fix follow in the same pull request, before the work is called done. Never silently skip the test; if it truly cannot be written (no harness reaches the layer), say so explicitly and record what would be needed.

## 7. What NOT to Do

- Don't fix what you haven't reproduced — reproduce, or report why you couldn't.
- Don't patch the symptomatic layer when the cause is below it — no defensive null-checks or re-mappings above the defect.
- Don't name tests after incidents (`testBug1234`) — name the behavior the system must have.
- Don't delete or weaken a regression test to make a later change pass — the defect it pins will return.
- Don't bundle opportunistic refactoring into the fix commit — separate commits, per the Git conventions.
- Don't skip the failing-test step because the fix "is obvious" — obvious fixes for unpinned behavior are how regressions recur.
