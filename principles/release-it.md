---
pack: release-it
book: Release It! — Michael T. Nygard
source: https://github.com/mattpocock/agent-rules-books
upstream_rev: a7d7649
license: MIT
applies_to: [design]
when: >
  The design's dependency graph contains a call that leaves the process — HTTP or
  gRPC client, database driver, message queue producer or consumer, subprocess
  spawn, cloud SDK call, or a read from a network-mounted path — or introduces an
  unbounded collection: a queue, buffer, connection pool, cache, or an API that
  returns a list whose length is not capped.
conflicts_with: Clean Code Principles / Interface Segregation
---

# Pressure Pack — Release It!

Blueprint designs for structure and says almost nothing about runtime failure.
`timeout`, `circuit breaker`, `bulkhead`, `back pressure`, and `load shedding`
appear zero times across all twelve `SKILL.md` files and `shared-principles.md`.
The one place blueprint speaks about failure — `design/SKILL.md:147` — instructs
"retry transient failures" and stops there, which is an unbounded retry by default.

Scope is the failure semantics of a crossing call. Deployment, infrastructure,
security, and chaos work are outside blueprint's stated remit
(`shared-principles.md:62-67`) and are not restated here.

## Final checklist

Check each against the Phase 2 dependency graph, the Phase 3.1 Protocol
definitions, and the Phase 3.2 config model produced by `design`.

1. **Every crossing call carries a finite time limit, set in the design, not
   inherited.** The Protocol signature or the config model names the timeout for
   each crossing call. A call whose timeout is "the library default" fails this —
   name the number. Grep the Phase 3.1 protocols: a crossing method with no
   timeout parameter and no timeout field in the Phase 3.2 config is a fail.
   *Upstream:* `_rule-workbench/release-it/traceability.md:21` (`M4`),
   `traceability.md:36` (`M16`).

2. **Retry is classified, bounded, and single-layered.** For each crossing call the
   design states which failures are retryable and which are not, the maximum
   attempt count, the maximum total elapsed time, and the backoff. If two layers of
   the dependency graph both retry the same call, the design states the resulting
   worst-case multiplier or removes one layer. `design/SKILL.md:147`'s "retry
   transient failures" is the input to this item, not the answer.
   *Upstream:* `traceability.md:22` (`M5`).

3. **Every queue, pool, buffer, cache, and list-returning interface has a stated
   bound and a stated full-behaviour.** For each: maximum size, and what happens on
   overflow — block, reject, drop oldest, shed. "Unbounded" is an acceptable
   answer only when written down as a deliberate choice with the input rate that
   makes it safe.
   *Upstream:* `traceability.md:24` (`M7`), `traceability.md:37` (`M17`).

4. **Each dependency failure has a named blast radius.** For each edge in the Phase
   2.1 dependency graph that crosses the process boundary, the design states what
   the caller does when the dependency is *slow* — distinct from what it does when
   the dependency is *down*. Slow is the harder case and the one that exhausts
   pools. Where the answer is "the caller also stops serving", the design says so
   explicitly rather than leaving it implied.
   *Upstream:* `traceability.md:23` (`M6`), `traceability.md:19` (`M2`).

5. **Dependency responses are validated, not just user input.** Blueprint validates
   what comes *in* from users and config. This item covers what comes *back* from a
   dependency: status, shape, and business plausibility, checked before the value
   is written to a cache, enqueued, or persisted. The design names the check and
   what happens when it fails.
   *Upstream:* `traceability.md:28` (`M11`).

6. **The diagnosis surface at each crossing boundary is named.** For each crossing
   call the design names what is emitted on failure: a correlation identifier that
   survives the boundary, the latency, the error class, and the saturation signal
   for whatever pool or queue backs it. `shared-principles.md:107` fixes the log
   *format*; this item fixes the *content* at the one place content matters.
   *Upstream:* `traceability.md:29` (`M12`).

7. **Declared conflict — call granularity.** `shared-principles.md:24-27`
   (Interface Segregation) pushes toward narrow protocols, "one method is better
   than ten". Applied across a process boundary this produces chatty remote
   interaction, which upstream names as a production failure mode. Where a Phase
   3.1 Protocol is crossing, the design must state the granularity choice out loud:
   either it accepts the round-trip count, or it coarsens the interface and accepts
   the wider protocol. **`shared-principles.md` wins by default** — this pack does
   not overrule it. The requirement is that the trade is named at the gate, not
   that it is decided the other way.
   *Upstream:* `traceability.md:40` (`M20`), `traceability.md:31` (`M14`).

## Excluded — already covered

| Upstream item | Already enforced by |
|---|---|
| External *input* validated at trust boundaries | `shared-principles.md:86` — Pydantic mandated at external boundaries (config, API contracts, serialisation). Retained only as the *response* half, item 5 |
| Diagnostics have a consistent structured form | `shared-principles.md:107` — structured logging required, print statements banned in library code. Retained only as the *content* half, item 6 |
| Failure behaviour is designed per layer, not per call | `design/SKILL.md:145-149` — Error Handling Strategy already forces a per-layer decision. Items 1-4 supply the runtime dimensions that section does not name |
| Shared mutable state under concurrency is a design failure | `design/SKILL.md:88-92` — Inversion Check names "shared mutable state that breaks under concurrency" |
| A component depending on too much is a structural defect | `design/SKILL.md:100` God module detection; `review-architecture/SKILL.md:85-110` Dimension 2 fan-in/fan-out |

## Excluded — outside blueprint's scope

Not admitted, and not because blueprint covers them. `shared-principles.md:62-67`
states that blueprint does not prescribe web frameworks, infrastructure, databases
or ORMs, or CI/CD tooling. These upstream areas have no gate to change:

- Startup, health checks, migrations, one-time jobs, delivery tooling (`traceability.md:30`, `M13`).
- Load balancing, service discovery, routing, readiness handshakes (`traceability.md:39`, `M19`).
- Security posture, hostile traffic, game days, chaos and disaster simulation (`traceability.md:32`, `M15`).
- Deployment and operational automation idempotency (`traceability.md:38`, `M18`).

Roughly half of upstream's checklist is cut here. That is the correct outcome for a
repo that builds Python libraries and pipelines rather than operating services. If
blueprint later grows a deployment skill, these become admissible against it.

## Attribution

Derived from `release-it/release-it.mini.md` in
<https://github.com/rockandrolla13/agent-rules-books> at `a7d7649`, MIT licensed,
Copyright (c) 2026 Maciej Ciemborowicz. Rewritten, not copied. The underlying book
is Michael T. Nygard, *Release It!* (2nd ed., 2018).
