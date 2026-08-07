# Registry Defect Repair

**Objective:** Repair the 10 defects found by the first compat-audit self-audit, then bring the
four hand-synced registries back into agreement with the filesystem.

**Source of findings:** `compat-audit/references/blueprint-self-audit.md`

---

## Root cause

Every trigger collision found is **one-sided**. The newer or narrower skill defers to the older
or broader one; the older never reciprocates. Negative triggers were written looking backward.
The only pair with mutual disclaimers (`design` vs `ideate`) is the only ✅ in the audit.

Contract defects share a sibling cause: a downstream edge is *declared by the sender* and
*enforced by the receiver*, so a one-sided declaration always looks fine and never runs.

**Standing rule this implies:** when a new skill lands, the negative triggers of the OLDER
skill must be updated too, and any claimed downstream edge must be checked against the
receiver's `### Consumes` before it is written.

---

## Phase 1 — Contract edges

| # | Finding | Fix | File |
|---|---|---|---|
| 1.1 | CA-CONT-001 | Admit `DM-*` and `CA-*` in Consumes + step `Finding IDs:` vocabulary | `refactoring-plan/SKILL.md` |
| 1.2 | CA-CONT-002 | Drop the unilateral `architect` downstream claim | `review-depth/SKILL.md` |
| 1.3 | CA-CONT-003 | Description invites direct ideation entry the contract refuses; route via architect | `design/SKILL.md` |
| 1.4 | (mine) | Restore the `refactoring-plan` edge now that 1.1 makes it true | `compat-audit/SKILL.md` |

**Dependency:** 1.4 depends on 1.1. Nothing else in Phase 1 is ordered.

**Success:** no skill declares a downstream consumer whose `### Consumes` would reject it.

## Phase 2 — Duplication

| # | Finding | Fix | File |
|---|---|---|---|
| 2.1 | CA-DUP-001 | Make Phase 3 conditional on an absent upstream Handoff rather than deleting it — `refactor` must still work standalone | `refactor/SKILL.md` |

**Success:** `refactor` executes a supplied plan and only builds one when none was supplied.
Its `**STOP.**` gates survive.

## Phase 3 — Trigger collisions

| # | Finding | Fix | File |
|---|---|---|---|
| 3.1 | CA-TRIG-001 | Add negatives naming `review-depth` and `review-architecture` | `code-review/SKILL.md` |
| 3.2 | CA-TRIG-003 | Remove the literal token `"architect"`; add a negative naming the architect skill | `design/SKILL.md` |
| 3.3 | CA-TRIG-004 | Qualify `"explore"` → `"explore my options"` / `"explore the codebase"` | `ideate/SKILL.md`, `navigator/SKILL.md` |

Note: CA-TRIG-002 (`refactor` disclaims no review skill) is folded into 2.1's edit of the same
frontmatter block.

**Dependency:** 3.2 touches the same frontmatter as 1.3. Apply as one edit.

**Success:** each collision is disclaimed from BOTH sides, not one.

## Phase 4 — Registry sync

| # | Fix | File |
|---|---|---|
| 4.1 | Add missing skill-map rows: `navigator`, `orch`, `review-depth`, `compat-audit`, `spec-interview` | `README.md` |
| 4.2 | Add missing Minimum Viable Output rows for the same five | `shared-principles.md` |
| 4.3 | Add the two new skills to the decision table and transitions | `WORKFLOWS.md` |
| 4.4 | Regenerate the generated index | `SKILL-INDEX.md` |

**Dependency:** Phase 4 runs after 1–3, since row text quotes descriptions those phases edit.

**Note on 4.2:** anchor on the `## Minimum Viable Output` heading, not line numbers — the
pending pressure-pack section shifts this table (recorded as conflict C2).

## Deferred — needs a user decision

| Finding | Why deferred |
|---|---|
| CA-GAP-002 — `code-review`, `navigator`, `review-architecture`, `review-depth` have zero `**STOP.**` gates | This IS open Decision 1 (gate invariant wording). Option A amends `CLAUDE.md` to recognise two legitimate gate forms; Option B bolts literal stops onto read-only diagnostics. Not a decision to make unilaterally — it edits the instruction file itself. |
| `navigator` has no `## Contract (BCS-1.0)` block | The only skill of fourteen without one. Genuine violation, but writing a contract for it is authoring work, not repair. |

---

## Invariants — check after each phase

- `no-gate-removed` — `grep -c '\*\*STOP\.\*\*'` per skill never decreases
- `no-principle-duplicated` — no principle text copied from `shared-principles.md` into a skill
- `under-500-lines` — every `SKILL.md` stays under the cap
- `contract-block-present` — no skill loses its `## Contract (BCS-1.0)` block
- `registry-check-clean` — `python3 tools/registry_check.py --check` exits 0 at the end

Verify all five with `python3 tools/registry_check.py --check`.

**If an invariant breaks: STOP.** State which and why. Do not proceed.

## Risk register

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Sharpening a trigger causes undertriggering — the skill stops firing when it should | Medium | High | Only qualify collided phrases; never delete a whole trigger. `"explore"` → `"explore my options"` keeps the intent, narrows the claim. |
| Making `refactor` Phase 3 conditional breaks standalone use | Low | High | Conditional, not deleted. Standalone path preserved explicitly. |
| Registry rows drift again on the next skill | High | Medium | `tools/registry_check.py --check` now detects it. Unresolved: it exits 0 on registry drift, so CI would not catch it — user decision pending. |
| Edits to 7 skills at once are hard to review | Medium | Medium | One concern per edit. No file rewritten wholesale. |
