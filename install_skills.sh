#!/usr/bin/env bash
# Install 17 skills into ~/.claude/skills/
# Generated from laptop skill inventory, 2026-03-01
# Usage: paste this entire script into Claude Code or run: bash install_skills.sh

set -euo pipefail

SKILLS_DIR="$HOME/.claude/skills"
mkdir -p "$SKILLS_DIR"

CREATED=0
SKIPPED=0

install_skill() {
  local name="$1"
  local dir="$SKILLS_DIR/$name"
  if [ -f "$dir/SKILL.md" ]; then
    echo "SKIP: $name (already exists)"
    ((SKIPPED++))
    return
  fi
  mkdir -p "$dir"
  cat > "$dir/SKILL.md"
  echo " OK:  $name"
  ((CREATED++))
}

# ─────────────────────────────────────────────────────────
# 1. artifact-tracker
# ─────────────────────────────────────────────────────────
install_skill "artifact-tracker" <<'SKILL'
---
name: artifact-tracker
description: >
  Track artifact validation status and propagate implications across governance documents.
  Trigger on: 'I validated [artifact]', 'update artifact status', 'mark [artifact] as tested',
  'what gets unblocked if I validate [X]', 'what should I validate next'.
  Do NOT trigger for code review or paper review — use those skills instead.
---

# Artifact Tracker

When an artifact changes validation status, update ARTIFACTS.md and propagate the
implications across all governance documents. This is the "ripple effect" skill — a
single status change can unblock tracks, upgrade CFP decisions, and advance papers.

## Workflow

### Step 1: Record the status change

Identify from the user's message:
- **Which artifact** (by ID or name — e.g., C-02, kernel_ci, T-01, D-01)
- **New status.** One of: `untested` → `unit-tested` → `integration-tested` → `production`
  - For theoretical results (T-xx): `unproved` → `proof-sketch` → `proved` → `published`
- **Evidence.** What was done to validate?

For theorems:
- `proof-sketch`: Argument outlined, key steps identified, not fully written
- `proved`: Complete proof exists, checked by at least one co-author
- `published`: Appeared in a submitted/accepted paper

### Step 2: Update ARTIFACTS.md

Locate the artifact and update:
1. **Status column:** Old → new status
2. **Owner column:** If TBD, ask user to assign
3. **Notes:** Add dated validation note
4. **Used In column:** Note venue if relevant

### Step 3: Propagate — Downstream tracks unblocked

Check `TRACK_DEPENDENCY_DAG.md` for downstream dependencies.

### Step 4: Propagate — CFP triage re-evaluation

Check `CFP_TRIAGE.md` for archived CFPs where the Reuse dimension was limiting.

### Step 5: Propagate — Paper pipeline advancement

Check `SUBMISSION_CALENDAR.md` for papers blocked by this artifact.

### Step 6: Propagate — Critical path update

Re-assess the critical path in `TRACK_DEPENDENCY_DAG.md`.

### Step 7: Summarise and offer updates

Present a complete impact summary. Offer to make all updates to governance documents.

## "What should I validate next?" Mode

Analyse the dependency graph to find the highest-leverage artifact:
1. Count downstream tracks and papers each unvalidated artifact blocks
2. Weight by deadline proximity
3. Weight by effort
4. Present as a prioritised list
SKILL

# ─────────────────────────────────────────────────────────
# 2. cfp-scorer
# ─────────────────────────────────────────────────────────
install_skill "cfp-scorer" <<'SKILL'
---
name: cfp-scorer
description: >
  Score a Call for Papers against a 5-dimension rubric and produce a commit/archive
  recommendation. Trigger on: user pastes a CFP, 'triage this CFP', 'score this call
  for papers', 'should I submit to [venue]', 'evaluate this CFP', 'does this fit our tracks'.
  Do NOT trigger for paper review or literature scanning.
---

# CFP Scorer

Score a Call for Papers against the 5-dimension rubric defined in CFP_TRIAGE.md and
produce a commit/archive recommendation. Replaces a 15-minute manual evaluation with
a 2-minute review-and-confirm.

## Workflow

### Step 1: Gather the CFP

Extract: Venue name and type, submission deadline, topic scope, editorial board,
submission format requirements, special instructions.

### Step 2: Identify best-fit track(s)

Match against tracks A, B, C, D1, D2, D3, E.

### Step 3: Score all 5 dimensions

