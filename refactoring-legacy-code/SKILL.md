---
name: refactoring-legacy-code
description: A strangler-style workflow for migrating non-conforming codebases toward the house conventions — characterization tests, seams, wrap-don't-rewrite. Use only when explicitly triggered by the user.
---

# Refactoring Legacy Code

Legacy code is code whose behavior you need but whose shape you don't. The house conventions' precedence rule says to leave a codebase's style alone unless the user approves a migration — this skill is what to do once they have. The governing discipline: behavior is preserved and proven at every step, and the codebase is left better in small, reversible increments — never rewritten in place.

## 1. Characterize Before Touching

Before changing any structure, pin the current behavior with characterization tests.

- **Test what the code does, not what it should do** — including behavior that looks like a bug. A characterization test that "corrects" the output changes behavior under the banner of refactoring.
- **Write them at the boundary you're about to refactor behind** — the seam's public surface, so they survive the restructuring they exist to protect.
- **Found a real bug while characterizing?** Record it and tell the user — fixing it is a separate task under `fixing-defects`, not a side effect of the refactor.

## 2. Find the Seams

A seam is a place where behavior can be swapped without editing the code that uses it.

- **Introduce an interface at the seam**, named after the domain concept (`Places`, `Moments`) per the organism conventions — even when the only implementation is the legacy code.
- **The first implementation is the legacy code itself**, adapted behind the new interface (`LegacyDatabasePlaces` wrapping the old DAO). No behavior change — the adapter only translates.
- **Callers migrate to the interface one at a time**, each migration its own small, green-gated change.

## 3. Wrap, Don't Rewrite

Grow the new shape around the old code, then let the old code fall away.

- **New capability goes into wrappers and new organisms** that compose with the legacy implementation — a `CachingPlaces` around `LegacyDatabasePlaces` — never into the legacy body.
- **Strangle, don't excise:** the legacy implementation is deleted only when nothing references it, and its deletion is its own commit.
- **Resist the rewrite urge.** A rewrite discards the one thing legacy code has proven: that it works. Wrapping keeps that proof live while the shape improves.

## 4. One Convention per Commit

Migrate one convention at a time, each in its own commit with the quality gate green: extract an interface (commit), migrate callers (commit), introduce the null object that replaces the null-checks (commit), rename toward domain vocabulary (commit). Small diffs keep every step reviewable and trivially revertible — a reviewer should never see "restructured module" as one change.

## 5. Stop and Surface When It Cascades

When a step fans out beyond what was agreed — one interface extraction wants to touch forty call sites, a rename crosses module boundaries — stop. Report what the step actually requires and let the user choose: proceed, narrow the scope, or defer. An approved migration is not approval for everything the migration touches.

## 6. What NOT to Do

- Don't refactor and change behavior in the same commit — if a characterization test must change, that is a behavior change and it gets its own, clearly-labeled step.
- Don't "fix" surprising behavior mid-refactor — record it, surface it, handle it under `fixing-defects`.
- Don't rewrite a working unit because wrapping feels slower — it isn't, once the rewrite's re-stabilization cost lands.
- Don't migrate conventions the user didn't approve — the mandate is scoped, not general.
- Don't leave both the old and new path live indefinitely — every strangler step ends with a deletion milestone, stated up front.
- Don't skip characterization because the code "obviously" does X — legacy code's obviousness is exactly what's untested.
