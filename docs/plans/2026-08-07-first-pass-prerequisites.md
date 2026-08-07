# First Pass: Pressure-Pack Prerequisites

## Objective

Fix the four defects that block the pressure-pack layer — unregistered skills, a fragmented
skill inventory, an untested checkpoint-gate invariant, and `review-depth`'s incomplete APOSD
finding vocabulary — so that adding a new rule pack is a single-edit operation that a lint can verify.

## Scope

Four findings: AR-EXT-001, AR-DRY-002, AR-TST-004, DM-LEAK-003. Nothing else. No pressure-pack
content is authored in this pass.

---

## Verification of the Four Findings

Each was checked against the working tree before planning. Results, including where the original
diagnosis was wrong or understated.

### AR-EXT-001 — CONFIRMED, with one correction

`grep` for `review-depth`, `navigator`, `orch` across `README.md`, `WORKFLOWS.md`, `domain.md`,
`CLAUDE.md`:

| Skill | README | WORKFLOWS | domain | CLAUDE |
|---|---|---|---|---|
| review-depth | 0 | 0 | 0 | 0 |
| navigator | 0 | 0 | 0 | 0 |
| orch | 0 | 1* | 1* | 0 |

\* Both `orch` hits are false positives: `WORKFLOWS.md:376` is a shell loop over unrelated repo
names (`for repo in orch dynamic-melo credit-analytics`), `domain.md:5` is the substring in
"orchestration". Neither registers the skill.

`git status` confirms `?? orch/` — untracked.

**Correction to the finding as stated.** "Registered in ZERO root documents" is false for
`review-depth`. `blueprint-usage-guide.md` is a tracked root document and mentions `review-depth`
19 times, including a row in its own `## Skill Inventory` table at line 476. The finding is
accurate for the four documents it names, and accurate in full for `navigator` and `orch`. The
overstatement matters because it means the fix must reconcile `blueprint-usage-guide.md` too — it
is a registry the finding did not count.

### AR-DRY-002 — CONFIRMED, and understated

The finding names five copies. There are at least ten, and they disagree three ways:

| # | Location | Skills listed | Notes |
|---|---|---|---|
| 1 | `README.md:34-44` Skills table | 9 | |
| 2 | `README.md:52-73` installation tree | 9 | second copy in the same file |
| 3 | `CLAUDE.md` repo-structure block | 9 | |
| 4 | `domain.md:77-83` Skill Taxonomy (By Function) | 9 | |
| 5 | `domain.md:87-94` By Workflow block | 9 | second copy in the same file |
| 6 | `shared-principles.md:141-151` Minimum Viable Output | 9 | |
| 7 | `blueprint-usage-guide.md:466-478` Skill Inventory | **10** | only copy containing `review-depth` |
| 8 | `tools/contract_lint.py` `CONTRACTS` | **6** | |
| 9 | `tools/contract_lint.py` `SKILL_SIGNATURES` | **6** | must stay in sync with #8 by hand |
| 10 | `setup.sh:11` `mkdir -p` list | **8** | stale bootstrap script |
| — | filesystem | **12** | ground truth |

`install_skills.sh` also enumerates skills but a *different* 17-skill set (`artifact-tracker`,
`paper-scout`, …) that is not blueprint's. It is out of scope and must be excluded from any
consistency check.

Copy #7 is the useful one: it already carries a `Mode` column using the same vocabulary as the
`### Mode` field in each skill's BCS-1.0 contract. It is the closest thing to a manifest that exists.

### AR-TST-004 — CONFIRMED as a gap, DISPUTED as a diagnosis

`grep -c STOP` returns 0 in `code-review`, `navigator`, `review-architecture`, `review-depth`.
`contract_lint.py` reads one output artifact and never opens a `SKILL.md`. Both true.

**Pushback.** `STOP` count is not evidence of a missing gate. Three of the four —
`code-review:77`, `review-architecture:297`, `review-depth:225` — have a `## Pre-Gate Self-Check`
section and declare `### Mode: READ-ONLY`. A read-only diagnostic that emits a report has no
subsequent write to withhold, so there is nothing for an approval gate to gate. `CLAUDE.md` itself
says skills are *either* read-only diagnostics *or* action skills. Bolting a literal "STOP, may I
proceed?" onto a diagnostic would be ritual, and the pressure-pack layer would inherit the ritual.