| Dimension | Scale | What it measures |
|-----------|-------|-----------------|
| Track Fit | 1–5 | How well the CFP aligns with a track's scope |
| Theory Welcome | 1–5 | Whether the venue values formal/theoretical contributions |
| Lead Time | 1–5 | Time available vs. paper readiness |
| Reuse | 1–5 | How much existing work can be leveraged |
| Audience Value | 1–5 | Strategic value of the venue's audience |

### Step 4: Apply decision rules

- **Total ≥ 20**: COMMIT
- **Total 15–19 AND Reuse ≥ 4**: CONDITIONAL COMMIT
- **Total 15–19 AND Reuse < 4**: ARCHIVE
- **Total ≤ 14**: ARCHIVE
- **Any dimension = 1**: VETO

Override rules:
- Editor invitation: +3 (cap 25)
- Dependency DAG blockers: cap Lead Time at 1
- Quarterly cap reached: defer

### Step 5: Produce output

Present scoring table with decision and rationale.

### Step 6: Confirm with user

**STOP.** Present the scoring and recommendation. Ask: "Accept this decision?"
Do NOT update governance files until the user approves.

After confirmation, offer to update `CFP_TRIAGE.md` and `SUBMISSION_CALENDAR.md`.
SKILL

# ─────────────────────────────────────────────────────────
# 3. compact-memory
# ─────────────────────────────────────────────────────────
install_skill "compact-memory" <<'SKILL'
---
name: compact-memory
description: >
  Create structured summaries of research conversations and store in memories/ for
  multi-agent memory sharing and conversation continuity. Trigger on: 'summarise this
  conversation', 'save a review', 'log this session', 'create a memory file',
  'save to memories/', 'record progress on a research track'.
---

# Compact Memory

Create structured summaries of research conversations for multi-agent memory sharing
and conversation continuity.

## File Naming Convention

```
{YYYYMMDD}_TRACK_{X}_version_{N}.md
```

## Summary Template

```markdown
# Conversation Summary: Track {X}

**Date**: {YYYY-MM-DD}
**Version**: {N}
**Previous Version**: {filename or "N/A"}

## Key Topics Discussed

## Technical Contributions

### Concepts Developed

### Methods / Approaches

## Code / Implementation Notes

## Open Questions

## Next Steps

## References / Resources Mentioned

## Cross-Track Connections

## Agent Memory Tags
```

## Critical Rules

- **Never overwrite** an existing version — always increment
- **Link previous versions** explicitly
- **Write for cold-start** — a fresh agent must be able to understand and continue
- **Be precise about state** — distinguish "explored and rejected", "explored and promising", "unexplored"
- **Tag consistently** — always include `#track-{x}` as the first tag
SKILL

# ─────────────────────────────────────────────────────────
# 4. empirical-pipeline
# ─────────────────────────────────────────────────────────
install_skill "empirical-pipeline" <<'SKILL'
---
name: empirical-pipeline
description: >
  Generate a complete, reproducible pipeline for real-data experiments. Trigger on:
  'build the empirical pipeline', 'set up the data pipeline', 'create the experiment
  pipeline', 'pipeline for §4b', 'set up the backtesting pipeline', 'create the Makefile
  for experiments', 'wire up the data to the estimator', 'now I need to run it on real data'.
  Do NOT trigger for code review or architecture review.
---

# Empirical Pipeline

Generate a complete, reproducible pipeline for real-data experiments. The pipeline takes
raw data through preprocessing, feature construction, estimation, and evaluation, producing
the tables and figures for the paper.

## Core Principle

**Pipelines, not scripts.** The output is a DAG of computational steps with clear inputs,
outputs, and dependencies.

## Workflow

### Step 1: Load experiment specifications

Read the quasi-theory template §4b (secondary experiments) and §4c (robustness checks).

### Step 2: Design the pipeline DAG

Decompose each experiment into stages:
```
RAW DATA → CLEAN → FEATURES → ESTIMATE → EVALUATE → FIGURES/TABLES
```

### Step 3: Generate pipeline orchestration

Produce a Makefile (or Snakemake/DVC file) that encodes the DAG.

### Step 4: Generate stage scripts

For each stage, generate a Python script with:
- Clear docstring
- Configuration via YAML/CLI
- Logging
- Error handling
- Artifact imports
- Output validation

### Step 5: Generate robustness pipeline

