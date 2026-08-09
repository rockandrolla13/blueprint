# Blueprint Architecture Q&A

## 1. Top 3 Workflows

**W2 Refactor** — `review-arch → code-review → refactoring-plan → refactor`
Bread-and-butter. User has working code, structure is painful, needs disciplined cleanup.
Every WORKFLOWS.md decision path funnels here unless building new.

**W1 Build** — `ideate → architect → design → scaffold`
Greenfield. Full chain exercises every build skill. Wrong decomposition at architect
stage costs the most downstream — this is where gate-before-code matters most.

**W4 Extend** — `architect → design → scaffold` (into existing code)
"Add a feature." Most frequent real-world task. Good boundaries mean 1 new file;
bad boundaries mean shotgun surgery.

Everything else is derivative:
- W0 = review-arch + code-review, then route to W2/W3/W4 (no plan, no code)
- W3 = W2 + architect/design before refactoring
- W5 = ideate only, exits into W1/W3/W4
- W6 = rare, gated against impatience

## 2. Non-Goals

| Non-goal | Why |
|---|---|
| **Runtime execution.** Blueprint does not run code, manage processes, or orchestrate deployments. It produces instructions, not automation. | Conflating instruction with execution makes skills untestable and environment-dependent. |
| **Framework/infrastructure prescription.** Blueprint prescribes conventions (pytest, Protocol, Pydantic), not frameworks. Convention choices are defaults overridable at the design gate. Framework and infrastructure choices belong to the user's project, not to Blueprint. | Convention defaults reduce decision fatigue without creating brittleness. The design gate is where project-specific overrides are surfaced and approved. |
| **Replacing human judgement.** Gates exist because Claude should NOT make decomposition/design decisions unilaterally. | Value is structured collaboration, not autonomous generation. |
| **Covering non-Python codebases.** shared-principles.md is Python-specific (pytest, click, dataclasses vs Pydantic). | Language-agnosticism would dilute conventions to uselessness. Better to be opinionated for one ecosystem. |
| **Research workflow integration.** Research skills (paper-scout, idea-refiner, literature-mapper) are installed alongside but are NOT part of blueprint. | Different domain, different contracts, different users. Co-location ≠ integration. |
| **CI/CD, linting, deployment.** Blueprint stops at "code is structured correctly." | Post-structure concerns belong to project-specific tooling. |

## 3. Skill Contracts

### The Gap

**RESOLVED.** This section recorded that no contract was written in blueprint itself
and called it the #1 fragility. All 14 skills now carry a `## Contract (BCS-1.0)`
block declaring Mode, Consumes, Produces, Degrees of Freedom, and Downstream
Consumers. `tools/registry_check.py --check` fails if any skill loses it.

**The failure mode that replaced it.** A downstream edge is *declared by the sender*
and *enforced by the receiver*, so a one-sided declaration always looks correct and
never runs. Three were found in one audit: `review-depth` named `refactoring-plan` as
its consumer while `refactoring-plan` admitted only `CR-*` and `AR-*` and would have
halted; `review-depth` claimed `architect`, which enumerates three entry points and
does not include it; `design`'s description invited direct entry from ideation while
its contract required an `architect` Handoff.

**Rule:** before adding a name to `### Downstream Consumers`, open that skill's
`### Consumes` and confirm it accepts what you emit. If it does not, either change the
receiver or write the edge as explicitly NOT a consumer. `compat-audit` finds these.

---

### ideate → architect

| Section | Status | Why |
|---|---|---|
| `## Decision Summary` | **MUST** | architect expects "a chosen approach from ideation" |
| `Chosen approach` (1 sentence) | **MUST** | becomes input problem for decomposition |
| `Load-bearing assumptions` | **MUST** | architect needs these to draw boundaries around what might change |
| `Key trade-off accepted` | OPTIONAL | useful context, not structurally required |
| `First thing to build` | OPTIONAL | can inform design priority |
| Comparison matrix (Mode A) | FORBIDDEN downstream | leaking this re-opens decisions that should be closed |

**Format:** Section header `## Decision Summary` must be literal. Bullet labels must
match (`Chosen approach:`, `Load-bearing assumptions:`). Phrasing within bullets is free.

---

### architect → design

