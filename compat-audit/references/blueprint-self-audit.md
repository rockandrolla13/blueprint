# Compatibility Audit: blueprint skill registry

**Sources audited:** 12 (architect, code-review, design, ideate, navigator, orch, plan-tracker, refactor, refactoring-plan, review-architecture, review-depth, scaffold)
**Pairs:** 66 total · 8 deep-dived · 58 not deep-dived
**Taken against:** commit `4394b0d`, 2026-08-07
**Produced by:** `compat-audit/SKILL.md`, applied to itself as validation

This audit is the first execution of the `compat-audit` skill. It also discharges the
`CLAUDE.md` testing checklist item *"would a given user prompt trigger exactly one skill,
not zero or two?"* — which had never been run against the registry.

Line citations are to files as of the commit above. Re-run after any frontmatter edit.

## Verdict Matrix

Triangular. `—` = not deep-dived (risk band in the triage table). `N/A` = diagonal.

| | arch | c-rev | des | ide | nav | orch | p-trk | ref | r-plan | r-arch | r-dep | scaf |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **architect** | N/A | — | ❌ | — | — | — | — | — | — | — | — | — |
| **code-review** | | N/A | — | — | — | — | — | — | — | — | ❌ | — |
| **design** | | | N/A | ✅ | — | — | — | — | — | — | — | — |
| **ideate** | | | | N/A | ❌ | — | — | — | — | — | — | — |
| **navigator** | | | | | N/A | — | — | — | — | — | — | — |
| **orch** | | | | | | N/A | — | — | — | — | — | — |
| **plan-tracker** | | | | | | | N/A | — | — | — | — | — |
| **refactor** | | | | | | | | N/A | 🔁 | ❌ | ❌ | — |
| **refactoring-plan** | | | | | | | | | N/A | — | — | — |
| **review-architecture** | | | | | | | | | | N/A | 🔁 | — |
| **review-depth** | | | | | | | | | | | N/A | — |
| **scaffold** | | | | | | | | | | | | N/A |

## Verdict Counts

✅ 1 · ❌ 5 · 🔁 2 · not deep-dived 58

Five of eight deep-dived pairs fail. The deep-dive set was selected *because* it was
high-risk, so this rate does not extrapolate to the 58 remaining pairs. It does mean the
triage signal works: every pair the triage flagged HIGH had a real defect.

## Triage Table

Risk per Phase 2 signals: **T** trigger overlap, **N** negative-trigger asymmetry,
**C** contract coupling, **M** mode collision.

| Pair | Risk | Driving signal | Deep-dived? |
|---|---|---|---|
| design vs architect | HIGH | T: `design:6` claims the literal word `"architect"`. N: one-sided | yes |
| code-review vs review-depth | HIGH | T: both claim Python-file review. N: one-sided. C: both declare refactoring-plan downstream | yes |
| refactor vs review-architecture | HIGH | T: literal shared phrase `"this grew organically"`. N: one-sided | yes |
| refactor vs review-depth | HIGH | T: `"clean up"` is a prefix of `"clean up interfaces"`. N: one-sided | yes |
| ideate vs navigator | HIGH | T: both claim the literal word `"explore"`. N: blind pair | yes |
| refactor vs refactoring-plan | HIGH | M: `refactor` Phase 3 is a planning phase. C: refactor consumes refactoring-plan | yes |
| review-architecture vs review-depth | HIGH | M: identical artifact shape. N: one-sided | yes |
| ideate vs design | MEDIUM | T: adjacent phrasing. N: **mutual** — the control case | yes |
| design vs scaffold | MEDIUM | T: shared verb `"create"` (`design:8`, `scaffold:5`). N: mutual | no |
| plan-tracker vs refactoring-plan | MEDIUM | T: shared noun "plan". N: neither names the other | no |
| design vs navigator | MEDIUM | T: `"structure"` (`design:6`) vs `"show me the structure"` (`navigator:5`) | no |
| architect vs review-architecture | MEDIUM | C: `review-architecture:384` declares architect downstream | no |
| refactoring-plan vs review-architecture | MEDIUM | C: declared pipeline edge, vocabularies match | no |
| code-review vs review-architecture | MEDIUM | T: shared verb "review". N: mutual | no |
| orch vs all others | LOW | Trigger vocabulary (`"fan this out"`, `"use the conductor"`) shares nothing | no |
| remaining 44 pairs | LOW | No shared vocabulary, no contract edge | no |