Only **`navigator` is a genuine violation**, and it is worse than the finding says: it has no
`## Contract (BCS-1.0)` block at all — zero of `### Mode`, `### Consumes`, `### Produces`,
`### Downstream Consumers`. It is the only skill of the twelve missing the contract.

Two further gate-adjacent defects surfaced that the finding did not name:

- `ideate/SKILL.md` has **3** `### Mode` headings; `plan-tracker/SKILL.md` has **4**. Only one
  belongs to the contract block. Any parser reading `### Mode` gets a wrong answer on both.
- `orch/SKILL.md:268` contains the literal string `**STOP.**` inside prose *about refusing gated
  skills*. A naive `STOP` grep would score `orch` as gated for the wrong reason.

### DM-LEAK-003 — CONFIRMED, with two corrections

`review-depth/SKILL.md:176-186` defines exactly 7 types (SHAL, LEAK, FLAT, COGN, INIT, PASS, SIGN).
Confirmed.

**Correction 1.** The upstream `a-philosophy-of-software-design.mini.md` has **13** decision rules,
not 12 (`grep -c '^- '` between `## Decision rules` and `## Trigger rules` = 13).

**Correction 2.** "Temporal coupling — prepare/process/finalize staging" is cited as a decision
rule. It is not. `prepare/process/finalize` appears in the **Trigger rules** section. The decision
rules mention temporal coupling only in passing (rule 1) and "fragile staging, setup sequences"
(rule 4). The gap is real; the citation is loose.

Coverage audit of all 13 decision rules against the existing 7 types:

| # | Decision rule | Covered by | Verdict |
|---|---|---|---|
| 1 | Reduced complexity as primary metric | COGN | partial — meta-rule |
| 2 | Design as continuous work; compare alternatives | — | **process rule, no finding form. Correctly excluded.** |
| 3 | Prefer deep modules; reject pass-throughs | SHAL, PASS | covered |
| 4 | Interfaces around caller need; avoid staging/flags | LEAK (params only) | **gap: staging, ordering** |
| 5 | Hide volatile decisions, representations, formats | LEAK | covered |
| 6 | Pull complexity downward | — | **gap** |
| 7 | Generality at right level; special-general decomposition | — | **gap** |
| 8 | Combine/split by total complexity, not size | FLAT, SHAL | partial |
| 9 | Reduce exception surface; define away invalid states | — | **gap** |
| 10 | Comments reduce complexity; don't compensate | SIGN (absence only) | **gap: compensating comments** |
| 11 | Names reveal abstraction, not mechanism | SIGN (presence only) | **gap: name quality** |
| 12 | Tests via public contracts; don't let tests force leaky interfaces | — | **gap (not in the finding)** |
| 13 | Optimizations/patterns only when they reduce complexity | — | **gap (not in the finding)** |

Six gaps as claimed, plus two the finding missed (12, 13). Handled in Phase 3.

---

## Phases

### Phase 0 — Track `orch/`

**Finding:** AR-EXT-001 (part).
**Scope:** trivial. One git command.

`orch/SKILL.md` is untracked. Everything downstream — manifest rows, lint runs, CI — assumes the
file is in the repo. This must land first or every later phase references a file that does not
exist for anyone but this machine.

- `git add orch/`

**Files touched:** none edited; `orch/SKILL.md` (21 KB, 413 lines) enters the index.

**Success criteria:**
- `git status` reports a clean tree with no `??` entries.
- `git ls-files orch/SKILL.md` returns the path.

---

### Phase 1 — Single source of truth for the skill inventory

**Finding:** AR-DRY-002.
**Scope:** large — one new file, six documents edited, no logic.

#### Options evaluated

**(a) Generate the registries from filesystem + frontmatter via a script in `tools/`.**

Rejected. Three reasons, in order of weight:

1. *It does not work on today's inputs.* Frontmatter carries only `name` and `description`. Every
   other column the registries need — Mode, Output, Feeds Into, Minimum Output — lives in the
   `## Contract (BCS-1.0)` prose body. Parsing that body is unsafe: `ideate` has 3 `### Mode`
   headings and `plan-tracker` has 4, so a generator would emit wrong Modes for two of twelve
   skills today. Making (a) viable first requires regularizing 12 skill files — which is more
   work than option (b) in total, before the generator is written.
