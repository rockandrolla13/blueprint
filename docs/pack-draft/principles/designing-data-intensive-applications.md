---
pack: designing-data-intensive-applications
book: Designing Data-Intensive Applications — Martin Kleppmann
source: https://github.com/rockandrolla13/agent-rules-books
upstream_rev: a7d7649
license: MIT
applies_to: [architect, design]
when: >
  The module table or dependency graph contains two components that write the same
  persistent record; or a component whose data is a copy of another's — cache,
  index, projection, materialized view, denormalized field, search copy, report
  table; or a consumer of a queue, event log, CDC feed, or a scheduled job that
  reprocesses input it has already seen.
conflicts_with: none
---

# Pressure Pack — Designing Data-Intensive Applications

Blueprint has exactly one rule in this territory: `architect/SKILL.md:152-161`,
Heuristic 7, which decides *module boundaries* from consistency requirements. That
rule is good and this pack does not restate it. What it does not do is say anything
about the copies that live on the far side of the boundary it draws — their
ownership, their staleness, or their reconstruction.

`source of truth`, `idempotent`, `schema evolution`, `derived data`, `replay`, and
`exactly-once` appear zero times across all twelve `SKILL.md` files.

## Final checklist

Check each against the Phase 2.3 module table produced by `architect` and the
Phase 2.2 data flow produced by `design`.

1. **Every persistent field has one named owner; every copy is labelled a copy.**
   The module table's "Knows About" column distinguishes the module that *decides*
   a value from modules that *hold* it. For each copy, the design names its
   rebuild path — the procedure that reconstructs it from the owner after it is
   deleted — and the signal that makes its lag visible. A copy with no rebuild
   path is a second source of truth that nobody declared.
   *Upstream:* `_rule-workbench/designing-data-intensive-applications/traceability.md:23` (`M6`),
   `traceability.md:40` (`M20`).

2. **Every retried or replayed unit of work states why running it twice is safe.**
   For each step that can be retried — including the retries `design/SKILL.md:147`
   already mandates — the design names the deduplication key, or shows the
   transition is naturally idempotent, or names the compensating action. "It won't
   happen twice" is not an answer; delivery guarantees are the thing being
   questioned.
   *Upstream:* `traceability.md:25` (`M8`), `traceability.md:42` (`M22`).

3. **A timeout on a write is handled as unknown, not as failure.** For each write
   that crosses a boundary the design states the behaviour when the call times out
   with the outcome undetermined: whether the caller re-reads, retries under item
   2's key, or records a pending state. Treating an unknown as a failure and
   retrying blind is the specific defect this catches.
   *Upstream:* `traceability.md:19` (`M2`), `traceability.md:39` (`M19`).

4. **Ordering requirements are scoped, or declared absent.** Where processing order
   affects correctness, the design names the scope the order holds within — per
   key, per partition, per entity history — rather than assuming global order.
   Where order does not matter, it says so; that is the cheaper answer and it
   should be stated rather than assumed.
   *Upstream:* `traceability.md:26` (`M9`).

5. **Every serialised contract has a version story across mixed readers.** For each
   schema, message, event, enum, or stored payload in the design, state what an old
   reader does with a new payload and what a new reader does with an old one. This
   applies to the Pydantic models `shared-principles.md:86` already mandates: those
   models fix the shape, not its evolution. Adding a required field is the standard
   failure.
   *Upstream:* `traceability.md:28` (`M11`), `traceability.md:41` (`M21`).

## Excluded — already covered

| Upstream item | Already enforced by |
|---|---|
| Service and module boundaries follow consistency requirements | `architect/SKILL.md:152-161` — Heuristic 7 is a sharper form of upstream `M18`: "if updating X, what else MUST be true right now?" Everything in that answer lives together |
| Boundaries follow rate of change and evolution pressure | `architect/SKILL.md:92-104` Rate of Change analysis; `architect/SKILL.md:167-168` "Rate-of-change wins over convenience"; `review-architecture/SKILL.md:60-84` Dimension 1 |
| Data models chosen from access patterns and relationships | `architect/SKILL.md:68-91` — domain relationships and the domain model precede module assignment |
| Each step in a data flow declares a failure mode | `design/SKILL.md:68-74` — the Data Flow section already asks "Retry, skip, propagate, alert?". Items 2 and 3 supply what that answer must contain when the step writes |
| Describe load with concrete numbers before changing architecture | `design/SKILL.md:75-85` Parallelisation Map; `review-architecture/SKILL.md:208-227` Dimension 7. Blueprint's version is throughput-shaped rather than tail-latency-shaped, but the gate outcome is the same: no restructuring without a measured workload |

## Excluded — outside blueprint's scope

Not admitted, and not covered. `shared-principles.md:62-67` states blueprint does
not prescribe databases or ORMs or infrastructure. These upstream areas have no
gate in blueprint to change:

- Storage engine and index selection, OLTP-vs-analytics layout (`traceability.md:22`, `M5`).
- Replication topology and quorum configuration (`traceability.md:29`, `M12`).
- Partitioning strategy, rebalancing, hot-key routing (`traceability.md:30`, `M13`).
- Transaction isolation level selection and anomaly mapping (`traceability.md:31`, `M14`).
- Clocks, leases, fencing, consensus (`traceability.md:32-33`, `M15`, `M16`).

Eighteen upstream decision rules reduce to five retained checklist items. The cut is
this deep because most of DDIA addresses choices about a datastore, and blueprint
never makes those choices.

## Attribution

Derived from
`designing-data-intensive-applications/designing-data-intensive-applications.mini.md`
in <https://github.com/rockandrolla13/agent-rules-books> at `a7d7649`, MIT licensed,
Copyright (c) 2026 Maciej Ciemborowicz. Rewritten, not copied. The underlying book is
Martin Kleppmann, *Designing Data-Intensive Applications* (2017).
