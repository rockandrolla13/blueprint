---
name: review-architecture
description: >
  Evaluate the architecture and structural decomposition of an existing codebase against
  principled design heuristics — boundary quality, dependency direction, abstraction fitness,
  rate-of-change alignment, and extensibility. Produces a scored diagnostic report with specific
  findings and evidence. Use this skill when the user says "review the architecture", "is this
  well-structured", "audit the structure", "evaluate the design", "does this decomposition make
  sense", "architecture review", "structural review", or shows an existing project and asks if
  the design is sound. Also trigger when the user says "this grew organically, is it still sane"
  or "before I build more, check the foundations". This complements the code-review skill — that
  skill reviews individual files for Clean Code compliance, this skill reviews the system-level
  structure. Do NOT trigger for file-level code review (use code-review), refactoring execution
  (use refactor), or new system design (use architect + design).
---

# Architecture Review Skill

You are operating as a Systems Auditor. Your job is to evaluate whether an existing codebase's
structure is sound — whether the boundaries are in the right places, the dependencies point
the right direction, and the abstractions fit the domain. This is a read-only diagnostic.
You produce findings and scores. You do not change code.

Before starting, read the shared engineering principles:
→ **Read**: `shared-principles.md` (sibling to this skill directory)

## Workflow

### Step 1: Ingest the Codebase

**The map is not the territory.** Your mental model of the codebase is not the codebase.
Read the actual code — trace imports, check what functions actually do, verify assumptions
against reality. Do not review your idea of the architecture; review the architecture as it
exists in the files.

Read the project structure and understand what exists:

1. **Directory tree** — list the full file/directory layout
2. **Module map** — for each `.py` file, read imports and public API (classes, functions, constants)
3. **Entry points** — identify CLI commands, scripts, or main functions
4. **Tests** — catalogue existing test coverage
5. **Configuration** — how is the system configured?

Produce a **Codebase Summary** (1 paragraph) that describes what the system does and how
it's currently structured. This proves you understand it before critiquing it.

### Step 2: Evaluate Against Dimensions

Score each dimension on a 4-point scale:

| Score | Meaning |
|---|---|
| 🟢 **Strong** | Follows principles well; minor issues at most |
| 🟡 **Adequate** | Functional but has identifiable structural weaknesses |
| 🟠 **Weak** | Significant structural issues that impede maintainability or extensibility |
| 🔴 **Critical** | Fundamental structural problems; adding features will compound debt |

---

#### Dimension 1: Boundary Quality

Evaluate whether module boundaries align with domain concepts and rates of change.

**What to check:**
- Does each module have a clear, single responsibility expressible in one sentence?
- Do module names reflect domain concepts (good: `strategy/carry.py`) or technical roles
  (smell: `services/`, `helpers/`, `utils/`)?
- Do things that change together live together? Do things that change independently live apart?
- Are there modules that seem to bundle unrelated concepts?

**Evidence format:**
```
Finding: data/loader.py mixes CSV parsing, API fetching, and data validation
Principle violated: Single Responsibility / Rate-of-change alignment
Impact: Changing the API client risks breaking CSV parsing; can't test validation independently
Score contribution: 🟠
```

**Rate-of-change analysis:**
For each module, classify: static / slow / fast / structural change rate. Flag misalignments
where modules bundle concepts with different change rates.

---

#### Dimension 2: Dependency Direction

Evaluate whether dependencies follow the Dependency Inversion Principle — domain logic
depends on abstractions, not infrastructure.

**What to check:**
- Map the actual import graph across modules
- Do domain/strategy modules import from data/infrastructure modules directly?
- Are there protocols/interfaces at the critical boundaries?
- Is the dependency graph a DAG? Flag any circular imports.
- Count the fan-in (dependents) and fan-out (dependencies) for each module. High fan-out
  (>5 imports from other project modules) suggests a module that knows too much.

**Evidence format:**
```
Finding: strategy/carry.py imports directly from data/bloomberg.py (line 3)
Principle violated: Dependency Inversion
Impact: Cannot test carry signal without Bloomberg connection; cannot swap data source
Score contribution: 🟠
```

**Produce a dependency graph** (Mermaid) of the actual imports. Annotate edges that violate
dependency direction with ⚠️.

---

#### Dimension 3: Abstraction Fitness

Evaluate whether the right abstraction level is used for each concept.

**What to check:**
- Are there classes that should be functions? (Classes with no state, single method, or only
  `__init__` + one method → probably a function)
- Are there functions that should be classes? (Functions with >3 parameters that are always
  passed together → state waiting to be a class)
- Are there missing protocols? (Multiple classes with the same method signatures but no
  shared protocol → implicit interface that should be explicit)
- Are there premature abstractions? (ABCs or protocols with exactly one implementation)
- Are there god classes? (Classes with >10 methods or >5 responsibilities)
- Are dataclasses vs Pydantic used appropriately? (Pydantic for serialisation boundaries,
  dataclasses for internal state)

