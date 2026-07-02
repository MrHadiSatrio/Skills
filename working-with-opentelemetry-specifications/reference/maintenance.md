# Maintaining These Reference Files

The files in this directory distill the OpenTelemetry specification at the commit pinned in `overview.md`'s header. When freshness validation (SKILL.md, "Freshness Validation") reports upstream drift and the user opts to re-distill, follow this procedure.

## Re-distillation Procedure

1. **Pin the new commit.** Choose the upstream commit to distill against (normally HEAD of `main`) and clone it:
   `git clone https://github.com/open-telemetry/opentelemetry-specification && git -C opentelemetry-specification checkout <new-commit>`
2. **Scope the drift before reading anything.**
   `git -C opentelemetry-specification diff --stat <old-commit>..<new-commit> -- specification/`
   Only reference files whose source areas changed need regeneration. Map changed spec files to reference files using the `[Source: ...]` pointers within each reference file; `file-index.md` holds the full file-to-area catalog.
3. **Regenerate each affected file, preserving the structure contract:**
   - The three-tier system: Tier 1 inline (MUST/MUST NOT requirements, API contracts, defaults, env vars), Tier 2 summary + pointer, Tier 3 pointer only.
   - A `[Source: path]` on every subsection, pointing into `specification/`.
   - RFC 2119 keywords carried verbatim for Tier 1 requirements — never paraphrase a MUST.
4. **Re-verify `compliance-checklist.md`** against every regenerated section — checklist items must trace to a current requirement.
5. **Update the header** of `overview.md` with the new source commit hash. This hash drives both freshness validation and the source-pointer retrieval recipe, so it must change in the same commit as the regenerated content.
6. **Update `file-index.md`** if upstream added, removed, or moved spec files.
7. **Validate:** run `scripts/validate-skills.sh` from the repository root, and spot-check a handful of `[Source: ...]` pointers against `raw.githubusercontent.com/.../<new-commit>/specification/<path>`.

## What NOT to Do

- Don't regenerate all eight files when the drift touches two — scope first (step 2).
- Don't summarize Tier 1 requirements — they are quoted contracts, not prose.
- Don't update reference content and the pinned hash in separate commits — a mismatched pair silently corrupts freshness validation.
