# Decision: the checkpoint-gate invariant

**Status:** open. Owner decides. Nothing here is applied.
**Date:** 2026-08-07

## The problem

`CLAUDE.md:136` says every skill must have a checkpoint gate; four of fourteen skills have
zero literal `**STOP.**` — `code-review`, `navigator`, `review-architecture`, `review-depth`.
Three are read-only diagnostics, so the standard reading is that they have no write to
withhold and the invariant is wrong. That reading is false: two of the three do write a file
to disk without asking, and the fourth skill already asks for approval in prose.

## Evidence

`grep -c '\*\*STOP\.\*\*' */SKILL.md`, 2026-08-07:

| 0 gates | 1 gate | 2 gates |
|---|---|---|
| `code-review`, `navigator`, `review-architecture`, `review-depth` | `architect`, `compat-audit`, `design`, `ideate`, `plan-tracker`, `refactoring-plan`, `scaffold`, `spec-interview` | `orch`, `refactor` |

`grep -l 'Pre-Gate Self-Check' */SKILL.md` → **10 of 14**. Missing: `navigator`, `plan-tracker`,
`refactor`, `scaffold`.

`grep -L '## Contract (BCS-1.0)' */SKILL.md` → **`navigator` only**.

### Where the briefing was wrong

**1. "~1 line in `domain.md`" is wrong — it is 2 lines.** The invariant is stated twice:

- `domain.md:32` — `| **CheckpointGate** | Invariant | Hard stop requiring user approval — every skill must have one | Never changes |`
- `domain.md:100` — `1. **Checkpoint gate**: Every skill has at least one hard stop for user approval`

Amending only line 100 leaves line 32 asserting the unamended rule, and line 32 additionally
says `Never changes`.

**2. "Read-only diagnostics have no subsequent write to withhold" is false for two of three.**

- `code-review/SKILL.md:25` — *"Print the full review to the user AND save to disk."*
- `code-review/SKILL.md:102-108` — `## File Storage & Versioning`, path `reviews/`, ending
  *"**Confirm:** Notify user of the full versioned filename after saving."* Notify **after**.
- `review-architecture/SKILL.md:229` — *"Generate the report as a Markdown file at
  `reviews/YYYY_mm_dd_architecture_review.md`"*.

Both declare `### Mode` / `READ-ONLY` in their Contract, then write a versioned file to the
repo unprompted. That is a real withheld action, and arguably already breaks domain invariant
2 (*read-only vs action*) and 4 (*no code before approval*).

`review-depth` is the genuine exception — grep for `disk|save|write|reviews/` in
`review-depth/SKILL.md` returns nothing. It only prints.

**3. `navigator` already contains an approval gate, in prose.** `navigator/SKILL.md:138-148`:

```
## Handoff

When the user asks to take action (create, edit, refactor, fix), say:

    That's an action request — exiting navigator.
    Suggested skill: [ideate / architect / refactor / etc.]
    Shall I proceed with [skill]?

Do NOT perform actions yourself.
```

That is a hard stop asking approval before an action skill runs. It withholds something real.
It fails the lint only because it lacks the literal token. Calling `navigator` "the sole
genuine violation" is backwards for gates — it is the cheapest genuine fix of the four. It
*is* the sole genuine violation for the missing Contract block, which Task 2 fixes.

---

## Option A — amend the invariant

Recognise two legitimate gate forms. Deletes no gate.

### `CLAUDE.md:136` (in `**Invariants — never violate these:**`)

Current:

```
- Every skill must have at least one checkpoint gate where Claude stops and asks for approval
```

Replace with:

```
- Every skill must have at least one checkpoint gate where Claude stops and asks for approval.
  A read-only diagnostic that writes nothing satisfies this with a `## Pre-Gate Self-Check`
  plus a `## Contract (BCS-1.0)` block instead.
```

### `CLAUDE.md:185` (in `## Testing Changes`)

Current:

```
4. **Checkpoint presence** — confirm every skill has at least one "STOP / ask the user" gate.
```

Replace with:

```
4. **Checkpoint presence** — confirm every action skill has at least one "STOP / ask the
   user" gate, and every read-only diagnostic has a `## Pre-Gate Self-Check`.
