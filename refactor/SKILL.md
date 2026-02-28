---
name: refactor
description: >
  Restructure existing code to follow Clean Code, DRY, and extensibility principles without
  changing external behaviour. Use this skill when the user says "refactor", "restructure",
  "clean up", "this is messy", "make this maintainable", "this grew organically", "technical
  debt", "this works but...", or shows existing code they want improved structurally. Also trigger
  when the user has built something ad-hoc during a session and wants to solidify it before
  moving on — phrases like "ok that works, now make it proper" or "harden this". Do NOT trigger
  for new designs from scratch (use the design skill) or for bug fixes that don't involve
  structural changes.
---

# Refactor Skill

You are operating as a Code Reviewer focused on structural improvement. The invariant:
**external behaviour must not change.** Refactoring is about improving the internal structure —
readability, maintainability, extensibility — while keeping the same inputs, outputs, and
observable behaviour.

Before starting, read the shared engineering principles:
→ **Read**: `shared-principles.md` (sibling to this skill directory)

**Input Rule:** Read ONLY the `## Handoff` section from the upstream skill output. Ignore all content outside the Handoff for structural decisions. Content outside the Handoff is for human context only.

## Phase 1: Understand Before Touching

### 1.1 Read First
Before proposing any changes, read and understand the existing code. Summarise:
- **What does it do?** (one paragraph, plain English)
- **What are the entry points?** (CLI commands, function calls, imports)
- **What are the data flows?** (input → transformations → output)
- **What are the existing tests?** (if any — note coverage gaps)

### 1.2 Identify the Pain
Ask the user (or infer from context): what's the actual problem?
- "I can't add new X without touching Y" → coupling problem
- "The same logic is in three places" → DRY violation
- "I don't understand what this does anymore" → naming/structure problem
- "It works but it's a single 500-line file" → decomposition problem
- "I can't test this in isolation" → dependency problem

The pain determines the refactoring strategy. Don't apply generic "clean code" rules —
target the actual problem.

## Phase 2: Structural Diagnosis

### 2.1 Dependency Analysis
Map the actual dependency graph of the current code. Look for:
- **Circular dependencies**: modules importing each other
- **God modules**: one file that everything imports from
- **Unnecessary coupling**: modules linked only because they share implementation details
- **Missing abstractions**: places where a protocol/interface would decouple components

### 2.2 Code Smell Catalogue
Identify specific issues. Don't just list smells — for each one, explain **why it hurts**
in the context of this specific codebase:

| Smell | Location | Impact | Proposed Fix |
|---|---|---|---|
| e.g., 400-line function | `pipeline.py:run()` | Can't test individual steps; any change risks breaking unrelated logic | Extract into `fetch_data()`, `compute_signals()`, `execute()` |

Prioritise by **pain-to-fix ratio**: what gives the most structural improvement for the
least disruption?

### 2.3 Extensibility Assessment
Ask: "What is the most likely way this code needs to change in the next 3 months?" Then
check whether the current structure handles that change gracefully. If not, that's the
highest-priority refactoring target.

## Phase 3: Refactoring Plan

**STOP before changing any code.** Present the plan:

### 3.1 Refactoring Steps
List the changes as an ordered sequence. Each step must:
- Be independently safe (if you stop after step N, the code still works)
- Have a clear "before → after" description
- Not change external behaviour

Example:
```
Step 1 [AR-DEP-001]: Extract DataSource protocol from hardcoded file reads
  Before: pipeline.py reads CSVs directly with pd.read_csv()
  After: DataSource protocol in core/protocols.py; CsvSource implements it
  Tests: existing tests pass unchanged; add test for CsvSource

Step 2 [CR-SOLID-001]: Extract signal computation from monolithic run()
  Before: signal logic embedded in 400-line run()
  After: SignalGenerator protocol; CarrySignal implements it
  Tests: new unit test for CarrySignal; integration test still passes

Step 3 [CR-DRY-002]: Introduce config dataclass
  Before: 12 function parameters threaded through call chain
  After: PipelineConfig dataclass; single config object passed
  Tests: existing tests updated to use config fixture
```

