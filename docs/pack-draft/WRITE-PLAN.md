# WRITE-PLAN — what lands in `/home/ak/blueprint` when approved

Nothing in this staging directory has touched the target repo. Everything below is
proposed, ordered, and stated against the tree at commit `fb34b24`.

Six files: four created, two edited. No `SKILL.md` gains or loses a gate. No
principle text moves out of `shared-principles.md`.

---

## Order relative to the prerequisites plan

`docs/plans/2026-08-07-first-pass-prerequisites.md` has Phases 0–4. This work sits
**after all of them**, with one exception that runs first because it costs nothing.

```
  Step P  — PASTE-TEST                  ← runs FIRST, writes no files, gates everything
     │
  Prereq Phase 0  (git add orch/)
  Prereq Phase 1  (SKILLS.md; collapse 6 registries)
  Prereq Phase 2  (WORKFLOWS; navigator contract; Mode dedup)
  Prereq Phase 3  (review-depth finding types)  ← fold Step 1 into this
  Prereq Phase 4  (contract_lint --skills; invariant wording)  ← GATE in that plan
     │
  Step 1  — review-depth reads shared-principles.md
  Step 2  — shared-principles.md gains ## Pressure Packs
  Step 3  — four pack files created
  Step 4  — CLAUDE.md repo-structure line  (optional)
  Step 5  — contract_lint --packs          (deferred)
```

**Why after, not before.** Three reasons, in order of weight:

1. **Prereq Phase 3 changes what the packs may claim.** It adds a `CMNT` finding
   type to `review-depth` for "a comment explaining a confusing name, flow, or
   decomposition" (`docs/plans/2026-08-07-first-pass-prerequisites.md:329`). That is
   `code-complete` checklist item 4. Landing the pack first means shipping an item
   that a planned change invalidates a week later.
2. **Prereq Phase 4 builds the lint the packs need.** `--packs` (checks P1–P10 in
   `CONSOLIDATED-DESIGN.md` § 8) belongs in the same tool as `--skills`, written by
   the same hands, not in a second script.
3. **That plan says so.** Its Out of Scope list ends: "Any pressure-pack content.
   This plan clears the runway; it does not build the aircraft" (line 544).

**Why the paste test runs first.** It writes nothing, touches no repo, and can
return "do not ship this design". Running it before Phase 0 costs one experiment
and can save all five steps.

---

## Step P — PASTE-TEST (before everything)

Per `PASTE-TEST.md`. No files created in `/home/ak/blueprint` or in
`/home/ak/research_worker`. Result recorded in the staging directory.

**Gate:** on a null result (§ 4 branch two), Steps 1–5 do not proceed and the design
is reworked around generation-time loading. Do not ship four unread files.

---

## Step 1 — `review-depth/SKILL.md` reads `shared-principles.md`

**Edit:** insert after line 28 (end of `## Purpose`), before line 30
(`## When to Run`):

```markdown

Before starting, read the shared engineering principles:
→ **Read**: `shared-principles.md` (sibling to this skill directory)
```

**Why this is a prerequisite, not a nicety.** Ten of the eleven other skills carry
this line; `review-depth` and `navigator` do not. The pack mechanism lives entirely
in `shared-principles.md`, so a skill that does not read that file cannot see it.
`review-depth` is named in `applies_to` by no pack today — but it is invoked
alongside `review-architecture` and `code-review`, both of which *do* read the
shared file, by four commands:

- `commands/triage.md:5`
- `commands/research-triage.md:3`
- `commands/review-cycle.md:4`
- `commands/deep-clean.md:14`

In those four, two of the three skills see pack pressure and one is blind. That is
worse than none seeing it.

**Placement rationale:** matches the sibling convention — after the role or purpose
statement, before the first workflow section. Compare `architect/SKILL.md:25-26`,
`refactor/SKILL.md:28-29`, `code-review/SKILL.md:10-11`.