## Findings

### architect vs design

Status: reviewed
Verdict: ❌ Conflicting
Conflict: 55% · Overlap: 40% · Complementarity: 70%

**Loading decision.** Keep both installed — they are a genuine pipeline. But they cannot both
be trusted to self-select, because `design` claims the word "architect" as its own trigger.
The fix is one word, not a deprecation: delete `"architect"` from `design:6` and add an
explicit negative naming the architect skill.

**Overlap**
- Claim: Both enumerate components and both draw boundaries, at different resolutions.
  - `architect/SKILL.md:105-187` (Phase 2: Boundary Drawing, incl. 2.3 Present Candidate Boundaries): produces the module decomposition.
  - `design/SKILL.md:41-48` (1.3 Component Enumeration): re-enumerates components, presupposing they already exist.

**Complementarity**
- Claim: There is a clean, well-typed producer→consumer contract between them.
  - `architect/SKILL.md:371-373` (Downstream Consumers): names `design (reads Handoff only)`.
  - `design/SKILL.md:256-259` (Consumes): `MUST: ## Handoff from architect containing domain model, module table, abstraction decisions, rate-of-change map, DAG check` — and halts if the DAG check failed. The pair passes a typed artifact, not prose.

**Conflict**
- Claim: The literal token "architect" fires both skills, and the two prescribe different
  first moves. Worse, if `design` wins the race it immediately halts.
  - `design/SKILL.md:6` (frontmatter description): lists `"architect"` among positive triggers.
  - `architect/SKILL.md:9` (frontmatter description): claims `"help me architect this"`.
  - `design/SKILL.md:9-11` (frontmatter negatives): disclaims single-function tasks, bug fixes, refactoring, and open-ended exploration — it never names the architect skill. By contrast `architect/SKILL.md:12-14` does defer to design. The asymmetry is one-sided in the wrong direction: the skill that claims the other's name is the one that fails to disclaim it.
  - `design/SKILL.md:259` (Consumes): `If Handoff missing: STOP with CONTRACT VIOLATION`. A user who says "help me architect this" and lands on `design` gets a contract violation instead of a decomposition.

**Use together when** — running the W1 Build workflow end to end, in order, with architect first.
**Prefer one when** — the user has no components yet: architect. The user has components and needs them wired: design.
**Open questions** — None.

### code-review vs review-depth

Status: reviewed
Verdict: ❌ Conflicting
Conflict: 50% · Overlap: 45% · Complementarity: 55%

**Loading decision.** These are complementary in intent and broken in wiring. `code-review`'s
trigger claim is unbounded over Python files, and `review-depth`'s findings are silently
rejected by the shared downstream consumer. Load both only after `refactoring-plan`'s
Consumes clause is widened to accept `DM-*` IDs; until then, running both wastes half the work.

**Overlap**
- Claim: Both claim jurisdiction over "review this Python module", with no phrase separating them.
  - `code-review/SKILL.md:3` (frontmatter): triggers on `'review this code'`, `'code review'`, and — critically — `asks for feedback on Python source files`, an unbounded claim over the whole file type.
  - `review-depth/SKILL.md:4-9` (frontmatter): `Review Python code for deep module design...` triggering on `"simplify"`, `"too complex"`, `"reduce complexity"`. A user saying "review this module, it's too complex" satisfies both descriptions completely.

**Complementarity**
- Claim: Their finding vocabularies are disjoint, so the reports do not duplicate.
  - `code-review/SKILL.md:129-130` (Contract → Produces): IDs are `CR-<TYPE>-<NNN>` where TYPE is `BUG, STYLE, SOLID, DRY, PERF, TYPE` — line-level defects.
  - `review-depth/SKILL.md:247,256` (Contract → Produces, Degrees of Freedom): IDs are `DM-*-NNN` with types `SHAL, LEAK, FLAT, COGN, INIT, PASS, SIGN` — module-shape defects. No type appears in both lists.