Create variant configurations from §4c that stress-test the assumptions.

### Step 6: Generate results aggregation

Create a script that produces: main results table, robustness summary table,
and figure specifications.

### Step 7: Save and document

Save to `track_*/experiments/[paper_name]/` with README documentation.

## Track-Specific Pipeline Patterns

- **Track A:** LOB data → features → prediction → execution-aware evaluation
- **Track B:** Market data → instrument construction → IV/DML estimation → placebo tests
- **Track C:** Historical data → offline dataset → policy learning → off-policy evaluation
- **Track D:** Price data → multiscale decomposition → spectrum estimation → downstream analysis
- **Track E:** Market data → kernel computation → test statistic → inference
SKILL

# ─────────────────────────────────────────────────────────
# 5. idea-refiner
# ─────────────────────────────────────────────────────────
install_skill "idea-refiner" <<'SKILL'
---
name: idea-refiner
description: >
  Structure the "how does this change my work?" thinking after reading new papers.
  Trigger on: 'how does this affect my claim', 'refine my idea based on this',
  'update my template based on this paper', 'this paper uses weaker assumptions than mine',
  'should I change my proof strategy'. Do NOT trigger for paper review or literature mapping.
---

# Idea Refiner

After reading new papers (typically from Paper Scout), structure the "how does this
change my work?" thinking. Takes the user's reaction to a paper, identifies which parts
of their quasi-theory template are affected, proposes specific changes, and ensures
updates propagate to governance documents.

## Workflow

### Step 1: Identify what triggered the refinement

Types:
- **A.** Competitive landscape change
- **B.** Methodological insight
- **C.** New data/empirical results
- **D.** Paper solves part of planned work
- **E.** General experience/intuition shift

### Step 2: Load the current state

Read the affected quasi-theory template and check POSITIONING.md, ARTIFACTS.md.

### Step 3: Generate the diff

For each affected section, produce a **before/after** with rationale.

### Step 4: Assess the implications

Classify as: strengthening, weakening, pivoting, or no change needed.

### Step 5: Present the refinement proposal

**STOP.** Present: summary table + detailed diffs + downstream effects + questions.
Ask: "Do these refinements look right?"
Do NOT modify any templates or governance documents until the user approves.

### Step 6: Apply approved changes

Update quasi-theory template, POSITIONING.md, ARTIFACTS.md, flag SUBMISSION_CALENDAR.md.

## Refinement Patterns

- "They proved it under i.i.d., I can extend to dependent data"
- "Their assumptions are weaker than mine"
- "They use a method I hadn't considered"
- "They already solved the easy case"
- "This makes my paper less novel"
SKILL

# ─────────────────────────────────────────────────────────
# 6. literature-mapper
# ─────────────────────────────────────────────────────────
install_skill "literature-mapper" <<'SKILL'
---
name: literature-mapper
description: >
  Map the complete structure of a research subfield — sub-problems, methods, formal results,
  key groups, and open gaps. Trigger on: 'map the field of [topic]', 'what exists in [area]',
  'formal gaps in [area]', 'literature map', 'decompose [topic] into sub-problems',
  'where are the open problems', 'I want to enter [field]'. Sits upstream of Paper Scout.
---

# Literature Mapper

Map the complete structure of a research subfield so the user can identify where to
place a formal claim. Sits *upstream* of Paper Scout.

## Required Inputs & Defaults

| Parameter | Default |
|-----------|---------|
| `topic` | *required* |
| `target_domain` | `"financial microstructure"` |
| `contribution_type` | `"theory-first"` |
| `venue_bar` | `"mid-high"` |
| `time_budget` | `"4h"` |

## Workflow

### Step 1: Decompose the topic into sub-problems (3–6)

### Step 2: Search the literature per sub-problem

Four layers:
1. **Foundational papers** (2–3)
2. **Methodological advances** (3–5)
3. **Formal results** (theorem statements, assumptions, proof techniques)
4. **Domain applications**

### Step 3: Saturation & Stop Conditions

Stop when: citation convergence, formal results plateau, matrix completeness,
or diminishing returns.

### Step 4: Build the Claim Engineering Table

Columns: Result category, Model class, Dependence structure, Status
(✅ PROVED / ⚠️ UNVERIFIED / 📊 EMPIRICAL ONLY / 💭 CONJECTURED / ❌ OPEN GAP),
Reference, Assumptions, Proof ingredients, Closest reusable lemma,
What breaks in target setting.

