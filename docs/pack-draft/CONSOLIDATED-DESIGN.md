# Pressure Pack Layer — Consolidated Design

Design B. Packs are files under `principles/` that self-declare applicability in
frontmatter. `shared-principles.md` gains one new top-level section. Zero
`SKILL.md` edits.

Everything below was checked against the working tree at `/home/ak/blueprint`
(commit `fb34b24`) and against `agent-rules-books` at `a7d7649`. Where the brief
was wrong, § Pushback says so.

---

## 1. What a pack is

A distillation of one book into a checklist that a skill verifies before it
presents at its gate. A pack:

- **adds checks.** It does not add a phase, a gate, or an output field.
- **is subordinate.** `shared-principles.md` is policy; packs are pressure.
- **is disposable.** Rollback is `rm principles/<slug>.md`.

Packs live at `principles/<book-slug>.md`, one file per book, flat. No index file —
see § 4.

---

## 2. Frontmatter schema

```yaml
---
pack: <slug>                    # required
book: <Title — Author>          # required
source: <upstream repo URL>     # required
upstream_rev: <short SHA>       # required
license: <SPDX id>              # required
applies_to: [<skill>, ...]      # required, ≥1 entry
when: >                         # required
  <codebase-observable condition>
conflicts_with: <section> | none # required
---
```

| Field | Rule | Lintable |
|---|---|---|
| `pack` | Must equal the filename stem. Kebab-case | Yes |
| `book` | Free text. Title and author | Presence only |
| `source` | Upstream repo URL. Diagnosis only — nothing fetches it | Presence only |
| `upstream_rev` | Short SHA of the upstream commit the pack was derived from. Never updated automatically | Presence + hex shape |
| `license` | Upstream licence. All four current packs are MIT | Presence only |
| `applies_to` | List of skill directory names. Each must resolve — see § 3. Non-empty | Yes |
| `when` | Must be checkable against the code or design under discussion, not against the task type. A `when` that is true of every invocation of every skill in `applies_to` is not a condition and the pack must be rejected | **No** — human judgement |
| `conflicts_with` | Names a `## ` or `### ` heading in `shared-principles.md`, or the literal `none` | Yes |

Body requirements:

- `## Final checklist` — required, non-empty. This is what the gate consumes.
- `## Excluded — already covered` — required. Each row cites `file:line` in blueprint.
- `## Attribution` — required when upstream is licensed.
- `## Excluded — outside blueprint's scope` / `## Excluded — no gate to change` —
  optional, used where an upstream item is cut for a reason other than existing
  coverage. Both appear in the four drafted packs and both are load-bearing: they
  are how the admission rule shows its work.

**No `specificity` field.** Specificity is derived — see § 6 — so there is nothing
to keep in sync.

---

## 3. Name resolution

`applies_to: [refactor]` resolves to `<blueprint-root>/refactor/SKILL.md` existing.

Against the **filesystem**, deliberately. Blueprint currently has at least ten
mutually disagreeing skill registries — `README.md` twice, `CLAUDE.md`,
`domain.md` twice, `shared-principles.md:141-151`, `blueprint-usage-guide.md:466-478`,
`tools/contract_lint.py` twice, `setup.sh:11` — carrying 6, 8, 9 or 10 skills
against a filesystem that has 12 (`docs/plans/2026-08-07-first-pass-prerequisites.md:49-61`).
Resolving against any of them would create an eleventh. The filesystem is the only
thing that cannot disagree with itself.

This holds even after that plan's Phase 1 introduces `SKILLS.md`. `SKILLS.md`
becomes the *documentation* source of truth; pack resolution stays filesystem. The
lint may cross-check the two — that is Phase 4's `S10`, not this layer's problem.

---

## 4. The two load points, and which ships

**Generation-time.** A skill, on entry, consults a router that maps skill → packs
and loads them before Phase 1. Pressure is available while the output is being
constructed.

**Verification-time.** A skill, at its gate, reads the packs that apply and treats
their `Final checklist` as additional gate items. Pressure arrives after the output
exists and forces revision.

**Verification-time ships now. Generation-time does not.**

Generation-time requires a router that skills read on entry, which means either a
`SKILL.md` edit per skill (breaking the zero-edit property) or a hand-written
`principles/PACKS.md` that duplicates every pack's frontmatter and immediately
starts drifting — a fresh instance of the exact defect the prerequisites plan is
fixing. If a router is ever built it is **generated** from pack frontmatter with a
`--check` mode that fails when the file disagrees with the packs. No router file is
authored by hand, and none is authored now.