**Evidence format:**
```
Finding: SignalGenerator ABC in core/base.py has exactly one subclass (CarrySignal)
Principle violated: Premature abstraction (YAGNI)
Impact: Extra indirection with no current benefit; creates maintenance overhead
Recommendation: Delete ABC, use CarrySignal directly, extract protocol when second signal appears
Score contribution: 🟡
```

---

#### Dimension 4: DRY & Knowledge Duplication

Evaluate whether knowledge is appropriately centralised.

**What to check:**
- Scan for duplicated logic (same business rule in multiple places)
- Distinguish knowledge duplication (bad) from structural similarity (often fine)
- Check for the inverse problem: premature DRY that couples unrelated concepts
- Look for magic numbers, hardcoded strings, or configuration scattered in code
- Check for `utils.py` / `helpers.py` / `common.py` dumping grounds

**Evidence format:**
```
Finding: Z-spread calculation appears in both strategy/carry.py:45 and risk/model.py:112
Type: Knowledge duplication (same business rule, same formula)
Impact: Divergence risk — if the formula changes, both must be updated
Recommendation: Extract to core/bond_math.py
Score contribution: 🟠
```

---

#### Dimension 5: Extensibility

Evaluate how easy it is to add the most likely new features.

**What to check:**
- Identify the 2–3 most likely extensions (new strategy, new data source, new output format)
- For each: trace what files would need to change. Count them.
  - 1 file = 🟢 (well-isolated extension point)
  - 2–3 files = 🟡 (acceptable coupling)
  - 4+ files = 🟠 (shotgun surgery)
  - Requires modifying existing logic (not just adding new) = 🔴 (violates Open/Closed)
- Check for hardcoded type checks (`isinstance`, `if type == "carry"`) that would need
  updating for each new variant

**Evidence format:**
```
Extension scenario: Add a new "momentum" signal
Files to change: strategy/__init__.py (register), config/default.yaml (add params),
  execution/cli.py (add CLI option), strategy/momentum.py (new file)
Verdict: 3 existing files + 1 new = 🟡 Adequate
Improvement: Registry pattern would reduce to 1 existing file + 1 new
```

---

#### Dimension 6: Testability

Evaluate whether the structure supports effective testing.

**What to check:**
- Can each module be unit tested by mocking only its direct dependencies?
- Are there modules that require >3 mocks to test? (Smell: depends on too much)
- Is there a clear separation between pure logic (easy to test) and I/O (needs mocking)?
- Do integration tests exist at module boundaries?
- For numerical/quant code: are edge cases tested? (Empty inputs, singular matrices,
  NaN handling, boundary conditions)

**Evidence format:**
```
Finding: pipeline.py:run() requires mock of DataSource, SignalGenerator, RiskModel,
  ExecutionEngine, Logger, and ConfigLoader to unit test
Principle violated: Excessive coupling
Impact: Tests are fragile and expensive to write; function is effectively untestable in isolation
Score contribution: 🔴
```

---

#### Dimension 7: Parallelisation Readiness

Evaluate whether the structure supports concurrent execution where appropriate.

**What to check:**
- Are there loops over independent items (instruments, dates, files) that could be parallelised?
- Is shared mutable state isolated or scattered?
- Are pure functions clearly separated from stateful operations?
- If parallelisation is already implemented: is it correct? (Thread safety, no race conditions,
  proper error handling in workers)

**Evidence format:**
```
Finding: strategy/carry.py:compute_all() iterates over 500 bonds sequentially;
  each computation is independent (no shared state)
Opportunity: Embarrassingly parallel — concurrent.futures.ProcessPoolExecutor
Estimated speedup: ~Nx on N cores for CPU-bound signal computation
Score contribution: 🟡 (not a problem, but a missed opportunity)
```

## Step 3: Produce the Report

Generate the report as a Markdown file at `reviews/YYYY_mm_dd_architecture_review.md`
(relative to repository root). Follow the versioning convention: use Glob to check for
existing files with the same date and scope; if matches exist, increment the version suffix.

### Report Template

Every finding MUST include a Finding ID as the first element.
Format: `AR-<DIM>-<NNN>`
DIM is one of: BND, DEP, DRY, EXT, TST, ABS, PAR
NNN is zero-padded sequential starting at 001.

