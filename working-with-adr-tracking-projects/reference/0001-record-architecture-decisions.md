# 1. Record architecture decisions

Date: 2026-07-02

## Context

This project's architectural decisions — which database, which protocol, which module owns what — live in commit messages, chat threads, and the memories of whoever was present when they were made. New contributors rediscover them by trial and error, and nobody can tell whether a constraint is deliberate or accidental.

## Decision

We will record every architecturally significant decision as an Architecture Decision Record, following the format Michael Nygard described in "Documenting Architecture Decisions" (2011). Records live in a flat directory, numbered sequentially; once accepted they are immutable and can only be superseded or deprecated.

## Status

Accepted

## Consequences

Every significant decision gains a citable, dated record, and future contributors can distinguish deliberate constraints from accidents. Writing the record adds friction to decisions that used to be implicit, and the trail is only as trustworthy as our discipline in keeping it — an unrecorded decision is now easier to mistake for a non-decision.