Whether generation-time is worth building at all is an empirical question, and
`PASTE-TEST.md` is the experiment that answers it.

### Where the gate actually is

Not uniformly at `## Pre-Gate Self-Check`. Verified across the tree:

| Skill | Gate form | Location |
|---|---|---|
| architect | Pre-Gate Self-Check | `architect/SKILL.md:256` |
| code-review | Pre-Gate Self-Check | `code-review/SKILL.md:77` |
| design | Pre-Gate Self-Check | `design/SKILL.md:193` |
| ideate | Pre-Gate Self-Check | `ideate/SKILL.md:121` |
| orch | Pre-Gate Self-Check | `orch/SKILL.md:341` |
| refactoring-plan | Pre-Gate Self-Check | `refactoring-plan/SKILL.md:237` |
| review-architecture | Pre-Gate Self-Check | `review-architecture/SKILL.md:297` |
| review-depth | Pre-Gate Self-Check | `review-depth/SKILL.md:225` |
| **refactor** | **`**STOP.**` + Review Checkpoint** | `refactor/SKILL.md:110`, `:142-146` |
| **scaffold** | **`**STOP.**` before writing files** | `scaffold/SKILL.md:53` |
| **plan-tracker** | **`**STOP.**` + plan summary** | `plan-tracker/SKILL.md:123` |
| **navigator** | **neither** | — |

The rule in `shared-principles.md` is therefore worded "at your gate", naming both
forms. The four exceptions include both `WRITES CODE` skills. See § Pushback.

---

## 5. Admission rule

A pack is admitted only if **at least one of its items changes a gate outcome that
blueprint's existing twelve skills miss**, and that item cites the line in
`_rule-workbench/<book>/traceability.md` that justifies it.

Applied per item, not per pack. An item blueprint already forces is cut and
recorded in `## Excluded — already covered` with a blueprint `file:line`. Three
exclusion reasons are in use:

1. **already covered** — blueprint enforces the outcome. Cite where.
2. **outside blueprint's scope** — `shared-principles.md:62-67` states blueprint does
   not prescribe web frameworks, infrastructure, databases or ORMs, or CI/CD.
3. **no gate to change** — real advice, but no blueprint skill gates the activity.
   Code Complete's debugging discipline is the clean example: blueprint has no
   debugging skill, so there is no outcome to move.

Cut ratios for the four drafted packs are in § 10.

---

## 6. The two-pack cap

**At most two packs load per gate.** On three or more matches the skill reports
every match and loads two.

Selection: fewest `applies_to` entries wins — a pack aimed at one skill is more
specific than one aimed at three. Tie broken alphabetically by `pack`.

The tiebreak is arbitrary and stated as arbitrary. It is deterministic, which is
what matters; and because the gate reports all matches, a human sees what was
dropped and can ask for it. Worked example on the current four: at the `refactor`
gate both `working-effectively-with-legacy-code` (1 entry) and `code-complete`
(2 entries) can match. WELC wins on specificity, which is the intended behaviour —
for a module with no tests the legacy techniques matter more than type discipline.

The cap is **per gate**, not per session. A workflow that passes through
`architect → design → refactor` evaluates three times and may load different packs
each time.

---

## 7. Conflict declaration and surfacing

`conflicts_with` names the section of `shared-principles.md` a pack argues with.

When a pack with a non-`none` `conflicts_with` loads, the skill **names the conflict
at the gate**:

> Pack `<slug>` conflicts with `<section>`. `shared-principles.md` governs; the pack
> asks for `<what>`. Proceeding under the shared principle unless you say otherwise.

`shared-principles.md` wins by default. The pack does not get to overrule policy.
The point is that the disagreement reaches the user, who can overrule it.

One of the four packs declares a conflict: `release-it` against
`Clean Code Principles / Interface Segregation` (`shared-principles.md:24-27`).
Interface Segregation says one method is better than ten; Release It says chatty
remote interaction is a production failure mode
(`_rule-workbench/release-it/traceability.md:40`, `M20`). Both are right at
different distances from the process boundary, and the correct behaviour is to
name the trade rather than pick silently.

The other three declare `none`. **Not every pack needs a conflict.** Manufacturing
one to exercise the field would be worse than leaving it empty.

---

## 8. What is testable — and what is not

### A lint can check

