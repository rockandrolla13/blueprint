# Resume State — Pressure Packs

**Saved:** 2026-08-07, before reboot.
**Repo state:** no tracked file modified. `git status` = `?? docs/` and `?? orch/` only.
`orch/` was already untracked before this session started.

```
STATE:
  plan: docs/plans/2026-08-07-first-pass-prerequisites.md
  current_step: awaiting 3 user decisions (below)
  completed: [review of external repo, /ideate, /review-depth, /review-architecture,
              3-agent fan-out: scope, sequence+ingest, pack drafting]
  blocked: [gate-invariant wording — user decision]
  files_modified: []            # nothing tracked has been touched
  files_created: [docs/plans/2026-08-07-first-pass-prerequisites.md,
                  docs/pack-draft/**, docs/RESUME-STATE.md]
  tests: N/A (no code changed)
  invariants_checked: [no tracked file modified, no gate removed, no principle duplicated]
```

## What this is

Adapting rule sets from `https://github.com/rockandrolla13/agent-rules-books`
into blueprint as an on-demand "pressure pack" layer.

**Upstream pinned at:** `a7d7649044505b9c377c8dca28d2d6a543bc7f8c` (2026-05-13).
The clone lived in `/tmp` and is **gone after reboot**. Re-clone if needed:
`git clone https://github.com/rockandrolla13/agent-rules-books` then
`git checkout a7d7649`. Public repo, MIT licensed. Nothing was lost — the packs
already carry `source:` and `upstream_rev:` in their frontmatter.

## The decision (settled — do not relitigate)

**Design B.** Packs are files under `principles/` that self-declare applicability in
their own frontmatter (`applies_to`, `when`, `source`, `upstream_rev`, `conflicts_with`).
`shared-principles.md` gains a **new top-level `## Pressure Packs` section** — deliberately
*not* inside `Gate Behaviour`, because gate semantics are near-frozen while the pack rule
will churn. **Zero `SKILL.md` edits.**

Supporting rules:
- `applies_to` resolves against the **filesystem** (dirs containing `SKILL.md`), never
  against a manifest. Blueprint has 5+ mutually contradictory skill registries; do not
  create a sixth.
- The router (`principles/PACKS.md`) is **deferred**. If ever built it is **generated**
  from pack frontmatter with a `--check` mode, never hand-written.
- Packs are PRESSURE and are subordinate to `shared-principles.md`, which is POLICY.
  A declared conflict must be **surfaced** at the gate, never silently resolved.
- Staleness is accepted. No sync mechanism. Rollback = delete the file.
- Admission rule: a pack is admitted only if it changes a gate outcome blueprint's 12
  skills miss, evidenced by a named line in that book's upstream `traceability.md`.
- `when:` must be codebase-observable. Cap: at most 2 packs load per gate.

## Three decisions still open

1. **Gate invariant wording.** `CLAUDE.md` says every skill must have a checkpoint gate
   where Claude stops and asks for approval. Three read-only diagnostics cannot satisfy
   this without inventing a ritual. Either amend it to name two legitimate forms
   (approval gate for action skills; `Pre-Gate Self-Check` for diagnostics), or add
   literal `**STOP.**` to `code-review`, `review-architecture`, `review-depth`.
   **Recommendation: amend.** Blocks prerequisite Phase 4.

2. **Three packs or four.** `code-complete` scores 🔁 Overlap 78% "choose one" against
   Clean Code upstream, and blueprint's `code-review` is a Clean Code skill by
   construction. Its cut ratio (32 upstream rules → 4 retained) says blueprint already
   has nearly all of it. **Recommendation: drop it, ship three.**

3. **Run the paste test first.** It writes no files and can return "do not ship this
   design". Every other step assumes the answer. **Recommendation: yes, run it first.**

Housekeeping, just accept: the new section shifts `shared-principles.md`'s Minimum Viable
Output table from lines 141–151 to 189–199, so prerequisite Phase 4's `S13` check must
anchor on the `## Minimum Viable Output` heading, not on line numbers.

## Findings that corrected the original framing