2. *It adds a build step to a repo that is pure Markdown.* Generated Markdown means a
   "did you re-run the generator?" failure mode, a stale-artifact class of bug the repo has never
   had, and a `tools/` dependency for anyone editing docs.
3. *`CLAUDE.md` forbids overengineering.* "Simple instruction beats elaborate framework."

**(b) One hand-written manifest that the other documents reference rather than restate.**

Sound but incomplete on its own. It removes the *divergence* problem — six copies collapse to one
— but not the *omission* problem: nothing forces a newly-created `newskill/` directory to acquire
a manifest row. That is exactly how the current three orphans happened.

**(c) RECOMMENDED — (b) plus a verification check, not a generator.**

Hand-written `SKILLS.md` manifest is the single source of truth. Other documents delete their
tables and link to it. Then `contract_lint.py` gains **one** check (built anyway in Phase 4):
every `*/SKILL.md` on disk has a manifest row, and every manifest row has a directory.

This is strictly better than (a) or (b) alone:

- Verification, not generation. No generated files, no build step, no staleness class. `SKILLS.md`
  stays hand-edited like every other document in the repo.
- The drift the finding describes is a *divergence* problem, and a manifest solves divergence by
  construction. The residual *omission* problem is exactly what a lint is good at.
- It reuses the tool AR-TST-004 already forces us to write. Marginal cost of this option over (b)
  is one function.
- It mirrors how `shared-principles.md` already works: one source, referenced by directive from
  each consumer. The repo's existing idiom, not a new mechanism.

#### Work

**1.1 Create `SKILLS.md`** (new root document). One table, one row per skill directory, 12 rows.
Columns, chosen because they are the union of what the six existing copies carry:

| Skill | Mode | Trigger | Produces | Feeds Into | Minimum Output |

`Mode` uses the existing vocabulary already present in the contract blocks: `READ-ONLY`,
`READ-ONLY until approved at gate`, `WRITES CODE (after <gate>)`, `CROSS-CUTTING`.
`navigator` and the two duplicate-`### Mode` skills are resolved here; Phase 2 propagates the
resolution back into the skill files.

The three orphans get rows in this step. AR-EXT-001 is *mostly discharged as a side effect* —
see the ordering argument below.

**1.2 Replace the six duplicate registries with references.** Each edit deletes a table and
substitutes a one-line pointer. Nothing else in these files changes.

| File | Lines | Action |
|---|---|---|
| `README.md` | 34-44 | Delete Skills table → `**Skill inventory:** [`SKILLS.md`](SKILLS.md)`. Keep the ASCII workflow diagram at 8-30 — it is a picture of chaining, not a registry. |
| `README.md` | 52-73 | Delete the per-skill tree from the install block. Replace with `~/.claude/skills/` + `shared-principles.md` + "one directory per row in SKILLS.md". |
| `CLAUDE.md` | repo-structure block | Collapse the twelve `<skill>/SKILL.md` lines to a single `<skill>/SKILL.md   # one per row in SKILLS.md`. Keep the root-document lines. |
| `domain.md` | 77-83 | Delete the By-Function taxonomy table → pointer. The Mode column it carries is now in `SKILLS.md`. |
| `domain.md` | 87-94 | **Keep.** This is a workflow-chain diagram (W1–W6), not an inventory. It happens to name skills; that is its subject. Out of scope. |
| `blueprint-usage-guide.md` | 466-478 | Delete the Blueprint block of the Skill Inventory table → pointer. **Keep** the Research / Reasoning / Utility blocks — those are external skills with no directory here, so `SKILLS.md` must not claim them. |
| `shared-principles.md` | 141-151 | **Keep in place.** See note below. |
| `tools/contract_lint.py` | 8-52 | See note below. |
| `setup.sh` | 11 | **Out of scope.** One-shot bootstrap that already ran; it does not describe the current repo and is not read by anything. Flag, do not touch. |

**Note on `shared-principles.md:141-151` (Minimum Viable Output).** Do not move it. It is
per-skill contract data, and moving it into `SKILLS.md` would either duplicate the column or strip
`shared-principles.md` of content that `CLAUDE.md`'s file-role table assigns to it. Instead:
`SKILLS.md` carries a `Minimum Output` column that is the authoritative short form, and Phase 4's
lint asserts the two row sets are identical. Divergence becomes a lint failure rather than a
silent drift. This is the minimum change that fixes the defect.