| ID | Check |
|---|---|
| P1 | Frontmatter is `---`-delimited and parses as YAML |
| P2 | All eight required fields present |
| P3 | `pack` equals the filename stem |
| P4 | `applies_to` is a non-empty list, and every entry resolves to `<root>/<entry>/SKILL.md` |
| P5 | `upstream_rev` is a non-empty hex string |
| P6 | `conflicts_with` is `none` or matches a heading in `shared-principles.md` |
| P7 | Body contains a non-empty `## Final checklist` |
| P8 | Body contains `## Excluded — already covered` |
| P9 | Every `file:line` citation in an Excluded block points at a file that exists and a line within it |
| P10 | No two packs share a `pack` slug |

P9 is the strongest check available and the one most worth building: it catches
exclusion citations that rot when a `SKILL.md` is edited, which is the failure mode
that turns an honest exclusion table into a lie.

**P9 implementation note.** A pack cites two repos. `_rule-workbench/<book>/traceability.md:NN`
and `docs/COMPATIBILITY.md` are upstream; everything else is blueprint-relative.
P9 must resolve only the blueprint-relative set and skip the rest, or it reports
false failures on every pack. Running this check by hand over the four drafted
packs resolved 101 blueprint citations with 0 failures, and 49 upstream `M`-rule
citations with 0 mismatches — so the exclusion tables are currently accurate, which
is the baseline P9 exists to defend.

### A lint cannot check

**Whether a checklist item was applied.** Pack checklists are consumed at the gate,
before the `## Handoff` is written, and leave no trace in any artefact. There is no
observable output that distinguishes "the pack was read and satisfied" from "the
pack was never opened".

This is a real and accepted limitation. It is not fixed by adding a `Packs applied:`
field to the Handoff — that would require editing the `### Produces` contract of
every skill in every pack's `applies_to`, destroying the zero-`SKILL.md`-edits
property that is the whole reason Design B was chosen. **Do not design that field.**

Also uncheckable:

- Whether `when` is genuinely codebase-observable. A human reviews this at admission.
- Whether an item genuinely changes a gate outcome. Same.
- Whether an `## Excluded — already covered` row is *correct* — P9 checks the
  citation resolves, not that it says what the row claims.

The honest summary: **the lint checks that a pack is well-formed and that its claims
about blueprint point somewhere real. It does not check that packs work.** The only
evidence that packs work is the A/B experiment in `PASTE-TEST.md`.

---

## 9. Deferred to v2

| Item | Why deferred |
|---|---|
| Generated router `principles/PACKS.md` | Blocked on the paste test. Build only if verification-time pressure proves too late |
| Generation-time loading | Same |
| Any sync with upstream | Settled: staleness accepted. `upstream_rev` is a diagnosis breadcrumb, not a mechanism |
| PoEAA pack | Cut — see § 11 |
| Per-item application evidence | Impossible without `SKILL.md` edits. See § 8 |
| `overlaps_with:` field | Overlap with an existing skill is stated in pack prose, not schema. One relationship field is enough |
| Packs for `commands/` | `commands/*.md` are thin wrappers over skills; pressure applies at the skill's gate underneath |

---

## 10. The four packs, and their cut ratios

| Pack | `applies_to` | Upstream items | Retained | Cut | Conflict |
|---|---|---|---|---|---|
| working-effectively-with-legacy-code | `[refactor]` | 9 checklist / 23 rules | 7 | 8 excluded rows | none |
| release-it | `[design]` | 8 checklist / 22 rules | 7 | 5 covered + 4 out-of-scope | Interface Segregation |
| designing-data-intensive-applications | `[architect, design]` | 10 checklist / 27 rules | 5 | 5 covered + 5 out-of-scope | none |
| code-complete | `[code-review, refactor]` | 6 checklist / 32 rules | 4 | 12 covered + 4 no-gate | none |

Retained counts are checklist items in the drafted pack, which do not map one-to-one
onto upstream checklist lines — WELC's two surviving areas expand into seven
checkable items, while Code Complete's thirty-two rules collapse to four. The
ordering is the signal: WELC retains most, Code Complete least, and that tracks
exactly how much of each book blueprint already contains.

**WELC is pack #1** — but not because blueprint lacks legacy-code coverage. It has
it: `refactor/SKILL.md:53-81` is a hard `**STOP.**` with characterization tests,
and `refactor/SKILL.md:166-184` a second one for high-risk untested steps. WELC is
first *because* that baseline exists — it makes the pack's effect measurable. The
pack adds only the technique taxonomy, which blueprint has zero of: `seam`,
`sprout`, `wrap method`, `extract and override`, `pinch point`, and `dependency
break` return **zero hits** across all twelve `SKILL.md` files.

---

## 11. PoEAA is cut

Three independent reasons, all verified:

1. Upstream's compatibility grid has exactly **two ❌ verdicts in 14×14**
   (`docs/COMPATIBILITY.md:61`), and both are PoEAA: DDD❌PoEAA
   (`docs/COMPATIBILITY.md:21`) and IDDD❌PoEAA (`docs/COMPATIBILITY.md:23`). ❌ means
   "do not load together as equal active rule sets" (`docs/COMPATIBILITY.md:8`).
2. Blueprint's `architect` is DDD-flavoured: "bounded contexts" in its own trigger
   description (`architect/SKILL.md:4`), aggregates as a candidate abstraction class
   (`architect/SKILL.md:47`), a mandatory domain model (`architect/SKILL.md:261`),
   and an explicit anaemic-domain-model anti-pattern (`architect/SKILL.md:322`).
3. PoEAA's layer-ownership rules argue with the fixed project layout at
   `shared-principles.md:89-105`, which already assigns `core/`, `data/`,
   `strategy/`, `execution/`.

The first four packs are pairwise ✅ with each other in the same grid.

---

## Pushback

Four points where the brief was wrong on the evidence, plus one risk it did not name.

### P1 — The load point is not "the Pre-Gate Self-Check". Corrected.

The brief specifies verification-time loading "at the Pre-Gate Self-Check". Only
**8 of 12** skills have one. Missing: `refactor`, `scaffold`, `plan-tracker`,
`navigator` — and `refactor` and `scaffold` are the only two `WRITES CODE` skills
in the repo. As written, the mechanism would be dead at exactly the two gates where
code gets produced, including `refactor`, the target of the paste test.

Corrected to "at your gate", naming both forms. Table in § 4. No `SKILL.md` edit
needed; the wording change is entirely inside `shared-principles.md`.

### P2 — The paste test as specified cannot be run. Retargeted.

D4 asks to paste WELC's checklist "into the Pre-Gate Self-Check" of `refactor`.
`refactor` has no such section (P1). `PASTE-TEST.md` retargets the paste to
`refactor/SKILL.md:142-146`, the Phase 3.3 Review Checkpoint, which is the gate
immediately preceding the Phase 3 plan the test compares. The experiment is
unchanged in substance.

### P3 — `code-complete` carries an overlap the brief did not weigh.

The brief cut PoEAA on a ❌ verdict but admitted `code-complete` without checking
its grid row. Upstream scores Code Complete against Clean Code at **🔁 Overlap,
78%, "choose one"** (`docs/compatibility/clean-code/code-complete.md`), and
blueprint's `code-review` is a Clean Code skill by construction
(`code-review/SKILL.md:137`). 🔁 is weaker than ❌ — "compete for the same decision
layer", not "push toward contradictory decisions" — so this is not grounds to cut.

**Recommendation: keep, as drafted.** The pack is scoped down to four items,
twelve exclusion rows, and states the overlap in its own first paragraph. If the
user prefers a three-pack first wave, `code-complete` is the one to drop, and
dropping it costs the least.

### P4 — Item 4 of `code-complete` collides with the pending `review-depth` change.

`docs/plans/2026-08-07-first-pass-prerequisites.md:329` adds a `CMNT` finding type
to `review-depth` for exactly "a comment explaining a confusing name, flow, or
decomposition". That is `code-complete` item 4. The plan is written but not applied,
so at `fb34b24` the item is admissible; once Phase 3 lands it is not.

This is the admission rule's first live failure mode: **coverage is a moving
target, and a pack admitted before a skill change can be invalidated by it.**
Handled in `WRITE-PLAN.md` by ordering the pack layer strictly after the
prerequisites plan and re-running the exclusion audit. No mechanism is proposed to
detect this in general — P9 catches rotted line citations, not new coverage.

### P5 — Risk the brief did not name: the `when` field has no enforcement.

`when` is the entire targeting mechanism and is the one field a lint cannot check
(§ 8). Nothing stops a future pack from writing `when: refactoring`, at which point
that pack loads at every `refactor` gate, consumes one of the two cap slots
permanently, and starves the pack that actually applied. The cap turns an
unenforceable field into a resource that packs compete for.

Mitigation is procedural only: the admission review reads `when` and rejects
conditions that are true of every invocation. Stated here so it is a known
limitation rather than a discovery.

---

## Invariants this design preserves

- No `SKILL.md` is created, modified, or deleted.
- No checkpoint gate is added, removed, or weakened.
- No principle text is duplicated out of `shared-principles.md` into a pack — packs
  cite it (`release-it` item 7, `code-complete` items 1 and 3).
- No skill both diagnoses and acts as a result of this layer.
- `shared-principles.md` grows by one section and one bullet; it stays well under
  any size that would warrant extraction.