| Section | Status | Why |
|---|---|---|
| Domain model (Mermaid diagram) | **MUST** | design Phase 2.1: "becomes the basis for the dependency graph" |
| Module decomposition table | **MUST** | design Phase 1.3: "becomes the component enumeration" |
| Abstraction decisions (function/class/protocol per piece) | **MUST** | design Phase 3.1: "becomes the interface definitions" |
| Rate-of-change map | **MUST** | design uses for extensibility assessment |
| Dependency direction verification | **MUST** | design Phase 2.1 checks DAG property |
| Cross-cutting concerns | OPTIONAL | design has its own Phase 3.3 |
| Boundary conflict resolution rationale | FORBIDDEN downstream | design must not re-litigate boundary decisions |

**Format:** Module table columns must include: Module, Responsibility, Knows About,
Doesn't Know About, Changes When. Mermaid diagram format is fixed. Abstraction labels
must use architect's vocabulary: Module/Package/Class/Protocol/Function/Dataclass/Config.

---

### design → scaffold

| Section | Status | Why |
|---|---|---|
| File structure (tree format) | **MUST** | scaffold generates these exact files |
| Protocol definitions (Python code) | **MUST** | scaffold copies into `core/protocols.py` |
| Config design (Pydantic model) | **MUST** | scaffold generates `core/types.py` from this |
| Dependency graph (Mermaid) | OPTIONAL | scaffold doesn't use directly — for humans |
| Data flow with schemas | OPTIONAL | useful but scaffold works from file structure + protocols |
| Testing strategy | OPTIONAL | scaffold includes smoke tests regardless |

**Format:** File structure must use exact tree format (`├──` / `└──`). Protocol code
must be valid Python. Config must use Pydantic `BaseModel`. Scaffold copies verbatim.

---

### review-architecture → refactoring-plan

| Section | Status | Why |
|---|---|---|
| `## Scorecard` (Dimension / Score / Key Finding table) | **MUST** | plan reproduces as baseline; Phase 5 uses for before/after |
| Detailed findings with severity + dimension + location | **MUST** | plan deduplicates and scores these |
| Dependency graph | OPTIONAL | useful context, plan doesn't structurally depend on it |
| Positive highlights | FORBIDDEN in plan input | plan only consumes problems; strengths dilute priority scoring |

**Format:** Scorecard must use emoji scale (🟢🟡🟠🔴). Findings must have `Severity`,
`Dimension`, and `Location` fields — plan's deduplication keys on these.

---

### code-review → refactoring-plan

| Section | Status | Why |
|---|---|---|
| `## Summary Table` (Severity / Pillar / Location / Finding) | **MUST** | plan merges with arch-review findings |
| Individual findings with `Severity` + `Location` | **MUST** | keyed for deduplication against arch-review |
| BEFORE/AFTER snippets | FORBIDDEN in plan input | plan works at structural level, not code level |

---

### refactoring-plan → refactor / plan-tracker

| Section | Status | Why |
|---|---|---|
| Phased steps with ordering | **MUST** | refactor executes in this order; plan-tracker creates status table |
| Per-step: Finding ID, scope, risk level | **MUST** | plan-tracker maps to PENDING rows |
| Per-step: "What changes" + "What doesn't change" | **MUST** | refactor uses as work specification |
| Per-step: "Verification" checklist | **MUST** | refactor runs after each step |
| Per-step: "Depends on" / "Blocks" | **MUST** | plan-tracker uses for dependency tracking |
| Dependency DAG (Mermaid) | OPTIONAL | visual aid; plan-tracker uses per-step fields instead |
| Expected Outcome scorecard (before/after) | OPTIONAL | plan-tracker uses for verification if present |

**Format:** Phase numbering: sequential integers. Step numbering: `N.M` (phase.step).
Status labels exactly: `PENDING`, `IN PROGRESS`, `DONE`, `FAILED`, `SKIPPED`, `BLOCKED`.
Scope vocabulary: single-function / single-module / multi-module / cross-cutting.

---

### spec-interview → architect