**Note on `contract_lint.py:8-52`.** The `CONTRACTS` dict is not a registry of skills — it is a
registry of *output contracts*, and only 6 of 12 skills produce a lintable output artifact today.
Do not expand it to 12 in this phase. Phase 4 adds a check that every `CONTRACTS` key is a
`SKILLS.md` row (catching typos and deletions) without requiring the reverse. `SKILL_SIGNATURES`
keeps its 6 keys; Phase 4 asserts `set(SKILL_SIGNATURES) == set(CONTRACTS)`, which is the actual
invariant those two dicts have been silently relying on.

**Files touched:** `SKILLS.md` (new), `README.md`, `CLAUDE.md`, `domain.md`,
`blueprint-usage-guide.md`.

**Success criteria:**
- `SKILLS.md` has exactly 12 rows, one per `*/SKILL.md` on disk.
- `grep -c "| \*\*ideate\*\*" README.md domain.md` → 0 in both; the string appears only in `SKILLS.md`.
- Every document that previously carried a table now carries a link to `SKILLS.md`.
- No principle text moved out of `shared-principles.md` (invariant: principles are never duplicated
  into or migrated out of the shared file).
- No `SKILL.md` modified in this phase.

---

### Phase 2 — Register the three orphans (residue) and fix `navigator`

**Finding:** AR-EXT-001 (remainder).
**Scope:** small-to-medium. One prose section, one contract block.

Phase 1 gives `review-depth`, `navigator`, and `orch` manifest rows. What it does **not** give
them is a place in the workflow narrative, and it does not fix `navigator`'s missing contract.

**2.1 `WORKFLOWS.md` placement.** `WORKFLOWS.md` is prose choreography, not a registry, so it
cannot be collapsed into `SKILLS.md`. Each orphan needs an editorial decision about where it sits:

- `review-depth` — a third diagnostic alongside `review-architecture` and `code-review`. Add to
  the W0 Triage and W2 Refactor step lists, and to the `## Workflow Decision Cheat Sheet`
  (line 388). `blueprint-usage-guide.md` already documents this chaining and can be used as the
  source for the wording — do not invent new sequencing.
- `navigator` — not part of W1–W6. It is an exploration mode. Add one row to the cheat sheet
  under a "not a workflow" note; do not force it into a numbered workflow.
- `orch` — an execution *substitute* for `scaffold`/`refactor` when work fans out. Add to
  `## Multi-Repo Workflow` (line 370) and one cheat-sheet row. Its own contract says
  `READ-ONLY until approved at gate`, so it slots after a plan gate, never before.

Update the decision tree at line 3 and the transitions table at line 402 per `CLAUDE.md`'s
WORKFLOWS rule ("Update the decision tree… cheat sheet… transitions table").

**2.2 `navigator/SKILL.md` — add a `## Contract (BCS-1.0)` block.** It is the only skill without
one. Append at end of file (currently 145 lines; +30 keeps it far under 500):

```
### Mode           READ-ONLY
### Consumes       Freeform user question about a codebase; no upstream Handoff
### Produces       Free-form answers; no `## Handoff` artifact — this skill emits
                   nothing downstream. Declared explicitly so the lint can pass it
                   rather than treating silence as an omission.
### Downstream Consumers   None (hands off to a named skill by prompting the user)
```

The existing `## Handoff` section at the file's end already asks *"Shall I proceed with [skill]?"*
— that is a hand-off prompt, not a self-check. Add a `## Pre-Gate Self-Check` per the Phase 4
read-only form (see 4.2).

**2.3 Fix the duplicate `### Mode` headings.** `ideate/SKILL.md` (3) and `plan-tracker/SKILL.md`
(4) — rename the non-contract occurrences so that exactly one `### Mode` per file lives under
`## Contract (BCS-1.0)`. In `ideate` the extras are Mode A / Mode B of the reasoning process:
rename to `### Mode A — Open exploration` / `### Mode B — Stress-test`, matching how
`WORKFLOWS.md:319-320` already refers to them. Renaming a heading changes no phase numbering and
removes no gate.

**Files touched:** `WORKFLOWS.md`, `navigator/SKILL.md`, `ideate/SKILL.md`,
`plan-tracker/SKILL.md`.