### Step 5: Classify gaps and assess claim viability

Gap types:
- 🟢 **NATURAL EXTENSION** — 1–3 months, applied venues
- 🟡 **NON-TRIVIAL EXTENSION** — 3–9 months, JFEc/JASA
- 🔴 **FOUNDATIONAL GAP** — 6–18 months, Econometrica/AoS
- 🔵 **APPLICATION GAP** — 1–4 months, JFM/JFE

### Step 6: Map key research groups

Scoop risk assessment: HIGH/MEDIUM/LOW.

### Step 7: Produce outputs

1. **Field Map (Markdown)**
2. **Machine-readable companion (YAML)** for TRACKS.yaml and CLAIMS_LIBRARY.md
3. **BibTeX file**
SKILL

# ─────────────────────────────────────────────────────────
# 7. paper-lit-finder
# ─────────────────────────────────────────────────────────
install_skill "paper-lit-finder" <<'SKILL'
---
name: paper-lit-finder
description: >
  Find 4–5 most relevant recent papers for a track or topic. Lighter than paper-scout,
  works without TRACKS.yaml. Trigger on: 'find recent papers on [topic]', 'paper digest',
  'any new papers I should know about', 'literature scan'. Do NOT trigger for full
  literature mapping — use literature-mapper instead.
---

# Paper Lit Finder

Find the 4–5 most relevant recent papers for a given track, produce structured digests
the user can scan in 10 minutes, and flag overlaps with the existing research programme.

## Configuration Dependencies (Optional)

- `TRACKS.yaml` — Search terms, scope, quasi-theory expectations
- `CLAIMS_LIBRARY.md` — Existing formal claims for overlap detection

Works without either file (degrades to keyword-based search).

## Workflow

### Step 1: Determine the search scope

Track(s), time window (default 90 days), focus narrowing.

### Step 2: Search across sources

arXiv, SSRN, Hugging Face Papers, Google Scholar.

### Step 3: Filter and rank

Priority: Direct overlap with claims, scope match, methodological relevance,
formal content, venue quality, recency, citation momentum.

### Step 4: Produce structured digests