| Section | Status | Why |
|---|---|---|
| `## Handoff` | **MUST** | entry point into the build chain |
| `Chosen approach:` (1 sentence) | **MUST** | deliberately the same literal label `ideate` emits, so `architect` accepts it via its existing ideate entry point with no contract change |
| `Load-bearing assumptions:` | **MUST** | each marked `confirmed` or `unverified` |
| `Refined document:` | **MUST** | absolute path to the sharpened copy |
| `Open questions:` | **MUST** | or the literal `none` — unanswered questions must never vanish |
| Module names, protocols, file structure | FORBIDDEN | that is `architect` and `design`; this skill produces prose |

**Not a direct producer for `design` or `scaffold`.** `design` requires an `architect`
Handoff. Route `spec-interview → architect → design`.

---

### review-depth → refactoring-plan

| Section | Status | Why |
|---|---|---|
| `## Handoff` with `DM-*` Finding IDs | **MUST** | `refactoring-plan` admits `DM-*` alongside `CR-*`, `AR-*`, `CA-*` |
| Module census table | **MUST** | Module / Interface Size / Impl Depth / Depth Ratio / Rating |
| Depth scorecard | **MUST** | 5 dimensions, 🟢🟡🟠🔴 |

**Deduplication.** `AR-*` and `DM-*` can describe one problem through two lenses —
`AR-ABS`/`DM-PASS` for a one-implementation abstraction, `AR-BND`/`DM-LEAK` for an
exposed mutable internal. `refactoring-plan` merges these into one step listing both IDs.

**Not a producer for `architect`.** It claimed to be; `architect` never accepted it.

---

### compat-audit → refactoring-plan

| Section | Status | Why |
|---|---|---|
| `## Handoff` with `CA-*` Finding IDs | **MUST** | types: TRIG, CONT, DUP, GAP |
| Verdict matrix | **MUST** | one verdict per deep-dived pair; `—` for pairs not examined |
| Verdicts for pairs not deep-dived | FORBIDDEN | an unexamined pair has no verdict |

`CA-*` findings are registry and instruction defects, not code defects. They never
co-locate with the code-level IDs, so they are planned as their own phase and verified
by re-running the audit rather than by the test suite.

---

### navigator → nothing

Terminal, in the same sense as `scaffold`. Answers conversationally, emits no artifact
and no Handoff. Verified against all 13 other skills' `### Consumes` blocks: nothing
accepts navigator output.

Note the `## Handoff` heading at `navigator/SKILL.md:138` is **not** a BCS-1.0 Handoff —
it is a session-exit instruction handing the *user* to an action skill. A tool grepping
for `## Handoff` will wrongly conclude navigator produces one.

---

## 4. Unit of Value

A **checkpoint gate**. Everything else exists to earn the right to place that gate
at the right moment. The gate converts Claude from a code generator into a collaborator
that can be corrected before mistakes compound.

Secondary: the **shared-principles.md reference pattern**. One file, all skills inherit.
Update once, propagate everywhere.

---

## 5. Checkpoint Gate Protocol

### What counts as approval?

**Currently: freeform.** Skills use phrases like "Does this look right?" and "Want me
to proceed?" — the user can say "yes", "looks good", "approved", "go ahead", or anything
affirmative. There is no structured token like `APPROVED: DESIGN v1`.

**Current state is correct for the problem.** Structured approval tokens create friction
without adding safety — the gate's value is the *pause*, not the token format. The user
reads the output, forms an opinion, and responds. Forcing a specific format makes the
interaction feel robotic without preventing mistakes.

**If you ever need machine-checkable approval** (e.g., orch integration), then introduce
a structured format. Until then, freeform is the right choice.

### Can the user partially approve?

**Yes, implicitly.** Users naturally say things like "boundaries look right but rethink
the data model" or "approve the plan but swap steps 3 and 4." Skills handle this by
iterating on the rejected parts while preserving the approved parts.

**No skill currently tracks which parts are approved.** This means after a partial
approval + revision, the full output is re-presented. For small outputs this is fine.
For large architect outputs (domain model + module table + abstraction decisions +
dependency direction + cross-cutting concerns), re-presenting everything after changing
one table is noisy.

**Recommendation:** For architect and design (the largest outputs), acknowledge partial
approval explicitly: "Boundaries approved. Revising data model only. Other sections
unchanged." This prevents the user from re-reading 200 lines they already approved.

### What happens on refusal?

**Currently underspecified.** Skills say "Do NOT proceed until the user approves" and
"If they push back, iterate on the design" — but don't define the iteration protocol.

**What should happen (three branches):**