```markdown
# Architecture Review Report

**Project:** [name]
**Date:** [date]
**Files reviewed:** [count]
**Overall health:** [🟢 | 🟡 | 🟠 | 🔴]

## Codebase Summary

[1 paragraph: what the system does, how it's structured, entry points]

## Scorecard

| Dimension | Score | Key Finding |
|---|---|---|
| Boundary Quality | 🟡 | Data module mixes I/O and validation |
| Dependency Direction | 🟠 | Strategy imports infrastructure directly |
| Abstraction Fitness | 🟢 | Appropriate use of protocols and dataclasses |
| DRY & Knowledge | 🟡 | Z-spread duplicated in two modules |
| Extensibility | 🟠 | Adding a new strategy requires 4 file changes |
| Testability | 🟡 | Core logic testable; pipeline function too coupled |
| Parallelisation | 🟡 | Sequential loops over independent items |

**Overall: 🟡 Adequate — functional but structural investment needed before scaling**

## Dependency Graph

[Mermaid diagram with ⚠️ annotations on violating edges]

## Detailed Findings

[Ordered by severity: 🔴 → 🟠 → 🟡 → 🟢]

### AR-DEP-001: [title]
- **Finding ID:** AR-DEP-001
- **Dimension:** [which]
- **Severity:** [score]
- **Location:** [files and lines]
- **Principle violated:** [specific principle]
- **Evidence:** [what you observed]
- **Impact:** [why it matters]
- **Recommendation:** [what to do — but NOT a code change, just direction]

### Finding 2: ...

## Positive Highlights

[2–4 things the architecture does well. This matters — it tells the user what to preserve.]

## Recommended Review Cadence

[When should this review be re-run? After major feature additions? Before scaling?
Suggest a trigger, not a calendar interval.]
```

## Pre-Gate Self-Check

Before saving the report, verify your output against the contract:

- [ ] Every finding has a Finding ID in format AR-<DIM>-<NNN>
- [ ] `## Handoff` section exists at the end of the output
- [ ] Handoff contains scorecard table with columns: Dimension | Score | Key Finding
- [ ] Each finding in Handoff has: Finding ID, Severity, Dimension, Location, Summary (1-2 sentences)
- [ ] Handoff contains NO positive highlights (keep those in report body only)

If any check fails, fix the output before saving.

## Quick Constraint Checks

Before the full dimensional review, run these fast binary checks against the codebase.
Each is a yes/no question — any "yes" is an immediate finding.

**Dependency direction violations:**
- Does any module in `core/` or `strategy/` import from `data/` or `execution/`?
- Does domain logic reference specific infrastructure (file paths, API endpoints, database
  connections, ORM classes)?
- Are there `import sqlalchemy`, `import requests`, or similar infrastructure imports inside
  business logic modules?

**Encapsulation violations:**
- Are mutable internal collections exposed directly (e.g., returning a list that callers
  can `.append()` to)?
- Can external code construct domain objects in invalid states (missing required fields,
  violating invariants)?

**Testing red flags:**
- Do unit tests require a database, network, or filesystem to run?
- Are tests slow (>5s for the unit suite)? This usually means infrastructure is leaking
  into logic.
- Is there no way to swap a real dependency for a fake/mock without modifying the module
  under test?

**Coupling red flags:**
- Does adding a new strategy/signal/data source require modifying more than 2 existing files?
- Are there `isinstance` or `type ==` checks that would need updating for each new variant?
- Do multiple modules hardcode the same magic numbers, column names, or config values?

These checks run in minutes and often catch the highest-severity findings before the full
review even starts. Report any failures as findings with their dimension and severity.

## Critical Rules

- **Read-only.** Do not modify, create, or delete any source files. This is a diagnostic.
- **Evidence-based.** Every finding must cite specific files, line numbers, and import
  statements. No vague "this could be better" — show the evidence.
- **Scored.** Every dimension gets a score. The scorecard is the first thing the user sees.
- **Actionable.** Every finding includes a recommendation, but expressed as *direction*
  (what to change and why), not *implementation* (how to change it). The refactoring-plan
  and refactor skills handle implementation.
- **Proportional.** Don't flag 30 minor issues in a 200-line project. Focus on the
  structural issues that will compound as the system grows. For small projects, 5–8 findings
  is appropriate. For large projects, 10–15.
- **Honest about strengths.** If the architecture is sound, say so. Not every review needs
  to find problems. Positive highlights build trust and tell the user what to preserve.

## Contract (BCS-1.0)

### Mode
READ-ONLY

### Consumes
- Python project directory and source files
- No structured upstream Handoff required

### Produces
MUST emit a `## Handoff` section at the end of the output containing:
- Scorecard table: Dimension | Score | Key Finding
- Findings each with: Finding ID, Severity, Dimension, Location, Summary (1-2 sentences)
- Finding IDs format: AR-<DIM>-<NNN> where DIM is: BND, DEP, DRY, EXT, TST, ABS, PAR
OPTIONAL inside Handoff:
- Dependency graph (Mermaid)
FORBIDDEN inside Handoff:
- Positive highlights (keep in report body only)

### Degrees of Freedom
- Scorecard uses 🟢🟡🟠🔴
- Dimension: Boundaries | Dependencies | DRY | Extensibility | Testability | Abstraction | Parallelisation
- Location: path/to/file.py or module.symbol

### Downstream Consumers
- refactoring-plan (reads Handoff only, merges with code-review)
- architect (reads Handoff in W3 Redesign)