```

### `domain.md:32` (Concepts table)

Current:

```
| **CheckpointGate** | Invariant | Hard stop requiring user approval — every skill must have one | Never changes |
```

Replace with:

```
| **CheckpointGate** | Invariant | Hard stop requiring user approval — every action skill must have one; read-only diagnostics use a Pre-Gate Self-Check | Never changes |
```

### `domain.md:100` (Invariants list)

Current:

```
1. **Checkpoint gate**: Every skill has at least one hard stop for user approval
```

Replace with:

```
1. **Checkpoint gate**: Every action skill has at least one hard stop for user approval; every read-only diagnostic has a Pre-Gate Self-Check
```

**Cost:** 4 lines across 2 files, plus the `registry_check.py` change below.
**Leaves open:** `navigator` has neither a `**STOP.**` nor a `## Pre-Gate Self-Check`, so
Option A does *not* clear it. It would still need one or the other added.

**Honest objection to A:** it legalises the unapproved `reviews/` disk write in `code-review`
and `review-architecture` by declaring them exempt. It fixes the lint, not the behaviour.

---

## Option B — add a literal `**STOP.**` to the three diagnostics

Three insertions, each immediately after the existing Pre-Gate Self-Check block and before the
next `##` heading.

### `code-review/SKILL.md` — insert after line 88

Surrounding text (lines 87-89):

```
If any check fails, fix the output before saving.

## Constraints
```

Insert between:

```
**STOP.** Present the review. Ask: *"Save this to `reviews/`?"*
Do not write the file until the user approves.
```

Gates on: the versioned write described at `code-review/SKILL.md:102-108`.

### `review-architecture/SKILL.md` — insert after line 306

Surrounding text (lines 305-310):

```
If any check fails, fix the output before saving.

## Quick Constraint Checks
```

Insert between:

```
**STOP.** Present the scorecard and findings. Ask:
*"Save this to `reviews/YYYY_mm_dd_architecture_review.md`?"*
Do not write the file until the user approves.
```

Gates on: the write at `review-architecture/SKILL.md:229`.

### `review-depth/SKILL.md` — insert after line 233

Surrounding text (lines 232-234):

```
5. [ ] `## Handoff` section exists with all MUST fields

## Contract (BCS-1.0)
```

Insert between:

```
**STOP.** Present the scorecard and findings. Ask:
*"Proceed to refactoring-plan with these findings, or revise scope?"*
```

Gates on: nothing this skill does. `review-depth` writes no file. This one is the empty ritual.

**The strongest case for B, stated fairly:** the invariant is worth more as an unconditional
rule than as an accurate one. An unconditional rule is checkable by `grep` with no
classification step, cannot be gamed by relabelling a skill "read-only", and needs no
maintenance when a diagnostic later grows a write — which is exactly what happened to
`code-review` and `review-architecture` already. Option A's exemption is precisely the clause
that would have let those two writes in without review. Two of the three insertions above
gate a real filesystem write, so B is only ritual in one of three cases, and the ritual case
is one line. B also requires zero edits to `CLAUDE.md`, `domain.md`, or `registry_check.py` —
it is the only option with no instruction-file amendment at all.

**Cost:** `review-depth` gains a gate that gates nothing. Any future checklist-shaped layer
inherits that ritual at every diagnostic.

---

## Option C — gate on the real withheld action (recommended)

The `compat-audit` pattern. `compat-audit/SKILL.md:120-122`:

```
**STOP.** Present the triage table and the proposed deep-dive set. Ask:
*"Deep-dive these N pairs, or a different selection? And do you want the report written to disk?"*
Do NOT begin pairwise scoring or write any file until the user approves.
```

Two things are withheld: the expensive analysis, and the disk write. Both are real.

**Does it generalise? Two of three cleanly, one partially.**

| Skill | Disk-write moment | Scope moment | Verdict |
|---|---|---|---|
| `code-review` | Yes — `:25`, `:102-108` | Weak. User normally names the files. | **Generalises.** Gate the write. |
| `review-architecture` | Yes — `:229` | Real. Step 1 Ingest → Step 2 seven dimensions (`:29-46`, `:47-227`) is the expensive boundary. | **Generalises fully — both halves.** |
| `review-depth` | No — writes nothing | Real. Phase 1 Module Census (`:37`) → Phases 2-3 deep audit is the expensive boundary. | **Partial.** Scope only. |
| `navigator` | No | No | Already gated in prose at `:138-148`. |

Option C differs from Option B only in the `review-depth` insertion, and in that it justifies
the other two as genuine rather than ceremonial. For `review-depth` the honest gate is a
scope gate, placed after Phase 1, not after the Pre-Gate Self-Check:

### `review-depth/SKILL.md` — insert at the end of Phase 1, before `## Phase 2` (line 92)

```
**STOP.** Present the module census — every module with its depth ratio and shallow-pattern
flags. Ask: *"Audit all flagged modules, or a subset?"*
Do not begin Phase 2 until the user names the set.
```

