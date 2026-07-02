# 3. Move the event store to EventStoreDB

Date: 2026-05-20

## Context

[ADR 0002](0002-store-events-in-postgresql.md) chose PostgreSQL for the event store while volume was low and the team had no event-store experience. Two years on, the order service writes roughly two million events per day, the polling-based subscriptions that ADR 0002 warned about now dominate database load, and two engineers have since run EventStoreDB in production elsewhere. The circumstances that justified ADR 0002 no longer hold.

## Decision

We will move the event store to EventStoreDB and consume events through its native subscriptions instead of polling. Carried forward from ADR 0002: events remain append-only, and no service reads another service's events directly.

## Status

Accepted

Supersedes [ADR 0002](0002-store-events-in-postgresql.md)

## Consequences

Subscription load leaves the transactional database, and consumers receive events as streams instead of poll loops. The platform team takes on a second stateful system — backups, monitoring, and upgrades that the managed PostgreSQL cluster previously absorbed — and event writes are no longer transactional with state changes, so the migration design must close the resulting consistency gap.