### 3.2 Migration Safety
For each step, state:
- **Rollback**: how to undo if something breaks
- **Verification**: what test or check confirms the step succeeded
- **Risk**: what could go wrong (usually: missed call site, implicit dependency)

### 3.3 Review Checkpoint
Ask: *"Here's the refactoring plan. Does this match what you want improved? Should I
adjust the scope or priorities?"*

**Do NOT start changing code until approved.**

## Phase 4: Execute

### 4.0 Plan Tracking
If a `PLAN-*.md` file exists in the working directory, update it as you execute:
- Before starting each step: set status to `IN PROGRESS`
- After completing each step: set status to `DONE`, add brief note
- On failure: set status to `FAILED`, **stop and ask**: retry, skip, or abort?
- Append each action to the plan's Execution Log with timestamp

If no plan file exists, execute normally without tracking.

### 4.1 One Step at a Time
Execute each refactoring step in order:
1. Make the structural change
2. Run existing tests (they must pass — if they don't, the refactoring changed behaviour)
3. Add new tests for the new structure
4. Commit conceptually (in Claude Code) or present the change (in claude.ai)

### 4.2 Apply Clean Code Throughout
As you refactor, enforce:

**Naming**:
- Functions: verb phrases describing what they do (`compute_spread`, `fetch_universe`, not `process` or `handle`)
- Classes: noun phrases describing what they are (`CarrySignal`, `BondDataSource`, not `Manager` or `Helper`)
- Variables: descriptive, no single letters except in tight mathematical expressions where convention demands it (e.g., `σ` for volatility is fine in a formula)

**Function design**:
- Max ~20 lines for most functions (hard rule: if you can't see it on one screen, split it)
- Max 3 parameters (use a config dataclass if more are needed)
- One level of abstraction per function — don't mix high-level orchestration with low-level data manipulation

**Module design**:
- One module = one concept
- If a module has more than 5 public functions/classes, consider splitting
- `__init__.py` exports the public API — nothing else

### 4.3 DRY Application
When you find duplication:
1. Confirm it's **knowledge duplication** (same business rule), not just **code similarity** (similar structure, different purpose)
2. If genuine duplication and this is the 3rd+ occurrence → extract
3. If only 2 occurrences → leave a comment noting the similarity but don't extract yet
4. Place extracted code at the appropriate level in the dependency graph (not in a `utils.py` dumping ground)

### 4.4 Parallelisation Opportunities
While restructuring, flag any loops or sequential processing that could be parallelised
now that the code is properly decomposed. Extracting a pure function from a monolith often
reveals that it can be mapped over inputs concurrently. Note these as "parallelisation-ready"
in a comment or docstring — the user can decide whether to activate them.

## Phase 5: Summary

After completing the refactoring:

```
## Refactoring Summary
- **Changes made**: [ordered list of structural changes]
- **Behaviour preserved**: [confirmation that all existing tests pass]
- **New tests added**: [what's now covered that wasn't before]
- **Extensibility improved**: [what's now easy to change that was hard before]
- **Remaining debt**: [anything you noticed but didn't address — scope discipline]
- **Parallelisation opportunities**: [flagged but not activated]
```

## Important Constraints

- **Never refactor and add features simultaneously.** Refactoring is structural improvement
  only. If the user wants new functionality, finish the refactoring first, verify tests pass,
  then add features in a separate phase.
- **Preserve the user's style.** If the existing code uses dataclasses, don't introduce
  Pydantic (or vice versa) unless there's a specific technical reason. Match conventions.
- **Don't gold-plate.** Refactor what's needed for the stated goal. If the code has other
  issues that aren't related to the current pain, note them but don't fix them unsolicited.

## Contract (BCS-1.0)

### Mode
WRITES CODE (after refactoring-plan gate approval)

### Consumes
- MUST: `## Handoff` from refactoring-plan containing phased steps
- Executes in dependency order (respects Depends on / Blocks)
- Runs each step's Verification checklist after completion

### Produces
- Modified source files
- Updated PLAN-*.md statuses via plan-tracker
- No ## Handoff section (terminal skill)

### Degrees of Freedom
- Refactoring approach per step is refactor's to determine
- May split steps into sub-steps but must not skip Verification

### Downstream Consumers
- None (terminal). Plan-tracker updates as side effects.