**Conflict**
- Claim: `review-depth` declares a downstream consumer that contractually refuses its output.
  This is a broken pipeline edge, not a stylistic overlap.
  - `review-depth/SKILL.md:259-260` (Contract → Downstream Consumers): `refactoring-plan (reads Handoff, merges with code-review and review-architecture findings)`.
  - `refactoring-plan/SKILL.md:295-297` (Contract → Consumes): `MUST: ## Handoff from code-review (CR-* IDs) AND/OR review-architecture (AR-* IDs). At least one must be present. If neither: STOP with CONTRACT VIOLATION.` `DM-*` is not admissible. A `review-depth` run handed to `refactoring-plan` alone is a contract violation; handed alongside a code-review it is silently dropped, because `refactoring-plan:304` requires each step to carry `CR-*` and/or `AR-*` IDs and `:317` forbids steps without them.
- Claim: `code-review` disclaims nothing inside blueprint.
  - `code-review/SKILL.md:3` (frontmatter negatives): `Do NOT trigger for paper/manuscript review or general writing feedback` — both out-of-repo domains. It names no sibling skill, so it never yields to `review-depth` or `review-architecture`.

**Use together when** — a full pre-refactor sweep, only after the contract fix below.
**Prefer one when** — the complaint is "this is wrong": code-review. The complaint is "this is hard to understand": review-depth.
**Open questions** — None.

### refactor vs refactoring-plan

Status: reviewed
Verdict: 🔁 Overlap
Conflict: 40% · Overlap: 65% · Complementarity: 50%

**Loading decision.** `refactor` contains a complete second implementation of
`refactoring-plan` while simultaneously declaring that it consumes `refactoring-plan`'s
output. One of the two must go: either delete `refactor` Phase 3 and rely on the contract,
or drop the contract requirement and accept that `refactoring-plan` is for multi-review
synthesis only. Loading both as they stand means the agent plans twice.

**Overlap**
- Claim: `refactor` Phase 3 reproduces `refactoring-plan`'s entire job — steps, sequencing, and an approval gate.
  - `refactor/SKILL.md:108-147` (Phase 3: Refactoring Plan, incl. `3.1 Refactoring Steps` at :112 and `3.3 Review Checkpoint` at :142): an in-skill planning phase with its own checkpoint.
  - `refactoring-plan/SKILL.md:134-167` (Phase 4: Size and Plan Each Step) and `:300-319` (Contract → Produces): the same artifact, formalised with `Scope:`, `Risk:`, `Depends on:`, `Blocks:`, and `Verification:` fields.

**Complementarity**
- Claim: Where the contract is honoured, the split is clean: one is read-only, the other writes.
  - `refactoring-plan/SKILL.md:292-293` (Contract → Mode): `READ-ONLY`.
  - `refactor/SKILL.md:256-257` (Contract → Mode): `WRITES CODE (after refactoring-plan gate approval)`. The gate belongs to the planner; execution belongs to the executor.

**Conflict**
- Claim: `refactor`'s own contract contradicts `refactor`'s own body.
  - `refactor/SKILL.md:259-260` (Contract → Consumes): `MUST: ## Handoff from refactoring-plan containing phased steps`.
  - `refactor/SKILL.md:108-135` (Phase 3): generates those phased steps itself, with no instruction to skip the phase when an upstream Handoff is present. An agent following the body produces a plan it was contractually required to receive.
- Claim: Trigger vocabulary is a proper-prefix collision.
  - `refactor/SKILL.md:6-7` (frontmatter): `"clean up"`, `"technical debt"`.
  - `refactoring-plan/SKILL.md:8,10` (frontmatter): `"plan the cleanup"`, `"I have tech debt, help me plan"`. The disambiguator is the word "plan" alone. `refactoring-plan:11-13` defers to `refactor`; `refactor:9-11` names only the design skill and never defers back.

**Use together when** — findings arrive from two or more review skills and need dependency ordering before execution.
**Prefer one when** — a single known smell in a single module: `refactor` alone, skipping the planner.
**Open questions** — Which of the two duplicated planning phases the maintainer intends to keep. Not resolvable from the sources.

### review-architecture vs review-depth

Status: reviewed
Verdict: 🔁 Overlap
Conflict: 35% · Overlap: 55% · Complementarity: 50%