Three agents each found the brief they were given was factually wrong somewhere. Keep these:

- **`refactor` does NOT assume tests exist.** `refactor/SKILL.md:53-81` already has a hard
  `**STOP.**` with characterization tests. Blueprint does not lack legacy-code coverage.
  WELC is still pack #1 — because that baseline makes its effect *measurable*.
- **Only 8 of 12 skills have a `## Pre-Gate Self-Check`.** Missing: `refactor`, `scaffold`,
  `plan-tracker`, `navigator` — and `refactor`/`scaffold` are the only two WRITES CODE
  skills. The load point must read "at your gate", naming both forms. Anchoring to
  `Pre-Gate Self-Check` alone would be dead at exactly the gates that produce code.
- **STOP-count is not evidence of a missing gate.** Read-only diagnostics have nothing to
  withhold. Only `navigator` is a genuine violation — it has no `## Contract (BCS-1.0)`
  block at all, the only skill of twelve without one.
- **`review-depth/SKILL.md` never reads `shared-principles.md`.** Ten of the other eleven
  do. One-line fix. Without it the pack mechanism is blind in `commands/triage.md`,
  `deep-clean.md`, `review-cycle.md`, `research-triage.md`.
- **PoEAA is cut.** The only two hard-conflict pairs in upstream's 14×14 grid are
  DDD❌PoEAA and IDDD❌PoEAA. Blueprint's `architect` is DDD-flavoured.

## Cut ratios — the finding of the whole exercise

Upstream decision+trigger rules → retained checklist items. The ordering tracks exactly
how much of each book blueprint already contains.

| Pack | Upstream | Retained | Excluded as already covered |
|---|---:|---:|---:|
| working-effectively-with-legacy-code | 23 | 7 | 8 |
| release-it | 22 | 7 | 5 |
| designing-data-intensive-applications | 27 | 5 | 5 |
| code-complete | 32 | 4 | 12 |

## Riskiest thing in the design

`when:` is the entire targeting mechanism and is the one field a lint provably cannot
check. A future pack writing `when: refactoring` loads at every `refactor` gate,
permanently occupies one of the two cap slots, and starves the pack that actually
applied. Mitigation is procedural only — the admission review rejects always-true
conditions. No mechanism fix recommended; one would be the elaborate-framework failure
`CLAUDE.md` warns about.

Second-order, no fix: **coverage moves.** Prerequisite Phase 3 adds a `CMNT` finding type
to `review-depth` that covers `code-complete` item 4 exactly. A pack admitted today can be
invalidated by a skill edit tomorrow and nothing detects it.

## Paste-test target

`/home/ak/research_worker/src/research_harness/runner/backends.py` — 86 lines, zero test
references across 22 test files, two live callers. Ambient reads, inline `subprocess.Popen`,
a module-level `BACKENDS` global, a SIGTERM→kill branch unobservable without a seam.
Selection criteria for a replacement are in `docs/pack-draft/PASTE-TEST.md` if it has moved.

Retarget noted: the paste goes into `refactor/SKILL.md:142-146` (§3.3 Review Checkpoint),
not a Pre-Gate Self-Check, since `refactor` has none.

## Where everything is

| What | Path |
|---|---|
| Prerequisite plan (544 lines, 5 phases) | `docs/plans/2026-08-07-first-pass-prerequisites.md` |
| Pack layer spec, schema, pushback | `docs/pack-draft/CONSOLIDATED-DESIGN.md` |
| Drop-in `## Pressure Packs` section | `docs/pack-draft/shared-principles.PRESSURE-PACKS-SECTION.md` |
| Four drafted packs | `docs/pack-draft/principles/*.md` |
| Paste-test protocol | `docs/pack-draft/PASTE-TEST.md` |
| Exact write-plan + 3 flagged conflicts | `docs/pack-draft/WRITE-PLAN.md` |

Nothing under `docs/` is tracked yet. `git add docs/` when you want it kept.

## Next action on resume

Answer the three open decisions, then run the paste test. Nothing else should start
before that test returns.