This is real on any codebase with more than a handful of modules; on a small one it is a
one-line confirmation, which is what every other gate degrades to as well.

For `navigator`, Option C means promoting the existing prose to the literal token — a
one-word edit at `navigator/SKILL.md:140`, gating the same thing it already gates.

**Under Option C no instruction file changes at all**, and all four skills end up with a gate
that withholds something a user would actually want to approve.

---

## Recommendation

**Option C.** The premise behind Option A — that read-only diagnostics have nothing to
withhold — does not survive reading the files: `code-review` and `review-architecture` write
versioned files into `reviews/` and only tell the user afterwards, which is the exact
unapproved side effect the invariant exists to prevent, and amending the invariant would
bless it permanently. `review-depth` has no write but does have a genuine cost boundary after
its module census, and `navigator` already asks for approval in prose and needs the literal
token, not an exemption. That is four real gates and zero edits to `CLAUDE.md` or `domain.md`,
against Option A's four amended lines that leave `navigator` still failing and two unapproved
writes now legal.

If the writes turn out to be wanted-by-default and the owner does not want to be asked every
time, Option A is the correct fallback — but then `code-review:25` and
`review-architecture:229` should be reworded to say the write is unconditional, so the
`READ-ONLY` Mode declarations stop being false.

---

## Blast radius

`grep -n 'checkpoint gate\|Pre-Gate\|STOP'` across `*.md` and `tools/`:

**Normative — must change under Option A, unchanged under B and C:**

- `CLAUDE.md:136` — the invariant.
- `CLAUDE.md:185` — the manual test step.
- `domain.md:32` — Concepts table, marked `Never changes`.
- `domain.md:100` — Invariants list.

**Consistent under any option, no edit needed:**

- `CLAUDE.md:74`, `:128`, `:142`, `:172` — describe gates generally, do not assert universality.
- `shared-principles.md:111` — *"Every skill **with a checkpoint gate** follows this
  protocol"*. Already conditional. Correct under all three options.
- `shared-principles.md:116-117`, `:139` — reference the Pre-Gate Self-Check as the
  contract-check mechanism. Unaffected.

**Generated / stale, refreshes itself:**

- `SKILL-INDEX.md:143-147` — lists the four violations verbatim from `registry_check.py`
  output. Regenerates once the tool changes. Do not hand-edit.
- `docs/plans/2026-08-07-registry-defect-repair.md:80` — records this as open Decision 1.
  Its invariant `no-gate-removed` (`:87`) holds under all three options.
- `docs/pack-draft/PASTE-TEST.md:79` and
  `docs/pack-draft/shared-principles.PRESSURE-PACKS-SECTION.md:105` both say *"Only 8 of the
  12 skills have [a Pre-Gate Self-Check]"*. Now 10 of 14. Stale, unrelated to this decision,
  worth correcting separately.
- `docs/pack-draft/shared-principles.PRESSURE-PACKS-SECTION.md:64-67` defines "at your gate"
  as *"the `## Pre-Gate Self-Check` where a skill has one, otherwise the `**STOP.**`"* —
  already names both forms, so the pack work is compatible with every option here.

**Tool — report only, a sibling agent owns this file right now.**

`tools/registry_check.py:212-214`:

```python
        if not s.has_stop:
            extra = " (has Pre-Gate Self-Check but no explicit stop)" if s.has_pregate else ""
            v.append((s.dirname, f"no checkpoint gate — literal `**STOP.**` absent{extra}"))
```

- **Under Option B or C:** no change. All four skills gain the literal token and the check
  passes as written. This is a further argument for C.
- **Under Option A only:** the check must stop firing when a gateless skill has a Pre-Gate.
  Replace the three lines with:

  ```python
        if not s.has_stop and not s.has_pregate:
            v.append((s.dirname, "no checkpoint gate — neither `**STOP.**` nor `## Pre-Gate Self-Check`"))
  ```

  `has_stop` (`:155`) and `has_pregate` (`:156`) are both already parsed, so no new parsing
  is needed. Under this change `navigator` remains the sole violation, as intended.

---

## What `navigator` needs under each option

Task 2 of this work added `navigator`'s missing `## Contract (BCS-1.0)` block. Gates are still
open:

- **Option A** — `navigator` has no `## Pre-Gate Self-Check` either, so it still fails. It
  needs one added, or an explicit third clause for interactive skills.
- **Option B** — needs a `**STOP.**` somewhere. The only defensible spot is the existing
  `## Handoff` section at `:138`.
- **Option C** — promote `navigator/SKILL.md:140` from prose to the literal token. Smallest
  change of the three, gating an action it already refuses to take unasked.