**Loading decision.** Same mode, same artifact shape, same downstream, adjacent triggers, and
only one of the two knows the other exists. They are separable in principle — the scored
dimensions are disjoint — but nothing in `review-architecture` routes a user away from it,
so selection is a coin flip on adjacent phrasings. Either merge `review-depth`'s five
dimensions into `review-architecture`'s seven, or make the negative triggers mutual.

**Overlap**
- Claim: The two produce structurally identical Handoffs, so a consumer cannot tell them apart by shape.
  - `review-architecture/SKILL.md:367-371` (Contract → Produces): `Scorecard table: Dimension | Score | Key Finding`, findings with `Finding ID, Severity, Dimension, Location, Summary`, scorecard uses 🟢🟡🟠🔴 (`:378`).
  - `review-depth/SKILL.md:243-247,255` (Contract → Produces): `Scorecard table: Dimension | Score | Key Finding (5 rows)`, findings with `Rating, Type, Location, Problem, Fix direction`, scorecard uses 🟢🟡🟠🔴. Both also forbid positive highlights in the Handoff (`review-architecture:374-375`, `review-depth:250-252`) — the same rule, written twice.

**Complementarity**
- Claim: The scored dimensions do not intersect, so the reports genuinely add information.
  - `review-architecture/SKILL.md:379` (Degrees of Freedom): `Boundaries | Dependencies | DRY | Extensibility | Testability | Abstraction | Parallelisation`.
  - `review-depth/SKILL.md:37-171` (Phase 1 Module Census, Phase 2 Progressive Disclosure Audit, Phase 3 Cognitive Load Scoring): interface-to-implementation ratio, `__init__.py` disclosure, per-module cognitive load. None of these is one of the seven architecture dimensions.

**Conflict**
- Claim: The disclaimer is one-sided, and `review-architecture`'s frontmatter asserts a
  two-skill worldview that `review-depth` invalidates.
  - `review-depth/SKILL.md:10-11` (frontmatter negatives): `Do NOT trigger for general code review (use code-review), architecture scoring (use review-architecture)` — correctly defers.
  - `review-architecture/SKILL.md:11-14` (frontmatter): `This complements the code-review skill — that skill reviews individual files for Clean Code compliance, this skill reviews the system-level structure. Do NOT trigger for file-level code review (use code-review), refactoring execution (use refactor), or new system design (use architect + design).` It describes the review space as exactly two skills and never names `review-depth`, which was added later.

**Use together when** — auditing a codebase before a large extension, running both and merging findings downstream.
**Prefer one when** — the complaint is about dependency direction or boundaries: `review-architecture`. The complaint is about navigability or interface bloat: `review-depth`.
**Open questions** — None.

### ideate vs navigator

Status: reviewed
Verdict: ❌ Conflicting
Conflict: 45% · Overlap: 20% · Complementarity: 60%

**Loading decision.** These two skills do unrelated jobs and both claim the literal word
`"explore"`. Neither disclaims the other — the only blind pair in the deep-dive set. The
overlap score is low precisely because the jobs are unrelated, which makes the collision
worse, not better: a misfire here produces a completely wrong response, not a slightly
wrong one.

**Overlap**
- Claim: One literal token, claimed by both.
  - `ideate/SKILL.md:5` (frontmatter): `Use this skill when the user says "ideate", "explore", "brainstorm"...`
  - `navigator/SKILL.md:6-7` (frontmatter): `Also triggers on "navigate", "explore", "find", "locate", "what calls", "what uses".`

**Complementarity**
- Claim: The jobs are genuinely disjoint — one reads a codebase, the other reads a plan.
  - `navigator/SKILL.md:13-16` (role statement): `answer questions about where things are, what they do, and how they connect — without modifying anything. Mode: READ-ONLY.`
  - `ideate/SKILL.md:48-53` (Mode B: Stress-Test): steel-manning and assumption auditing of a user's proposed approach. There is no codebase-navigation step anywhere in the skill.