| User says | Skill should |
|---|---|
| "No, because X is wrong" | Revise the specific section, re-present only the changed parts |
| "I'm not sure, what about Y?" | Present Y as an alternative, compare trade-offs, ask again |
| "Back up, I need to rethink the approach" | Acknowledge, suggest re-running the upstream skill (e.g., re-ideate) |

**Currently, skills do the right thing accidentally** — Claude naturally iterates. But
there's no guarantee a future skill edit preserves this behaviour. The refusal protocol
should be explicit in the skill body.

### How do you prevent gate leakage?

**Gate leakage = Claude emitting code while still in design/plan mode.**

Current defence: skills explicitly say "Do NOT write implementation code until the user
approves." This is a single sentence buried in each skill. It works because Claude follows
instructions, but it's fragile — a long conversation can push the instruction out of
effective context.

**Stronger defences (not currently implemented):**

1. **Mode tag:** Skills could set a mental mode: `MODE: DESIGN (no code output)`. The
   scaffold/refactor skills would then explicitly transition: `MODE: IMPLEMENTATION`.
2. **Output format constraint:** Design skill could state: "All code in this phase is
   illustrative Protocol definitions only. No function bodies. No implementation logic."
3. **Self-check:** Before any code block, the skill could require: "Verify: has the user
   approved the design? If not, stop."

The current single-sentence defence is adequate for now. If gate leakage becomes a
real problem, implement defence #2 first — it's the lightest touch.

### Are gates consistent across skills?

**Mostly yes, with variation in language.**

| Skill | Gate location | Gate language |
|---|---|---|
| ideate | End (Decision Summary) | Implicit — presents summary, waits for user to choose |
| architect | Phase 4 | "Does this decomposition feel right? ... Do NOT proceed until the user approves." |
| design | Phase 5 | "Does this design look right? ... Do NOT write implementation code until the user approves." |
| scaffold | Step 3 | "present it for review before writing files" |
| refactor | Phase 3.3 | "Here's the refactoring plan. Does this match what you want improved?" |
| refactoring-plan | (inherits from plan-tracker) | Plan file created, then "Ready to begin execution?" |
| plan-tracker | Mode 1 end | "Plan created at PLAN-<name>.md. Ready to begin execution?" |
| review-architecture | None needed | Read-only diagnostic, no downstream action to gate |
| code-review | None needed | Read-only diagnostic, no downstream action to gate |

**Inconsistencies:**
- ideate's gate is implicit (no "STOP" / "Do NOT proceed" language)
- scaffold's gate is weaker ("present for review") vs design's ("Do NOT write")
- review skills have no gates because they're read-only — correct

**Recommendation:** Standardise gate language to: `**STOP.** Present [output]. Ask:
"[question]?" Do NOT proceed until the user approves.` — This pattern already exists
in architect and design. Apply it to scaffold and make ideate's gate explicit.

---

## 6. Markdown-to-Markdown Type System

### Canonical section headers

These exact strings matter if skills are ever chained programmatically:

| Skill | Required output headers |
|---|---|
| ideate | `## Decision Summary` |
| architect | `## Phase 1: Domain Mapping`, `## Phase 2: Boundary Drawing`, `## Phase 3: Abstraction Decisions`, `## Phase 4: Architecture Review Checkpoint` |
| design | `## Phase 1: Problem Framing`, `## Phase 2: Architecture`, `## Phase 3: Interface Design`, `## Phase 4: File Structure`, `## Phase 5: Design Review Checkpoint` |
| scaffold | (generates files, not sections) |
| refactor | `## Refactoring Summary` |
| review-architecture | `## Codebase Summary`, `## Scorecard`, `## Dependency Graph`, `## Detailed Findings`, `## Positive Highlights` |
| code-review | `## Executive Summary`, `## Findings`, `## Summary Table`, `## Positive Highlights` |
| refactoring-plan | `## Executive Summary`, `## Dependency Graph`, `## Parallel Tracks`, phases as `## Phase N:`, `## Expected Outcome`, `## What This Plan Does NOT Address` |
| plan-tracker | `## Objective`, `## Pre-Execution Snapshot`, `## Phases`, `## Verification Criteria`, `## Execution Log` |

### Minimal viable output (thin input)