**Success criteria:**
- `grep -c review-depth WORKFLOWS.md` > 0; same for `navigator`, `orch` — and each hit is a real
  registration, not a substring (verify by eye; `orch` in particular).
- All 12 skills have `grep -c '^## Contract (BCS-1.0)'` == 1.
- All 12 skills have `grep -c '^### Mode'` == 1.
- No `SKILL.md` exceeds 500 lines (`orch` is the longest at 413; it is not edited here).
- No checkpoint gate removed from any file. Verify with `git diff` — no deletion of a line
  containing `**STOP.**` or `## Pre-Gate Self-Check`.

---

### Phase 3 — Extend `review-depth`'s finding vocabulary

**Finding:** DM-LEAK-003.
**Scope:** medium. One skill file, three sections.

**Independent of Phases 1–2.** It touches one file none of them touch. It is placed third only
so Phase 4's lint runs against the finished state.

**3.1 Add six finding types to §4.1** (`review-depth/SKILL.md:176-186`). Existing seven unchanged.
Four letters each, matching the existing convention. ID format `DM-<TYPE>-<NNN>` is unchanged.

| New code | Name | APOSD decision rule covered | Detection cue |
|---|---|---|---|
| `DEFN` | Avoidable exception surface | **9** — "Reduce exception surface by changing interfaces or invariants… Define away invalid states" | Two or more call sites repeating the same defensive check; a constructor that permits an invalid state a caller must then guard against |
| `TEMP` | Temporal coupling | **4** (+ rule 1, "temporal coupling") — "avoid fragile staging, setup sequences" | Required call ordering not enforced by types; `prepare`/`process`/`finalize` staging; objects with a valid-only-after-`init` phase |
| `UPWD` | Complexity pushed upward | **6** — "Pull complexity downward when the lower module owns the detail" | Mode flags, config knobs, or the same reasoning repeated at 2+ call sites that the owning module could absorb |
| `SPEC` | Special-general conflation | **7** — "isolate special behavior with special-general decomposition" | Rare-case branches on the common path; one-caller overfitting; speculative abstraction with no second caller |
| `CMNT` | Compensating comment | **10** — "Do not narrate code or compensate for bad names, poor decomposition, or confusing flow" | A comment explaining a confusing name, flow, or decomposition rather than documenting a contract or rationale |
| `NAME` | Mechanism-revealing name | **11** — "Names should reveal abstractions rather than mechanisms" | Names describing *how* (`process_list_v2`, `do_work`, `handle`) rather than *what*; inconsistent conventions across sibling operations |

`CMNT` and `NAME` are deliberately distinct from the existing `SIGN`. `SIGN` fires on a signpost
being **absent** (no docstring, no `__all__`, no type hint). `CMNT` fires on a comment being
**present and compensating**; `NAME` on a name being **present and wrong**. Three different fixes,
so three codes. State this distinction in §4.1 so reviewers do not collapse them.

**Deliberately NOT added.** Rules 12 and 13 are real gaps but out of scope for this pass:

- Rule 12 (tests forcing leaky interfaces) overlaps `code-review`'s remit. Adding it here would
  make two skills able to raise the same finding under different ID schemes — the trigger-overlap
  anti-pattern `CLAUDE.md` warns about.
- Rule 13 (optimizations/patterns only when they reduce complexity) is a project-policy judgement,
  not a depth measurement. It does not belong to a skill that scores interface-to-implementation
  ratios.

Rule 2 (design as continuous work) has no finding form at all — it is a process instruction.
Correctly excluded, as the finding already assumed.