**Conflict**
- Claim: Blind pair — neither frontmatter names the other, so the shared token is unresolved.
  - `ideate/SKILL.md:10-11` (frontmatter negatives): `Do NOT trigger for "build this", "implement", or "write code" — those belong to the design or scaffold skills.` Names design and scaffold only.
  - `navigator/SKILL.md:7-8` (frontmatter negatives): `Do NOT trigger for action requests like "refactor X" or "add Y" — those go to action skills.` Names a category, not a skill, and excludes only action skills — `ideate` is read-only, so this disclaimer does not reach it.

**Use together when** — never in one turn. `navigator` may precede `ideate` to gather context, but as sequential invocations.
**Prefer one when** — "explore this codebase": navigator. "explore my options": ideate. The disambiguator is the object of the verb, which neither frontmatter states.
**Open questions** — None.

### refactor vs review-architecture

Status: reviewed
Verdict: ❌ Conflicting
Conflict: 50% · Overlap: 30% · Complementarity: 65%

**Loading decision.** A verbatim shared trigger sentence, disclaimed from one side only. Keep
both — the diagnose/fix split is exactly right — but `refactor` must disclaim the review
skills, or "this grew organically" will start writing code when the user wanted a diagnosis.

**Overlap**
- Claim: Both accept the same complaint about the same kind of codebase.
  - `refactor/SKILL.md:42-52` (1.2 Identify the Pain) and `:92-102` (2.2 Code Smell Catalogue): diagnoses structural problems before changing anything.
  - `review-architecture/SKILL.md:47-227` (Step 2: Evaluate Against Dimensions): diagnoses structural problems and stops there.

**Complementarity**
- Claim: Clean read-only/writes split, and a declared path from one to the other.
  - `review-architecture/SKILL.md:360-361,382-384` (Contract → Mode, Downstream Consumers): `READ-ONLY`, feeding `refactoring-plan` and `architect`.
  - `refactor/SKILL.md:256-257` (Contract → Mode): `WRITES CODE (after refactoring-plan gate approval)`. The review produces findings, the plan orders them, refactor executes — no step is duplicated across this particular pair.

**Conflict**
- Claim: A verbatim shared trigger phrase, with the disclaimer running only one way.
  - `refactor/SKILL.md:6` (frontmatter): triggers on `"this grew organically"`.
  - `review-architecture/SKILL.md:10` (frontmatter): `Also trigger when the user says "this grew organically, is it still sane"`. The refactor trigger is a strict prefix of the review-architecture trigger, so the shorter, more aggressive claim wins on any partial match.
  - `review-architecture/SKILL.md:13-14` (frontmatter negatives): `Do NOT trigger for ... refactoring execution (use refactor)` — defers correctly. `refactor/SKILL.md:9-11` disclaims only `new designs from scratch (use the design skill)` and bug fixes. It never defers to a review skill, so the read-only-first intent is unenforced.

**Use together when** — the W3 Redesign workflow: review first, then plan, then refactor.
**Prefer one when** — the user wants a verdict and no edits: `review-architecture`. The user has already accepted the diagnosis: `refactor`.
**Open questions** — None.

### refactor vs review-depth

Status: reviewed
Verdict: ❌ Conflicting
Conflict: 45% · Overlap: 25% · Complementarity: 65%

**Loading decision.** Same shape as the pair above: a prefix collision disclaimed from one
side only. The fix is the same single edit to `refactor`'s negative triggers, which resolves
both pairs at once.

**Overlap**
- Claim: Both respond to "this module is unpleasant to work with", and both discuss interfaces.
  - `refactor/SKILL.md:199-216` (4.4 Apply Clean Code Throughout): reshapes functions and interfaces during execution.
  - `review-depth/SKILL.md:41-53` (1.1 Measure Interface Surface Area): scores the same interfaces, read-only.

**Complementarity**
- Claim: `review-depth` supplies a measurement `refactor` has no way to produce, and `refactor` supplies the execution `review-depth` forbids.
  - `review-depth/SKILL.md:66-76` (1.3 Compute Depth Ratio): a numeric interface-to-implementation ratio per module.
  - `review-depth/SKILL.md:250-251` (Contract → Produces, FORBIDDEN): `Code changes or patches` — it cannot act on its own findings.