| Skill | Minimum output |
|---|---|
| ideate | Decision Summary with chosen approach + 2 load-bearing assumptions |
| architect | Module table (3 rows minimum) + dependency direction check |
| design | Component list + dependency graph + 1 Protocol definition + file structure |
| review-architecture | Scorecard (7 rows) + 3 findings + 1 positive highlight |
| code-review | Executive Summary + 2 findings + Summary Table |
| refactoring-plan | 1 phase with 2 steps, each with scope/risk/verification |
| plan-tracker | Objective + 1 phase table + verification criteria |

### Forbidden sections (by skill)

| Skill | Forbidden output | Why |
|---|---|---|
| ideate | Implementation code | Ideation explores approaches, doesn't implement |
| architect | Protocol/class definitions (Python code) | Architect decides *what*, design decides *how* |
| design | Function bodies, implementation logic | Design defines interfaces, scaffold/refactor implements |
| review-architecture | Code changes, refactoring suggestions | Read-only diagnostic; refactoring-plan handles action |
| code-review | Patches, diffs, replacement files | Feedback only; refactor handles changes |
| refactoring-plan | Code changes | Plan, don't execute |
| scaffold | Architecture rationale | Scaffold stamps out approved design, doesn't re-justify |

### Contract versioning

**Currently: no versioning mechanism.** If you change architect's output template,
downstream skills (design) silently break.

**Options (increasing formality):**
1. **Comment-based:** Add `<!-- contract-version: 1 -->` to each skill's output template.
   Downstream skills check for the version they expect.
2. **CLAUDE.md registry:** Maintain a contract version table in CLAUDE.md. Any skill edit
   that changes MUST/FORBIDDEN sections requires incrementing the version.
3. **Automated check:** A validation script that parses all SKILL.md files, extracts
   required output headers, and verifies downstream skills reference headers that exist
   upstream.

**Recommendation:** Option 2. It's lightweight, lives in the governance doc, and is
checkable during manual review. Option 3 is premature — blueprint has no automation
layer yet.

---

## 7. Triggering and Invocation Reliability

### Accidental invocation

**Yes, it happens.** Natural language triggers are fuzzy. "build this" triggers design
but could plausibly trigger scaffold. "review this" triggers code-review but could
trigger review-architecture.

**Current defence:** Negative triggers in frontmatter ("Do NOT trigger for..."). Every
skill lists sibling skills to exclude. This is the right approach — it works with
Claude's instruction-following rather than against it.

### Slash commands vs natural language

**Both should remain.** Slash commands (`/architect`) give precise control. Natural
language triggers catch users who don't know the skill names. These aren't in tension.

