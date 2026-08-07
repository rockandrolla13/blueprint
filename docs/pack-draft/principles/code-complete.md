---
pack: code-complete
book: Code Complete — Steve McConnell
source: https://github.com/rockandrolla13/agent-rules-books
upstream_rev: a7d7649
license: MIT
applies_to: [code-review, refactor]
when: >
  A public function in the code under review takes or returns a `str`, `int`,
  `float`, `bool`, or `dict` that encodes a closed set of values, a unit-bearing
  quantity, or more than two states; or a function contains a defensive check whose
  failure would mean a caller in this repo is wrong rather than that external data
  is bad; or the module's test file contains only inputs that succeed.
conflicts_with: none
---

# Pressure Pack — Code Complete

**Read the overlap warning before admitting this pack.** Upstream scores Code
Complete against Clean Code as 🔁 Overlap, 78%, verdict "choose one"
(`docs/compatibility/clean-code/code-complete.md`). Blueprint's `code-review` is a
Clean Code skill by construction — its pillars are Correctness, Style, SOLID, DRY,
Performance, Types (`code-review/SKILL.md:137`). So most of Code Complete competes
with an existing blueprint skill for the same decision layer rather than adding to
it.

This pack is therefore the narrowest of the four by a wide margin: four items out
of thirty-two upstream decision-and-trigger rules. Everything that `code-review`,
`refactor` §4.4, or `review-depth` can already raise has been cut, including
several items that are genuinely good advice. That is the admission rule working,
not an oversight.

## Final checklist

Check each against the findings `code-review` produces, or the diff `refactor`
produces.

1. **Closed sets, units, and multi-state values live in the type, not in a
   convention.** `shared-principles.md:60` requires a type hint on every public
   function; this item asks whether the hint excludes the invalid value. A `str`
   holding one of four statuses is an `Enum`. A `float` carrying basis points is a
   named type or a parameter whose name states the unit. A `bool` standing for
   three states is a defect regardless of annotation. Checkable: for each public
   signature, name the invalid value the type still admits, or state that none
   remains.
   *Upstream:* `_rule-workbench/code-complete/traceability.md:24` (`M7`),
   `traceability.md:42` (`M22`).

2. **Programmer-error checks and external-failure checks are different mechanisms.**
   For each defensive check in the reviewed code, classify it: a violated
   *assumption about this repo's own callers* is an assertion or a precondition
   that fails loudly and is never caught in normal flow; *bad data arriving from
   outside* is a validation error handled per `design/SKILL.md:145-149`. A single
   `if not x: return None` serving both is the defect. Checkable: every defensive
   check in the diff falls into one class and uses that class's mechanism.
   *Upstream:* `traceability.md:27` (`M10`), `traceability.md:43` (`M23`).

3. **Tests cover at least one boundary case and one invalid input per public
   function, or the omission is stated.** `shared-principles.md:106` asks for
   property-based testing "for numerical code where edge cases matter", and
   `review-architecture/SKILL.md:194-195` asks for edge cases "for numerical/quant
   code". Neither reaches ordinary code. Checkable: for each public function
   touched, the test file contains an input at the edge of the accepted range and
   an input outside it — or the review records which functions lack them and why.
   *Upstream:* `traceability.md:47` (`M27`).

4. **Comments that remain explain intent, constraint, or rationale — never
   mechanism.** A comment restating what the line does is deleted; a name that
   needed the comment is changed instead. Checkable against the diff: every comment
   added or retained answers "why" or "what must hold", not "what happens next".
   *Upstream:* `traceability.md:21` (`M4`), `traceability.md:51` (`M31`).

   *Note:* if the pending `review-depth` change in
   `docs/plans/2026-08-07-first-pass-prerequisites.md` §3.1 lands, `CMNT`
   (compensating comment) will cover this item and it must be cut. See WRITE-PLAN.

## Excluded — already covered

| Upstream item | Already enforced by |
|---|---|
| Cohesive, precisely named routines, small interfaces, no flag arguments | `refactor/SKILL.md:202-216` — verb-phrase function names, ~20-line limit, max 3 parameters, one abstraction level per function |
| Focused classes and modules; hide representation; no god objects | `refactor/SKILL.md:212-216`; `design/SKILL.md:99` God module detection; `review-depth/SKILL.md:37-91` module census and depth ratio |
| Rising complexity is defect risk; reduce maintainer working memory | `review-depth/SKILL.md:140-171` — Cognitive Load scoring is a direct measurement of this |
| Control flow simple enough to verify; no clever one-liners | `code-review/SKILL.md:92` "Keep control flow explicit — never suggest clever tricks that obscure logic"; `review-depth` `COGN` findings |
| Remove duplication that multiplies maintenance effort | `shared-principles.md:29-48` — DRY with the knowledge-vs-code distinction and the Rule of Three, which is the sharper rule |
| Keep refactoring separate from behaviour change | `refactor/SKILL.md:246-248` |
| Errors handled at the right abstraction level | `design/SKILL.md:145-149` — per-layer error strategy |
| Validate input at trust boundaries | `shared-principles.md:86` — Pydantic mandated at external boundaries |
| Build in small verifiable increments | `refactor/SKILL.md:114-116`, `refactor/SKILL.md:159-165`; `plan-tracker/SKILL.md:74-96` invariants after each step |
| Match review depth to defect risk | `code-review/SKILL.md:29-34` severity ladder; `code-review/SKILL.md:97` prioritisation rule for large files |
| Follow shared conventions rather than a module dialect | `refactor/SKILL.md:249-250` "Preserve the user's style"; `scaffold/SKILL.md:290` Consistency Rules |
| Tune performance only on evidence | `refactor/SKILL.md:186-197` — performance note required, benchmark suggested, user decides |

## Excluded — no gate to change

These are real Code Complete rules that blueprint neither covers nor has a gate
for. They fail the admission rule because there is no gate outcome to change:

- Reproduce-isolate-explain before fixing (`traceability.md:48`, `M28`). Blueprint
  has no debugging skill. Admissible only if one is created.
- Table-driven and data-driven dispatch (`traceability.md:26`, `M9`). Prescribing a
  technique rather than stating a principle; `CLAUDE.md`'s anti-pattern table
  forbids it.
- Tooling, build automation, profilers (`traceability.md:35`, `M18`). Blueprint does
  not prescribe CI/CD tooling (`shared-principles.md:66`).
- Pre-construction verification of requirements and architecture fit
  (`traceability.md:18`, `M1`). This is what workflow W1 *is* — `ideate → architect
  → design → scaffold`. A pack cannot add pressure to the shape of the workflow it
  runs inside.

## Attribution

Derived from `code-complete/code-complete.mini.md` in
<https://github.com/rockandrolla13/agent-rules-books> at `a7d7649`, MIT licensed,
Copyright (c) 2026 Maciej Ciemborowicz. Rewritten, not copied. The underlying book
is Steve McConnell, *Code Complete* (2nd ed., 2004).