**Recommended amendment to the prerequisites plan.** Fold this into its Phase 3 as
step **3.4**. Phase 3 already opens `review-depth/SKILL.md` and touches nothing near
line 28, so the two edits do not collide. One file, one pass, one review. If that
amendment is declined, apply it here as its own step — it is independent either way.

**Verify:** `grep -c 'shared-principles.md' review-depth/SKILL.md` returns 1.
`navigator/SKILL.md` remains at 0 and is out of scope — it is `READ-ONLY` with no
Handoff (`docs/plans/2026-08-07-first-pass-prerequisites.md:280-284`) and no pack
names it.

---

## Step 2 — `shared-principles.md` gains `## Pressure Packs`

Two edits to one file. **Apply bottom-up** so the first edit does not shift the
second's line numbers. Both positions are given against the unmodified file.

**2a — the new section.** Insert between line 135 ("Skills must not invent
additional refusal branches.") and line 137 (`## Minimum Viable Output`). Content is
the fenced block in `shared-principles.PRESSURE-PACKS-SECTION.md`, verbatim,
without the fence.

Result: new section occupies 137–183; `## Minimum Viable Output` moves to 185.

**2b — the cross-reference.** Append as a fourth bullet under `### Rules`, after
line 123:

```markdown
- Before presenting at a gate, check `## Pressure Packs` below. If a pack applies, its
  Final checklist is part of what you verify — and any conflict it declares is reported
  at the gate, never resolved silently.
```

**Not inside `Gate Behaviour`.** Gate semantics are near-frozen; the pack rule will
churn. The cross-reference is a pointer, not the rule.

**Interaction with prereq Phase 1.** None. That phase explicitly leaves
`shared-principles.md:141-151` (Minimum Viable Output) in place
(`docs/plans/2026-08-07-first-pass-prerequisites.md:224-229`) and edits no other
part of the file. After Step 2 those lines are at 189–199 — **update prereq Phase
4's check `S13`**, which reads that table by position if it was implemented against
the old numbers. Anchor `S13` on the heading, not the line range.

**Verify:** exactly one `## Pressure Packs` heading; `### Rules` has four bullets;
no principle text was moved or duplicated.

---

## Step 3 — create the four packs

```
principles/working-effectively-with-legacy-code.md
principles/release-it.md
principles/designing-data-intensive-applications.md
principles/code-complete.md
```

Copied from `pack-draft/principles/` unchanged, **except**: re-run each pack's
`## Excluded — already covered` audit against the post-Phase-3 tree before copying.
Specifically:

- **`code-complete` item 4 must be re-checked and probably cut.** Prereq Phase 3
  adds `CMNT` to `review-depth`, which covers it. If cut, `code-complete` drops to
  three items — at which point ask whether it still clears the admission rule at
  all. It does on items 1–3, but the margin is thin. See
  `CONSOLIDATED-DESIGN.md` § Pushback P3 and P4.
- Every other pack's exclusion citations point at `refactor`, `design`, `architect`,
  `code-review`, and `shared-principles.md`. Prereq Phases 0–4 touch none of those
  bodies except `shared-principles.md`, whose cited lines (24-27, 62-67, 86, 89-105,
  106, 107) all sit above the Step 2 insertion at 137 and do not move.

`principles/` is a new top-level directory. It contains no `SKILL.md`, so prereq
Phase 4's `--skills` mode, which globs `*/SKILL.md`, will not pick it up.

**One flag on `S10`.** That check is specified bidirectionally: "Directory has a row
in `SKILLS.md`, and every `SKILLS.md` row has a directory"
(`docs/plans/2026-08-07-first-pass-prerequisites.md:430`). If the first half is
implemented as *every top-level directory* rather than *every directory containing a
`SKILL.md`*, `principles/` fails `S10` on arrival — as would `commands/`, `docs/`,
`tools/`, `examples/`, and `reviews/`, which already exist. The check must be
anchored on `*/SKILL.md`, and it already is in the plan's own wording at line 412.
Confirm when implementing.

**Verify:** four files; each parses as YAML frontmatter plus body; every
`applies_to` entry resolves to an existing `<name>/SKILL.md`; no two packs share a
slug.

---

## Step 4 — `CLAUDE.md` repo-structure line (optional)

`CLAUDE.md`'s repo-structure block and its "File Roles — What Goes Where" table both
enumerate where content lives. Adding a directory without a row leaves the same
omission defect the prerequisites plan exists to fix.

Two one-line additions:

- Repo-structure block: `├── principles/                    # Pressure packs — see shared-principles.md`
- File Roles table: `| Book-derived pressure checklists | `principles/<slug>.md` | One file per book. Never duplicated into a skill. Subordinate to shared-principles.md. |`

**Must land after prereq Phase 1**, which collapses the twelve `<skill>/SKILL.md`
lines in that block to one (`docs/plans/2026-08-07-first-pass-prerequisites.md:216`).
Editing before means writing into a block that is about to be rewritten.

Marked optional because it is documentation, not mechanism. The layer works without
it. It should still be done.

---

## Step 5 — `tools/contract_lint.py --packs` (deferred)

Checks P1–P10 from `CONSOLIDATED-DESIGN.md` § 8. Same output format as `--skills`,
mutually exclusive with the positional `file` argument, non-zero exit on failure.

Deferred because prereq Phase 4 writes `--skills` and this is one more mode in the
same file. Splitting them means two people learning the same code.

**P9 is the check worth building** — it verifies that every `file:line` citation in
an `## Excluded — already covered` block points at a file that exists and a line
within it. That is the citation-rot failure mode, and it is the only automated
defence the exclusion tables have.

Explicitly **not** built: any check that a pack was applied. It is not observable —
`CONSOLIDATED-DESIGN.md` § 8.

---

## Conflicts with the prerequisites plan

Three. None blocking; all need a decision.

| # | Conflict | Resolution |
|---|---|---|
| C1 | Prereq Phase 3 adds `CMNT` to `review-depth`, which covers `code-complete` item 4 | Pack layer lands after Phase 3; re-audit and cut item 4. `CONSOLIDATED-DESIGN.md` § Pushback P4 |
| C2 | Step 2 shifts `shared-principles.md`'s Minimum Viable Output table from 141-151 to 189-199. Prereq Phase 4's `S13` reads that table | Anchor `S13` on the `## Minimum Viable Output` heading, not on line numbers. Either ordering works if it is heading-anchored; neither works if it is not |
| C3 | Step 1 edits `review-depth/SKILL.md`, the same file as prereq Phase 3 | Fold Step 1 in as Phase 3 step 3.4. Non-overlapping regions (line 28 vs lines 176+), so this is a convenience, not a necessity |

**No conflict** on: the `SKILLS.md` manifest (packs resolve against the filesystem
by design — `CONSOLIDATED-DESIGN.md` § 3, and `principles/` is not a skill); the
gate invariant amendment at prereq 4.1 (packs add no gate and remove none, and the
"at your gate" wording in Step 2 is compatible with both the amended and unamended
invariant); `orch/` tracking; the `WORKFLOWS.md` placement work.

---

## What is not in this plan

- No router file. `principles/PACKS.md` is not authored by hand, now or later.
- No `Packs applied:` Handoff field. It would require editing every named skill's
  `### Produces` contract. Refused.
- No PoEAA pack. Cut — `CONSOLIDATED-DESIGN.md` § 11.
- No sync mechanism, no `upstream_rev` update path. Staleness is accepted.
- No `WORKFLOWS.md` edit. Packs do not change any workflow's shape; they change what
  a gate verifies.
- No `README.md` edit. Its skill map is about skills; `principles/` is not a skill.

---

## Rollback

Per file. `rm principles/<slug>.md` removes one pack with no other effect — nothing
references packs by name. Removing the layer entirely is that, four times, plus
reverting the two `shared-principles.md` edits and the one `review-depth` line.

Nothing in this plan is hard to reverse, which is the main argument for shipping it
small and finding out.