**The failure mode isn't "wrong skill triggered" — it's "no skill triggered."** Skills
are deliberately pushy in their trigger descriptions (CLAUDE.md: "Descriptions are
deliberately pushy to combat undertriggering"). Undertriggering is worse than
overtriggering because the user doesn't know what they missed.

### Collision with other installed skills

**Real risk.** `~/.claude/skills/` contains 17 skills from multiple sources. Collisions:

| Phrase | Could trigger | Should trigger |
|---|---|---|
| "review this" | code-review, paper-reviewer, core-reviewer | Depends on context (code vs manuscript) |
| "what are my options" | ideate, skills-help | ideate |
| "help me think through" | ideate, core-reviewer | Depends on context (design vs proof) |

**Current mitigation:** Domain-specific negative triggers. paper-reviewer says "Do NOT
trigger for general writing feedback." code-review says "Do NOT trigger for paper/
manuscript review." This works when the domain is clear. Ambiguous prompts still collide.

**Recommendation:** Don't add a router. Instead, sharpen negative triggers on the
research skills to exclude software engineering contexts, and vice versa. The skills-help
skill already serves as a disambiguation mechanism.

### Guard phrases

Not currently implemented. If misfires become frequent, add guard phrases like:
- code-review: only trigger if user references `.py` files, `src/`, or code
- paper-reviewer: only trigger if user references manuscript, paper, draft, PDF
- ideate vs core-reviewer: ideate triggers on "options/approaches", core-reviewer
  triggers on "proof/verify/check reasoning"

---

## 8. Refactor Safety

### Defining "no behaviour change"

**Currently: "tests pass after every single step."** (refactor/SKILL.md Phase 4.1)

This is necessary but insufficient. Tests passing means *tested* behaviour is preserved.
Untested behaviour can silently change.

**Full definition should be:**
1. All existing tests pass (non-negotiable)
2. No public interface changes (function signatures, class APIs) without explicit
   user acknowledgment
3. No change to observable outputs for the same inputs
4. Performance changes are flagged but allowed (see below)

### What if there are no tests?

**Currently unaddressed.** refactor/SKILL.md assumes tests exist ("Run existing tests —
they must pass"). It doesn't handle the no-tests case.

**Recommendation:** Add to refactor Phase 1.1: "If no tests exist, scaffold
characterization tests first. These capture current behaviour as assertions. Then
refactor against those assertions. This is a prerequisite, not an optional step."

**Without characterization tests, refactoring is rewriting with plausible deniability.**

### Risk escalation

**Currently implicit.** refactor/SKILL.md Phase 3.2 has "Risk: what could go wrong" per
step but doesn't define when to refuse.

**Recommendation:** Add an explicit escalation rule: "If a refactoring step has Risk
level High AND no tests cover the affected code path, STOP. Present three options:
(1) write characterization tests first, (2) skip this step, (3) proceed with explicit
user acknowledgment of risk."

### Performance-sensitive code

**Not addressed.** Refactoring can change performance characteristics (e.g., extracting
a function adds call overhead; changing data structures changes cache behaviour).

**Recommendation:** Add to refactor/SKILL.md: "Performance changes are allowed during
refactoring but must be flagged. If the code is in a hot path (loop body, per-tick
computation), note: 'This change may affect performance. Benchmark before and after
if this is latency-sensitive.'"

---

## 9. Plan-Tracker as Execution Engine

### Human-only or machine-checkable?

**Currently human-readable, partially machine-checkable.** The status table uses a
fixed enum (`PENDING`/`DONE`/`FAILED`/etc.) which is parseable. The Execution Log is
freeform text which is not.

**To make it fully machine-checkable, enforce:**
1. Status values from the exact enum (already done)
2. Step IDs in `N.M` format (already done)
3. Verification criteria as checkboxes `- [ ]` / `- [x]` (already done)
4. Execution Log entries with ISO timestamps (not enforced — should be)

### Minimum viable status fields

| Field | Required? | Why |
|---|---|---|
| Step ID (`N.M`) | Yes | Ordering and dependency tracking |
| Description | Yes | What the step does |
| Status (enum) | Yes | Progress tracking |
| Notes | Yes (can be empty) | Failure reasons, skip justifications |
| Depends on | Yes (can be "None") | Dependency resolution |
| Verification | Yes (per phase) | Completion criteria |

**Not needed:** Owner (single-user system), timestamps on individual steps (Execution
Log covers this), priority score (that belongs to refactoring-plan, not plan-tracker).

### Objective verification

**What plan-tracker can verify today:**
- All steps have terminal status (DONE/SKIPPED) — binary check
- Verification checkboxes are checked — binary check
- Pre/post snapshot comparison (file count, line count, test status) — objective

**What it cannot verify:**
- "Code quality improved" — subjective
- "Architecture score improved" — requires re-running review-architecture
- "No behaviour changed" — requires running tests (which it can trigger)

**Recommendation:** plan-tracker Mode 3 should explicitly run `pytest` (or equivalent)
as a verification step, not just report test status. Currently it says "capture test
status" but doesn't say "run the tests."

### Preventing plan fiction

**Plans drift from reality when:**
1. Steps are marked DONE but the actual change wasn't made
2. New work happens outside the plan (ad-hoc changes between steps)
3. The plan was written for a codebase state that has since changed

**Current defence:** Execution Log (append-only) and pre/post snapshots. These help
but don't prevent fiction.

**Stronger defences:**
1. **Git-anchored steps:** Each DONE step records the commit hash. Verification can
   check that the commit exists and touches the expected files.
2. **Drift detection:** Before starting a step, verify the files it targets haven't
   changed since the previous step completed. If they have, flag it.
3. **Snapshot refresh:** At the start of each phase (not just pre-execution), re-capture
   file count / line count. Compare to expected state.

**Recommendation:** Implement #1 (commit hash per step). It's lightweight, objective,
and makes plans auditable. #2 and #3 are valuable but require more infrastructure.