**3.2 Update the contract's Degrees of Freedom.** `review-depth/SKILL.md`, `### Degrees of
Freedom`, the line reading *"Finding types use exact vocabulary: SHAL, LEAK, FLAT, COGN, INIT,
PASS, SIGN"* → append the six new codes. This is the only contract-visible change; downstream
consumers (`refactoring-plan`, `architect`) read finding IDs by regex `DM-*-NNN` and are unaffected.

**3.3 Extend §5.2 fix directions.** The current list is closed ("Fix direction — one of:" with 5
entries) and has no landing spot for the new codes. Add three: *"Define away the invalid state"*
(`DEFN`), *"Pull complexity downward"* (`UPWD`, `TEMP`), *"Rename to the abstraction"*
(`NAME`, `CMNT`). `SPEC` maps to the existing "Split god module".

**Do NOT add scorecard dimensions.** §5.1 has 5 rows; the contract says `(5 rows)` and the
Pre-Gate Self-Check says "Scorecard covers all 5 dimensions". Changing the row count is a
contract change that ripples to `refactoring-plan`. The new codes map onto existing dimensions:
`DEFN`/`TEMP`/`UPWD`/`SPEC` → Module Depth and Cognitive Load; `CMNT`/`NAME` → Signposting. Add a
one-line mapping note under §5.1 instead.

**Files touched:** `review-depth/SKILL.md` only.

**Success criteria:**
- §4.1 lists 13 types; the original 7 are byte-identical.
- `### Degrees of Freedom` vocabulary line lists all 13.
- Scorecard still 5 rows; contract still says `(5 rows)`; Pre-Gate Self-Check unchanged on that point.
- File length under 500 (currently 261; expected ≈ 290).
- The skill's Pre-Gate Self-Check still present — no gate removed.

---

### Phase 4 — Skill-file lint mode in `contract_lint.py`

**Finding:** AR-TST-004.
**Scope:** medium-large. One Python file, one invariant-text decision.

**Runs last** because its checks assert the end state produced by Phases 0–3. Running it earlier
guarantees failures that are not defects.

**4.1 Decide the invariant's wording — GATE, user decision required.**