**Conflict**
- Claim: `"clean up"` is a proper prefix of `"clean up interfaces"`, and only `review-depth` disclaims.
  - `refactor/SKILL.md:6` (frontmatter): triggers on `"clean up"`.
  - `review-depth/SKILL.md:7` (frontmatter): triggers on `"clean up interfaces"`. A user asking to "clean up interfaces" matches `refactor`'s shorter claim first.
  - `review-depth/SKILL.md:10-11` (frontmatter negatives): `Do NOT trigger for ... refactoring execution (use refactor)`. `refactor/SKILL.md:9-11` does not reciprocate — it names only the design skill.

**Use together when** — a navigability complaint on a codebase you intend to change: measure with `review-depth`, then execute with `refactor`.
**Prefer one when** — no code should change yet: `review-depth`.
**Open questions** — None.

### design vs ideate

Status: reviewed
Verdict: ✅ Complementary
Conflict: 20% · Overlap: 25% · Complementarity: 75%

**Loading decision.** Load both. This is the registry's best-formed pair and the model the
other pairs should be edited toward: each frontmatter names the other in its negative
triggers, and the trigger vocabularies partition cleanly. One residual risk, below.

**Overlap**
- Claim: Adjacent question phrasings, distinguished by verb rather than left ambiguous.
  - `ideate/SKILL.md:6` (frontmatter): `"how should I approach"`, `"what's the best way to"`.
  - `design/SKILL.md:6` (frontmatter): `"how should I build this"`. "Approach" versus "build" is a real semantic split, not an accident.

**Complementarity**
- Claim: Mutual negative triggers — each explicitly routes its non-cases to the other.
  - `ideate/SKILL.md:10-11` (frontmatter negatives): `Do NOT trigger for "build this", "implement", or "write code" — those belong to the design or scaffold skills.`
  - `design/SKILL.md:10-11` (frontmatter negatives): `Do NOT trigger for open-ended exploration — that belongs to the ideate skill.` The claims are exact complements: `design:8` claims `"build"`, `"implement"`, `"create"`, which is precisely the set `ideate:10` disclaims.

**Conflict**
- Claim: No direct contradiction in triggers or defaults. The residual risk is a missing
  intermediate step that `design`'s own trigger list invites the user to skip.
  - `design/SKILL.md:6-7` (frontmatter): invites `"ok let's go with approach X, design it"` — the natural next utterance after an ideate session.
  - `ideate/SKILL.md:162-163` (Contract → Downstream Consumers): `architect (reads Handoff only)`. `ideate` does not feed `design`.
  - `design/SKILL.md:257-259` (Contract → Consumes): requires an architect Handoff and halts with `CONTRACT VIOLATION` without one. So the exact phrase `design:6-7` advertises produces a halt whenever the user goes ideate → design directly. The trigger layer and the contract layer disagree about whether `architect` is optional.

**Use together when** — the W1 Build workflow, with `architect` between them.
**Prefer one when** — the approach is not yet chosen: `ideate` only.
**Open questions** — Whether `architect` is intended as mandatory between ideate and design. `design:257` says yes; `design:6-7` implies no.

## Registry Defects

Cross-cutting defects found while auditing. These are more actionable than any single verdict.

