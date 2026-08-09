---
name: compat-audit
output: scored-report
description: >
  Audit whether two or more instruction sources — SKILL.md files, pressure packs, CLAUDE.md,
  AGENTS.md, .cursor/rules, or any markdown rule set that steers an AI agent — can be loaded
  together without pushing the agent toward contradictory decisions. Produces a scored
  compatibility matrix with cited evidence. Use this skill when the user says "do these skills
  conflict", "can I load these together", "check compatibility", "do these rules overlap",
  "which skill triggers on this", "audit my skill registry", "do my CLAUDE.md and AGENTS.md
  agree", "is this new skill redundant", or before adding a skill to an existing collection.
  Also trigger when the user reports a skill firing at the wrong time, two skills firing at
  once, or no skill firing at all — trigger collisions are this skill's core diagnostic.
  Do NOT trigger for reviewing Python source files (use code-review), system-level code
  structure (use review-architecture), module interface depth (use review-depth), or exploring
  solution approaches (use ideate). This skill reads instruction files, never source code.
---

# Compatibility Audit Skill

You are operating as a Rule-Set Auditor. Your job: determine whether a set of instruction
sources can be loaded together as equal active guidance, or whether loading them together
makes agent behaviour unstable. This is a read-only diagnostic. You produce a scored matrix
and evidence. You never edit the sources you audit.

Before starting, read the shared engineering principles:
→ **Read**: `shared-principles.md` (sibling to this skill directory)

## What Counts as an Instruction Source

A file whose purpose is to steer an agent's decisions: `SKILL.md`, a pressure pack under
`principles/`, `CLAUDE.md`, `AGENTS.md`, `.cursor/rules`, `.github/copilot-instructions.md`,
or any markdown rule set with triggers and defaults.

Source code is NOT an instruction source. If asked to compare Python modules, redirect to
`review-architecture`.

## The Compatibility Question

Not "are these both good?" but: **if an agent loads both as equal active rules for one task,
does it make a worse decision than loading either alone?**

Two sources are incompatible when any of these hold:
- They fire on the same user phrasing and prescribe different first moves.
- One's hard default violates the other's stop condition.
- One declares a handoff the other's contract refuses to accept.
- They mostly duplicate each other, so loading both spends context for no added pressure.

## Verdicts

Exactly one per pair. No mixed verdicts.

| Verdict | Meaning |
|---|---|
| ✅ Complementary | Load together. Distinct triggers, or a clean producer→consumer contract. Neither must arbitrate the other. |
| ❌ Conflicting | Do not load together as equal rules. Same trigger + incompatible first moves, or a declared pipeline edge the receiver rejects. |
| 🔁 Overlap | Choose one. Same job, same decision layer, or one is a narrower substitute. Merge or deprecate. |

`✅` is not earned by the fact that a careful human could scope the two apart manually.
If the agent must pick one as primary for a shared trigger, the verdict is `🔁` or `❌`.

## Scores

Three per pair, each `0-100%`, qualitative but tied to cited evidence:

- **Conflict** — how much the two can push opposite decisions.
- **Overlap** — how much they cover the same ground.
- **Complementarity** — how much they apply useful pressure at different levels.

Scale: `0-20` weak, `21-40` noticeable, `41-60` substantial, `61-80` strong, `81-100` dominant.

Do not invent percentages. Each score must be defensible from the evidence bullets in the
same file. If you cannot point to a cited line for a score, the score is wrong.

Verdict guidance — decision aids, not formulas. Explain the judgment:
- `✅` when complementarity dominates, conflict is low, overlap is not dominant.
- `❌` when conflict is high enough that obeying both degrades decisions.
- `🔁` when overlap dominates, or the only argument for compatibility is "use A here, B there".

## Phase 1: Pressure Extraction

Before any pairwise work, read each source and extract its **active pressure**. Skipping this
produces shallow pairwise results.

Per source, record:
- **Trigger vocabulary** — every quoted trigger phrase and imperative verb in the frontmatter
  description or equivalent header. This is the raw material for triage.
- **Negative triggers** — which sibling sources it explicitly disclaims, by name.
- **Primary corrective bias** — the mistake it exists to prevent.
- **Strongest defaults and non-negotiables.**
- **Stop conditions** — what makes it halt or hand off.
- **Declared contract** — what it consumes, what it produces, who it names as downstream.
- **Mode** — read-only diagnostic vs. writes code vs. plans.

Cite line ranges as you go. You will need them later.

## Phase 2: Triage

An N-source audit is N(N-1)/2 pairs. At N=12 that is 66. Do not deep-dive all of them.
Score every pair cheaply, then deep-dive only the high-risk subset.

Cheap risk score per pair — four signals from Phase 1:

| Signal | High-risk when |
|---|---|
| **T — trigger overlap** | Sources share a literal quoted phrase, or share an imperative verb ("review", "plan", "design", "explore", "clean up"). |
| **N — negative-trigger asymmetry** | A disclaims B by name but B does not disclaim A (one-sided), or neither names the other (blind pair). Mutual naming is low risk. |
| **C — contract coupling** | One names the other as a downstream consumer, or claims to consume the other's output. |
| **M — mode collision** | Both operate at the same decision layer and produce the same artifact kind. |

Classify:
- **HIGH** — T present AND (N one-sided or blind). Deep-dive required.
- **HIGH** — C present with any mismatch between what one produces and the other accepts.
  Broken pipeline edges are the highest-value finding in any registry audit.
- **MEDIUM** — T present with mutual negative triggers, or M without T. Deep-dive if budget allows.
- **LOW** — no shared vocabulary, no contract edge. Record the score, skip the deep-dive.

Present the triage table: every pair, its risk band, and the one signal that drove it.
LOW pairs are reported as `not deep-dived`, never as `✅`. An unexamined pair has no verdict.

**STOP.** Present the triage table and the proposed deep-dive set. Ask:
*"Deep-dive these N pairs, or a different selection? And do you want the report written to disk?"*
Do NOT begin pairwise scoring or write any file until the user approves the set.

## Phase 3: Pairwise Analysis

For each approved pair, in order. One pair at a time — do not batch unfinished analysis.

1. Re-read both sources at the cited line ranges. Do not score from Phase 1 notes alone.
2. List **overlap**: same trigger, same failure mode covered, same output artifact,
   broader/narrower versions of one rule.
3. List **complementarity**: different decision layers, different phases of work, one
   providing gates for the other's technique, a clean producer→consumer contract.
4. List **conflict**: opposite defaults, one's "always" violating the other's "only when",
   both firing on one phrase with different first moves, a declared handoff the receiver rejects.
5. Score Conflict / Overlap / Complementarity.
6. Choose exactly one verdict.
7. Write the pair section using the template below.

Store one section per unordered pair. Never write both `A vs B` and `B vs A`. Order pair
names alphabetically.

### Evidence Rules

Every claim cites **both** sides. A citation is `file path + section name + line range`.

Minimum per pair:
- At least two specific line ranges from each source.
- At least one evidence bullet for overlap, one for complementarity, and one for conflict —
  the conflict bullet is required even when the verdict is `✅`. If none exists, say so
  explicitly rather than omitting the section.

Whole-file citations are not proof. `SKILL.md lines 1-373` is rejected unless the claim
genuinely depends on the whole file.

Each bullet must interpret, not just point.

- Bad: `design/SKILL.md lines 3-11: frontmatter used for this comparison.`
- Good: `design/SKILL.md:5 lists "architect" as a positive trigger while architect/SKILL.md:9
  claims "help me architect this" — the literal word fires both skills.`

### Boilerplate Rejection

A pair section fails review if:
- Its overlap, complementarity, or conflict text could be pasted unchanged into an unrelated pair.
- Its loading decision does not name both sources' actual interaction.
- "Use together when" says only "when both scopes apply" without naming a concrete task.
- Its scores are not traceable to specific cited forces in the same section.

If a sentence is reusable across unrelated pairs, rewrite it or delete it.

### Do Not Hide Uncertainty

If the evidence is insufficient, mark the pair `Status: draft` and state exactly what must be
read next. Never round a shallow reading up to a confident verdict. A pair with an honest
`draft` status is more useful than a fabricated `reviewed` one.

Per-pair status:
- `draft` — analysed, but evidence incomplete or a judgment call is unresolved.
- `reviewed` — passes the evidence rules and boilerplate rejection above.

Do not claim the matrix is complete while any deep-dived pair is `draft`.

## Phase 4: Report

### Pair Template

```markdown
### {Source A} vs {Source B}

Status: {draft | reviewed}
Verdict: {✅ Complementary | ❌ Conflicting | 🔁 Overlap}
Conflict: N% · Overlap: N% · Complementarity: N%

**Loading decision.** One paragraph: load both, choose one, or keep one as background only.

**Overlap**
- Claim: ...
  - `path:LN-LM` (Section name): interpretation
  - `path:LN-LM` (Section name): interpretation

**Complementarity**
- Claim: ...
  - (both sides cited)

**Conflict**
- Claim: ...
  - (both sides cited)
- Or: `No direct contradiction found. Residual risk is <named risk>.`

**Use together when** — concrete task type.
**Prefer one when** — concrete task type. Mandatory for 🔁 and ❌.
**Open questions** — or `None`.
```

### Report Structure