The invariant in `CLAUDE.md` ("Every skill must have at least one checkpoint gate where Claude
stops and asks for approval") and `domain.md:100` ("Every skill has at least one hard stop for
user approval") cannot be satisfied by a read-only diagnostic without inventing a ritual.
`code-review`, `review-architecture`, and `review-depth` all declare `Mode: READ-ONLY`, all have a
`## Pre-Gate Self-Check`, and none has anything to withhold. Recommend amending both statements to
name the two legitimate forms:

> Every skill must have a verification gate. Action skills (Mode `WRITES CODE` or `READ-ONLY until
> approved at gate`) must have an approval gate: a `**STOP.**` where Claude presents output and
> waits. Read-only diagnostics must have a `## Pre-Gate Self-Check` and must present their output
> before saving. No skill proceeds past its gate unverified.

This **does not remove a gate** — no `**STOP.**` and no `Pre-Gate Self-Check` is deleted from any
file. It names what already exists in nine of twelve skills. But it edits a stated invariant, so
per `CLAUDE.md` it stops here for approval before Phase 4 proceeds.

If the user rejects the amendment, the alternative is to add a literal approval `**STOP.**` to
`code-review`, `review-architecture`, and `review-depth`. That is a larger and, in this plan's
view, worse change — but it is the user's call, not this plan's.

**4.2 Add `--skills` mode to `tools/contract_lint.py`.** New invocation:

```
python tools/contract_lint.py --skills [--root .]
```

Reads `<root>/*/SKILL.md` — the *skill files* — instead of an output artifact. Existing
single-file output-lint behaviour is untouched; `--skills` is mutually exclusive with the
positional `file` argument. Exit non-zero if any check fails. Report per-skill, one line per check,
in the existing `[PASS]`/`[FAIL]` format so output is consistent with the current tool.

Exact check list:

| ID | Check | Rationale / catches |
|---|---|---|
| S1 | Frontmatter is `---`-delimited and parses; has `name:` and `description:` | Malformed skill won't load |
| S2 | `name:` value == directory name | Rename drift |
| S3 | `description` contains a negative trigger (case-insensitive `do not trigger` / `do NOT trigger`) | `CLAUDE.md`: skills need positive AND negative triggers |
| S4 | Exactly one `## Contract (BCS-1.0)` heading | Catches `navigator` today |
| S5 | Exactly one `### Mode` heading, and it is inside the contract block | Catches `ideate` (3) and `plan-tracker` (4) |
| S6 | `### Mode` value matches the Mode vocabulary and equals the skill's `SKILLS.md` row | Manifest/skill divergence |
| S7 | Contract block contains `### Consumes`, `### Produces`, `### Downstream Consumers` | Structural completeness |
| S8 | **Gate present.** If Mode is an action mode: at least one `**STOP.**` **outside fenced code blocks and outside blockquotes**. If Mode is `READ-ONLY`: a `## Pre-Gate Self-Check` heading. | The invariant. Fence-stripping is mandatory — `orch/SKILL.md:268` contains `**STOP.**` inside prose *about* gated skills and would otherwise pass for the wrong reason |
| S9 | File is under 500 lines | `CLAUDE.md` fat-SKILL.md rule |
| S10 | Directory has a row in `SKILLS.md`, and every `SKILLS.md` row has a directory | AR-EXT-001 recurrence; the omission half of AR-DRY-002 |
| S11 | `SKILL.md` is git-tracked (`git ls-files --error-unmatch`) | Catches the `?? orch/` class of defect |
| S12 | `set(SKILL_SIGNATURES) == set(CONTRACTS)`, and every `CONTRACTS` key is a `SKILLS.md` row | The unstated invariant those two dicts already rely on |
| S13 | `shared-principles.md` Minimum Viable Output row set == `SKILLS.md` row set | Keeps the retained copy honest (see Phase 1 note) |
| S14 | `## Phase N` headings are ascending with no gaps; each `### N.M` sub-heading's `N` matches its parent Phase | `CLAUDE.md`: "maintain section numbering consistency" — currently unenforced |

S8's fence-and-blockquote stripping is the single most important implementation detail. A regex
over raw text produces a false PASS on `orch` and would let the invariant rot exactly where it
was supposed to be caught.

S14 is the only check that may need to be advisory rather than failing on first run — `navigator`
and `orch` do not use `## Phase N` headings at all. Skip S14 when a file has zero `## Phase`
headings rather than failing it; a skill is not required to use phase numbering, only to be
consistent if it does.

Do not add a check that every skill produces a `## Handoff` — `navigator` legitimately does not,
and S7 already records that fact in its contract.

**Files touched:** `tools/contract_lint.py`, `CLAUDE.md` (invariant text), `domain.md:100`
(invariant text).

**Success criteria:**
- `python tools/contract_lint.py --skills` exits 0 against the tree after Phases 0–3.
- Deliberate negative tests, each producing exactly one FAIL and a non-zero exit:
  - temporarily rename a skill directory → S2, S10
  - temporarily delete `navigator`'s contract block → S4
  - temporarily add a 13th row to `SKILLS.md` with no directory → S10
  - run against the pre-Phase-0 tree → S11 fails on `orch`
- `python tools/contract_lint.py <existing-review-file> --skill code-review` still behaves exactly
  as before. Regression-check against a file in `reviews/`.
- `orch/SKILL.md` passes S8 for the right reason (it has a real gate at line 153), verified by
  confirming the line-268 prose occurrence is excluded.

---

## Dependencies Between Phases

```
Phase 0  (git add orch/)
   │
   ├──────────────► Phase 1  (SKILLS.md manifest; collapse 6 registries)
   │                   │
   │                   ▼
   │                Phase 2  (WORKFLOWS placement; navigator contract; Mode dedup)
   │                   │
   ▼                   ▼
Phase 3  (review-depth finding types)  ── independent ──┐
                                                        ▼
                                                     Phase 4  (lint + invariant wording)
```

| Phase | Depends on | Why |
|---|---|---|
| 0 | — | Untracked file; every later phase references it as repo content |
| 1 | 0 | The manifest must have a row for `orch`, and S11 later asserts it is tracked |
| 2 | 1 | `navigator`'s Mode and the orphans' workflow placement are decided *in* `SKILLS.md`; Phase 2 propagates that decision into skill files. Reversing it means deciding twice |
| 3 | 0 only | Touches one file no other phase touches. Can run in parallel with 1–2 |
| 4 | 1, 2, 3 | Its checks assert the end state. Run earlier and every FAIL is a phase not yet done, not a defect |

### Ordering argument: AR-DRY-002 must land before AR-EXT-001

**AR-DRY-002 (Phase 1) first. This is not close.**

Registering the three orphans first means editing every registry that exists: `README.md` ×2,
`CLAUDE.md`, `domain.md`, `blueprint-usage-guide.md`, `shared-principles.md` — six tables ×
three skills = eighteen hand edits. Phase 1 then deletes five of those six tables. Roughly
fifteen of the eighteen edits are written and immediately discarded.

Worse than the wasted effort: doing EXT-001 first is *doing the thing that caused the bug*. The
finding's own root cause is "adding a skill requires 5+ hand-synced edits, so nobody does them."
Performing those 5+ edits by hand demonstrates the defect rather than fixing it, and leaves the
next skill in exactly the same trap.

Run it the other way and AR-EXT-001 largely stops being a separate task. Building `SKILLS.md`
*is* enumerating the filesystem, so the three orphans get registered as an unavoidable
consequence of doing Phase 1 correctly. What remains — Phase 2 — is the genuine residue that a
manifest cannot express: where in the W1–W6 narrative each orphan belongs, and `navigator`'s
missing contract. That residue is editorial prose, not registry data, and it is the correct
shape for a separate phase.

One real counter-argument, and its answer: `SKILLS.md` needs a `Mode` for `navigator`, but
`navigator` has no contract block declaring one — so Phase 1 appears to depend on Phase 2.
It does not. Phase 1 *decides* the Mode (`READ-ONLY`; the file already says
`**Mode**: READ-ONLY. Never create, edit, or delete files.` in its body at line 14). Phase 2
propagates that decision into the contract block. Decision then propagation, not the reverse.

---

## Risk Register

| ID | Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| R1 | Phase 1 deletes a table that carried information no other copy has, and it is lost | Medium | High | Before each deletion, diff the table's columns against the `SKILLS.md` schema. `blueprint-usage-guide.md`'s Research/Reasoning/Utility blocks are explicitly retained for this reason — they name skills with no directory here |
| R2 | S8's gate check produces a false PASS on prose that merely quotes `**STOP.**` | High if unmitigated | High — the invariant silently stops being enforced | Fence- and blockquote-stripping is a stated requirement of S8, not an optimisation. `orch/SKILL.md:268` is the standing test case |
| R3 | User rejects the 4.1 invariant amendment, forcing literal approval gates into three read-only diagnostics | Medium | Medium | Phase 4 stops at a gate before touching invariant text. The alternative path is scoped in 4.1. Phases 0–3 are unaffected either way and can land first |
| R4 | `SKILLS.md` becomes a fourteenth stale copy — the exact failure being fixed | Low after S10 | High | S10 is bidirectional (dir→row and row→dir) and S13 cross-checks the one retained duplicate. Without the lint this risk is Medium-High, which is why option (b) alone was rejected |
| R5 | Renaming `### Mode` headings in `ideate`/`plan-tracker` breaks an internal cross-reference | Low | Low | Grep both files for self-references to "Mode" before renaming. `WORKFLOWS.md:319-320` already uses "Mode A (open)" / "Mode B (stress-test)" — match that wording rather than inventing new |
| R6 | Phase 3's new codes overlap `code-review`'s findings, creating the trigger-overlap anti-pattern | Low | Medium | Rules 12 and 13 were excluded for exactly this reason. Re-read `code-review`'s Pillar vocabulary (Correctness/Style/SOLID/DRY/Performance/Types) against the six new codes before committing; none should be expressible as a CR-* pillar |
| R7 | `.gitignore` contains a bare `CLAUDE.md` pattern. The root file is tracked so it is unaffected, but any future `CLAUDE.md` in a subdirectory would be silently ignored | Low | Low | Out of scope. Flagged because Phases 1 and 4 both edit `CLAUDE.md` and someone will notice the pattern. Do not "fix" it in this pass |
| R8 | `install_skills.sh` (17 unrelated skills) or `setup.sh` (stale 8-skill list) get pulled into the manifest or the lint | Medium | Medium | Both are explicitly out of scope in Phase 1. The lint globs `*/SKILL.md`, never `*.sh` |
| R9 | Phase 4 lands with S14 failing on `navigator`/`orch`, which use no `## Phase N` headings | High if unmitigated | Low | S14 is specified to skip files with zero `## Phase` headings. Consistency-if-used, not mandatory-numbering |

---

## Out of Scope

Named here so a later pass does not treat them as new discoveries:

- `setup.sh:11` — stale 8-skill `mkdir` list in a one-shot bootstrap script.
- `install_skills.sh` — installs a different 17-skill inventory; unrelated to blueprint's twelve.
- `.gitignore`'s bare `CLAUDE.md` pattern (R7).
- APOSD decision rules 12 and 13 — real coverage gaps in `review-depth`, deliberately deferred (§3.1).
- `commands/` (15 files) — has no registry problem in scope here, but has no manifest either.
  Candidate for a `COMMANDS.md` on the same pattern if `SKILLS.md` works.
- Any pressure-pack content. This plan clears the runway; it does not build the aircraft.