For each paper: Claim, Method, Data, Key result, Formal content rating,
Limitation (authors' and programme-aware), Claim overlap, Positioning action.

### Step 5: Produce the digest summary

Key takeaways, claims status, positioning implications, ideas triggered,
recommended actions.

### Step 6: Offer downstream actions

- 🔴 threat → Positioning Updater
- Claim affected → Idea Refiner
- New dataset → ARTIFACTS.md check
SKILL

# ─────────────────────────────────────────────────────────
# 8. paper-scout
# ─────────────────────────────────────────────────────────
install_skill "paper-scout" <<'SKILL'
---
name: paper-scout
description: >
  Weekly or on-demand literature scanning for a given track/topic. Requires TRACKS.yaml.
  Trigger on: 'scan for papers on [topic]', 'what is new in [track]', 'paper scout for
  Track [X]', 'weekly digest', 'who published on [topic] recently'.
  For quick ad-hoc searches without config, use paper-lit-finder instead.
---

# Paper Scout

Weekly or on-demand literature scanning to surface the 4–5 most relevant recent papers
for a given track/topic and extract specific ingredients for positioning and paper-writing.

## Sources

- arXiv (q-fin + relevant ML categories)
- SSRN
- Google Scholar
- Hugging Face Papers

## Extractions per paper

1. **Claim** (what the paper asserts/contributes)
2. **Formal result** (theorem/proposition + assumptions)
3. **Method** (what they actually do)
4. **Data** (datasets, assets, horizon, frequency)
5. **Key limitation** (explicit + programme-aware)

## Programme-aware overlap analysis

Flags whether paper overlaps with Track definitions and Existing Claims Library.
If overlap is a **threat**, produces actionable note for Positioning Updater.

## Configuration Files (Required)

1. `TRACKS.yaml` — track definitions with scope, keywords, quasi-theory expectations
2. `CLAIMS_LIBRARY.md` — existing claims for overlap detection
SKILL

# ─────────────────────────────────────────────────────────
# 9. positioning-updater
# ─────────────────────────────────────────────────────────
install_skill "positioning-updater" <<'SKILL'
---
name: positioning-updater
description: >
  Keep POSITIONING.md current by incorporating new competitor papers and assessing whether
  differentiation claims (wedges) remain valid. Trigger on: 'new competitor paper',
  'update positioning for Track [X]', 'someone published something similar', 'check if
  our wedge still holds', 'positioning check', shares arXiv/SSRN URL.
---

# Positioning Updater

Keep `POSITIONING.md` current by incorporating new competitor papers and assessing
whether the research programme's differentiation claims (wedges) remain valid.

## Workflow

### Step 1: Identify the trigger

Specific paper, general concern, or quarterly review flag.

### Step 2: Analyse the new paper

Extract: Core contribution, methodology, data, formal results, venue.

### Step 3: Assess impact on positioning

| Level | Meaning | Action |
|-------|---------|--------|
| **No threat** | Different setting/approach/question | Log as "related but distinct" |
| **Narrowing** | Partial overlap, wedge narrower | Update competitor table, revise wedge |
| **Threatening** | Same result/approach/setting | Immediate alert, full assessment |

### Step 4: Determine what's still unique

Check: Assumptions, setting, formal strength, economic question, scope.

### Step 5: Update POSITIONING.md

Add to competitor table, revise wedge statement if needed.

### Step 6: Propagate updates

Flag quasi-theory templates, papers in progress, CFP decisions.

### Step 7: Proactive scanning (when requested)

Search arXiv, SSRN, Google Scholar for recent publications matching track keywords.
SKILL

# ─────────────────────────────────────────────────────────
# 10. quarterly-review
# ─────────────────────────────────────────────────────────
install_skill "quarterly-review" <<'SKILL'
---
name: quarterly-review
description: >
  Execute the quarterly review protocol across all governance documents. Trigger on:
  'quarterly review', 'run the quarterly check', 'programme status', 'state of the
  research programme', 'Q[1-4] review', 'audit the programme'.
---

# Quarterly Review

Execute the quarterly review protocol. Walk every governance document, identify issues,
produce a one-page status report with prioritised action items.

## 7 Sequential Checks

1. **Submission Pipeline** — Check SUBMISSION_CALENDAR.md for upcoming deadlines, overdue items, stalled papers
2. **New CFP Scan** — Search SoFiE, SSRN, INOMICS, journal websites for new opportunities
3. **Artifact Audit** — Walk ARTIFACTS.md, flag untested or stale artifacts
4. **Dependency DAG** — Check TRACK_DEPENDENCY_DAG.md for blocked paths and resolved blockers
5. **Positioning Currency** — Review POSITIONING.md for stale wedges (>90 days since last update)
6. **CFP Triage Log** — Review CFP_TRIAGE.md for archived CFPs worth re-evaluating
7. **Template & Paper Progress** — Check quasi-theory templates for completeness

## Output: Quarterly Report

```markdown
# Quarterly Review: Q[X] 2026

## Executive Summary
## Submission Pipeline
## New Opportunities
## Artifact Health
## Critical Path
## Positioning
## Action Items
## Decisions Needed
```

Save to `reports/quarterly_Q[X]_YYYY.md`.
SKILL

# ─────────────────────────────────────────────────────────
# 11. quasi-theory-assistant
# ─────────────────────────────────────────────────────────
install_skill "quasi-theory-assistant" <<'SKILL'
---
name: quasi-theory-assistant
description: >
  Guide the user through filling QUASI_THEORY_TEMPLATE.md for a new paper. Adversarial
  in a helpful way — catches vague claims, missing assumptions, hand-wavy proof strategies.
  Trigger on: 'help me fill the template', 'start a new paper', 'I have a paper idea for
  Track [X]', 'what is my formal claim', 'help me sharpen my claim'. Do NOT trigger for
  paper review — use paper-reviewer instead.
---

# Quasi-Theory Assistant

Guide the user through filling `QUASI_THEORY_TEMPLATE.md` for a new paper. Be adversarial
in a helpful way — catch vague claims, missing assumptions, and hand-wavy proof strategies.

## Workflow

### Step 1: Identify the starting point

Blank template, partially filled, verbal description, or rejected paper.

### Step 2: Work through sections in order

**§2: Economic Question** — One sentence, no method reference.

**§3: Formal Claim (THE CRITICAL SECTION)**
- §3a: Claim type
- §3b: Informal statement
- §3c: Formal statement (assumptions + conclusion)
- §3d: Proof strategy (3–5 steps, identify hard part)
- §3e: What could go wrong (premortem)

**§4: Experimental Design** — Primary experiment must TEST the formal claim.

**§5: Positioning** — Name 2–3 competitors, state one-sentence wedge.

**§6: Infrastructure Check** — Walk through ARTIFACTS.md.

**§7: Risk Assessment** — Theorem risk, data risk, timeline risk.

### Step 3: Complete go/no-go checklist (§8)

### Step 4: Create the file

Save as `qt_[short_descriptive_name].md` in track directory.

## Anti-patterns to watch

1. **Method-first framing** — "I want to use [method]" without a question
2. **Vague claims** — "We show that X improves Y" without formal statement
3. **Experiments disconnected from claims** — §4 doesn't test §3
4. **Missing assumptions** — Formal claim without stated conditions
5. **Proof by wishful thinking** — "It should follow from..." without steps
6. **Premature commitment** — Jumping to implementation before §3 is solid
SKILL

# ─────────────────────────────────────────────────────────
# 12. review-implementation
# ─────────────────────────────────────────────────────────
install_skill "review-implementation" <<'SKILL'
---
name: review-implementation
description: >
  Systematically implement changes based on code review feedback. Plan-first: creates
  detailed strategy and waits for approval before touching code. Trigger on: user provides
  reviewer comments, PR feedback, code review notes, asks to implement review suggestions.
  Do NOT trigger for the review itself — use code-review instead.
---

# Review Implementation

Systematically process and implement changes based on code review feedback.
PLAN-FIRST: creates detailed implementation strategy and waits for approval
before touching code.

## Core Principles (Invariants)

1. **No Invention Rule** — Never invent requirements
2. **Spec Compliance** — Match quasi-theory template definitions
3. **Behavior Preservation** — Preserve functionality unless explicitly requested
4. **Explicit Approval Gate** — Never proceed without user confirmation
5. **Performance Preservation** — No degradation in performance-sensitive code

## Workflow

### Phase A: Prerequisites

Review file in `reviews/`, access to source files and specs.

### Phase B: Review Analysis (Read-Only)

1. Locate review file
2. Read and parse (extract severity, pillar, location, BEFORE/AFTER, WHY)
3. Early conflict detection
4. Create todo list

### Phase C: Planning (Read-Only)

Create implementation plan with: risk assessment, spec impact, test impact,
performance risk.

**STOP.** Present the implementation plan. Ask: "Approve this plan?"
Do NOT modify any source files until the user approves.

### Phase D: Implementation (State-Changing)

One severity tier at a time. One todo at a time. Run tests after each change.

### Phase E: Validation

Cross-reference check, syntax validation, governance consistency, convention check.
Produce implementation report.
SKILL

# ─────────────────────────────────────────────────────────
# 13. submission-readiness
# ─────────────────────────────────────────────────────────
install_skill "submission-readiness" <<'SKILL'
---
name: submission-readiness
description: >
  Systematic pre-flight check before submitting a paper. Walks governance documents
  and produces go/no-go verdict with specific blockers. Trigger on: 'is [paper] ready
  to submit', 'readiness check', 'what is blocking [paper]', 'go/no-go for [submission]',
  'pre-submission check'. Do NOT trigger for paper review — use paper-reviewer instead.
---

# Submission Readiness

Systematic pre-flight check before submitting a paper. Walks every governance document
and produces a go/no-go verdict with specific blockers.

## 6-Point Check

1. **Quasi-Theory Template** — Filled template with §8 checklist complete
2. **Dependency DAG** — Upstream dependencies identified
3. **Artifact Validation** — Every required artifact at required validation level
4. **Positioning Wedge** — Clear, current wedge for target venue
5. **Quarterly Constraint** — <2 active submissions in quarter
6. **Paper Stage Assessment** — Stage feasibility vs. deadline

## Verdict

- **GO** — All 6 checks pass
- **NO-GO** — One or more blockers. List each with specific remediation.
- **CONDITIONAL GO** — Minor issues that can be resolved before deadline.
  List conditions with owner and timeline.

If NO-GO: offer help with the most critical blocker.
SKILL

# ─────────────────────────────────────────────────────────
# 14. core-paper-review-skill-special
# ─────────────────────────────────────────────────────────
install_skill "core-paper-review-skill-special" <<'SKILL'
---
name: core-paper-review-skill-special
description: >
  Expert reviewer for theoretical/statistical ML manuscripts with deep expertise in point
  process theory, stochastic calculus, and measure-theoretic probability. Extends
  paper-reviewer with Lens 7: Proof Architecture. Trigger on: verify proofs, check
  measure-theoretic arguments, audit martingale/compensator derivations, validate
  asymptotic results for counting processes or marked point processes.
---

# Core Paper Review Skill (Extended)

Expert reviewer for theoretical and statistical machine learning manuscripts targeting
top-tier journals (JFDS, JMLR, Annals of Statistics, Biometrika, JASA, Stochastic
Processes and their Applications). Extends paper-reviewer with Lens 7 for proof
verification in point process theory and stochastic calculus.

## Philosophy

1. **"So What?"** — Every finding must connect to clear insight
2. **Methodological honesty** — Sophistication requires justification
3. **Proof correctness** — Every proof must be logically complete
4. **Narrative coherence** — Paper is an argument, not a catalogue

## Seven Diagnostic Lenses

1. The "So What?" Test
2. Methodological Justification
3. Internal Consistency
4. Narrative Architecture
5. Statistical Rigor
6. Presentation Quality
7. **Proof Architecture & Point Process Theory**

## Lens 7: Point Process Specifics

- Intensity/compensator relationship (Doob-Meyer decomposition)
- Palm distributions and conditional intensity
- Marked point processes (mark distribution vs. ground process)
- Thinning arguments (Ogata's method)
- Time-change theorems (random time change to unit-rate Poisson)
- Hawkes processes (spectral radius condition < 1 for stationarity)
- Martingale CLTs for counting processes
- Predictable vs. optional projection

## Proof Verification Checklist

For each proof:
- [ ] All assumptions explicitly stated and referenced
- [ ] σ-algebra and filtration specified
- [ ] Adaptedness verified for martingale arguments
- [ ] Integrability conditions checked
- [ ] Mode of convergence stated (a.s., L², in probability, in distribution)
- [ ] Regularity conditions verified for limit theorems
- [ ] Compensator correctly identified
- [ ] Optional/predictable distinction respected
SKILL

# ─────────────────────────────────────────────────────────
# 15. core-reviewer
# ─────────────────────────────────────────────────────────
install_skill "core-reviewer" <<'SKILL'
---
name: core-reviewer
description: >
  Deep reasoning assistant for exhaustive analysis of proofs, theorems, and logical
  arguments. Uses stream-of-consciousness thinking with minimum 10k characters of
  contemplation. Trigger on: 'think through', 'verify', 'check my reasoning',
  'is this proof correct', 'work through this carefully', 'deep review'.
---

# Core Reviewer

Deep reasoning assistant that engages in extremely thorough, self-questioning analysis.
Uses stream-of-consciousness thinking with continuous exploration, self-doubt, and
iterative refinement.

## Core Principles

1. **EXPLORATION OVER CONCLUSION** — Never rush to an answer
2. **DEPTH OF REASONING** — Minimum 10,000 characters of contemplation
3. **THINKING PROCESS** — Short, simple sentences; express uncertainty naturally
4. **PERSISTENCE** — Value thorough exploration over quick resolution

## Output Format

```
\thoughts
[Extensive internal monologue]
- Begin with small, foundational observations
- Question each step thoroughly
- Show natural thought progression
- Express doubts and uncertainties
- Revise and backtrack if needed
- Continue until natural resolution

\answer
[Only if reasoning naturally converges]
- Clear, concise summary
- Acknowledge remaining uncertainties
- Note if conclusion feels premature
```

## Style Guidelines

Natural thought flow:
- "Hmm... let me think about this..."
- "Wait, that doesn't seem right..."
- "Maybe I should approach this differently..."
- "Actually, going back to the basics..."
- "I'm not confident about this step because..."
SKILL

# ─────────────────────────────────────────────────────────
# 16. paper-reviewer
# ─────────────────────────────────────────────────────────
install_skill "paper-reviewer" <<'SKILL'
---
name: paper-reviewer
description: >
  Expert reviewer for theoretical and statistical ML manuscripts. Produces structured
  referee reports matching senior associate editor rigor. Trigger on: 'review', 'critique',
  'assess', 'give feedback on' a manuscript/paper/draft. Also trigger for response to
  reviewers and revision planning. Do NOT trigger for code review or casual proofreading.
---

# Paper Reviewer

Expert reviewer for theoretical and statistical ML manuscripts. Produces structured,
actionable referee reports matching senior associate editor or R2-level reviewer rigor.

## Philosophy

1. **"So What?"** — Findings must connect to insight
2. **Methodological honesty** — Justify sophistication
3. **Narrative coherence** — Paper is an argument, not a catalogue

## Reference Library

- `references/evaluation-framework.md`
- `references/proof-verification.md`
- `references/causal-inference-proofs.md`
- `references/mixing-dependence-toolkit.md`

## Severity Levels

| Level | Meaning | Journal Action |
|-------|---------|----------------|
| 🔴 Fatal | Invalidates core claims | Major revision / Reject |
| 🟠 Major | Substantially weakens contribution | Major revision |
| 🟡 Moderate | Unclear or incomplete | Minor revision |
| 🔵 Minor | Presentation fixes | Minor revision |

## Six Diagnostic Lenses

1. The "So What?" Test
2. Methodological Justification
3. Internal Consistency
4. Narrative Architecture
5. Statistical Rigor
6. Presentation Quality

## Domain Calibration

- *JMLR/NeurIPS:* Novelty, theoretical contribution, computational experiments
- *Annals of Statistics/Biometrika:* Mathematical rigor, asymptotic analysis
- *JFDS/JFE:* Economic interpretation, practical relevance
- *JASA:* Balance methodology and application

## Workflow

### Step 1: First Pass — Architecture

Map: research questions → hypotheses → experiments → claimed conclusions.
Flag broken links in this chain.

### Step 2: Second Pass — Technical Audit

Evaluate methodology, statistical validity, reproducibility against
evaluation-framework.md.

### Step 3: Third Pass — Interpretation Gap Analysis

For each key result (table, figure, theorem): does the paper explain
*what it means*, not just *what it is*?

### Step 4: Synthesize

Produce the report. Classify issues by severity and priority.
SKILL

# ─────────────────────────────────────────────────────────
# 17. status-dashboard
# ─────────────────────────────────────────────────────────
install_skill "status-dashboard" <<'SKILL'
---
name: status-dashboard
description: >
  Quick, actionable overview of the entire research programme. Scans governance docs,
  extracts deadlines/claims/todos/threats, produces a concise dashboard. Trigger on:
  'what should I work on', 'programme status', 'status update', 'what is next across
  all tracks', 'weekly check-in'. Read-only — does not modify governance files.
---

# Status Dashboard

Quick, actionable overview of the entire research programme. Scans governance docs,
extracts deadlines/claims/todos/threats, produces a concise dashboard, saves to
`reports/`, and optionally emails it.

## Workflow

### Step 1: Read Governance Files

1. `CLAIMS_LIBRARY.md` — Claim ID, status, scoop vulnerability, last reviewed, days since review
2. `submission/SUBMISSION_CALENDAR.md` — Deadlines flagged URGENT (≤14 days) or UPCOMING (≤30 days)
3. `docs/plans/*.md` — Unchecked `[ ]` items
4. `track_*/README.md` — Unchecked/completed todos, claims table rows
5. Latest `literature_scan_session*_synthesis.md` — Threats, priority reading, scoop updates

### Step 2: Build Dashboard

5 sections:
1. **DEADLINES** — Sorted by urgency
2. **CLAIMS STATUS** — Flag STALE if >30 days since review
3. **ACTION ITEMS** — Unchecked items across all plans
4. **THREAT ALERTS** — From literature scans
5. **DO THIS WEEK** — Top 5 priorities by impact × urgency

### Step 3: Save Report

Write to `reports/status_{YYYY-MM-DD}.md`

### Step 4: Display to User

### Step 5: Send Email (optional)

```bash
python3 scripts/send_email.py "reports/status_{YYYY-MM-DD}.md"
```

## Important

- **READ-ONLY** — do not modify governance files
- Keep concise — no section exceeds 20 lines
- Skip missing files silently
- Always show dashboard even if email fails
SKILL

# ─────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════════════"
echo "  Skills installation complete"
echo "  Created: $CREATED"
echo "  Skipped: $SKIPPED (already existed)"
echo "  Total:   $((CREATED + SKIPPED))"
echo "════════════════════════════════════════════════"
echo ""
echo "Verify with:"
echo "  find ~/.claude/skills/ -name 'SKILL.md' | wc -l"
echo "  find ~/.claude/skills/ -name 'SKILL.md' | sort"