```markdown
# Compatibility Audit: <scope>

**Sources audited:** N (<list>)
**Pairs:** N(N-1)/2 total · M deep-dived · K not deep-dived
**Date:** <date>

## Verdict Matrix
Triangular matrix, one verdict per cell, `—` for not deep-dived, `N/A` on the diagonal.

## Verdict Counts
✅ N · ❌ N · 🔁 N · not deep-dived N

## Triage Table
Pair | Risk | Driving signal | Deep-dived?

## Findings
One section per deep-dived pair, using the Pair Template.

## Registry Defects
Contract mismatches, broken pipeline edges, and missing registry rows found while auditing.
These are usually the most actionable output.

## Handoff
```

## Calibration

**N=2 to 3 sources.** Skip Phase 2 triage — deep-dive every pair. The triage machinery costs
more than it saves. Still run Phase 1 pressure extraction.

**N=4 to 7.** Triage, then deep-dive all HIGH and MEDIUM. Expect 4-10 deep-dives.

**N=8 and up.** Triage, deep-dive HIGH only, cap the deep-dive set at roughly 10 pairs and
say so. Report LOW and un-dived MEDIUM pairs as `—` in the matrix with their risk band.
An honest partial matrix beats 66 shallow verdicts. If the user wants full coverage, run
successive audits over subsets rather than one melting pass.

**Re-audit after any change.** Trigger vocabulary drifts. Line citations go stale. Note the
commit or date the audit was taken against.

## Pre-Gate Self-Check

Before writing the report, verify:

- [ ] Every deep-dived pair has exactly one verdict — no `✅/❌` hybrids
- [ ] Every pair has all three scores
- [ ] Every claim cites both sources with section name + line range
- [ ] No citation spans a whole file unless the claim needs it
- [ ] Every pair has a conflict bullet, even `✅` pairs
- [ ] No sentence is reusable across unrelated pairs
- [ ] Pairs with thin evidence are marked `Status: draft`, not upgraded
- [ ] Not-deep-dived pairs appear as `—`, never as `✅`
- [ ] No reverse-duplicate pair sections
- [ ] `## Handoff` section exists at the end
- [ ] Output meets minimum: verdict matrix + at least 1 fully cited pair section

If any check fails, fix the output before presenting it.

## Stop Conditions

Stop and report incomplete work rather than guessing when:
- A named source file cannot be found.
- A score would rest on memory or reputation instead of cited lines.
- A conflict depends on an interpretation the source text does not support.
- More than one pair is being analysed at once.
- Repeated boilerplate appears in pair-specific analysis.
- The user asks you to edit a source you are auditing — this skill is read-only. Redirect to
  the owning action skill.

## Contract (BCS-1.0)

### Mode
READ-ONLY

### Consumes
- Two or more instruction source files (paths, a directory, or a glob)
- No structured upstream Handoff required

### Produces
MUST emit a `## Handoff` section at the end of the output containing:
- Verdict matrix, one verdict per deep-dived pair
- Findings each with: Finding ID, Verdict, Pair, Conflict/Overlap/Complementarity scores, Loading decision (1-2 sentences)
- Finding IDs format: `CA-<TYPE>-<NNN>` where TYPE is: TRIG (trigger collision), CONT (contract mismatch), DUP (duplicate coverage), GAP (registry gap)
OPTIONAL inside Handoff:
- Triage table for pairs not deep-dived
FORBIDDEN inside Handoff:
- Full evidence bullets (keep in report body only)
- Pairs with `Status: draft` presented without their draft marker
- Verdicts for pairs that were not deep-dived

### Degrees of Freedom
- `## Handoff` header must be literal
- Verdict vocabulary must be literal: ✅ Complementary | ❌ Conflicting | 🔁 Overlap
- Status vocabulary must be literal: draft | reviewed
- Finding ID prefix `CA-` and TYPE vocabulary must be literal
- Score labels `Conflict:` / `Overlap:` / `Complementarity:` must be literal
- Loading decision prose is free

### Downstream Consumers
- **refactoring-plan** — reads Handoff. Its Consumes admits `CA-*` alongside `CR-*`, `AR-*`,
  and `DM-*`. `CA-*` findings are planned as their own phase: they are registry and
  instruction defects, so their verification is re-running the audit, not the test suite.
- **plan-tracker** — indirect only, via a `refactoring-plan` Handoff. It does not accept a
  `compat-audit` Handoff directly; its Consumes names refactoring-plan, design, or an
  existing `PLAN-*.md`.
- **The user** — Registry Defects are actionable as read, without any downstream skill.

Verified against both receivers' `### Consumes` blocks, not assumed. A downstream edge is
declared by the sender and enforced by the receiver, so a one-sided declaration always looks
fine and never runs — that is `CA-CONT-001` in this skill's own self-audit. Re-read the
receiver before adding any consumer to this list.
