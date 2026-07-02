# 2. Store events in PostgreSQL

Date: 2024-03-11

## Context

The order service needs an append-only event store. Expected volume at launch is under a thousand events per day, the four-person team has deep PostgreSQL experience and none with purpose-built event stores, and the platform already operates a managed PostgreSQL cluster with backups and failover. Adopting a new datastore would add an operational surface we cannot yet staff.

## Decision

We will store events in PostgreSQL, in a single append-only table written within the same transaction as the state change it records. We will not adopt a dedicated event-store product until operational load demands it.

## Status

Superseded by [ADR 0003](0003-move-the-event-store-to-eventstoredb.md)

## Consequences

The team ships on infrastructure it already knows how to back up, monitor, and restore, and event writes are transactional with state changes, which removes a class of consistency bugs. Subscribers have to poll — PostgreSQL offers no native event-stream consumers — and if volume grows past what polling tolerates, this decision will need revisiting.
