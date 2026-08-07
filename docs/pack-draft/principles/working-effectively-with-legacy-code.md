---
pack: working-effectively-with-legacy-code
book: Working Effectively with Legacy Code — Michael Feathers
source: https://github.com/rockandrolla13/agent-rules-books
upstream_rev: a7d7649
license: MIT
applies_to: [refactor]
when: >
  The module under change has no test file, or its tests do not execute the
  function being changed; or the change point cannot be instantiated in a test
  without a network call, a database, a clock read, a filesystem write outside
  tmp, or a module-level global.
conflicts_with: none
---

# Pressure Pack — Working Effectively with Legacy Code

Blueprint already refuses to refactor untested code. This pack supplies what
happens *after* that refusal: how to choose where to cut, which barrier to break,
and what debt the cut creates.

Scope is the technique taxonomy only. The coverage gate is blueprint's and is not
restated here.

## Final checklist

Check each against the refactoring plan produced at `refactor` Phase 3, and against
the diff produced at Phase 4. Every item is answerable from an artefact, not from
belief.

1. **Seam named and located.** The plan names the seam as `file.py:line` or
   `Class.method`, and states which of the three it provides: substitution,
   observation, or both. A step whose seam is "extract a protocol" without a named
   location does not satisfy this.
   *Upstream:* `_rule-workbench/working-effectively-with-legacy-code/traceability.md:23` (`M6`).

2. **Sensing vs separation declared per seam.** For each seam the plan states
   whether it exists to *observe* a value the test cannot otherwise reach (sensing)
   or to *replace* a collaborator the test cannot otherwise supply (separation).
   A seam that is both says so. This determines whether the seam can be deleted
   after the change or must survive as structure.
   *Upstream:* `traceability.md:23` (`M6`), `traceability.md:41` (`M21`).

3. **Barrier named before technique chosen.** Each dependency-breaking step names
   the specific barrier it removes — constructor work, hidden allocation, factory
   call, module-level global, static, framework object, ambient context (clock,
   environment, current user), or hard parameter — and the technique follows from
   that barrier. "Introduce a protocol" appearing against three different barriers
   is a fail: it means the barrier was never diagnosed.
   *Upstream:* `traceability.md:28` (`M11`), `traceability.md:37` (`M17`).

4. **Test point chosen by tracing effects, not by file boundary.** The plan names
   the observation point and shows the path from the change point to it through at
   least one of: return value, field write, call to a collaborator, output stream.
   Where several changed paths converge on one function, that pinch point is named
   and used. A test point chosen because it is "the public API of the module" does
   not satisfy this.
   *Upstream:* `traceability.md:22` (`M5`).

5. **Behaviour additions in untested code use sprout or wrap, not in-place edit.**
   Where the change adds behaviour rather than restructuring it, the plan uses
   sprout method, sprout class, wrap method, wrap class, or extract-and-override,
   and says which. The new behaviour lands in a unit that has a test; the untested
   host is edited by one call site only. Grep the diff: the host function should
   gain one line, not a branch.
   *Upstream:* `traceability.md:26` (`M9`).

6. **Every temporary seam has a named cleanup obligation.** Any seam that is
   public-for-test, subclass-only, a sensing variable, a `# for testing` parameter
   default, or a monkeypatch target is listed in the plan's Remaining debt with the
   condition that retires it. A temporary seam with no retirement condition is
   permanent structure that was never designed.
   *Upstream:* `traceability.md:41` (`M21`).

7. **Characterization tests run without the barrier they were written to cross.**
   The tests added under blueprint's Phase 1.3 execute with no network, no database,
   no wall-clock dependence, and no writes outside a tmp path. If they cannot, the
   seam was placed on the wrong side of the barrier and item 3 was not actually done.
   *Upstream:* `traceability.md:21` (`M4`), `traceability.md:38` (`M18`).

## Excluded — already covered

Cut from the upstream checklist because blueprint already forces the outcome.

| Upstream item | Already enforced by |
|---|---|
| Untested area treated as legacy risk | `refactor/SKILL.md:53-72` — hard `**STOP.**`, three named options, no silent proceed |
| Uncertain current behaviour characterized | `refactor/SKILL.md:74-81` — characterization tests must "capture reality, not intent" and carry a labelling comment |
| Behaviour delta and behaviour-to-preserve stated | `refactor/SKILL.md:16-26` — four enumerated preservation conditions; `refactor/SKILL.md:113-117` — each step carries before → after |
| Behaviour change, refactoring, and cleanup kept separate | `refactor/SKILL.md:246-248` — "Never refactor and add features simultaneously" |
| Small verified steps, safe to stop after step N | `refactor/SKILL.md:114-116` — each step independently safe; `refactor/SKILL.md:159-165` — one step at a time, tests between |
| Blocking dependency reduced without expanding hidden dependencies | Partially — `design/SKILL.md:100` flags leaky abstractions and `refactor/SKILL.md:85-91` maps unnecessary coupling. Retained only as the *barrier-naming* half, item 3 |
| Touched area more understandable, testable, or changeable | `refactor/SKILL.md:236-241` — Summary must report "New tests added" and "Extensibility improved" |
| High-risk untested step needs explicit acknowledgment | `refactor/SKILL.md:166-184` — second `**STOP.**` with the same three options |

Seven of nine upstream checklist items are wholly or mostly covered. The two that
are not — seam discipline and technique-to-barrier matching — expand into items 1-7
above because blueprint has no vocabulary for either: `seam`, `sprout`, `wrap
method`, `extract and override`, `pinch point`, and `dependency break` each appear
zero times across all twelve `SKILL.md` files.

## Attribution

Derived from `working-effectively-with-legacy-code/working-effectively-with-legacy-code.mini.md`
in <https://github.com/rockandrolla13/agent-rules-books> at `a7d7649`, MIT licensed,
Copyright (c) 2026 Maciej Ciemborowicz. Rewritten, not copied: upstream items were
cut against blueprint's existing coverage and the survivors restated as artefact
checks. The underlying book is Michael Feathers, *Working Effectively with Legacy
Code* (2004).