| ID | Defect | Evidence | Fix |
|---|---|---|---|
| CA-CONT-001 | `review-depth` findings cannot enter a refactoring plan. Declared edge, refused by receiver. | `review-depth:259-260` names refactoring-plan downstream; `refactoring-plan:295-297,304,317` admits only `CR-*` and `AR-*` | Add `DM-*` to `refactoring-plan`'s Consumes and step `Finding IDs:` vocabulary |
| CA-CONT-002 | `review-depth` → `architect` edge is also unilateral. | `review-depth:261` claims `architect (reads Handoff in W3 Redesign)`; `architect:332-345` enumerates exactly three entry points — ideate, review-architecture, direct — and `review-depth` is not among them | Add a `review-depth` entry point to `architect`'s Consumes, or drop the claim from `review-depth` |
| CA-CONT-003 | Trigger layer and contract layer disagree on whether `architect` is skippable. | `design:6-7` invites direct entry from ideation; `design:257-259` halts without an architect Handoff; `ideate:163` feeds only architect | Decide, then align. Either add `ideate` as a `design` entry point or remove the ideation-transition phrasing from `design:6-7` |
| CA-DUP-001 | `refactor` contains a duplicate of `refactoring-plan`. | `refactor:108-147` (Phase 3) vs `refactoring-plan:134-167,300-319`; contradicted by `refactor:259-260` | Delete `refactor` Phase 3, or make it conditional on an absent upstream Handoff |
| CA-GAP-001 | Minimum Viable Output table is missing three of twelve skills. | `shared-principles.md:141-151` lists 9 rows: ideate, architect, design, code-review, review-architecture, refactoring-plan, scaffold, refactor, plan-tracker. No row for `review-depth`, `navigator`, or `orch` | Add three rows (see parent report) |
| CA-GAP-002 | Four skills violate the `CLAUDE.md` checkpoint invariant. | `CLAUDE.md` invariant: *"Every skill must have at least one checkpoint gate."* Zero occurrences of `**STOP.**` in `code-review/SKILL.md`, `navigator/SKILL.md`, `review-architecture/SKILL.md`, `review-depth/SKILL.md` | Resolve the read-only-gate debate, then either add gates or amend the invariant to exempt read-only diagnostics |
| CA-TRIG-001 | `code-review` disclaims no sibling skill. | `code-review:3` negatives name only paper/manuscript review and general writing feedback — both outside the repo | Add negatives naming `review-depth` and `review-architecture` |
| CA-TRIG-002 | `refactor` disclaims no review skill, so it out-claims all three on shared phrases. | `refactor:9-11` names only the design skill; collides with `review-architecture:10` and `review-depth:7` | Add `Do NOT trigger for read-only diagnosis (use review-architecture, review-depth, or code-review)` |
| CA-TRIG-003 | `design` claims the token `"architect"`. | `design:6` vs `architect:9` | Remove `"architect"` from `design:6`; add a negative naming the architect skill |
| CA-TRIG-004 | `ideate` and `navigator` both claim `"explore"` with no mutual disclaimer. | `ideate:5`, `navigator:7`; negatives at `ideate:10-11` and `navigator:7-8` name neither | Qualify to `"explore my options"` and `"explore the codebase"` respectively |

The pattern behind CA-TRIG-001 through -004: **every collision found is one-sided.** In each
case the newer or narrower skill correctly defers to the older or broader one, and the older
one never reciprocates. Negative triggers were written looking backward, never forward. The
one pair with mutual disclaimers — `design` vs `ideate` — is the only ✅ in the audit.

## Handoff

| Finding ID | Verdict | Pair | Conflict / Overlap / Complementarity | Loading decision |
|---|---|---|---|---|
| CA-TRIG-003 | ❌ Conflicting | architect vs design | 55 / 40 / 70 | Real pipeline, broken selection. Drop `"architect"` from `design:6`. |
| CA-CONT-001 | ❌ Conflicting | code-review vs review-depth | 50 / 45 / 55 | Complementary in intent; `DM-*` findings are silently dropped downstream. Fix the contract before loading both. |
| CA-DUP-001 | 🔁 Overlap | refactor vs refactoring-plan | 40 / 65 / 50 | `refactor` re-implements the planner it claims to consume. Delete one. |
| CA-TRIG-005 | 🔁 Overlap | review-architecture vs review-depth | 35 / 55 / 50 | Disjoint dimensions, identical artifact shape, one-sided disclaimer. Merge or make negatives mutual. |
| CA-TRIG-004 | ❌ Conflicting | ideate vs navigator | 45 / 20 / 60 | Unrelated jobs, shared token `"explore"`, blind pair. Qualify both triggers. |
| CA-TRIG-002 | ❌ Conflicting | refactor vs review-architecture | 50 / 30 / 65 | Verbatim shared phrase `"this grew organically"`, disclaimed one way only. |
| CA-TRIG-002 | ❌ Conflicting | refactor vs review-depth | 45 / 25 / 65 | `"clean up"` prefixes `"clean up interfaces"`. Same fix as above. |
| — | ✅ Complementary | design vs ideate | 20 / 25 / 75 | Load both. The reference pattern for the registry. |

**Not deep-dived:** 58 pairs. Six carry MEDIUM risk and are listed in the triage table above;
they have no verdict and must not be recorded as compatible.
